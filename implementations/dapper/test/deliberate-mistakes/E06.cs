using System;
using System.Collections.Generic;
using System.Linq;
using DapperAirBench.Models;

public class E06
{
    public static void Run(List<Flight> flights)
    {
        var q = flights.Select(f => f.NonExistentColumn).ToList();
    }
}
