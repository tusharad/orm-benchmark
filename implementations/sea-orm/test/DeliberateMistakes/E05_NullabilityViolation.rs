use sea_orm::Set;
use sea_orm_postgres_air_bench::entities::flight;

pub fn bad_null() {
    // E05: Nullability Violation - assigning None to non-nullable flight_no column
    let _ = flight::ActiveModel {
        flight_no: Set(None),
        ..Default::default()
    };
}

fn main() {}
