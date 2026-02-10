namespace BoggleUtils;

public static class BoggleUtils
{
    public static int GetPoints(string word)
    {
        switch (word.Length)
        {
            case 3:
            case 4:
                return 1;
            case 5:
                return 2;
            case 6:
                return 3;
            case 7:
                return 4;
            case >= 8:
                return 11;
            default:
                return 0;
        }
    }
}
