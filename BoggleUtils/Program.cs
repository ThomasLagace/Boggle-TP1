namespace BoggleUtils;

public class Program
{
    static void Main(string[] args)
    {

        var db = new BoggleWordsDatabase("dict.txt");
        var boggleBoard = new BoggleBoard(db);
        var game = new BoggleConsole(boggleBoard);
        game.Play();
    }
}
