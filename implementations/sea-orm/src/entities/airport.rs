use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "airport")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub airport_code: String,
    pub airport_name: String,
    pub city: String,
    pub airport_tz: String,
    pub continent: Option<String>,
    pub iso_country: Option<String>,
    pub iso_region: Option<String>,
    pub intnl: Option<bool>,
    pub update_ts: Option<DateTimeWithTimeZone>,
    pub description: Option<String>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
