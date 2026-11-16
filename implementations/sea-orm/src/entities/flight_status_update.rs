use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "flight_status_update")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub flight_id: i32,
    pub status: String,
    pub actual_departure: Option<DateTimeWithTimeZone>,
    pub actual_arrival: Option<DateTimeWithTimeZone>,
    pub update_ts: DateTimeWithTimeZone,
    pub version: i32,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
