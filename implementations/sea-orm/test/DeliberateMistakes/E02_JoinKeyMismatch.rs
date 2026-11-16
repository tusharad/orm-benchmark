use sea_orm::EntityTrait;
use sea_orm_postgres_air_bench::entities::{flight, passenger};

pub fn bad_join() {
    // E02: Foreign Key Relation Mismatch - joining unrelated flight and passenger without relation
    let _ = flight::Entity::find().find_also_related(passenger::Entity);
}

fn main() {}
