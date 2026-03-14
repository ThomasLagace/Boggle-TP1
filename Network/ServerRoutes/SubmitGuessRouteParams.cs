using Boggle;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Network.ServerRoutes
{
    public class SubmitGuessRouteParams : RouteParams
    {
        public List<(int, int)> Guess { get; init; }

        public SubmitGuessRouteParams(List<(int, int)> guess)
        {
            Guess = guess;
        }
    }
}
