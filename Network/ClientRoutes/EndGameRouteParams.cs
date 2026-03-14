using Boggle;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Network.ClientRoutes
{
    public class EndGameRouteParams : RouteParams
    {
        public int Player1Score { get; init; }
        public int Player2Score { get; init; }

        public EndGameRouteParams(int player1Score, int player2Score)
        {
            Player1Score = player1Score;
            Player2Score = player2Score;
        }
    }
}
