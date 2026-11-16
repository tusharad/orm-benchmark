using System;
using System.Linq;
using EFCoreAirBench;

public class E01
{
    public static void Run(AirDbContext db)
    {
        var q = db.Flights.Where(f => f.FlightId == "INVALID").ToList();
    }
}
