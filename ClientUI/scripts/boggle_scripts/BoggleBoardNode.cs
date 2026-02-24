using Boggle;
using Godot;
using System.Collections.Generic;

[GlobalClass]
public partial class BoggleBoardNode : Node
{
    private BoggleBoard _boggleBoard;

    public BoggleBoardNode(BoggleBoard boggleBoard)
    {
        _boggleBoard = boggleBoard;
    }

    public bool ValidateGuess(Godot.Collections.Array<BoggleCoords> boggleCoords)
    {
        List<(int, int)> coords = ConvertBoggleCoordsToTuple(boggleCoords);
        return _boggleBoard.ValidateGuess(coords);
    }

    public string GetStringFromCoords(Godot.Collections.Array<BoggleCoords> boggleCoords)
    {
        List<(int, int)> coords = ConvertBoggleCoordsToTuple(boggleCoords);
        return _boggleBoard.GetStringFromCoords(coords);
    }

    public bool AreCoordsValid(Godot.Collections.Array<BoggleCoords> boggleCoords)
    {
        List<(int, int)> coords = ConvertBoggleCoordsToTuple(boggleCoords);
        return _boggleBoard.AreCoordsValid(coords);
    }

    public Godot.Collections.Array<Godot.Collections.Array<string>> GetBoardLetters()
    {
        Godot.Collections.Array<Godot.Collections.Array<string>> letters = new();

        foreach (var row in _boggleBoard.Board)
        {
            Godot.Collections.Array<string> rowList = new();
            foreach (IDie die in row)
            {
                rowList.Add(die.GetLetter());
            }
            letters.Add(rowList);
        }

        return letters;
    }

    private static List<(int, int)> ConvertBoggleCoordsToTuple(Godot.Collections.Array<BoggleCoords> boggleCoords)
    {
        List<(int, int)> tupleCoords = new();
        foreach (var coords in boggleCoords)
        {
            tupleCoords.Add((coords.Y, coords.X));
        }
        return tupleCoords;
    }
}
