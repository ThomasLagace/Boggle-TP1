using Boggle;
using Network;
using Network.ClientRoutes;
using Network.ServerRoutes;
using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;

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

                    await Task.WhenAll(
                        HandleGameplayAsync(socketPlayer1),
                        HandleGameplayAsync(socketPlayer2)
                    );

                    StartGameRouteParams startGameParams = new(DateTimeOffset.Now, queuedMatch.Board); // placeholder date value -- will be replaced shortly
                    Packet startGamePacket = new(Route.StartGame, startGameParams);

                    // Start match clock + notify clients
                    await Task.WhenAll(
                        NetworkUtils.SendPacketAsync(socketPlayer1, startGamePacket, _cts.Token),
                        NetworkUtils.SendPacketAsync(socketPlayer2, startGamePacket, _cts.Token),
                        queuedMatch.StartGame()
                    );

                    // End match handling when clock runs out + notify clients
                    queuedMatch.OnGameOver += async () =>
                    {
                        BogglePlayer player1 = _clients[socketPlayer1];
                        BogglePlayer player2 = _clients[socketPlayer2];

                        EndGameRouteParams endGameParams = new(BoggleGame.GetWinner(player1, player2));
                        Packet endGamePacket = new(Route.EndGame, endGameParams);

                        await Task.WhenAll(
                            NetworkUtils.SendPacketAsync(socketPlayer1, endGamePacket, _cts.Token),
                            NetworkUtils.SendPacketAsync(socketPlayer2, endGamePacket, _cts.Token)
                        );

                        _cts.Cancel();
                    };
                }
                catch (SocketException ex) when (ex.SocketErrorCode == SocketError.Interrupted)
                {
                    break;
                }
                catch (OperationCanceledException) { }
            }
        }

        private async Task HandleGameplayAsync(Socket playerSocket)
        {
            BogglePlayer player;

            if (_clients.TryGetValue(playerSocket, out player!)) 
            {
                // Listen for guesses until game ends
                while (!_cts.IsCancellationRequested)
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
                    catch (OperationCanceledException) { return; }
                }
            }
        }

        private async Task RegisterPlayerAsync(Socket playerSocket, BoggleGame match) 
        {
            // Listen for player name
            Packet namePacket = await NetworkUtils.ReceivePacketAsync(playerSocket, _cts.Token);

            if (namePacket.RouteParams is not SubmitNameRouteParams nameParams) return;

            string name = nameParams.Name;
            BogglePlayer player = new BogglePlayer(name, match);

            if (_clients.TryAdd(playerSocket, player))
            {
                // Notify client when its score updates
                player.OnScoreUpdate += () =>
                {
                    ScoreUpdateRouteParams scoreParams = new(player.Score);
                    Packet scorePacket = new(Route.ScoreUpdate, scoreParams);

                    _ = NetworkUtils.SendPacketAsync(playerSocket, scorePacket, _cts.Token);
                };
            }
        }
    }
}