namespace Network.Client;

public class ScoreUpdateEndpoint
{
    public int ClientScore { get; init; }
    public int OpponentScore { get; init; }

    public ScoreUpdateEndpoint(int clientScore, int opponentScore)
    {
        ClientScore = clientScore;
        OpponentScore = opponentScore;
    }
}
