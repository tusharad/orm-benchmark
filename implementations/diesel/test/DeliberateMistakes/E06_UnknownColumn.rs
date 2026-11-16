use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
        flight_no -> Text,
    }
}

pub fn bad_selection() {
    // E06: Selecting non-existent column flight_noo
    let _ = flight::table.select(flight::flight_noo);
}

fn main() {}
