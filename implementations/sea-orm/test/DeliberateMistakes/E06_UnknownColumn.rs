use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
use sea_orm_postgres_air_bench::entities::flight;

pub fn bad_column() {
    // E06: Non-Existent Column - accessing unknown column variant on flight entity
    let _ = flight::Entity::find().filter(flight::Column::NonExistentColumn.eq(100));
}

fn main() {}
