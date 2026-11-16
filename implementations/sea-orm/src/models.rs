use rust_decimal::Decimal;
use sea_orm::FromQueryResult;
use sea_orm::entity::prelude::DateTimeWithTimeZone;
use serde::{Deserialize, Serialize};

// HQ02: Composite Joined Record
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct CompositeJoinedRecord {
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Decimal,
    pub email: String,
    pub passenger_id: i32,
    pub first_name: String,
    pub last_name: String,
    pub age: Option<i32>,
    pub booking_leg_id: i32,
    pub leg_num: Option<i32>,
    pub is_returning: Option<bool>,
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub status: String,
}

// HQ03: Deep Hierarchical Graph
#[derive(Clone, Debug, FromQueryResult)]
pub struct FlightGraphFlatRow {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub booking_leg_id: i32,
    pub leg_num: Option<i32>,
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Decimal,
    pub pass_id: Option<i32>,
    pub seat: Option<String>,
    pub boarding_time: Option<DateTimeWithTimeZone>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct FlightGraph {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub legs: Vec<BookingLegNode>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BookingLegNode {
    pub booking_leg_id: i32,
    pub leg_num: Option<i32>,
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Decimal,
    pub boarding_pass: Option<BoardingPassNode>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BoardingPassNode {
    pub pass_id: i32,
    pub seat: Option<String>,
    pub boarding_time: Option<DateTimeWithTimeZone>,
}

// HQ04: Account Graph
#[derive(Clone, Debug, FromQueryResult)]
pub struct AccountGraphFlatRow {
    pub account_id: i32,
    pub login: String,
    pub first_name: String,
    pub last_name: String,
    pub ff_id: Option<i32>,
    pub ff_level: Option<i32>,
    pub ff_award_points: Option<i32>,
    pub phone_id: Option<i32>,
    pub phone: Option<String>,
    pub phone_type: Option<String>,
    pub booking_id: Option<i64>,
    pub booking_ref: Option<String>,
    pub booking_price: Option<Decimal>,
    pub passenger_id: Option<i32>,
    pub passenger_first_name: Option<String>,
    pub passenger_last_name: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct AccountGraph {
    pub account_id: i32,
    pub login: String,
    pub first_name: String,
    pub last_name: String,
    pub frequent_flyer: Option<FrequentFlyerNode>,
    pub phones: Vec<PhoneNode>,
    pub bookings: Vec<BookingNode>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct FrequentFlyerNode {
    pub ff_id: i32,
    pub level: i32,
    pub award_points: i32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PhoneNode {
    pub phone_id: i32,
    pub phone: Option<String>,
    pub phone_type: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BookingNode {
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Option<Decimal>,
    pub passengers: Vec<PassengerNode>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PassengerNode {
    pub passenger_id: i32,
    pub first_name: String,
    pub last_name: String,
}

// HQ05: Route Financial Ledger
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct RouteFinancialLedger {
    pub origin: String,
    pub destination: String,
    pub aircraft_model: Option<String>,
    pub total_flights: i64,
    pub total_legs_booked: i64,
    pub total_revenue: Option<Decimal>,
    pub avg_delay_minutes: Option<Decimal>,
    pub on_time_pct: Option<Decimal>,
}

// HQ06: Hub Centrality
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct HubCentralityRecord {
    pub airport_code: String,
    pub airport_name: String,
    pub city: String,
    pub total_departures: i64,
    pub total_arrivals: i64,
    pub unique_destinations: i64,
    pub fleet_diversity: i64,
    pub avg_dep_delay: Decimal,
    pub avg_arr_delay: Decimal,
    pub hub_centrality_score: Decimal,
}

// HQ07: At Capacity Flights
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct AtCapacityFlightRecord {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub model: Option<String>,
    pub range: Option<Decimal>,
    pub total_booked_legs: i64,
    pub tier_flyers_count: i64,
}

// HQ08: Recursive Flight Paths
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct FlightPathResult {
    pub hops: i32,
    pub route: String,
    pub journey_start: DateTimeWithTimeZone,
    pub journey_end: DateTimeWithTimeZone,
    pub total_elapsed_minutes: Decimal,
    pub total_flight_minutes: Decimal,
}

// HQ09: Delay Dispersion
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct FlightDelayDispersion {
    pub flight_id: i32,
    pub flight_no: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub delay_minutes: Option<Decimal>,
    pub rolling_avg_delay_5: Option<Decimal>,
    pub delay_diff_prev: Option<Decimal>,
    pub rolling_stddev_10: Option<Decimal>,
    pub severity_rank: i64,
}

// HQ10: Keyset Flight
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct KeysetFlight {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub status: String,
}

// HQ11: Faceted Flight Result
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct FacetedFlightResult {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub scheduled_arrival: DateTimeWithTimeZone,
    pub status: String,
    pub model: Option<String>,
    pub range: Option<Decimal>,
    pub class: Option<i32>,
}

// HQ14: Seat Allocation Row
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct FlightSeatInventoryRow {
    pub flight_id: i32,
    pub seat_no: String,
    pub version: i32,
}

// HQ16: Hybrid Search
#[derive(Clone, Debug, FromQueryResult, Serialize, Deserialize)]
pub struct HybridAirportResult {
    pub airport_code: String,
    pub airport_name: String,
    pub city: String,
    pub active_flights_count: i64,
    pub rrf_score: Decimal,
}
