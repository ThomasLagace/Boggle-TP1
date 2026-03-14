using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Network.ServerRoutes
{
    public class SubmitNameRouteParams : RouteParams
    {
        public string Name { get; init; }

        public SubmitNameRouteParams(string name)
        {
            Name = name;
        }
    }
}
