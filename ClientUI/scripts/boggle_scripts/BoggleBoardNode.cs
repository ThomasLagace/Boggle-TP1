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

    public bool ValidateGuess(Godot.Collections.Array<Godot.Collections.Array<int>> godotCoords)
    {
        List<(int, int)> coords = ConvertGodotCoordsToTupleCoords(godotCoords);
        return _boggleBoard.ValidateGuess(coords);
    }

    public string GetStringFromCoords(Godot.Collections.Array<Godot.Collections.Array<int>> godotCoords)
    {
        List<(int, int)> coords = ConvertGodotCoordsToTupleCoords(godotCoords);
        return _boggleBoard.GetStringFromCoords(coords);
    }

    public bool AreCoordsValid(Godot.Collections.Array<Godot.Collections.Array<int>> godotCoords)
    {
        List<(int, int)> coords = ConvertGodotCoordsToTupleCoords(godotCoords);
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

    private static List<(int, int)> ConvertGodotCoordsToTupleCoords(Godot.Collections.Array<Godot.Collections.Array<int>> godotCoords)
    {
        List<(int, int)> coords = new();
        foreach (var godotCoord in godotCoords)
        {
            if (godotCoord.Count < 2) continue;
            coords.Add((godotCoord[0], godotCoord[1]));
        }
        return coords;
    }
}
