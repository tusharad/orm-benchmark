using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using EFCoreAirBench;

public class E09
{
    public static void Run(AirDbContext db)
    {
        var f = db.Flights.First();
        f.FlightId = 999999;
        db.SaveChanges();
    }
}
