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
         * [4-11] : Time end of game (unix time) (long)
         * [12-27]: 16 chars for the dice, "Qu" is sent "Q", from top left to bottom right
         */
        StartGame,
        /**
         * Enpoint to update the score
         *
         * Bytes:
         * [0-3] : ClientEndPoint enum
         * [4-7] : Client Score (int)
         * [8-11]: Opponent Score (int)
         */
        ScoreUpdate,
        /**
         * Enpoint to send a message to the client
         *
         * Bytes:
         * [0-3]      : ClientEndPoint enum
         * [4-7]      : Size of message (n) (int)
         * [8-(n + 8)]: Message (string)
         */
        ReceiveMessage,
    }

    public IPEndPoint IP { get; private set; }
    public bool IsRunning { get; private set; } = false;

    private CancellationTokenSource? _cts;
    private Socket _socket;

    public event Action<DateTimeOffset, BoggleBoard>? OnGameStart;
    public event Action<int, int>? OnScoreUpdate;
    public event Action<string>? OnReceiveMessage;

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
                int endPointInt = BitConverter.ToInt32(await NetworkUtils.ReceiveExactAsync(_socket, 4, _cts.Token));
                ClientEndPoint endPoint = (ClientEndPoint)Enum.ToObject(typeof(ClientEndPoint), endPointInt);

                switch (endPoint)
                {
                    case ClientEndPoint.StartGame:
                        byte[] unixTimeBytes = await NetworkUtils.ReceiveExactAsync(_socket, 8, _cts.Token);
                        DateTimeOffset endOfGameTime = DateTimeOffset.FromUnixTimeSeconds(BitConverter.ToInt64(unixTimeBytes));

                        byte[] diceBytes = await NetworkUtils.ReceiveExactAsync(_socket, 16, _cts.Token);
                        char[] diceChars = Encoding.UTF8.GetChars(diceBytes);
                        StartGameEndPoint(endOfGameTime, diceChars);
                        break;
                    case ClientEndPoint.ScoreUpdate:
                        int clientScore = BitConverter.ToInt32(await NetworkUtils.ReceiveExactAsync(_socket, 4, _cts.Token));
                        int opponentScore = BitConverter.ToInt32(await NetworkUtils.ReceiveExactAsync(_socket, 4, _cts.Token));
                        ScoreUpdateEndPoint(clientScore, opponentScore);
                        break;
                    case ClientEndPoint.ReceiveMessage:
                        int lengthPrefix = BitConverter.ToInt32(await NetworkUtils.ReceiveExactAsync(_socket, 4, _cts.Token));
                        string message = Encoding.UTF8.GetString(await NetworkUtils.ReceiveExactAsync(_socket, lengthPrefix, _cts.Token));
                        ReceiveMessageEndPoint(message);
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

    private void ScoreUpdateEndPoint(int clientScore, int opponentScore)
    {
        OnScoreUpdate?.Invoke(clientScore, opponentScore);
    }

    private void ReceiveMessageEndPoint(string message)
    {
        OnReceiveMessage?.Invoke(message);
    }
}
