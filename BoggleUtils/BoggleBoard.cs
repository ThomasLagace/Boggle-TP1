using System.Text;

namespace BoggleUtils;

public class BoggleBoard
{
    private BoggleWordsDatabase _database;
    private List<List<Dice>> _board;

    public IReadOnlyList<IReadOnlyList<Dice>> Board => _board;

    public BoggleBoard(BoggleWordsDatabase database, List<List<Dice>> board)
    {
        _database = database;
        _board = board;
    }

    public BoggleBoard(BoggleWordsDatabase database)
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

        List<List<Dice>> board = new();
        for (var i = 0; i < 4; i++)
        {
            board.Add([new Dice(dices[i * 4 + 0]), new Dice(dices[i * 4 + 1]), new Dice(dices[i * 4 + 2]), new Dice(dices[i * 4 + 3])]);
        }


        _database = database;
        _board = board;
    }

    public void RandomizeBoard()
    {
        foreach (var row in _board)
        {
            foreach (var dice in row)
                dice.Roll();
        }

        // Random algorithm from https://www.csharphelper.com/howtos/howto_randomize_2d_array.html
        int num_rows = _board.Count + 1;
        int num_cols = _board[0].Count + 1;
        int num_dices = num_rows * num_cols;
        
        for (int i = 0; i < num_dices; i++)
        {
            int j = Random.Shared.Next(i, num_dices);

            int row_i = i / num_cols;
            int col_i = i % num_cols;
            int row_j = j / num_cols;
            int col_j = j % num_cols;

            Dice temp = _board[row_i][col_i];
            _board[row_i][col_i] = _board[row_j][col_j];
            _board[row_j][col_j] = temp;
        }
    }

    public bool ValidateGuess(List<(int, int)> selectedDices)
    {
        if (selectedDices.Count <= 1)
            return false;
        if (!AreCoordsValid(selectedDices))
            return false;

        string stringGuess = GetStringFromCoords(selectedDices);

        return _database.ContainsWord(stringGuess.ToString());
    }

    public string GetStringFromCoords(List<(int, int)> coords)
    {
        List<Dice> dicesGuess = new();
        foreach (var (selectedX, selectedY) in coords)
            dicesGuess.Add(_board[selectedY][selectedX]);

        StringBuilder stringGuess = new();

        foreach (Dice dice in dicesGuess)
            stringGuess.Append(dice.GetSelectedLetter());
        return stringGuess.ToString();
    }

    public bool AreCoordsValid(List<(int, int)> coords)
    {
        if (coords.Count != coords.Distinct().Count())
            return false;

        (int, int)? lastCoord = null;
        foreach ((int, int) coord in coords)
        {
            if (lastCoord == null)
            {
                lastCoord = coord;
                continue;
            }

            var (x, y) = coord;
            var (lastX, lastY) = ((int, int)) lastCoord;
            if (!(x + 1 != lastX && x - 1 != lastX))
                return false;
            if (!(y + 1 != lastY && y - 1 != lastY))
                return false;
        }

        return true;
    }
}
