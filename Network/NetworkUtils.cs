using System.Net.Sockets;
using System.Text;

namespace Network;

public static class NetworkUtils
{
    public static async Task SendMessageAsync(Socket socket, byte[] data, CancellationToken? cts = null)
    {
        await socket.SendAsync(data, cts ?? default);
    }

    public static async Task<byte[]> ReceiveExactAsync(Socket clientSocket, int size, CancellationToken? cts = null)
    {
        byte[] buffer = new byte[size];
        int received = 0;
        while (received < size)
        {
            int bytesRead = await clientSocket.ReceiveAsync(buffer.AsMemory(received, size - received), SocketFlags.None, cts ?? default);
            if (bytesRead == 0)
                throw new SocketException();
            received += bytesRead;
        }
        return buffer;
    }
}
