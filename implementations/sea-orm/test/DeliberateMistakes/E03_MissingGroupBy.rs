use sea_orm::{EntityTrait, QuerySelect};
use sea_orm_postgres_air_bench::entities::flight;

pub fn bad_group_by() {
    // E03: Missing Column in GROUP BY - passing invalid type to group_by
    let _ = flight::Entity::find().group_by(42);
}

fn main() {}
