using System;
using System.Collections.Generic;

namespace DapperAirBench.Models;

public class Flight
{
    public int FlightId { get; set; }
    public string FlightNo { get; set; } = null!;
    public DateTime ScheduledDeparture { get; set; }
    public DateTime ScheduledArrival { get; set; }
    public string DepartureAirport { get; set; } = null!;
    public string ArrivalAirport { get; set; } = null!;
    public string Status { get; set; } = null!;
    public string AircraftCode { get; set; } = null!;
    public DateTime? ActualDeparture { get; set; }
    public DateTime? ActualArrival { get; set; }
    public DateTime? UpdateTs { get; set; }
    public int Version { get; set; }
    public Aircraft? Aircraft { get; set; }
    public List<BookingLeg> BookingLegs { get; set; } = new();
}

public class Booking
{
    public long BookingId { get; set; }
    public string BookingRef { get; set; } = null!;
    public string? BookingName { get; set; }
    public int? AccountId { get; set; }
    public string Email { get; set; } = null!;
    public string Phone { get; set; } = null!;
    public DateTime? UpdateTs { get; set; }
    public decimal? Price { get; set; }
}

public class Passenger
{
    public int PassengerId { get; set; }
    public long BookingId { get; set; }
    public string? BookingRef { get; set; }
    public string FirstName { get; set; } = null!;
    public string LastName { get; set; } = null!;
    public int? AccountId { get; set; }
    public int? Age { get; set; }
}

public class BookingLeg
{
    public int BookingLegId { get; set; }
    public long BookingId { get; set; }
    public int FlightId { get; set; }
    public int? LegNum { get; set; }
    public bool? IsReturning { get; set; }
    public DateTime? UpdateTs { get; set; }
}

public class BoardingPass
{
    public int PassId { get; set; }
    public int PassengerId { get; set; }
    public long BookingLegId { get; set; }
    public string Seat { get; set; } = null!;
    public string? BoardingTime { get; set; }
    public DateTime? UpdateTs { get; set; }
}

public class Account
{
    public int AccountId { get; set; }
    public string Login { get; set; } = null!;
    public string FirstName { get; set; } = null!;
    public string LastName { get; set; } = null!;
    public int? FrequentFlyerId { get; set; }
}

public class FrequentFlyer
{
    public int FrequentFlyerId { get; set; }
    public int? Level { get; set; }
    public int? AwardPoints { get; set; }
}

public class Phone
{
    public int PhoneId { get; set; }
    public int AccountId { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PhoneType { get; set; }
}

public class Airport
{
    public string AirportCode { get; set; } = null!;
    public string AirportName { get; set; } = null!;
    public string City { get; set; } = null!;
}

public class Aircraft
{
    public string Code { get; set; } = null!;
    public string Model { get; set; } = null!;
    public decimal Range { get; set; }
    public int Class { get; set; }
}

public class FlightSeatInventory
{
    public int FlightId { get; set; }
    public string SeatNo { get; set; } = null!;
    public string? PassengerName { get; set; }
    public int? AccountId { get; set; }
    public DateTime? ReservedAt { get; set; }
    public string Status { get; set; } = null!;
    public int Version { get; set; }
}

public class FlightStatusUpdate
{
    public int FlightId { get; set; }
    public string Status { get; set; } = null!;
    public DateTime? ActualDeparture { get; set; }
    public DateTime? ActualArrival { get; set; }
    public DateTime UpdateTs { get; set; }
    public int Version { get; set; }
}

public record CompositeBookingRecord(
    long BookingId, string BookingRef, decimal? Price, string Email,
    int PassengerId, string FirstName, string LastName, int? Age,
    int BookingLegId, int? LegNum, bool? IsReturning,
    int FlightId, string FlightNo, string DepartureAirport, string ArrivalAirport,
    DateTime ScheduledDeparture, string Status
);

public record FlightGraphNode(Flight Flight, List<BookingLegNode> Legs);
public record BookingLegNode(BookingLeg Leg, Booking Booking, BoardingPass? BoardingPass);

public record RouteProfitability(
    string origin, string destination, string aircraft_model,
    long total_flights, long total_legs_booked, decimal total_revenue,
    decimal avg_delay_minutes, decimal on_time_pct
);

public record HubCentrality(
    string airport_code, string airport_name, string city,
    long total_departures, long total_arrivals, long unique_destinations,
    long fleet_diversity, decimal avg_dep_delay, decimal avg_arr_delay,
    decimal hub_centrality_score
);

public record Itinerary(
    int hops, string route, DateTime journey_start, DateTime journey_end,
    decimal total_elapsed_minutes, decimal total_flight_minutes
);

public record WindowDelay(
    int flight_id, string flight_no, string arrival_airport, DateTime scheduled_departure,
    decimal delay_minutes, decimal rolling_avg_delay_5, decimal? delay_diff_prev,
    decimal rolling_stddev_10, long severity_rank
);

public record HybridAirport(
    string airport_code, string airport_name, string city,
    long active_flights_count, decimal rrf_score
);
