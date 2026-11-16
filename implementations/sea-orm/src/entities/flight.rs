use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "flight")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub flight_id: i32,
    pub flight_no: String,
    pub scheduled_departure: DateTimeWithTimeZone,
    pub scheduled_arrival: DateTimeWithTimeZone,
    pub departure_airport: String,
    pub arrival_airport: String,
    pub status: String,
    pub aircraft_code: String,
    pub actual_departure: Option<DateTimeWithTimeZone>,
    pub actual_arrival: Option<DateTimeWithTimeZone>,
    pub update_ts: Option<DateTimeWithTimeZone>,
    pub version: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(has_many = "super::booking_leg::Entity")]
    BookingLeg,
    #[sea_orm(
        belongs_to = "super::aircraft::Entity",
        from = "Column::AircraftCode",
        to = "super::aircraft::Column::Code"
    )]
    Aircraft,
}

impl Related<super::booking_leg::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::BookingLeg.def()
    }
}

impl Related<super::aircraft::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Aircraft.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
