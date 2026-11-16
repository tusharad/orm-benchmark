using System;
using System.Linq;
using EFCoreAirBench;

public class E08
{
    public static void Run(AirDbContext db)
    {
        var q = db.Flights.Where(f => unbound.FlightId == 1).ToList();
    }
}
