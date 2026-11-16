use bigdecimal::BigDecimal;
use chrono::{DateTime, Utc};
use diesel::prelude::*;
use serde::{Deserialize, Serialize};

use crate::schema::*;

// HQ01: Full Flight entity
#[derive(Debug, Clone, Queryable, Selectable, Serialize, Deserialize)]
#[diesel(table_name = flight)]
pub struct Flight {
    pub flight_id: i32,
    pub flight_no: String,
    pub scheduled_departure: DateTime<Utc>,
    pub scheduled_arrival: DateTime<Utc>,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub status: String,
    pub aircraft_code: String,
    pub actual_departure: Option<DateTime<Utc>>,
    pub actual_arrival: Option<DateTime<Utc>>,
    pub update_ts: Option<DateTime<Utc>>,
    pub version: i32,
}

// HQ02: 4-table joined composite record (17 fields)
#[derive(Debug, Clone, Queryable, Serialize)]
pub struct CompositeJoinedRecord {
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Option<BigDecimal>,
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
    pub scheduled_departure: DateTime<Utc>,
    pub status: String,
}

// HQ03: 4-level deep graph flat row & nested graph
#[derive(Debug, Clone, Queryable)]
pub struct FlightGraphFlatRow {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTime<Utc>,
    pub booking_leg_id: i32,
    pub leg_num: Option<i32>,
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Option<BigDecimal>,
    pub pass_id: Option<i32>,
    pub seat: Option<String>,
    pub boarding_time: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize)]
pub struct FlightGraph {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTime<Utc>,
    pub legs: Vec<BookingLegNode>,
}

#[derive(Debug, Clone, Serialize)]
pub struct BookingLegNode {
    pub booking_leg_id: i32,
    pub leg_num: Option<i32>,
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Option<BigDecimal>,
    pub boarding_pass: Option<BoardingPassNode>,
}

#[derive(Debug, Clone, Serialize)]
pub struct BoardingPassNode {
    pub pass_id: i32,
    pub seat: Option<String>,
    pub boarding_time: Option<DateTime<Utc>>,
}

// HQ04: Account relationship graph
#[derive(Debug, Clone, Queryable)]
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
    pub booking_price: Option<BigDecimal>,
    pub passenger_id: Option<i32>,
    pub passenger_first_name: Option<String>,
    pub passenger_last_name: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct AccountGraph {
    pub account_id: i32,
    pub login: String,
    pub first_name: String,
    pub last_name: String,
    pub frequent_flyer: Option<FrequentFlyerNode>,
    pub phones: Vec<PhoneNode>,
    pub bookings: Vec<BookingNode>,
}

#[derive(Debug, Clone, Serialize)]
pub struct FrequentFlyerNode {
    pub ff_id: i32,
    pub level: i32,
    pub award_points: i32,
}

