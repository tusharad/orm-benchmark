use sea_orm::Set;
use sea_orm_postgres_air_bench::entities::flight;

pub fn bad_query() {
    // E01: Type Mismatch - assigning an integer to a DateTime ActiveModel field
    let _ = flight::ActiveModel {
        actual_departure: Set(42),
        ..Default::default()
    };
}

fn main() {}
