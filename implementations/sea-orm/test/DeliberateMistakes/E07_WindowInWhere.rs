use sea_orm::sea_query::Func;
use sea_orm::{EntityTrait, QueryFilter};
use sea_orm_postgres_air_bench::entities::flight;

pub fn bad_window() {
    // E07: Placing window function directly inside WHERE filter
    let _ = flight::Entity::find().filter(Func::row_number());
}

fn main() {}
