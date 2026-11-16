use sea_orm::{DatabaseConnection, DbErr, TransactionTrait};

pub async fn bad_transaction(db: &DatabaseConnection) -> Result<(), DbErr> {
    // E04: Returning an unhandled IO Error from transaction closure expecting DbErr
    db.transaction::<_, (), DbErr>(|_txn| {
        Box::pin(async move {
            let _ = std::fs::File::open("non_existent_file.txt")?;
            Ok(())
        })
    })
    .await
    .map_err(|e| match e {
        sea_orm::TransactionError::Connection(err) => err,
        sea_orm::TransactionError::Transaction(err) => err,
    })
}

fn main() {}
