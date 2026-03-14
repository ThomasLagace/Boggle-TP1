using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ServerSide
{
    public abstract class Warning
    {
        protected const string DuplicateGuess = "You have already found this word.";
        protected const string ConnectionLost = "You have lost connection to the server.";
        protected static string SharedGuess(string guess) => $"Both players have found {guess.ToUpper()}.";
    }
}
