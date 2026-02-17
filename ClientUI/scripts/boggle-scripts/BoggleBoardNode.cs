using Boggle;
using Godot;
using System.Collections.Generic;

[GlobalClass]
public partial class BoggleBoardNode : Node
{
    private BoggleBoard _boggleBoard;

    public void Initialize(Godot.Collections.Array<Godot.Collections.Array<string>> letters)
    {
        List<List<IDie>> dice = new List<List<IDie>>();
        foreach (var row in letters)
        {
            List<IDie> newRow = new List<IDie>();
            foreach (var letter in row)
            {
                newRow.Add(new SimpleDie(letter));
            }
            dice.Add(newRow);
        }

        _boggleBoard = new BoggleBoard(dice);
    }
}
