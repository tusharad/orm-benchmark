use diesel::prelude::*;

pub fn bad_transaction(conn: &mut PgConnection) -> Result<(), diesel::result::Error> {
    // E04: Returning an unhandled IO Error from a pure transaction
    conn.transaction(|_conn| {
        let _ = std::fs::File::open("non_existent_file.txt")?;
        Ok(())
    })
}

fn main() {}
