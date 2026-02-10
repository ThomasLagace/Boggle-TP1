namespace BoggleUtils;

public class Dice
{
    public int SelectedLetter { get; private set; }

    private List<string> _possibleLetters;

    public Dice(List<string> possibleLetters, int selectedLetter)
    {
        _possibleLetters = possibleLetters;
        SelectedLetter = selectedLetter;
    }

    public Dice(List<string> possibleLetters)
        : this(possibleLetters, 0) { }

    public void Roll()
    {
        SelectedLetter = Random.Shared.Next();
    }

    public string GetSelectedLetter()
    {
        return _possibleLetters[Math.Abs(SelectedLetter) % _possibleLetters.Count];
    }
}
