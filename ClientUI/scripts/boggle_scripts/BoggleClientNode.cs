using Boggle;
using ClientSide;
using Godot;
using Network;
using System;
using System.Collections.Generic;
using System.Net;

[GlobalClass]
public partial class BoggleClientNode : Node
{
    [Signal]
    public delegate void OnLoggingEventHandler(string message, Client.LoggingSeverity severity);

    [Signal]
    public delegate void OnGameEndEventHandler(long endTime);
    [Signal]
    public delegate void OnReceiveMessageEventHandler(string message);
    [Signal]
    public delegate void OnScoreUpdateEventHandler(int clientScore, int opponentScore);
    [Signal]
    public delegate void OnGameStartEventHandler(long endTime);

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

        _client.OnEndGame += (clientScore, opponentScore) =>
        {
            EmitSignal(SignalName.OnGameEnd, clientScore, opponentScore);
        };

        _client.OnReceiveMessage += (message) =>
        {
            EmitSignal(SignalName.OnReceiveMessage, message);
        };

        _client.OnScoreUpdate += (clientScore, opponentScore) =>
        {
            EmitSignal(SignalName.OnScoreUpdate, clientScore, opponentScore);
        };

        _client.OnGameStart += (DateTimeOffset endTime, BoggleBoard board) =>
        {
            _board = new BoggleBoardResource(board);
            EmitSignal(SignalName.OnGameStart, endTime.ToUnixTimeSeconds());
        };
    }

    public void SubmitGuessToServer(Godot.Collections.Array<BoggleCoords> boggleCoords)
    {
        List<(int, int)> guess = GodotUtils.ConvertBoggleCoordsToTuple(boggleCoords);
        _ = _client.SubmitGuessToServerAsync(guess);
    }

    public void SubmitNameToServer(string name)
    {
        _ = _client.SubmitNameToServerAsync(name);
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
