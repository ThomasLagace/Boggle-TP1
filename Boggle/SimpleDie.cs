namespace Boggle;

public class SimpleDie : IDie
{
    public string Letter { get; private set; }

    public SimpleDie(string letter)
    {
        Letter = letter;
    }

    public string GetLetter()
    {
        return Letter;
    }

    public override string ToString()
    {
        return Letter;
    }
}
