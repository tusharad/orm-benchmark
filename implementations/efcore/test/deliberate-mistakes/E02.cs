using System;
using System.Linq;
using EFCoreAirBench;

public class E02
{
    public static void Run(AirDbContext db)
    {
        var q = from f in db.Flights
                join p in db.Passengers on f.FlightId equals p.FirstName
                select new { f, p };
    }
}
