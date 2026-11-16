using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using NpgsqlTypes;
using Pgvector;

namespace EFCoreAirBench.Models;

[Table("flight", Schema = "postgres_air")]
public class Flight
{
    [Key]
    [Column("flight_id")]
    public int FlightId { get; set; }

    [Column("flight_no")]
    public string FlightNo { get; set; } = null!;

    [Column("scheduled_departure")]
    public DateTime ScheduledDeparture { get; set; }

    [Column("scheduled_arrival")]
    public DateTime ScheduledArrival { get; set; }

    [Column("departure_airport")]
    public string DepartureAirport { get; set; } = null!;

    [Column("arrival_airport")]
    public string ArrivalAirport { get; set; } = null!;

    [Column("status")]
    public string Status { get; set; } = null!;

    [Column("aircraft_code")]
    public string AircraftCode { get; set; } = null!;

    [Column("actual_departure")]
    public DateTime? ActualDeparture { get; set; }

    [Column("actual_arrival")]
    public DateTime? ActualArrival { get; set; }

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }

    [Column("version")]
    public int Version { get; set; }

    [ForeignKey(nameof(AircraftCode))]
    public Aircraft? Aircraft { get; set; }

    public List<BookingLeg> BookingLegs { get; set; } = new();
}

[Table("booking", Schema = "postgres_air")]
public class Booking
{
    [Key]
    [Column("booking_id")]
    public long BookingId { get; set; }

    [Column("booking_ref")]
    public string BookingRef { get; set; } = null!;

    [Column("booking_name")]
    public string? BookingName { get; set; }

    [Column("account_id")]
    public int? AccountId { get; set; }

    [Column("email")]
    public string Email { get; set; } = null!;

    [Column("phone")]
    public string Phone { get; set; } = null!;

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }

    [Column("price")]
    public decimal? Price { get; set; }

    [ForeignKey(nameof(AccountId))]
    public Account? Account { get; set; }

    public List<BookingLeg> BookingLegs { get; set; } = new();
    public List<Passenger> Passengers { get; set; } = new();
}

[Table("passenger", Schema = "postgres_air")]
public class Passenger
{
    [Key]
    [Column("passenger_id")]
    public int PassengerId { get; set; }

    [Column("booking_id")]
    public long BookingId { get; set; }

    [Column("booking_ref")]
    public string? BookingRef { get; set; }

    [Column("passenger_no")]
    public int? PassengerNo { get; set; }

    [Column("first_name")]
    public string FirstName { get; set; } = null!;

    [Column("last_name")]
    public string LastName { get; set; } = null!;

    [Column("account_id")]
    public int? AccountId { get; set; }

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }

    [Column("age")]
    public int? Age { get; set; }

    [ForeignKey(nameof(BookingId))]
    public Booking? Booking { get; set; }

    [ForeignKey(nameof(AccountId))]
    public Account? Account { get; set; }
}

[Table("booking_leg", Schema = "postgres_air")]
public class BookingLeg
{
    [Key]
    [Column("booking_leg_id")]
    public int BookingLegId { get; set; }

    [Column("booking_id")]
    public long BookingId { get; set; }

    [Column("flight_id")]
    public int FlightId { get; set; }

    [Column("leg_num")]
    public int? LegNum { get; set; }

    [Column("is_returning")]
    public bool? IsReturning { get; set; }

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }

    [ForeignKey(nameof(FlightId))]
    public Flight? Flight { get; set; }

    [ForeignKey(nameof(BookingId))]
    public Booking? Booking { get; set; }
}

[Table("boarding_pass", Schema = "postgres_air")]
public class BoardingPass
{
    [Key]
    [Column("pass_id")]
    public int PassId { get; set; }

    [Column("passenger_id")]
    public long? PassengerId { get; set; }

    [Column("booking_leg_id")]
    public long? BookingLegId { get; set; }

    [Column("seat")]
    public string? Seat { get; set; }

    [Column("boarding_time")]
    public DateTime? BoardingTime { get; set; }

    [Column("precheck")]
    public bool? Precheck { get; set; }

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }
}

[Table("account", Schema = "postgres_air")]
public class Account
{
    [Key]
    [Column("account_id")]
    public int AccountId { get; set; }

    [Column("login")]
    public string Login { get; set; } = null!;

