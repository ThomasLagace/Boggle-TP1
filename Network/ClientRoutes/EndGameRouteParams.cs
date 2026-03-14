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
        // Nullable to handle tie
        public BogglePlayer? Winner { get; init; }

        public EndGameRouteParams(BogglePlayer? winner)
        {
            Winner = winner;
        }
    }
}
