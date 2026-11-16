use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "booking")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub booking_id: i64,
    pub booking_ref: String,
    pub booking_name: Option<String>,
    pub account_id: Option<i32>,
    pub email: String,
    pub phone: String,
    pub update_ts: Option<DateTimeWithTimeZone>,
    pub price: Decimal,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(has_many = "super::passenger::Entity")]
    Passenger,
    #[sea_orm(has_many = "super::booking_leg::Entity")]
    BookingLeg,
    #[sea_orm(
        belongs_to = "super::account::Entity",
        from = "Column::AccountId",
        to = "super::account::Column::AccountId"
    )]
    Account,
}

impl Related<super::passenger::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Passenger.def()
    }
}

impl Related<super::booking_leg::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::BookingLeg.def()
    }
}

impl Related<super::account::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Account.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
