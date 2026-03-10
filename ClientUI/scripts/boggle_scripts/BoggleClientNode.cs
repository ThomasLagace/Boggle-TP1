using Boggle;
using ClientSide;
using Godot;
using Network;
using System;
using System.Net;

[GlobalClass]
public partial class BoggleClientNode : Node
{
    [Signal]
    public delegate void OnConnectReturnEventHandler(bool connectedSuccessfully);

    [Signal]
    public delegate void OnLoggingEventHandler(string message, Client.LoggingSeverity severity);

    [Signal]
    public delegate void OnGameStartEventHandler(long endTime);
    [Signal]
    public delegate void OnScoreUpdateEventHandler(int clientScore, int opponentScore);
    [Signal]
    public delegate void OnReceiveMessageEventHandler(string message);

    public bool HasGameStarted() => _board != null;
    public BoggleBoardResource? GetBoggleBoard() => _board;

    private Client _client;
    private BoggleBoardResource? _board;

    public BoggleClientNode(IPEndPoint iPEndPoint)
    {
        _client = new Client(iPEndPoint);

        _client.OnLogging += (message, severity) =>
        {
            EmitSignal(SignalName.OnLogging, message, (int)severity);
        };

        _client.OnGameStart += (DateTimeOffset endTime, BoggleBoard board) =>
        {
            _board = new BoggleBoardResource(board);
            EmitSignal(SignalName.OnGameStart, endTime.ToUnixTimeSeconds());
        };

        _client.OnScoreUpdate += (clientScore, opponentScore) =>
        {
            EmitSignal(SignalName.OnScoreUpdate, clientScore, opponentScore);
        };

        _client.OnReceiveMessage += (message) =>
        {
            EmitSignal(SignalName.OnReceiveMessage, message);
        };
    }

    public async void ConnectAsync(Callable onConnectionCallback)
    {
        if (_client == null)
        {
            onConnectionCallback.Call(false);
            return;
        }
        await _client.ConnectAsync();

        onConnectionCallback.Call(_client.IsRunning);
    }

    public static BoggleClientNode? CreateClientNode(string stringIp, string stringPort)
    {
        if (!NetworkUtils.IsValidAddress(stringIp, stringPort, out IPEndPoint? iPEndPoint))
            return null;

        return new BoggleClientNode(iPEndPoint!);
    }
}