    [Column("first_name")]
    public string FirstName { get; set; } = null!;

    [Column("last_name")]
    public string LastName { get; set; } = null!;

    [Column("frequent_flyer_id")]
    public int? FrequentFlyerId { get; set; }

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }

    [Column("version")]
    public int Version { get; set; }

    [ForeignKey(nameof(FrequentFlyerId))]
    public FrequentFlyer? FrequentFlyer { get; set; }

    public List<Phone> Phones { get; set; } = new();
    public List<Booking> Bookings { get; set; } = new();
}

[Table("frequent_flyer", Schema = "postgres_air")]
public class FrequentFlyer
{
    [Key]
    [Column("frequent_flyer_id")]
    public int FrequentFlyerId { get; set; }

    [Column("first_name")]
    public string FirstName { get; set; } = null!;

    [Column("last_name")]
    public string LastName { get; set; } = null!;

    [Column("title")]
    public string Title { get; set; } = null!;

    [Column("card_num")]
    public string CardNum { get; set; } = null!;

    [Column("level")]
    public int Level { get; set; }

    [Column("award_points")]
    public int AwardPoints { get; set; }

    [Column("email")]
    public string Email { get; set; } = null!;

    [Column("phone")]
    public string Phone { get; set; } = null!;

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }
}

[Table("phone", Schema = "postgres_air")]
public class Phone
{
    [Key]
    [Column("phone_id")]
    public int PhoneId { get; set; }

    [Column("account_id")]
    public int? AccountId { get; set; }

    [Column("phone")]
    public string? PhoneNumber { get; set; }

    [Column("phone_type")]
    public string? PhoneType { get; set; }

    [Column("primary_phone")]
    public bool? PrimaryPhone { get; set; }

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }

    [ForeignKey(nameof(AccountId))]
    public Account? Account { get; set; }
}

[Table("airport", Schema = "postgres_air")]
public class Airport
{
    [Key]
    [Column("airport_code")]
    public string AirportCode { get; set; } = null!;

    [Column("airport_name")]
    public string AirportName { get; set; } = null!;

    [Column("city")]
    public string City { get; set; } = null!;

    [Column("airport_tz")]
    public string AirportTz { get; set; } = null!;

    [Column("continent")]
    public string? Continent { get; set; }

    [Column("iso_country")]
    public string? IsoCountry { get; set; }

    [Column("iso_region")]
    public string? IsoRegion { get; set; }

    [Column("intnl")]
    public bool Intnl { get; set; }

    [Column("update_ts")]
    public DateTime? UpdateTs { get; set; }

    [Column("description")]
    public string? Description { get; set; }

    [Column("embedding")]
    public Vector? Embedding { get; set; }

    [Column("search_tsv")]
    public NpgsqlTsVector? SearchTsv { get; set; }
}

[Table("aircraft", Schema = "postgres_air")]
public class Aircraft
{
    [Key]
    [Column("code")]
    public string Code { get; set; } = null!;

    [Column("model")]
    public string? Model { get; set; }

    [Column("range")]
    public decimal Range { get; set; }

    [Column("class")]
    public int Class { get; set; }

    [Column("velocity")]
    public decimal Velocity { get; set; }
}

[Table("flight_seat_inventory", Schema = "postgres_air")]
public class FlightSeatInventory
{
    [Column("flight_id")]
    public int FlightId { get; set; }

    [Column("seat_no")]
    public string SeatNo { get; set; } = null!;

    [Column("passenger_name")]
    public string? PassengerName { get; set; }

    [Column("account_id")]
    public int? AccountId { get; set; }

    [Column("reserved_at")]
    public DateTime? ReservedAt { get; set; }

    [Column("status")]
    public string Status { get; set; } = null!;

    [Column("version")]
    public int Version { get; set; }
}

[Table("flight_status_update", Schema = "postgres_air")]
public class FlightStatusUpdate
{
    [Key]
    [Column("flight_id")]
    public int FlightId { get; set; }

    [Column("status")]
    public string Status { get; set; } = null!;

    [Column("actual_departure")]
    public DateTime? ActualDeparture { get; set; }

    [Column("actual_arrival")]
    public DateTime? ActualArrival { get; set; }

    [Column("update_ts")]
    public DateTime UpdateTs { get; set; }

    [Column("version")]
    public int Version { get; set; }
}
