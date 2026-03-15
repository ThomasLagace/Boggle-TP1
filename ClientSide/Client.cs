using System.Net;
using System.Net.Sockets;
using Boggle;
using Network;
using Network.ClientRoutes;
using Network.ServerRoutes;

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

    public event Action<int, int>? OnEndGame;
    public event Action? OnOpponentDisconected;
    public event Action<string>? OnReceiveMessage;
    public event Action<int, int>? OnScoreUpdate;
    public event Action<DateTimeOffset, BoggleBoard, string>? OnGameStart;

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

    public async Task SubmitGuessToServerAsync(List<(int, int)> guess)
    {
        SubmitGuessRouteParams routeParams = new(guess);
        Packet packet = new(Route.SubmitGuess, routeParams);
        await NetworkUtils.SendPacketAsync(_socket, packet, _cts?.Token);
    }

    public async Task SubmitNameToServerAsync(string name)
    {
        SubmitNameRouteParams routeParams = new(name);
        Packet packet = new(Route.SubmitName, routeParams);
        await NetworkUtils.SendPacketAsync(_socket, packet, _cts?.Token);
    }

    private async Task ListenAsync()
    {
        OnLogging?.Invoke("Started listening requests from the server.", LoggingSeverity.Info);

        while (!_cts!.IsCancellationRequested)
        {
            Packet packet;
            try
            {
                packet = await NetworkUtils.ReceivePacketAsync(_socket, _cts.Token);
            }
            catch (OperationCanceledException) { return; }

            switch (packet.Route)
            {
                case Route.EndGame:
                    if (packet.RouteParams is EndGameRouteParams endGameRouteParams)
                        EndGameRoute(endGameRouteParams);
                    break;
                case Route.OpponnentDisconnected:
                    if (packet.RouteParams is OpponentDisconnectedRouteParams opponentDisconnectedRouteParams)
                        ReceiveMessageRoute(receiveMessageRouteParams);
                    break;
                case Route.ReceiveMessage:
                    if (packet.RouteParams is ReceiveMessageRouteParams receiveMessageRouteParams)
                        ReceiveMessageRoute(receiveMessageRouteParams);
                    break;
                case Route.ScoreUpdate:
                    if (packet.RouteParams is ScoreUpdateRouteParams scoreUpdateRouteParams)
                        ScoreUpdateRoute(scoreUpdateRouteParams);
                    break;
                case Route.StartGame:
                    if (packet.RouteParams is StartGameRouteParams startRouteParams)
                        StartGameRoute(startRouteParams);
                    break;
            }
        }
    }

    private void EndGameRoute(EndGameRouteParams routeParams)
    {
        OnEndGame?.Invoke(routeParams.ClientScore, routeParams.OpponentScore);
    }

    private void OpponentDisconectedRoute(OpponentDisconnectedRouteParams routeParams)
    {
        OnOpponentDisconected?.Invoke();
    }

    private void ReceiveMessageRoute(ReceiveMessageRouteParams routeParams)
    {
        OnReceiveMessage?.Invoke(routeParams.Message);
    }

    private void ScoreUpdateRoute(ScoreUpdateRouteParams routeParams)
    {
        OnScoreUpdate?.Invoke(routeParams.ClientScore, routeParams.OpponentScore);
    }

    private void StartGameRoute(StartGameRouteParams routeParams)
    {
        BoggleBoard board = routeParams.BoggleBoard;
        OnGameStart?.Invoke(routeParams.TimeEndOfGame, board, routeParams.OpponentName);
    }
}
