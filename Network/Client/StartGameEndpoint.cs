using Boggle;

namespace Network.Client;

public class StartGameEndpoint
{
    public DateTimeOffset TimeEndOfGame { get; init; }
    public BoggleBoard BoggleBoard { get; init; }

    public StartGameEndpoint(DateTimeOffset timeEndOfGame, BoggleBoard boggleBoard)
    {
        TimeEndOfGame = timeEndOfGame;
        BoggleBoard = boggleBoard;
    }
}
