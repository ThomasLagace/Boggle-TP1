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
        public int ClientScore { get; init; }
        public int OpponentScore { get; init; }

        public EndGameRouteParams(int clientScore, int opponentScore)
        {
            ClientScore = clientScore;
            OpponentScore = opponentScore;
        }
    }
}
