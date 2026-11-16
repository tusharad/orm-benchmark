use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
    }
}

diesel::table! {
    airport (airport_code) {
        airport_code -> Text,
        airport_name -> Text,
    }
}

pub fn bad_query() {
    // E08: Referencing airport column without joining airport table
    let _ = flight::table.select(airport::airport_name);
}

fn main() {}
