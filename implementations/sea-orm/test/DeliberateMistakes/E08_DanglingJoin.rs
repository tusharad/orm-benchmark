use sea_orm::ModelTrait;
use sea_orm_postgres_air_bench::entities::{airport, flight};

pub fn bad_dangling(flight: &flight::Model) {
    // E08: Dangling Join - calling find_related for unjoined, unrelated airport entity
    let _ = flight.find_related(airport::Entity);
}

fn main() {}
