namespace Network;

public class Packet
{
    public Route Route { get; init; }
    public RouteParams RouteParams { get; init; }

    public Packet(Route route, RouteParams routeParams)
    {
        this.Route = route;
        this.RouteParams = routeParams;
    }
}