using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Boggle
{
    public class BogglePlayer
    {
        public BoggleGame Match { get; init; }
        public string Name { get; init; }
        public int Score { get; set; }

        public BogglePlayer(string name, BoggleGame match) 
        {
            this.Match = match;
            this.Name = name;
            this.Score = 0;
        }
    }
}
