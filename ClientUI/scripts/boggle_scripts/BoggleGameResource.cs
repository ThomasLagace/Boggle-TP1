using Boggle;
using Godot;

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

    public static BoggleGameResource CreateInstance(string filePath)
    {
        BoggleWordsDatabase database = new(filePath);
        return new BoggleGameResource(new BoggleGame(database));
    }
}
