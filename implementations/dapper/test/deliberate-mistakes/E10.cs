using System;
using System.Collections.Generic;
using System.Linq;
using DapperAirBench.Models;

public class E10
{
    public static void Run(List<Flight> flights, List<BookingLeg> legs)
    {
        var q = from f in flights
                where legs.Any(bl => bl.FlightId == f.FlightId) && bl.LegNum == 1
                select f;
    }
}
