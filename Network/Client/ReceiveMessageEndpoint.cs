namespace Network.Client;

public class ReceiveMessageEndpoint
{
    public string Message { get; init; }

    public ReceiveMessageEndpoint(string message)
    {
        Message = message;
    }
}
