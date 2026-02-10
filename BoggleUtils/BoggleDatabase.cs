namespace BoggleUtils;

public class BoggleDatabase
{
    private readonly HashSet<string> _wordsList = new();

    public BoggleDatabase(HashSet<string> wordList)
    {
        _wordsList = wordList;
    }

    public BoggleDatabase(string filePath)
    {
        foreach (var word in File.ReadLines(filePath))
            _wordsList.Add(word.Trim());
    }

    public bool ContainsWord(string word)
    {
        return _wordsList.Contains(word);
    }
}
