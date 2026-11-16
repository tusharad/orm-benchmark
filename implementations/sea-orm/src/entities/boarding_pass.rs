use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "boarding_pass")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub pass_id: i32,
    pub passenger_id: Option<i64>,
    pub booking_leg_id: Option<i64>,
    pub seat: Option<String>,
    pub boarding_time: Option<DateTimeWithTimeZone>,
    pub precheck: Option<bool>,
    pub update_ts: Option<DateTimeWithTimeZone>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::booking_leg::Entity",
        from = "Column::BookingLegId",
        to = "super::booking_leg::Column::BookingLegId"
    )]
    BookingLeg,
}

impl Related<super::booking_leg::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::BookingLeg.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
