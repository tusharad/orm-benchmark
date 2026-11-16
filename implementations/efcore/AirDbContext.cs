using System;
using Microsoft.EntityFrameworkCore;
using EFCoreAirBench.Models;

namespace EFCoreAirBench;

public class AirDbContext : DbContext
{
    public DbSet<Flight> Flights => Set<Flight>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<Passenger> Passengers => Set<Passenger>();
    public DbSet<BookingLeg> BookingLegs => Set<BookingLeg>();
    public DbSet<BoardingPass> BoardingPasses => Set<BoardingPass>();
    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<FrequentFlyer> FrequentFlyers => Set<FrequentFlyer>();
    public DbSet<Phone> Phones => Set<Phone>();
    public DbSet<Airport> Airports => Set<Airport>();
    public DbSet<Aircraft> Aircrafts => Set<Aircraft>();
    public DbSet<FlightSeatInventory> FlightSeatInventories => Set<FlightSeatInventory>();
    public DbSet<FlightStatusUpdate> FlightStatusUpdates => Set<FlightStatusUpdate>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        var connStr = Environment.GetEnvironmentVariable("PG_CONN_STR") ??
            "Host=postgres-air;Port=5432;Database=postgres_air;Username=postgres;Password=postgres;Maximum Pool Size=20;Timeout=15";
        optionsBuilder
            .UseNpgsql(connStr, o => {
                o.UseVector();
            })
            .EnableSensitiveDataLogging(false);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("postgres_air");

        modelBuilder.Entity<FlightSeatInventory>()
            .HasKey(s => new { s.FlightId, s.SeatNo });
    }
}
