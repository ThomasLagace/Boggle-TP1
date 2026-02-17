using Boggle;
using Godot;

public partial class BoggleSimpleDieNode : Node
{
    [Export]
    private string _letter;
    private SimpleDie? _simpleDie;

    public BoggleSimpleDieNode() { }

    public void InitializeLetter(string letter)
    {
        _simpleDie = new SimpleDie(letter);
    }

    public BoggleSimpleDieNode(SimpleDie simpleDie)
    {
        _simpleDie = simpleDie;
    }

    public string GetLetter()
    {
        return _simpleDie?.GetLetter() ?? _letter;
    }
}
