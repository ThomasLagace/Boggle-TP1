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
        private BoggleWordsDatabase _db = new BoggleWordsDatabase(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "../../../../dict.txt"));
        private CancellationTokenSource _cts = new CancellationTokenSource();
        private ConcurrentDictionary<Socket, BogglePlayer> _clients = new ConcurrentDictionary<Socket, BogglePlayer>();

        public Server(IPEndPoint endpoint)
        {
            this.Endpoint = endpoint;
            this.Socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
        }

        public async Task StartupAsync() 
        {
            try
            {
                this.Socket.Bind(this.Endpoint);
            }
            catch (SocketException ex) when (ex.SocketErrorCode == SocketError.AddressAlreadyInUse)
            {
                return;
            }

            this.Socket.Listen(10);

            while (!_cts.IsCancellationRequested) 
            {
                BoggleGame queuedMatch = new BoggleGame(_db);

                try
                {
                    Socket socketPlayer1 = await this.Socket.AcceptAsync(_cts.Token);
                    await RegisterPlayerAsync(socketPlayer1, queuedMatch);

                    Socket socketPlayer2 = await this.Socket.AcceptAsync(_cts.Token);
                    await RegisterPlayerAsync(socketPlayer2, queuedMatch);
                }
                catch (SocketException ex) when (ex.SocketErrorCode == SocketError.Interrupted)
                {
                    break;
                }
                catch (OperationCanceledException) { }
            }
        }

        private async Task RegisterPlayerAsync(Socket playerSocket, BoggleGame match) 
        {
            string name = await NetworkUtils.ReceiveMessageAsync(playerSocket, _cts.Token);

            _clients.TryAdd(playerSocket, new BogglePlayer(name, match));
        }
    }
}