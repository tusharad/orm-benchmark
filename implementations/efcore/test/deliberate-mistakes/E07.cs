using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using EFCoreAirBench;

public class E07
{
    public static void Run(AirDbContext db)
    {
        var q = db.Flights.Where(f => EF.Functions.RowNumber() > 1).ToList();
    }
}
