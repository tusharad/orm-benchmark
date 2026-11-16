use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(schema_name = "postgres_air", table_name = "aircraft")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub code: String,
    pub model: Option<String>,
    pub range: Option<Decimal>,
    pub class: Option<i32>,
    pub velocity: Option<Decimal>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(has_many = "super::flight::Entity")]
    Flight,
}

impl Related<super::flight::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Flight.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
