using Boggle;
using Network;
using Network.ClientRoutes;
using Network.ServerRoutes;
using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Numerics;

namespace ServerSide
{
    public class Server : Warning
    {
        public IPEndPoint Endpoint { get; init; }
        public Socket Socket { get; init; }
        private readonly int _connectionQueueCapacity;
        private readonly BoggleWordsDatabase _db = new("../../../../dict.txt");
        private readonly CancellationTokenSource _cts = new();
        private readonly ConcurrentBiDictionary<Socket, BogglePlayer> _clients = new();

        public Server(IPEndPoint endpoint, int connectionQueueCapacity = 10)
        {
            this.Endpoint = endpoint;
            this.Socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            this._connectionQueueCapacity = connectionQueueCapacity;
        }

        public async Task StartupAsync() 
        {
            Console.WriteLine($"Starting server on {Endpoint.Address}:{Endpoint.Port}...");

            try
            {
                Socket.Bind(Endpoint);
            }
            catch (SocketException ex) when (ex.SocketErrorCode == SocketError.AddressAlreadyInUse)
            {
                return;
            }

            Socket.Listen(_connectionQueueCapacity);

            while (!_cts.IsCancellationRequested) 
            {
                BoggleGame queuedMatch = new(_db);

                try
                {
                    Socket socketPlayer1 = await Socket.AcceptAsync(_cts.Token);
                    await RegisterPlayerAsync(socketPlayer1, queuedMatch);

                    Socket socketPlayer2 = await Socket.AcceptAsync(_cts.Token);
                    await RegisterPlayerAsync(socketPlayer2, queuedMatch);

                    BogglePlayer player1 = _clients[socketPlayer1];
                    BogglePlayer player2 = _clients[socketPlayer2];

                    // Notify client 1 when its score updates
                    player1.OnScoreUpdate += () =>
                    {
                        ScoreUpdateRouteParams scoreParams = new(player1.Score, player2.Score);
                        Packet scorePacket = new(Route.ScoreUpdate, scoreParams);

                        _ = NetworkUtils.SendPacketAsync(socketPlayer1, scorePacket, _cts.Token);
                    };

                    // Notify client 2 when its score updates
                    player2.OnScoreUpdate += () =>
                    {
                        ScoreUpdateRouteParams scoreParams = new(player2.Score, player1.Score);
                        Packet scorePacket = new(Route.ScoreUpdate, scoreParams);

                        _ = NetworkUtils.SendPacketAsync(socketPlayer2, scorePacket, _cts.Token);
                    };

                    StartGameRouteParams startGameParams1 = new(queuedMatch.GameEndTime, queuedMatch.Board, player2.Name);
                    StartGameRouteParams startGameParams2 = new(queuedMatch.GameEndTime, queuedMatch.Board, player1.Name);

                    Packet startGamePacket1 = new(Route.StartGame, startGameParams1);
                    Packet startGamePacket2 = new(Route.StartGame, startGameParams2);

                    // Start match clock + notify clients
                    await Task.WhenAll(
                        NetworkUtils.SendPacketAsync(socketPlayer1, startGamePacket1, _cts.Token),
                        NetworkUtils.SendPacketAsync(socketPlayer2, startGamePacket2, _cts.Token),
                        queuedMatch.StartGame(_cts.Token)
                    );

                    // End match handling when clock runs out + notify clients
                    queuedMatch.OnGameOver += async () =>
                    {
                        EndGameRouteParams endGameParamsPlayer1 = new(player1.Score, player2.Score);
                        EndGameRouteParams endGameParamsPlayer2 = new(player2.Score, player1.Score);

                        Packet endGamePacket1 = new(Route.EndGame, endGameParamsPlayer1);
                        Packet endGamePacket2 = new(Route.EndGame, endGameParamsPlayer2);

                        await Task.WhenAll(
                            NetworkUtils.SendPacketAsync(socketPlayer1, endGamePacket1, _cts.Token),
                            NetworkUtils.SendPacketAsync(socketPlayer2, endGamePacket2, _cts.Token)
                        );
                    };

                    await Task.WhenAll(
                        HandleGameplayAsync(socketPlayer1, queuedMatch.GameCts),
                        HandleGameplayAsync(socketPlayer2, queuedMatch.GameCts)
                    );
                }
                catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionReset) { break; }
                catch (SocketException ex) when (ex.SocketErrorCode == SocketError.Interrupted) { break; }
                catch (OperationCanceledException) { }
            }

