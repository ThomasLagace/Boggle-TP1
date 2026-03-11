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
        private readonly int _connectionQueuecapcity;
        private readonly BoggleWordsDatabase _db = new("../../../../dict.txt");
        private readonly CancellationTokenSource _cts = new();
        private readonly ConcurrentDictionary<Socket, BogglePlayer> _clients = new();

        public Server(IPEndPoint endpoint, int connectionQueueCapacity = 10)
        {
            this.Endpoint = endpoint;
            this.Socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            this._connectionQueuecapcity = connectionQueueCapacity;
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

            Socket.Listen(_connectionQueuecapcity);

            while (!_cts.IsCancellationRequested) 
            {
                BoggleGame queuedMatch = new BoggleGame(_db);

                try
                {
                    Socket socketPlayer1 = await Socket.AcceptAsync(_cts.Token);
                    await RegisterPlayerAsync(socketPlayer1, queuedMatch);

                    Socket socketPlayer2 = await Socket.AcceptAsync(_cts.Token);
                    await RegisterPlayerAsync(socketPlayer2, queuedMatch);

                    await HandleMatchAsync(socketPlayer1);
                    await HandleMatchAsync(socketPlayer2);

                    //Add time property to BoggleGame
                    await NetworkUtils.SendMessageAsync(socketPlayer1, new Packet<BoggleGame>(Network.Endpoint.StartGame, queuedMatch));
                    await NetworkUtils.SendMessageAsync(socketPlayer2, new Packet<BoggleGame>(Network.Endpoint.StartGame, queuedMatch));
                }
                catch (SocketException ex) when (ex.SocketErrorCode == SocketError.Interrupted)
                {
                    break;
                }
                catch (OperationCanceledException) { }
            }
        }

        private async Task HandleMatchAsync(Socket playerSocket)
        {
            BogglePlayer player;
            _clients.TryGetValue(playerSocket, out player!);

            while (!_cts.IsCancellationRequested)
            {
                Packet<List<(int, int)>> packet = await NetworkUtils.ReceiveMessageAsync<List<(int, int)>>(playerSocket, _cts.Token);
                List<(int, int)> guess = packet.Payload;

                if (!player.Match.ValidateGuess(guess))
                {
                    continue;
                }

                string word = player.Match.Board.GetStringFromCoords(guess);
                int points = BoggleUtils.GetPoints(word);

                //Handle duplicate word verification
                player.Score += points;
            }
        }

        private async Task RegisterPlayerAsync(Socket playerSocket, BoggleGame match) 
        {
            Packet<string> name = await NetworkUtils.ReceiveMessageAsync<string>(playerSocket, _cts.Token);

            _clients.TryAdd(playerSocket, new BogglePlayer(name.Payload, match));
        }
    }
}