#[derive(Debug, Clone, Serialize)]
pub struct PhoneNode {
    pub phone_id: i32,
    pub phone: Option<String>,
    pub phone_type: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct BookingNode {
    pub booking_id: i64,
    pub booking_ref: String,
    pub price: Option<BigDecimal>,
    pub passengers: Vec<PassengerNode>,
}

#[derive(Debug, Clone, Serialize)]
pub struct PassengerNode {
    pub passenger_id: i32,
    pub first_name: String,
    pub last_name: String,
}

// HQ05: Route financial ledger
#[derive(Debug, Clone, Queryable, QueryableByName, Serialize)]
pub struct RouteFinancialLedger {
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub origin: String,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub destination: String,
    #[diesel(sql_type = diesel::sql_types::Nullable<diesel::sql_types::Text>)]
    pub aircraft_model: Option<String>,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub total_flights: i64,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub total_legs_booked: i64,
    #[diesel(sql_type = diesel::sql_types::Nullable<diesel::sql_types::Numeric>)]
    pub total_revenue: Option<BigDecimal>,
    #[diesel(sql_type = diesel::sql_types::Nullable<diesel::sql_types::Numeric>)]
    pub avg_delay_minutes: Option<BigDecimal>,
    #[diesel(sql_type = diesel::sql_types::Nullable<diesel::sql_types::Numeric>)]
    pub on_time_pct: Option<BigDecimal>,
}

// HQ06: Airport hub centrality
#[derive(Debug, Clone, Queryable, QueryableByName, Serialize)]
pub struct HubCentralityRecord {
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub airport_code: String,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub airport_name: String,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub city: String,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub total_departures: i64,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub total_arrivals: i64,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub unique_destinations: i64,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub fleet_diversity: i64,
    #[diesel(sql_type = diesel::sql_types::Numeric)]
    pub avg_dep_delay: BigDecimal,
    #[diesel(sql_type = diesel::sql_types::Numeric)]
    pub avg_arr_delay: BigDecimal,
    #[diesel(sql_type = diesel::sql_types::Numeric)]
    pub hub_centrality_score: BigDecimal,
}

// HQ07: Correlated at-capacity flight
#[derive(Debug, Clone, Queryable, Serialize)]
pub struct AtCapacityFlightRecord {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTime<Utc>,
    pub aircraft_model: Option<String>,
    pub aircraft_range: BigDecimal,
    pub seats_booked: i64,
    pub elite_flyer_count: i64,
}

// HQ08: Recursive flight path
#[derive(Debug, Clone, Queryable, QueryableByName, Serialize)]
pub struct FlightPathResult {
    #[diesel(sql_type = diesel::sql_types::Integer)]
    pub hops: i32,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub route: String,
    #[diesel(sql_type = diesel::sql_types::Timestamptz)]
    pub journey_start: DateTime<Utc>,
    #[diesel(sql_type = diesel::sql_types::Timestamptz)]
    pub journey_end: DateTime<Utc>,
    #[diesel(sql_type = diesel::sql_types::Numeric)]
    pub total_elapsed_minutes: BigDecimal,
    #[diesel(sql_type = diesel::sql_types::Numeric)]
    pub total_flight_minutes: BigDecimal,
}

// HQ09: Window statistical delay dispersion
#[derive(Debug, Clone, Queryable, QueryableByName, Serialize)]
pub struct FlightDelayDispersion {
    #[diesel(sql_type = diesel::sql_types::Integer)]
    pub flight_id: i32,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub flight_no: String,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub arrival_airport: String,
    #[diesel(sql_type = diesel::sql_types::Timestamptz)]
    pub scheduled_departure: DateTime<Utc>,
    #[diesel(sql_type = diesel::sql_types::Numeric)]
    pub delay_minutes: BigDecimal,
    #[diesel(sql_type = diesel::sql_types::Nullable<diesel::sql_types::Numeric>)]
    pub rolling_avg_delay_5: Option<BigDecimal>,
    #[diesel(sql_type = diesel::sql_types::Nullable<diesel::sql_types::Numeric>)]
    pub delay_diff_prev: Option<BigDecimal>,
    #[diesel(sql_type = diesel::sql_types::Nullable<diesel::sql_types::Numeric>)]
    pub rolling_stddev_10: Option<BigDecimal>,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub severity_rank: i64,
}

// HQ10: Keyset pagination row
#[derive(Debug, Clone, Queryable, Serialize)]
pub struct KeysetFlight {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTime<Utc>,
    pub status: String,
}

// HQ11: Dynamic faceted search row
#[derive(Debug, Clone, Queryable, Serialize)]
pub struct FacetedFlightResult {
    pub flight_id: i32,
    pub flight_no: String,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub scheduled_departure: DateTime<Utc>,
    pub scheduled_arrival: DateTime<Utc>,
    pub status: String,
    pub aircraft_model: Option<String>,
    pub aircraft_range: BigDecimal,
    pub aircraft_class: i32,
}

// HQ12: High-volume batch upsert model
#[derive(Debug, Clone, Insertable, AsChangeset)]
#[diesel(table_name = flight_status_update)]
pub struct NewFlightStatusUpdate {
    pub flight_id: i32,
    pub status: String,
    pub actual_departure: Option<DateTime<Utc>>,
    pub actual_arrival: Option<DateTime<Utc>>,
    pub update_ts: DateTime<Utc>,
    pub version: i32,
}

// HQ14: Flight seat inventory record
#[derive(Debug, Clone, Queryable, Serialize)]
pub struct FlightSeatInventoryRow {
    pub flight_id: i32,
    pub seat_no: String,
    pub version: i32,
}

// HQ16: Multi-modal hybrid vector & BM25 search
#[derive(Debug, Clone, Queryable, QueryableByName, Serialize)]
pub struct HybridAirportResult {
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub airport_code: String,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub airport_name: String,
    #[diesel(sql_type = diesel::sql_types::Text)]
    pub city: String,
    #[diesel(sql_type = diesel::sql_types::BigInt)]
    pub active_flights_count: i64,
    #[diesel(sql_type = diesel::sql_types::Numeric)]
    pub rrf_score: BigDecimal,
}
