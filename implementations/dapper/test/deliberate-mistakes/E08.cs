using System;
using System.Collections.Generic;
using System.Linq;
using DapperAirBench.Models;

public class E08
{
    public static void Run(List<Flight> flights)
    {
        var q = flights.Where(f => unbound.FlightId == 1).ToList();
    }
}
