use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
        flight_no -> Text,
    }
}

pub fn bad_scope() {
    // E10: Inner scope variable leaked to outer query
    {
        let inner_subquery = flight::table.select(flight::flight_no);
        let _ = inner_subquery;
    }
    // Attempting to reference inner variable outside its scope
    let _ = flight::table.filter(inner_subquery.eq("FL101"));
}

fn main() {}
