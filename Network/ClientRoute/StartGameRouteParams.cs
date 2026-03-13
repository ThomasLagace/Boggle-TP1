using Boggle;

namespace Network.ClientRoute;

public class StartGameRouteParams : RouteParams
{
    public DateTimeOffset TimeEndOfGame { get; init; }
    public BoggleBoard BoggleBoard { get; init; }

    public StartGameRouteParams(DateTimeOffset timeEndOfGame, BoggleBoard boggleBoard)
    {
        TimeEndOfGame = timeEndOfGame;
        BoggleBoard = boggleBoard;
    }
}
