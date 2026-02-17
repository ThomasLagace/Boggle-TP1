using System.Net;
using System.Net.Sockets;
using System.Text;

namespace Network;

public static class NetworkUtils
{
    public static async Task SendMessageAsync(Socket socket, string message, CancellationToken? cts = null)
    {
        byte[] messageLength = BitConverter.GetBytes(message.Length);
        byte[] messageBytes = Encoding.UTF8.GetBytes(message);

        await SendDataAsync(socket, [.. messageLength, .. messageBytes], cts);
    }

    public static async Task<string> ReceiveMessageAsync(Socket socket, CancellationToken? cts = null)
    {
        int lengthMessage = BitConverter.ToInt32(await ReceiveExactAsync(socket, sizeof(int), cts));
        string message = Encoding.UTF8.GetString(await ReceiveExactAsync(socket, lengthMessage, cts));

        return message;
    }

    public static async Task SendDataAsync(Socket socket, byte[] data, CancellationToken? cts = null)
    {
        await socket.SendAsync(data, cts ?? default);
    }

    public static async Task<byte[]> ReceiveExactAsync(Socket socket, int size, CancellationToken? cts = null)
    {
        byte[] buffer = new byte[size];
        int received = 0;
        while (received < size)
        {
            int bytesRead = await socket.ReceiveAsync(buffer.AsMemory(received, size - received), SocketFlags.None, cts ?? default);
            if (bytesRead == 0)
                throw new SocketException();
            received += bytesRead;
        }
        return buffer;
    }

    public static bool IsValidAddress(string address, string port, out IPEndPoint? iPEndPoint)
    {
        iPEndPoint = null;
        if (!ConfirmPort(port, out int portInt)) return false;
        if (IPAddress.TryParse(address, out IPAddress? iPAddress)) return false;

        iPEndPoint = new(iPAddress!, portInt);
        return true;
    }

    public static bool ConfirmPort(string input, out int holder)
    {
        if (!int.TryParse(input, out holder)) return false;
        if (input == null || input.Length == 0) return false;

        return holder > 0 && holder <= 65535;
    }
}
