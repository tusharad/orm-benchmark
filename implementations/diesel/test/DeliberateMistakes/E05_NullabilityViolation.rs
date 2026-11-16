use diesel::prelude::*;

diesel::table! {
    airport (airport_code) {
        airport_code -> Text,
        airport_name -> Text,
    }
}

#[derive(Insertable)]
#[diesel(table_name = airport)]
pub struct NewAirport {
    pub airport_code: String,
    pub airport_name: Option<String>, // Error: airport_name is NOT NULL in schema
}

pub fn bad_insert(conn: &mut PgConnection) {
    let item = NewAirport {
        airport_code: "XYZ".to_string(),
        airport_name: None,
    };
    let _ = diesel::insert_into(airport::table).values(&item).execute(conn);
}

fn main() {}
