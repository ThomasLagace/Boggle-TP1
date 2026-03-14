using System.Diagnostics;
using System.Threading.Tasks;

namespace Boggle;

public class BoggleGame
{
    public BoggleBoard Board { get; private set; }
    public DateTimeOffset GameEndTime { get; init; }
    public Dictionary<string, BogglePlayer> DiscoveredWords { get; set; }
    public CancellationTokenSource GameCts { get; init; }
    public event Action? OnGameOver;
    private readonly BoggleWordsDatabase _database;

    public BoggleGame(BoggleWordsDatabase database, DateTimeOffset gameEndTime)
    {
        List<List<string>> dice =
        [
            ["E", "T", "U", "K", "N", "O"],
            ["E", "V", "G", "T", "I", "N"],
            ["D", "E", "C", "A", "M", "P"],
            ["I", "E", "L", "R", "U", "W"],
            ["E", "H", "I", "F", "S", "E"],
            ["R", "E", "C", "A", "L", "S"],
            ["E", "N", "T", "D", "O", "S"],
            ["O", "F", "X", "R", "I", "A"],
            ["N", "A", "V", "E", "D", "Z"],
            ["E", "I", "O", "A", "T", "A"],
            ["G", "L", "E", "N", "Y", "U"],
            ["B", "M", "A", "Qu", "J", "O"],
            ["T", "L", "I", "B", "R", "A"],
            ["S", "P", "U", "L", "T", "E"],
            ["A", "I", "M", "S", "O", "R"],
            ["E", "N", "H", "R", "I", "S"]
        ];

        List<List<RandomDie>> board = new();
        for (var i = 0; i < 4; i++)
        {
            board.Add([new RandomDie(dice[i * 4 + 0]), new RandomDie(dice[i * 4 + 1]), new RandomDie(dice[i * 4 + 2]), new RandomDie(dice[i * 4 + 3])]);
        }

        BoggleUtils.RandomizeListOfDice(board);

        _database = database;
        Board = new BoggleBoard(board.Select(row => row.Cast<IDie>().ToList()).ToList());
        GameEndTime = gameEndTime;
        DiscoveredWords = [];
        GameCts = new CancellationTokenSource();
    }

    public BoggleGame(BoggleWordsDatabase database) : this(database, DateTimeOffset.Now + TimeSpan.FromMinutes(3)) { }

    public async Task StartGame(CancellationToken token) 
    {
        TimeSpan duration = GameEndTime - DateTimeOffset.Now;

        if (duration > TimeSpan.Zero) 
        {
            await Task.Delay(duration, token);
        }

        GameCts.Cancel();
        this.OnGameOver?.Invoke();
    }

    public bool ValidateGuess(List<(int, int)> selectedDices)
    {
        if (!Board.ValidateGuess(selectedDices))
            return false;

        string guessString = Board.GetStringFromCoords(selectedDices);
        return _database.ContainsWord(guessString);
    }
}
