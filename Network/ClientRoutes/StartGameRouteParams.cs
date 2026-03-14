using Boggle;

namespace Network.ClientRoutes;

public class StartGameRouteParams : RouteParams
{
    public DateTimeOffset TimeEndOfGame { get; init; }
    public BoggleBoard BoggleBoard { get; init; }
    public string OpponentName { get; init; }

    public StartGameRouteParams(DateTimeOffset timeEndOfGame, BoggleBoard boggleBoard, string opponentName)
    {
        TimeEndOfGame = timeEndOfGame;
        BoggleBoard = boggleBoard;
        OpponentName = opponentName;
    }
}
