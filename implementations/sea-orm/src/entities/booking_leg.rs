use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "booking_leg")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub booking_leg_id: i32,
    pub booking_id: i32,
    pub flight_id: i32,
    pub leg_num: Option<i32>,
    pub is_returning: Option<bool>,
    pub update_ts: Option<DateTimeWithTimeZone>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::booking::Entity",
        from = "Column::BookingId",
        to = "super::booking::Column::BookingId"
    )]
    Booking,
    #[sea_orm(
        belongs_to = "super::flight::Entity",
        from = "Column::FlightId",
        to = "super::flight::Column::FlightId"
    )]
    Flight,
    #[sea_orm(has_many = "super::boarding_pass::Entity")]
    BoardingPass,
}

impl Related<super::booking::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Booking.def()
    }
}

impl Related<super::flight::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Flight.def()
    }
}

impl Related<super::boarding_pass::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::BoardingPass.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
