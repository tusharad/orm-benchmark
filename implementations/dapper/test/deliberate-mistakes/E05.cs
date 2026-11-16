using System;
using System.Collections.Generic;
using System.Linq;
using DapperAirBench.Models;

public class E05
{
    public static void Run(List<Flight> flights)
    {
        var q = flights.Where(f => f.FlightId == null).ToList();
    }
}
