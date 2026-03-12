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
        private int _score;
        public event Action? OnScoreUpdate;

        public BogglePlayer(string name, BoggleGame match) 
        {
            this.Match = match;
            this.Name = name;
            this.Score = 0;
        }

        public int Score
        {
            get => _score;
            set
            {
                _score = value;
                OnScoreUpdate?.Invoke();
            }
        }

    }
}
