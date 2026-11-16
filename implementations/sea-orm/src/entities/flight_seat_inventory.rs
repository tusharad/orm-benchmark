use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "flight_seat_inventory")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub flight_id: i32,
    #[sea_orm(primary_key, auto_increment = false)]
    pub seat_no: String,
    pub passenger_name: Option<String>,
    pub account_id: Option<i32>,
    pub reserved_at: Option<DateTimeWithTimeZone>,
    pub status: String,
    pub version: i32,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
