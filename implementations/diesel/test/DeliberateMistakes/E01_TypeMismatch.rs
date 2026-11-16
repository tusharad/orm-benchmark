use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
        status -> Text,
        actual_departure -> Nullable<Timestamptz>,
    }
}

pub fn bad_query() {
    // E01: Type Mismatch in Equality - comparing Nullable<Timestamptz> to an integer 42
    let _ = flight::table.filter(flight::actual_departure.eq(42));
}

fn main() {}
