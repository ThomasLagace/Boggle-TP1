using ClientSide;
using Godot;
using Network;
using System.Net;

[GlobalClass]
public partial class BoggleClientNode : Node
{
	[Signal]
	public delegate void OnLoggingEventHandler(string message, Client.LoggingSeverity severity);
	[Signal]
	public delegate void OnGameStartEventHandler(long endTime);

	private Client? _client;

	public bool InitializeClient(string stringIp, string stringPort)
	{
		if (!NetworkUtils.IsValidAddress(stringIp, stringPort, out IPEndPoint iPEndPoint)) return false;
		_client = new(iPEndPoint);
		return true;
	}
}
