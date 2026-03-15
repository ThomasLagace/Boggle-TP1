using Godot;
using System.Collections.Generic;

public static class GodotUtils
{
    public static List<(int, int)> ConvertBoggleCoordsToTuple(Godot.Collections.Array<BoggleCoords> boggleCoords)
    {
        List<(int, int)> tupleCoords = new();
        foreach (var coords in boggleCoords)
        {
            tupleCoords.Add((coords.X, coords.Y));
        }
        return tupleCoords;
    }
}
