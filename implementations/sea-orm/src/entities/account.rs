use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "account")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub account_id: i32,
    pub login: String,
    pub first_name: String,
    pub last_name: String,
    pub frequent_flyer_id: Option<i32>,
    pub update_ts: Option<DateTimeWithTimeZone>,
    pub version: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::frequent_flyer::Entity",
        from = "Column::FrequentFlyerId",
        to = "super::frequent_flyer::Column::FrequentFlyerId"
    )]
    FrequentFlyer,
    #[sea_orm(has_many = "super::phone::Entity")]
    Phone,
    #[sea_orm(has_many = "super::booking::Entity")]
    Booking,
}

impl Related<super::frequent_flyer::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::FrequentFlyer.def()
    }
}

impl Related<super::phone::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Phone.def()
    }
}

impl Related<super::booking::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Booking.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
