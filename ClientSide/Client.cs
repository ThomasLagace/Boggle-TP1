using System.Net;
using System.Net.Sockets;
using Boggle;
using Network;
using Network.Client;

namespace ClientSide;

public class Client
{
    public enum LoggingSeverity
    {
        Info,
        Warning,
        Error,
    }

    public IPEndPoint IP { get; private set; }
    public bool IsRunning { get; private set; } = false;

    private CancellationTokenSource? _cts;
    private Socket _socket;

    public event Action<string, LoggingSeverity>? OnLogging;

    public event Action<DateTimeOffset, BoggleBoard>? OnGameStart;
    public event Action<int, int>? OnScoreUpdate;
    public event Action<string>? OnReceiveMessage;

    public Client(IPEndPoint ip)
    {
        IP = ip;
        _socket = new(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
    }
    
    public async Task ConnectAsync()
    {
        if (IsRunning)
        {
            OnLogging?.Invoke("Trying to connect with an already opened connection.", LoggingSeverity.Warning);
            return;
        }
        OnLogging?.Invoke($"Connecting to server at {IP.Address}:{IP.Port}.", LoggingSeverity.Info);

        _cts = new();

        try
        {
            await _socket.ConnectAsync(IP, _cts.Token);
            IsRunning = true;
        }
        catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionRefused)
        {
            OnLogging?.Invoke("Connection refused!", LoggingSeverity.Error);
            return;
        }
        catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
        {
            OnLogging?.Invoke("Connection timed out!", LoggingSeverity.Error);
            return;
        }
        catch (OperationCanceledException)
        {
            return;
        }

        OnLogging?.Invoke($"Connected to server at {IP.Address}:{IP.Port}.", LoggingSeverity.Info);

        _ = ListenAsync();
    }

    public void Disconnect()
    {
        if (!IsRunning)
        {
            OnLogging?.Invoke("Trying to disconnect from a server without an opened connection.", LoggingSeverity.Warning);
            return;
        }

        OnLogging?.Invoke("Trying to disconect from server.", LoggingSeverity.Info);

        _cts?.Cancel();
        _cts = null;

        _socket.Shutdown(SocketShutdown.Both);
        _socket.Close();

        OnLogging?.Invoke("Disconnected from server.", LoggingSeverity.Info);
    }

    private async Task ListenAsync()
    {
        OnLogging?.Invoke("Started listening requests from the server.", LoggingSeverity.Info);

        while (!_cts!.IsCancellationRequested)
        {
            Packet<object> packet;
            try
            {
                packet = await NetworkUtils.ReceiveMessageAsync<object>(_socket, _cts.Token);
            }
            catch (OperationCanceledException) { return; }

            switch (packet.Endpoint)
            {
                case Endpoint.StartGame:
                    if (packet.Payload is StartGameEndpoint startEndpointParams)
                        StartGameEndPoint(startEndpointParams);
                    break;
                case Endpoint.ScoreUpdate:
                    if (packet.Payload is ScoreUpdateEndpoint scoreUpdateEndpointParams)
                        ScoreUpdateEndPoint(scoreUpdateEndpointParams);
                    break;
                case Endpoint.ReceiveMessage:
                    if (packet.Payload is ReceiveMessageEndpoint receiveMessageEndpointParams)
                        ReceiveMessageEndPoint(receiveMessageEndpointParams);
                    break;
            }
        }
    }

    private void StartGameEndPoint(StartGameEndpoint endpointParams)
    {
        BoggleBoard board = endpointParams.BoggleBoard;
        OnGameStart?.Invoke(endpointParams.TimeEndOfGame, board);
    }

    private void ScoreUpdateEndPoint(ScoreUpdateEndpoint endpointParams)
    {
        OnScoreUpdate?.Invoke(endpointParams.ClientScore, endpointParams.OpponentScore);
    }

    private void ReceiveMessageEndPoint(ReceiveMessageEndpoint receiveMessageEndpointParams)
    {
        OnReceiveMessage?.Invoke(receiveMessageEndpointParams.Message);
    }
}