            await ShutdownAsync();
        }

        public async Task ShutdownAsync()
        {
            // Notify clients of shutdown
            foreach (var client in _clients) 
            {
                try
                {
                    ReceiveMessageRouteParams connectionErrorParams = new(Warning.ConnectionLost);
                    Packet connectionErrorPacket = new(Route.ReceiveMessage, connectionErrorParams);

                    await NetworkUtils.SendPacketAsync(client.Key, connectionErrorPacket);
                }
                catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionReset) { }
            }

            _cts.Cancel();

            Socket.Shutdown(SocketShutdown.Both);
            Socket.Close();
        }

        private async Task HandleGameplayAsync(Socket playerSocket, CancellationTokenSource gameCts)
        {
            if (_clients.TryGetValue(playerSocket, out BogglePlayer player)) 
            {
                // Listen for guesses until game ends
                while (!gameCts.IsCancellationRequested)
                {
                    try 
                    {
                        Packet guessPacket = await NetworkUtils.ReceivePacketAsync(playerSocket, _cts.Token);

                        if (guessPacket.RouteParams is not SubmitGuessRouteParams guessParams) continue;

                        List<(int, int)> guess = guessParams.Guess;

                        if (!player.Match.ValidateGuess(guess)) continue;

                        string word = player.Match.Board.GetStringFromCoords(guess);

                        // Limit double guesses + notify client
                        if (player.Guesses.Contains(word))
                        {
                            ReceiveMessageRouteParams warningParams = new(Warning.DuplicateGuess);
                            Packet dupeGuessPacket = new(Route.ReceiveMessage, warningParams);

                            await NetworkUtils.SendPacketAsync(playerSocket, dupeGuessPacket, _cts.Token);

                            continue;
                        }

                        player.Guesses.Add(word);

                        int points = BoggleUtils.GetPoints(word);

                        // Penalize shared guesses + notify clients
                        if (player.Match.DiscoveredWords.TryGetValue(word, out BogglePlayer? opponent))
                        {
                            if (_clients.TryGetKey(opponent, out Socket opponentSocket)) 
                            {
                                ReceiveMessageRouteParams warningParams = new(Warning.SharedGuess(word));
                                Packet sharedGuessPacket = new(Route.ReceiveMessage, warningParams);

                                await Task.WhenAll(
                                    NetworkUtils.SendPacketAsync(playerSocket, sharedGuessPacket, _cts.Token),
                                    NetworkUtils.SendPacketAsync(opponentSocket, sharedGuessPacket, _cts.Token)
                                );
                            }

                            opponent.Score -= points;

                            return;
                        }

                        player.Match.DiscoveredWords.Add(word, player);
                        player.Score += points;
                    }
                    catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionReset) { return; }
                    catch (OperationCanceledException) { return; }
                }
            }
        }

        private async Task RegisterPlayerAsync(Socket playerSocket, BoggleGame match) 
        {
            try
            {
                // Listen for player name
                Packet namePacket = await NetworkUtils.ReceivePacketAsync(playerSocket, _cts.Token); 
                
                if (namePacket.RouteParams is not SubmitNameRouteParams nameParams) return;

                string name = nameParams.Name;
                BogglePlayer player = new BogglePlayer(name, match);

                _clients.TryAdd(playerSocket, player);
            }
            catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionReset) { return; }
        }
    }
}