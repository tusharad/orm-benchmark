use diesel::prelude::*;

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
        status -> Text,
    }
}

#[derive(AsChangeset)]
#[diesel(table_name = flight)]
#[diesel(primary_key(flight_id))]
pub struct FlightUpdate {
    pub flight_id: i32, // Primary key cannot be updated via changeset
    pub status: String,
}

pub fn bad_update(conn: &mut PgConnection) {
    let update = FlightUpdate {
        flight_id: 999,
        status: "Delayed".to_string(),
    };
    let _ = diesel::update(flight::table).set(&update).execute(conn);
}

fn main() {}
