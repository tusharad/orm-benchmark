using System;
using System.Linq;
using EFCoreAirBench;

public class E03
{
    public static void Run(AirDbContext db)
    {
        var q = from f in db.Flights
                group f by f.DepartureAirport into g
                select new { g.Key, f.FlightNo };
    }
}
