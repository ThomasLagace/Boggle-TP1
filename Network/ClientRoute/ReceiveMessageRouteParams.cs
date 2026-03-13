namespace Network.ClientRoute;

public class ReceiveMessageRouteParams : RouteParams
{
    public string Message { get; init; }

    public ReceiveMessageRouteParams(string message)
    {
        Message = message;
    }
}
