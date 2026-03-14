using Boggle;
using Network;
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

                    Packet<BoggleGame> startGamePacket = new(Network.Endpoint.StartGame, queuedMatch);

                    // Start match clock + notify clients
                    await Task.WhenAll(
                        NetworkUtils.SendMessageAsync(socketPlayer1, startGamePacket, _cts.Token),
                        NetworkUtils.SendMessageAsync(socketPlayer2, startGamePacket, _cts.Token),
                        queuedMatch.StartGame()
                    );

                    // End match handling when clock runs out + notify clients
                    queuedMatch.OnGameOver += async () =>
                    {
                        Packet<BoggleGame> endGamePacket = new(Network.Endpoint.EndGame, queuedMatch);

                        await Task.WhenAll(
                            NetworkUtils.SendMessageAsync(socketPlayer1, endGamePacket, _cts.Token),
                            NetworkUtils.SendMessageAsync(socketPlayer2, endGamePacket, _cts.Token)
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
                        Packet<List<(int, int)>> packet = await NetworkUtils.ReceiveMessageAsync<List<(int, int)>>(playerSocket, _cts.Token);

                        if (packet.Endpoint != Network.Endpoint.SubmitGuess) continue;

                        List<(int, int)> guess = packet.Payload;

                        if (!player.Match.ValidateGuess(guess)) continue;

                        string word = player.Match.Board.GetStringFromCoords(guess);

                        // Limit double guesses + notify client
                        if (player.Guesses.Contains(word))
                        {
                            Packet<string> dupeGuessPacket = new(Network.Endpoint.ReceiveMessage, Warning.DuplicateGuess);

                            await NetworkUtils.SendMessageAsync(playerSocket, dupeGuessPacket, _cts.Token);

                            continue;
                        }

                        player.Guesses.Add(word);

                        int points = BoggleUtils.GetPoints(word);

                        // Penalize shared guesses + notify clients
                        if (player.Match.DiscoveredWords.TryGetValue(word, out BogglePlayer? opponent))
                        {
                            if (_clients.TryGetKey(opponent, out Socket opponentSocket)) 
                            {
                                Packet<string> sharedGuessPacket = new(Network.Endpoint.ReceiveMessage, Warning.SharedGuess(word));

                                await Task.WhenAll(
                                    NetworkUtils.SendMessageAsync(playerSocket, sharedGuessPacket, _cts.Token),
                                    NetworkUtils.SendMessageAsync(opponentSocket, sharedGuessPacket, _cts.Token)
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
            Packet<string> name = await NetworkUtils.ReceiveMessageAsync<string>(playerSocket, _cts.Token);
            BogglePlayer player = new BogglePlayer(name.Payload, match);

            if (_clients.TryAdd(playerSocket, player)) 
            {
                // Notify client when its score updates
                player.OnScoreUpdate += () =>
                {
                    Packet<BogglePlayer> scorePacket = new(Network.Endpoint.ScoreUpdate, player);

                    _ = NetworkUtils.SendMessageAsync(playerSocket, scorePacket, _cts.Token);
                };
            }
        }
    }
}