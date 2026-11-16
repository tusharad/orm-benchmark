use sea_orm::Set;
use sea_orm_postgres_air_bench::entities::account;

pub fn bad_pk_mutation() {
    // E09: Mutating primary key with invalid string type
    let _ = account::ActiveModel {
        account_id: Set("invalid_string_id"),
        ..Default::default()
    };
}

fn main() {}
