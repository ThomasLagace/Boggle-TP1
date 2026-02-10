using System.Text;

namespace BoggleUtils;

public class BoggleConsole
{
    private BoggleBoard _board;

    public BoggleConsole(BoggleBoard board)
    {
        _board = board;
    }

    public void Play()
    {
        _board.RandomizeBoard();

        int currentPoints = 0;
        List<(int, int)> currentSelectedCoords = new();
        List<string> guessedWords = new();
        while (true)
        {
            Console.WriteLine("Current points: " + currentPoints);
            Console.WriteLine(GetBoggleString());

            Console.Write("Your current word is: ");
            foreach (var (selectedCoordX, selectedCoordY) in currentSelectedCoords)
            {
                Dice dice = _board.Board[selectedCoordY][selectedCoordX];
                Console.Write(dice.GetSelectedLetter());
            }
            Console.WriteLine();
            Console.WriteLine();

            Console.Write("Are you done?: ");
            if (Console.ReadLine() == "yes")
            {
                if (currentSelectedCoords.Count < 3)
                {
                    Console.Clear();
                    Console.WriteLine("Not enough letters to guess!");

                    continue;
                }
                else if (_board.ValidateGuess(currentSelectedCoords))
                {
                    string word = _board.GetStringFromCoords(currentSelectedCoords);
                    if (guessedWords.Contains(word))
                    {
                        Console.Clear();
                        Console.WriteLine("You already guessed that word!");
                        continue;
                    }

                    int addedPoints = BoggleUtils.GetPoints(_board.GetStringFromCoords(currentSelectedCoords));
                    currentPoints += addedPoints;
                    currentSelectedCoords.Clear();

                    Console.Clear();
                    Console.WriteLine("You got " + addedPoints + " points!");

                    continue;
                }
                else
                {
                    currentSelectedCoords.Clear();

                    Console.Clear();
                    Console.WriteLine("This word does not exists!");

                    continue;
                }
            }

            Console.Write("Write your x: ");
            int x = Convert.ToInt32(Console.ReadLine());

            Console.Write("Write your y: ");
            int y = Convert.ToInt32(Console.ReadLine());
            Console.Clear();

            currentSelectedCoords.Add((x, y));

            if (!_board.AreCoordsValid(currentSelectedCoords))
            {
                currentSelectedCoords.RemoveAt(currentSelectedCoords.Count - 1);

                Console.WriteLine("These coords are not valid!");
                Console.ReadLine();
                Console.Clear();

                continue;
            }
            Console.Clear();
        }
    }

    public string GetBoggleString()
    {
        StringBuilder sb = new();

        sb.Append("---------\n");
        foreach (var row in _board.Board)
        {
            foreach (var dice in row)
            {
                sb.Append("| " + dice.GetSelectedLetter() + " |");
            }
            sb.Append("\n---------\n");
        }

        return sb.ToString();
    }
}
