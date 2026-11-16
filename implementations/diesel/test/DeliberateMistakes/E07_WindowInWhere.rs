use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
    }
}

pub fn bad_query() {
    // E07: Placing a window function directly into WHERE filter
    let window_expr = diesel::dsl::sql::<diesel::sql_types::BigInt>("ROW_NUMBER() OVER ()");
    let _ = flight::table.filter(window_expr.gt(5));
}

fn main() {}
