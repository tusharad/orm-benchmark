use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "passenger")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub passenger_id: i32,
    pub booking_id: i32,
    pub booking_ref: Option<String>,
    pub passenger_no: Option<i32>,
    pub first_name: String,
    pub last_name: String,
    pub account_id: Option<i32>,
    pub update_ts: Option<DateTimeWithTimeZone>,
    pub age: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::booking::Entity",
        from = "Column::BookingId",
        to = "super::booking::Column::BookingId"
    )]
    Booking,
}

impl Related<super::booking::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Booking.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
