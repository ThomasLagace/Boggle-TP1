namespace Network;

public class Packet<T>
{

    public Endpoint Endpoint { get; init; }
    public T Payload { get; init; }

    public Packet(Endpoint endpoint, T payload)
    {
        this.Endpoint = endpoint;
        this.Payload = payload;
    }
}