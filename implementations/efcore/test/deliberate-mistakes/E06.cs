using System;
using System.Linq;
using EFCoreAirBench;

public class E06
{
    public static void Run(AirDbContext db)
    {
        var q = db.Flights.Select(f => f.NonExistentColumn).ToList();
    }
}
