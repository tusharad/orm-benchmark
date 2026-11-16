using System;
using System.Collections.Generic;
using System.Linq;
using DapperAirBench.Models;

public class E03
{
    public static void Run(List<Flight> flights)
    {
        var q = from f in flights
                group f by f.DepartureAirport into g
                select new { g.Key, f.FlightNo };
    }
}
