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

                    // Notify clients when scores update
                    player1.OnScoreUpdate += () => HandleScoreUpdate(socketPlayer1, socketPlayer2);
                    player2.OnScoreUpdate += () => HandleScoreUpdate(socketPlayer1, socketPlayer2);

                    await StartGameAsync(queuedMatch, socketPlayer1, socketPlayer2);

                    _ = HandleGameplayAsync(socketPlayer1, queuedMatch.GameCts);
                    _ = HandleGameplayAsync(socketPlayer2, queuedMatch.GameCts);

                    // End match handling when clock runs out + notify clients
                    queuedMatch.OnGameOver += async () => await HandleGameOverAsync(socketPlayer1, socketPlayer2);
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

        private async Task StartGameAsync(BoggleGame game, Socket player1Socket, Socket player2Socket)
        {
            BogglePlayer player1 = _clients[player1Socket];
            BogglePlayer player2 = _clients[player2Socket];

            game.GameEndTime = DateTimeOffset.Now + TimeSpan.FromMinutes(3);

            StartGameRouteParams startGameParams1 = new(game.GameEndTime, game.Board, player2.Name);
            StartGameRouteParams startGameParams2 = new(game.GameEndTime, game.Board, player1.Name);

            Packet startGamePacket1 = new(Route.StartGame, startGameParams1);
            Packet startGamePacket2 = new(Route.StartGame, startGameParams2);

            await Task.WhenAll(
                NetworkUtils.SendPacketAsync(player1Socket, startGamePacket1, _cts.Token),
                NetworkUtils.SendPacketAsync(player2Socket, startGamePacket2, _cts.Token)
            );

            _ = game.StartGame(_cts.Token);
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

        private void HandleScoreUpdate(Socket player1Socket, Socket player2Socket)
        {
            BogglePlayer player1 = _clients[player1Socket];
            BogglePlayer player2 = _clients[player2Socket];

            ScoreUpdateRouteParams scoreParams1 = new(player1.Score, player2.Score);
            Packet scorePacket1 = new(Route.ScoreUpdate, scoreParams1);

            ScoreUpdateRouteParams scoreParams2 = new(player2.Score, player1.Score);
            Packet scorePacket2 = new(Route.ScoreUpdate, scoreParams2);

            _ = NetworkUtils.SendPacketAsync(player1Socket, scorePacket1, _cts.Token);
            _ = NetworkUtils.SendPacketAsync(player2Socket, scorePacket2, _cts.Token);
        }

        private async Task HandleGameOverAsync(Socket player1Socket, Socket player2Socket)
        {
            BogglePlayer player1 = _clients[player1Socket];
            BogglePlayer player2 = _clients[player2Socket];

            EndGameRouteParams endGameParamsPlayer1 = new(player1.Score, player2.Score);
            EndGameRouteParams endGameParamsPlayer2 = new(player2.Score, player1.Score);

            Packet endGamePacket1 = new(Route.EndGame, endGameParamsPlayer1);
            Packet endGamePacket2 = new(Route.EndGame, endGameParamsPlayer2);

            await Task.WhenAll(
                NetworkUtils.SendPacketAsync(player1Socket, endGamePacket1, _cts.Token),
                NetworkUtils.SendPacketAsync(player2Socket, endGamePacket2, _cts.Token)
            );
        }
    }
}