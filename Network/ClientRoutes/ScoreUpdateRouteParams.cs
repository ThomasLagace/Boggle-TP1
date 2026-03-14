namespace Network.ClientRoutes;

public class ScoreUpdateRouteParams : RouteParams
{
    public int ClientScore { get; init; }

    public ScoreUpdateRouteParams(int clientScore)
    {
        ClientScore = clientScore;
    }
}
