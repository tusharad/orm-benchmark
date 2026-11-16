using System;
using System.Collections.Generic;
using System.Linq;
using DapperAirBench.Models;

public class E04
{
    public static void Run(List<Flight> flights)
    {
        var q = flights.Where(f => Console.WriteLine(f.FlightNo)).ToList();
    }
}
