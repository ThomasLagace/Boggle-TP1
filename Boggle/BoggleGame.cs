using System.Diagnostics;
using System.Threading.Tasks;

namespace Boggle;

public class BoggleGame
{
    public BoggleWordsDatabase Database { get; private set; }
    public BoggleBoard Board { get; private set; }
    public int Clock { get; private set; }
    public event Action? OnGameOver;

    public BoggleGame(BoggleWordsDatabase database, int gameDurationSeconds = 180)
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

        Database = database;
        Board = new BoggleBoard(board.Select(row => row.Cast<IDie>().ToList()).ToList());
        Clock = gameDurationSeconds;
    }

    public async Task StartGame() 
    {
        for (; Clock > 0; Clock--) 
        {
            await Task.Delay(1000);
        }

        this.OnGameOver?.Invoke();
    }

    public bool ValidateGuess(List<(int, int)> selectedDices)
    {
        if (!Board.ValidateGuess(selectedDices))
            return false;

        string guessString = Board.GetStringFromCoords(selectedDices);
        return Database.ContainsWord(guessString);
    }
}
