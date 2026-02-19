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
	public BoggleBoardNode? GetBoggleBoard() => _board;

	private Client _client;
	private BoggleBoardNode? _board;

	public BoggleClientNode(IPEndPoint iPEndPoint)
	{
		_client = new Client(iPEndPoint);

		_client.OnLogging += (message, severity) =>
		{
			EmitSignal(SignalName.OnLogging, message, (int)severity);
		};

		_client.OnGameStart += (DateTimeOffset endTime, BoggleBoard board) =>
		{
			_board = new BoggleBoardNode(board);
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

	public async void ConnectAsync()
	{
		if (_client == null)
		{
			EmitSignal(SignalName.OnConnectReturn, false);
			return;
		}
        await _client.ConnectAsync();

        EmitSignal(SignalName.OnConnectReturn, _client.IsRunning);
	}

    public override void _Notification(int what)
    {
		if (what == NotificationPredelete)
		{
			_board?.QueueFree();
		}
    }

    public static BoggleClientNode? CreateClientNode(string stringIp, string stringPort)
	{
		if (!NetworkUtils.IsValidAddress(stringIp, stringPort, out IPEndPoint? iPEndPoint))
			return null;

		return new BoggleClientNode(iPEndPoint!);
	}
}
