using System;
using System.Linq;
using EFCoreAirBench;

public class E10
{
    public static void Run(AirDbContext db)
    {
        var q = from f in db.Flights
                where db.BookingLegs.Any(bl => bl.FlightId == f.FlightId) && bl.LegNum == 1
                select f;
    }
}
