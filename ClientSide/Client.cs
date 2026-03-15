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

    private CancellationTokenSource _cts = new();
    private Socket _socket;

    public event Action<string, LoggingSeverity>? OnLogging;
    public event Action? OnLostConnection;

    public event Action<int, int>? OnEndGame;
    public event Action? OnOpponentDisconnected;
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
            OnLogging?.Invoke("Tentative de connexion alors qu'une connexion est déjà ouverte.", LoggingSeverity.Warning);
            return;
        }
        OnLogging?.Invoke($"Connexion au serveur à {IP.Address}:{IP.Port}.", LoggingSeverity.Info);

        try
        {
            await _socket.ConnectAsync(IP, _cts.Token);
            IsRunning = true;
        }
        catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionRefused)
        {
            OnLogging?.Invoke("Connexion refusée !", LoggingSeverity.Error);
            return;
        }
        catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
        {
            OnLogging?.Invoke("Délai de connexion dépassé !", LoggingSeverity.Error);
            return;
        }
        catch (OperationCanceledException) { return; }

        OnLogging?.Invoke($"Connecté au serveur à {IP.Address}:{IP.Port}.", LoggingSeverity.Info);

        _ = ListenAsync();
    }

    public void Disconnect()
    {
        if (!IsRunning)
        {
            OnLogging?.Invoke("Tentative de déconnexion sans connexion ouverte.", LoggingSeverity.Warning);
            return;
        }

        OnLogging?.Invoke("Tentative de déconnexion du serveur.", LoggingSeverity.Info);

        _cts.Cancel();
        _cts = new();

        _socket.Shutdown(SocketShutdown.Both);
        _socket.Close();

        OnLogging?.Invoke("Déconnecté du serveur.", LoggingSeverity.Info);
    }

    public async Task SubmitGuessToServerAsync(List<(int, int)> guess)
    {
        SubmitGuessRouteParams routeParams = new(guess);
        Packet packet = new(Route.SubmitGuess, routeParams);
        OnLogging?.Invoke($"Envoie d'un 'guess' au serveur: {guess}.", LoggingSeverity.Info);
        await NetworkUtils.SendPacketAsync(_socket, packet, _cts.Token);
    }

    public async Task SubmitNameToServerAsync(string name)
    {
        SubmitNameRouteParams routeParams = new(name);
        Packet packet = new(Route.SubmitName, routeParams);
        OnLogging?.Invoke($"Envoie du nom au serveur: {name}.", LoggingSeverity.Info);
        await NetworkUtils.SendPacketAsync(_socket, packet, _cts.Token);
    }

    private async Task ListenAsync()
    {
        OnLogging?.Invoke("Début de l'écoute des requêtes du serveur.", LoggingSeverity.Info);

        while (!_cts.IsCancellationRequested)
        {
            Packet packet;
            try
            {
                OnLogging?.Invoke("En attente d'un packet du serveur.", LoggingSeverity.Info);
                packet = await NetworkUtils.ReceivePacketAsync(_socket, _cts.Token);
            }
            catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionReset)
            {
                OnLogging?.Invoke("Connexion au serveur perdue.", LoggingSeverity.Info);
                OnLostConnection?.Invoke();
                Disconnect();
                return;
            }
            catch (OperationCanceledException) { return; }

            OnLogging?.Invoke($"La route {packet.Route} a été exécutée avec les paramètre {packet.RouteParams}.", LoggingSeverity.Info);

            switch (packet.Route)
            {
                case Route.EndGame:
                    if (packet.RouteParams is EndGameRouteParams endGameRouteParams)
                        EndGameRoute(endGameRouteParams);
                    break;
                case Route.OpponentDisconnected:
                    if (packet.RouteParams is OpponentDisconnectedRouteParams opponentDisconnectedRouteParams)
                        OpponentDisconectedRoute(opponentDisconnectedRouteParams);
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
        OnOpponentDisconnected?.Invoke();
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
