using System.Text;

namespace Boggle;

public class BoggleBoard
{
    public IList<IList<IDie>> Board { get; private set; }

    public BoggleBoard(IList<IList<IDie>> board)
    {
        Board = board;
    }

    public bool ValidateGuess(List<(int, int)> selectedDice)
    {
        if (selectedDice.Count <= 1)
            return false;
        if (!AreCoordsValid(selectedDice))
            return false;

        return true;
    }

    public string GetStringFromCoords(List<(int, int)> coords)
    {
        List<IDie> diceGuess = new();
        foreach (var (selectedX, selectedY) in coords)
            diceGuess.Add(Board[selectedY][selectedX]);

        StringBuilder stringGuess = new();

        foreach (IDie die in diceGuess)
            stringGuess.Append(die.GetLetter());
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
            if (x + 1 != lastX && x - 1 != lastX && x != lastX)
                return false;
            if (y + 1 != lastY && y - 1 != lastY && y != lastY)
                return false;
            lastCoord = coord;
        }

        return true;
    }
}
