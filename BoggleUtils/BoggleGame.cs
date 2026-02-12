namespace BoggleUtils;

public class BoggleGame
{
    public BoggleWordsDatabase Database { get; private set; }
    public BoggleBoard Board { get; private set; }

    public BoggleGame(BoggleWordsDatabase database)
    {
        List<List<string>> dices =
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

        List<List<RandomDice>> board = new();
        for (var i = 0; i < 4; i++)
        {
            board.Add([new RandomDice(dices[i * 4 + 0]), new RandomDice(dices[i * 4 + 1]), new RandomDice(dices[i * 4 + 2]), new RandomDice(dices[i * 4 + 3])]);
        }

        BoggleUtils.RandomizeListOfDices(board);


        Database = database;
        Board = new BoggleBoard(board.Select(row => row.Cast<IDice>().ToList()).ToList());
    }

    public bool ValidateGuess(List<(int, int)> selectedDices)
    {
        if (!Board.ValidateGuess(selectedDices))
            return false;

        string guessString = Board.GetStringFromCoords(selectedDices);
        return Database.ContainsWord(guessString);
    }
}
