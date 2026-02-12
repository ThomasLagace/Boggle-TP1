namespace BoggleUtils;

public class Program
{
    static void Main(string[] args)
    {

        var db = new BoggleWordsDatabase("dict.txt");
        var boggleGame = new BoggleGame(db);
        var game = new BoggleConsole(boggleGame);
        game.Play();
    }
}
