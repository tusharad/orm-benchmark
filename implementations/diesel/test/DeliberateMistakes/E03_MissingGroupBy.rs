use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
        departure_airport -> Text,
    }
}

pub fn bad_query() {
    // E03: Missing Column in GROUP BY - projecting raw column departure_airport alongside aggregate count
    use diesel::dsl::count_star;
    let _ = flight::table
        .select((flight::departure_airport, count_star()));
}

fn main() {}
