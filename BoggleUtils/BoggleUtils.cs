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

    public static void RandomizeListOfDice(List<List<RandomDie>> dice)
    {
        foreach (var row in dice)
        {
            foreach (var die in row)
                die.Roll();
        }

        // Random algorithm from https://www.csharphelper.com/howtos/howto_randomize_2d_array.html
        int num_rows = dice.Count;
        int num_cols = dice[0].Count;
        int num_dices = num_rows * num_cols;
        
        for (int i = 0; i < num_dices; i++)
        {
            int j = Random.Shared.Next(i, num_dices);

            int row_i = i / num_cols;
            int col_i = i % num_cols;
            int row_j = j / num_cols;
            int col_j = j % num_cols;

            RandomDie temp = dice[row_i][col_i];
            dice[row_i][col_i] = dice[row_j][col_j];
            dice[row_j][col_j] = temp;
        }
    }
}
