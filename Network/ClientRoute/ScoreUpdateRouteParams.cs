namespace Network.ClientRoute;

public class ScoreUpdateRouteParams : RouteParams
{
    public int ClientScore { get; init; }
    public int OpponentScore { get; init; }

    public ScoreUpdateRouteParams(int clientScore, int opponentScore)
    {
        ClientScore = clientScore;
        OpponentScore = opponentScore;
    }
}
