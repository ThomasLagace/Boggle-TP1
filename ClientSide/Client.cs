using System.Net;
using System.Net.Sockets;
using System.Text;
using Boggle;
using Network;

namespace ClientSide;

public class Client
{
    public enum ClientEndPoint
    {
        /**
         * Enpoint to start the game
         *
         * Bytes:
         * [0-3]  : ClientEndPoint enum
         * [4-11] : Time end of game (unix time)
         * [12-27]: 16 chars for the dice, "Qu" is sent "Q", from top left to bottom right
         */
        StartGame,
    }

    public IPEndPoint IP { get; private set; }
    public bool IsRunning { get; private set; } = false;

    private CancellationTokenSource? _cts;
    private Socket _socket;

    public event Action<DateTimeOffset, BoggleBoard>? OnGameStart;

    public Client(IPEndPoint ip)
    {
        IP = ip;
        _socket = new(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
    }
    
    public async void Connect()
    {
        if (IsRunning) return;

        _cts = new();

        try
        {
            await _socket.ConnectAsync(IP, _cts.Token);
            IsRunning = true;
        }
        catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionRefused)
        {
            Console.WriteLine(ex.Message);
            return;
        }
        catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
        {
            Console.WriteLine(ex.Message);
            return;
        }

        Listen();
    }

    public void Disconnect()
    {
        if (!IsRunning) return;

        _cts?.Cancel();
        _cts = null;

        _socket.Shutdown(SocketShutdown.Both);
        _socket.Close();
    }

    private async void Listen()
    {
        while (!_cts!.IsCancellationRequested)
        {
            try
            {
                byte[] byteEndPoint = await NetworkUtils.ReceiveExactAsync(_socket, 4, _cts.Token);
                ClientEndPoint endPoint = (ClientEndPoint)Enum.ToObject(typeof(ClientEndPoint), BitConverter.ToInt32(byteEndPoint, 0));

                switch (endPoint)
                {
                    case ClientEndPoint.StartGame:
                        byte[] unixTimeBytes = await NetworkUtils.ReceiveExactAsync(_socket, 8, _cts.Token);
                        DateTimeOffset endOfGameTime = DateTimeOffset.FromUnixTimeSeconds(BitConverter.ToInt64(unixTimeBytes, 0));

                        byte[] diceBytes = await NetworkUtils.ReceiveExactAsync(_socket, 16, _cts.Token);
                        char[] diceChars = Encoding.UTF8.GetChars(diceBytes);
                        StartGameEndPoint(endOfGameTime, diceChars);
                        break;
                }
            }
            finally { }
        }
    }

    private void StartGameEndPoint(DateTimeOffset endOfGameTime, char[] diceChars)
    {
        if (diceChars.Length < 16)
            return;
        List<string> diceStrings = new();

        for (int i = 0; i < 16; i++)
        {
            char diceChar = diceChars[i];
            if (diceChar == 'Q')
                diceStrings.Add("Qu");
            else
                diceStrings.Add(diceChar.ToString());
        }
        
        List<List<IDie>> dice = new();
        for (var i = 0; i < 4; i++)
        {
            dice.Add([
                new SimpleDie(diceStrings[i * 4 + 0]),
                new SimpleDie(diceStrings[i * 4 + 1]),
                new SimpleDie(diceStrings[i * 4 + 2]),
                new SimpleDie(diceStrings[i * 4 + 3])
            ]);
        }

        BoggleBoard board = new(dice);
        OnGameStart?.Invoke(endOfGameTime, board);
    }
}
