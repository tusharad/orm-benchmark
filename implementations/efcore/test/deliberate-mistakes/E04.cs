using System;
using EFCoreAirBench;

public class E04
{
    public static void Run(AirDbContext db)
    {
        using var tx = db.Database.BeginTransaction();
        tx.Rollback();
        tx.Commit();
    }
}
