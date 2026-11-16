use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
    }
}

diesel::table! {
    passenger (passenger_id) {
        passenger_id -> BigInt,
    }
}

diesel::allow_tables_to_appear_in_same_query!(flight, passenger);

pub fn bad_query() {
    // E02: Foreign Key Type Mismatch in Join - flight_id (Int4) joined with passenger_id (BigInt)
    let _ = flight::table.inner_join(passenger::table.on(flight::flight_id.eq(passenger::passenger_id)));
}

fn main() {}
