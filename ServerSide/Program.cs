using System.Net;

namespace ServerSide
{
    internal class Program
    {
        static void Main(string[] args)
        {
            IPEndPoint endpoint = new IPEndPoint(IPAddress.Loopback, 12345);
            Server server = new Server(endpoint);

            _ = server.StartupAsync();
            Console.ReadLine();
        }
    }
}
