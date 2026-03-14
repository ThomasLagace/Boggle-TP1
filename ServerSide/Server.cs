using Boggle;
using Network;
using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;

namespace ServerSide
{
    public class Server
    {
        public IPEndPoint Endpoint { get; init; }
        public Socket Socket { get; init; }
        private readonly int _connectionQueueCapacity;
        private readonly BoggleWordsDatabase _db = new("../../../../dict.txt");
        private readonly CancellationTokenSource _cts = new();
        private readonly ConcurrentDictionary<Socket, BogglePlayer> _clients = new();

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

                    await Task.WhenAll(
                        NetworkUtils.SendMessageAsync(socketPlayer1, startGamePacket),
                        NetworkUtils.SendMessageAsync(socketPlayer2, startGamePacket)
                    );

                    queuedMatch.OnGameOver += async () =>
                    {
                        Packet<BoggleGame> endGamePacket = new(Network.Endpoint.EndGame, queuedMatch);

                        await Task.WhenAll(
                            NetworkUtils.SendMessageAsync(socketPlayer1, endGamePacket),
                            NetworkUtils.SendMessageAsync(socketPlayer2, endGamePacket)
                        );
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
                while (!_cts.IsCancellationRequested)
                {
                    Packet<List<(int, int)>> packet = await NetworkUtils.ReceiveMessageAsync<List<(int, int)>>(playerSocket, _cts.Token);

                    if (packet.Endpoint != Network.Endpoint.SubmitGuess) continue;

                    List<(int, int)> guess = packet.Payload;

                    if (!player.Match.ValidateGuess(guess)) continue;

                    string word = player.Match.Board.GetStringFromCoords(guess);

                    if (player.Guesses.Contains(word)) 
                    {
                        Packet<string> dupeGuessPacket = new(Network.Endpoint.ReceiveMessage, "You have already found this word.");

                        await NetworkUtils.SendMessageAsync(playerSocket, dupeGuessPacket);

                        continue;
                    }

                    player.Guesses.Add(word);

                    int points = BoggleUtils.GetPoints(word);

                    if (player.Match.DiscoveredWords.TryGetValue(word, out BogglePlayer? opponent))
                    {
                        opponent.Score -= points;

                        return;
                    }

                    player.Match.DiscoveredWords.Add(word, player);
                    player.Score += points;
                }
            }
        }

        private async Task RegisterPlayerAsync(Socket playerSocket, BoggleGame match) 
        {
            Packet<string> name = await NetworkUtils.ReceiveMessageAsync<string>(playerSocket, _cts.Token);
            BogglePlayer player = new BogglePlayer(name.Payload, match);

            if (_clients.TryAdd(playerSocket, player)) 
            {
                player.OnScoreUpdate += () =>
                {
                    _ = NetworkUtils.SendMessageAsync(playerSocket, new Packet<BogglePlayer>(Network.Endpoint.ScoreUpdate, player));
                };
            }
        }
    }
}