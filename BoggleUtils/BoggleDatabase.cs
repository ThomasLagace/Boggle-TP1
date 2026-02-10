namespace BoggleUtils;

public class BoggleDatabase
{
    private readonly HashSet<string> _wordsList = new();

    public BoggleDatabase(HashSet<string> wordList)
    {
        foreach (var word in wordList)
            _wordsList.Add(word.ToLower().Trim());
    }

    public BoggleDatabase(string filePath)
        : this(File.ReadLines(filePath).ToHashSet()) { }

    public bool ContainsWord(string word)
    {
        return _wordsList.Contains(word.ToLower());
    }
}
