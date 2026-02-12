namespace Boggle;

public class RandomDie : IDie
{
    public int SelectedLetter { get; private set; }

    private List<string> _possibleLetters;

    public RandomDie(List<string> possibleLetters, int selectedLetter)
    {
        _possibleLetters = possibleLetters;
        SelectedLetter = selectedLetter;
    }

    public RandomDie(List<string> possibleLetters)
        : this(possibleLetters, 0) { }

    public void Roll()
    {
        SelectedLetter = Random.Shared.Next();
    }

    public string GetLetter()
    {
        return _possibleLetters[Math.Abs(SelectedLetter) % _possibleLetters.Count];
    }

    public override string ToString()
    {
        return GetLetter();
    }
}
