using Boggle;
using Godot;
using System.Collections.Generic;

[GlobalClass]
public partial class BoggleGameResource : Node
{
    public BoggleGame Game { get; init; }

    public BoggleGameResource(BoggleGame game)
    {
        Game = game;
    }

    public BoggleBoardResource Board()
    {
        return new BoggleBoardResource(Game.Board);
    }

    public bool ValidateGuess(Godot.Collections.Array<BoggleCoords> boggleCoords)
    {
        List<(int, int)> coords = GodotUtils.ConvertBoggleCoordsToTuple(boggleCoords);
        return Game.ValidateGuess(coords);
    }

    public static BoggleGameResource CreateInstance(string filePath)
    {
        BoggleWordsDatabase database = new(filePath);
        return new BoggleGameResource(new BoggleGame(database));
    }
}
