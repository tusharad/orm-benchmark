use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
use sea_orm_postgres_air_bench::entities::flight;

pub fn bad_scope() {
    // E10: Inner scope variable leaked to outer query
    {
        let inner_condition = flight::Column::FlightNo.eq("FL101");
        let _ = inner_condition;
    }
    // Attempting to reference inner variable outside its scope
    let _ = flight::Entity::find().filter(inner_condition);
}

fn main() {}
