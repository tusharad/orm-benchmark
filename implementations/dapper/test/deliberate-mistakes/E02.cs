using System;
using System.Collections.Generic;
using System.Linq;
using DapperAirBench.Models;

public class E02
{
    public static void Run(List<Flight> flights, List<Passenger> passengers)
    {
        var q = from f in flights
                join p in passengers on f.FlightId equals p.FirstName
                select new { f, p };
    }
}
