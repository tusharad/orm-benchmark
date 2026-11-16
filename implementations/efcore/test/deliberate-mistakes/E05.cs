using System;
using System.Linq;
using EFCoreAirBench;

public class E05
{
    public static void Run(AirDbContext db)
    {
        var q = db.Flights.Where(f => f.FlightId == null).ToList();
    }
}
