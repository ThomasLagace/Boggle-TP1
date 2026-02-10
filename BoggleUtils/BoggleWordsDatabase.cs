namespace BoggleUtils;

public class BoggleWordsDatabase
{
    private readonly HashSet<string> _wordsList = new();

    public BoggleWordsDatabase(HashSet<string> wordList)
    {
        foreach (var word in wordList)
            _wordsList.Add(word.ToLower().Trim());
    }

    public BoggleWordsDatabase(string filePath)
        : this(File.ReadLines(filePath).ToHashSet()) { }

    public bool ContainsWord(string word)
    {
        if (word.Length < 3)
            return false;
        return _wordsList.Contains(word.ToLower());
    }
}
