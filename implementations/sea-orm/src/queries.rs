use rust_decimal::Decimal;
use sea_orm::entity::prelude::*;
use sea_orm::sea_query::{Expr, ExprTrait, OnConflict};
use sea_orm::{
    Condition, DatabaseConnection, DbBackend, FromQueryResult, InsertManyResult, JoinType,
    QueryOrder, QuerySelect, Set, Statement, TransactionError, TransactionTrait, UpdateResult,
};
use std::collections::BTreeMap;

use crate::entities::*;
use crate::models::*;

// HQ01: Massive Entity Deserialization (10,000 Wide Rows)
pub async fn hq01_massive_deserialization(
    db: &DatabaseConnection,
) -> Result<Vec<flight::Model>, DbErr> {
    flight::Entity::find()
        .order_by_asc(flight::Column::FlightId)
        .limit(10000)
        .all(db)
        .await
}

// HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
pub async fn hq02_wide_multi_join(
    db: &DatabaseConnection,
) -> Result<Vec<CompositeJoinedRecord>, DbErr> {
    let sql = r#"
        SELECT b.booking_id, b.booking_ref, b.price, b.email,
               p.passenger_id, p.first_name, p.last_name, p.age,
               bl.booking_leg_id, bl.leg_num, bl.is_returning,
               f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport,
               f.scheduled_departure, f.status
        FROM booking b
        JOIN passenger p ON b.booking_id = p.booking_id
        JOIN booking_leg bl ON b.booking_id = bl.booking_id
        JOIN flight f ON bl.flight_id = f.flight_id
        WHERE b.booking_id BETWEEN 100000 AND 105000
        ORDER BY b.booking_id ASC, p.passenger_id ASC, bl.booking_leg_id ASC
        LIMIT 5000;
    "#;
    CompositeJoinedRecord::find_by_statement(Statement::from_sql_and_values(
        DbBackend::Postgres,
        sql,
        [],
    ))
    .all(db)
    .await
}

// HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
pub async fn hq03_deep_hierarchical_graph(
    db: &DatabaseConnection,
) -> Result<Vec<FlightGraph>, DbErr> {
    let sql = r#"
        SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, f.scheduled_departure,
               bl.booking_leg_id, bl.leg_num,
               b.booking_id, b.booking_ref, b.price,
               bp.pass_id, bp.seat, bp.boarding_time
        FROM flight f
        JOIN booking_leg bl ON f.flight_id = bl.flight_id
        JOIN booking b ON bl.booking_id = b.booking_id
        LEFT JOIN boarding_pass bp ON bl.booking_leg_id = bp.booking_leg_id
        WHERE f.flight_id BETWEEN 2000 AND 2025
        ORDER BY f.flight_id ASC, bl.booking_leg_id ASC, bp.pass_id ASC;
    "#;
    let rows: Vec<FlightGraphFlatRow> = FlightGraphFlatRow::find_by_statement(
        Statement::from_sql_and_values(DbBackend::Postgres, sql, []),
    )
    .all(db)
    .await?;

    let mut map: BTreeMap<i32, FlightGraph> = BTreeMap::new();
    for row in rows {
        let fg = map.entry(row.flight_id).or_insert_with(|| FlightGraph {
            flight_id: row.flight_id,
            flight_no: row.flight_no.clone(),
            departure_airport: row.departure_airport.clone(),
            arrival_airport: row.arrival_airport.clone(),
            scheduled_departure: row.scheduled_departure,
            legs: Vec::new(),
        });

        if let Some(existing_leg) = fg
            .legs
            .iter_mut()
            .find(|l| l.booking_leg_id == row.booking_leg_id)
        {
            if existing_leg.boarding_pass.is_none() {
                if let Some(pid) = row.pass_id {
                    existing_leg.boarding_pass = Some(BoardingPassNode {
                        pass_id: pid,
                        seat: row.seat,
                        boarding_time: row.boarding_time,
                    });
                }
            }
        } else {
            let bp = row.pass_id.map(|pid| BoardingPassNode {
                pass_id: pid,
                seat: row.seat,
                boarding_time: row.boarding_time,
            });
            fg.legs.push(BookingLegNode {
                booking_leg_id: row.booking_leg_id,
                leg_num: row.leg_num,
                booking_id: row.booking_id,
                booking_ref: row.booking_ref,
                price: row.price,
                boarding_pass: bp,
            });
        }
    }

    Ok(map.into_values().collect())
}

// HQ04: Account Relationship Graph with Optional Sub-Entities
pub async fn hq04_account_relationship_graph(
    db: &DatabaseConnection,
) -> Result<Vec<AccountGraph>, DbErr> {
    let sql = r#"
        SELECT a.account_id, a.login, a.first_name, a.last_name,
               ff.frequent_flyer_id AS ff_id, ff.level AS ff_level, ff.award_points AS ff_award_points,
               ph.phone_id, ph.phone, ph.phone_type,
               b.booking_id, b.booking_ref, b.price AS booking_price,
               p.passenger_id, p.first_name AS passenger_first_name, p.last_name AS passenger_last_name
        FROM account a
        LEFT JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
        LEFT JOIN phone ph ON ph.account_id = a.account_id
        LEFT JOIN booking b ON b.account_id = a.account_id
        LEFT JOIN passenger p ON p.booking_id = b.booking_id
        WHERE a.account_id BETWEEN 50000 AND 50200
        ORDER BY a.account_id ASC, ph.phone_id ASC, b.booking_id ASC, p.passenger_id ASC;
    "#;
    let rows: Vec<AccountGraphFlatRow> = AccountGraphFlatRow::find_by_statement(
        Statement::from_sql_and_values(DbBackend::Postgres, sql, []),
    )
    .all(db)
    .await?;

    let mut map: BTreeMap<i32, AccountGraph> = BTreeMap::new();
    for row in rows {
        let acc = map.entry(row.account_id).or_insert_with(|| {
            let ff = if let (Some(ff_id), Some(level), Some(award_points)) =
                (row.ff_id, row.ff_level, row.ff_award_points)
            {
                Some(FrequentFlyerNode {
                    ff_id,
                    level,
                    award_points,
                })
            } else {
                None
            };
            AccountGraph {
                account_id: row.account_id,
                login: row.login.clone(),
                first_name: row.first_name.clone(),
                last_name: row.last_name.clone(),
                frequent_flyer: ff,
                phones: Vec::new(),
                bookings: Vec::new(),
            }
        });

        if let Some(pid) = row.phone_id {
            if !acc.phones.iter().any(|p| p.phone_id == pid) {
                acc.phones.push(PhoneNode {
                    phone_id: pid,
                    phone: row.phone.clone(),
                    phone_type: row.phone_type.clone(),
                });
            }
        }

        if let Some(bid) = row.booking_id {
            if let Some(b) = acc.bookings.iter_mut().find(|b| b.booking_id == bid) {
                if let Some(ps_id) = row.passenger_id {
                    if !b.passengers.iter().any(|p| p.passenger_id == ps_id) {
                        b.passengers.push(PassengerNode {
                            passenger_id: ps_id,
                            first_name: row.passenger_first_name.clone().unwrap_or_default(),
                            last_name: row.passenger_last_name.clone().unwrap_or_default(),
                        });
                    }
                }
            } else {
                let mut passengers = Vec::new();
                if let Some(ps_id) = row.passenger_id {
                    passengers.push(PassengerNode {
                        passenger_id: ps_id,
                        first_name: row.passenger_first_name.unwrap_or_default(),
                        last_name: row.passenger_last_name.unwrap_or_default(),
                    });
                }
                acc.bookings.push(BookingNode {
                    booking_id: bid,
                    booking_ref: row.booking_ref.unwrap_or_default(),
                    price: row.booking_price,
                    passengers,
                });
            }
        }
    }

    Ok(map.into_values().collect())
}

// HQ05: Fleet & Route Profitability Analytical Ledger
pub async fn hq05_route_financial_ledger(
    db: &DatabaseConnection,
) -> Result<Vec<RouteFinancialLedger>, DbErr> {
    let sql = r#"
        SELECT orig.airport_code AS origin,
               dest.airport_code AS destination,
               ac.model AS aircraft_model,
               count(DISTINCT f.flight_id) AS total_flights,
               count(bl.booking_leg_id) AS total_legs_booked,
               round(sum(b.price), 2) AS total_revenue,
               round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60)::numeric, 2) AS avg_delay_minutes,
               round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2) AS on_time_pct
        FROM flight f
        JOIN airport orig ON f.departure_airport = orig.airport_code
        JOIN airport dest ON f.arrival_airport = dest.airport_code
        JOIN aircraft ac ON f.aircraft_code = ac.code
        JOIN booking_leg bl ON f.flight_id = bl.flight_id
        JOIN booking b ON bl.booking_id = b.booking_id
        WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00' 
          AND f.scheduled_departure < '2024-07-04 00:00:00+00'
        GROUP BY orig.airport_code, dest.airport_code, ac.model
        HAVING count(DISTINCT f.flight_id) >= 3
        ORDER BY total_revenue DESC NULLS LAST
        LIMIT 50;
    "#;
    RouteFinancialLedger::find_by_statement(Statement::from_sql_and_values(
        DbBackend::Postgres,
        sql,
        [],
    ))
    .all(db)
    .await
}

// HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
pub async fn hq06_chained_ctes_hub_centrality(
    db: &DatabaseConnection,
) -> Result<Vec<HubCentralityRecord>, DbErr> {
    let sql = r#"
        WITH flight_volumes AS (
            SELECT departure_airport AS airport_code,
                   count(*) AS departures_count,
                   round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS avg_dep_delay
            FROM flight
            WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00'
              AND actual_departure IS NOT NULL
            GROUP BY departure_airport
        ),
        arrival_volumes AS (
            SELECT arrival_airport AS airport_code,
                   count(*) AS arrivals_count,
                   round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2) AS avg_arr_delay
            FROM flight
            WHERE scheduled_arrival >= '2024-06-01 00:00:00+00' AND scheduled_arrival < '2024-07-01 00:00:00+00'
              AND actual_arrival IS NOT NULL
            GROUP BY arrival_airport
        ),
        route_connectivity AS (
            SELECT departure_airport AS airport_code,
                   count(DISTINCT arrival_airport) AS unique_destinations,
                   count(DISTINCT aircraft_code) AS fleet_diversity
            FROM flight
            WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00'
            GROUP BY departure_airport
        )
        SELECT a.airport_code,
               a.airport_name,
               a.city,
               coalesce(fv.departures_count, 0) AS total_departures,
               coalesce(av.arrivals_count, 0) AS total_arrivals,
               coalesce(rc.unique_destinations, 0) AS unique_destinations,
               coalesce(rc.fleet_diversity, 0) AS fleet_diversity,
               coalesce(fv.avg_dep_delay, 0) AS avg_dep_delay,
               coalesce(av.avg_arr_delay, 0) AS avg_arr_delay,
               round(
                   (coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) * 
                   (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) / 
                   (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0), 
                   2
               ) AS hub_centrality_score
        FROM airport a
        JOIN flight_volumes fv ON a.airport_code = fv.airport_code
        JOIN arrival_volumes av ON a.airport_code = av.airport_code
        JOIN route_connectivity rc ON a.airport_code = rc.airport_code
        ORDER BY hub_centrality_score DESC
        LIMIT 50;
    "#;
    HubCentralityRecord::find_by_statement(Statement::from_sql_and_values(
        DbBackend::Postgres,
        sql,
        [],
    ))
    .all(db)
    .await
}

// HQ07: Correlated At-Capacity Subquery + Loyalty Cross-Check
pub async fn hq07_correlated_subqueries(
    db: &DatabaseConnection,
) -> Result<Vec<AtCapacityFlightRecord>, DbErr> {
    let sql = r#"
        SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, f.scheduled_departure,
               ac.model, ac.range,
               (SELECT count(*) FROM booking_leg bl WHERE bl.flight_id = f.flight_id) AS total_booked_legs,
               (SELECT count(*) 
                FROM booking_leg bl 
                JOIN passenger p ON bl.booking_id = p.booking_id 
                JOIN account a ON p.account_id = a.account_id 
                JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id 
                WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS tier_flyers_count
        FROM flight f
        JOIN aircraft ac ON f.aircraft_code = ac.code
        WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00'
          AND f.scheduled_departure < '2024-07-03 00:00:00+00'
          AND ac.class >= 2
          AND (SELECT count(*) FROM booking_leg bl WHERE bl.flight_id = f.flight_id) > 40
          AND EXISTS (
              SELECT 1 
              FROM flight route_f 
              WHERE route_f.departure_airport = f.departure_airport 
                AND route_f.arrival_airport = f.arrival_airport 
                AND route_f.status = 'Canceled' 
                AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00'
          )
        ORDER BY total_booked_legs DESC
        LIMIT 100;
    "#;
    AtCapacityFlightRecord::find_by_statement(Statement::from_sql_and_values(
        DbBackend::Postgres,
        sql,
        [],
    ))
    .all(db)
    .await
}

// HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
pub async fn hq08_recursive_multi_hop(
    db: &DatabaseConnection,
) -> Result<Vec<FlightPathResult>, DbErr> {
    let sql = r#"
        WITH RECURSIVE flight_paths AS (
            SELECT f.flight_id,
                   f.departure_airport::text AS departure_airport,
                   f.arrival_airport::text AS arrival_airport,
                   f.scheduled_departure,
                   f.scheduled_arrival,
                   1 AS hops,
                   ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports,
                   ARRAY[f.flight_id] AS route_flights,
                   f.scheduled_departure AS journey_start,
                   f.scheduled_arrival AS journey_end,
                   (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::numeric(10,2) AS total_flight_minutes
            FROM flight f
            WHERE f.departure_airport = 'JFK'
              AND f.scheduled_departure >= '2024-07-05 00:00:00+00'
              AND f.scheduled_departure < '2024-07-06 00:00:00+00'

            UNION ALL

            SELECT next_f.flight_id,
                   fp.departure_airport,
                   next_f.arrival_airport::text,
                   next_f.scheduled_departure,
                   next_f.scheduled_arrival,
                   fp.hops + 1,
                   fp.route_airports || next_f.arrival_airport::text,
                   fp.route_flights || next_f.flight_id,
                   fp.journey_start,
                   next_f.scheduled_arrival,
                   (fp.total_flight_minutes + (EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60))::numeric(10,2)
            FROM flight_paths fp
            JOIN flight next_f ON fp.arrival_airport = next_f.departure_airport
            WHERE fp.hops < 3
              AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '60 minutes'
              AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '360 minutes'
              AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports))
        )
        SELECT hops,
               array_to_string(route_airports, ' -> ') AS route,
               journey_start,
               journey_end,
               (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::numeric(10,2) AS total_elapsed_minutes,
               total_flight_minutes
        FROM flight_paths
        WHERE arrival_airport = 'ORD'
        ORDER BY hops ASC, total_elapsed_minutes ASC
        LIMIT 25;
    "#;
    FlightPathResult::find_by_statement(Statement::from_sql_and_values(
        DbBackend::Postgres,
        sql,
        [],
    ))
    .all(db)
    .await
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
pub async fn hq09_window_statistical_dispersion(
    db: &DatabaseConnection,
) -> Result<Vec<FlightDelayDispersion>, DbErr> {
    let sql = r#"
        WITH flight_delays AS (
            SELECT flight_id,
                   flight_no,
                   departure_airport,
                   arrival_airport,
                   scheduled_departure,
                   actual_departure,
                   round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS delay_minutes
            FROM flight
            WHERE departure_airport = 'ORD'
              AND actual_departure IS NOT NULL
              AND scheduled_departure >= '2024-06-01 00:00:00+00'
              AND scheduled_departure < '2024-07-01 00:00:00+00'
        )
        SELECT flight_id,
               flight_no,
               arrival_airport,
               scheduled_departure,
               delay_minutes,
               round(avg(delay_minutes) OVER (
                   PARTITION BY departure_airport, arrival_airport 
                   ORDER BY scheduled_departure 
                   ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
               ), 2) AS rolling_avg_delay_5,
               delay_minutes - lag(delay_minutes, 1) OVER (
                   PARTITION BY departure_airport, arrival_airport 
                   ORDER BY scheduled_departure
               ) AS delay_diff_prev,
               round(coalesce(stddev_samp(delay_minutes) OVER (
                   PARTITION BY departure_airport, arrival_airport 
                   ORDER BY scheduled_departure 
                   ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
               ), 0), 2) AS rolling_stddev_10,
               dense_rank() OVER (
                   PARTITION BY departure_airport, arrival_airport 
                   ORDER BY delay_minutes DESC
               ) AS severity_rank
        FROM flight_delays
        ORDER BY departure_airport, arrival_airport, scheduled_departure
        LIMIT 5000;
    "#;
    FlightDelayDispersion::find_by_statement(Statement::from_sql_and_values(
        DbBackend::Postgres,
        sql,
        [],
    ))
    .all(db)
    .await
}

// HQ10: Keyset (Cursor) Pagination over Composite Key Under Load
pub async fn hq10_keyset_pagination(
    db: &DatabaseConnection,
    cursor_time: DateTimeWithTimeZone,
    cursor_id: i32,
) -> Result<Vec<KeysetFlight>, DbErr> {
    flight::Entity::find()
        .filter(
            Condition::any()
                .add(flight::Column::ScheduledDeparture.gt(cursor_time))
                .add(
                    Condition::all()
                        .add(flight::Column::ScheduledDeparture.eq(cursor_time))
                        .add(flight::Column::FlightId.gt(cursor_id)),
                ),
        )
        .order_by_asc(flight::Column::ScheduledDeparture)
        .order_by_asc(flight::Column::FlightId)
        .limit(50)
        .select_only()
        .column(flight::Column::FlightId)
        .column(flight::Column::FlightNo)
        .column(flight::Column::DepartureAirport)
        .column(flight::Column::ArrivalAirport)
        .column(flight::Column::ScheduledDeparture)
        .column(flight::Column::Status)
        .into_model::<KeysetFlight>()
        .all(db)
        .await
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
pub async fn hq11_dynamic_faceted_search(
    db: &DatabaseConnection,
    dep_airports: Option<Vec<String>>,
    arr_airports: Option<Vec<String>>,
    min_dep: Option<DateTimeWithTimeZone>,
    max_dep: Option<DateTimeWithTimeZone>,
    aircraft_classes: Option<Vec<i32>>,
    min_range: Option<Decimal>,
    statuses: Option<Vec<String>>,
    cursor: Option<(DateTimeWithTimeZone, i32)>,
) -> Result<Vec<FacetedFlightResult>, DbErr> {
    let mut query = flight::Entity::find()
        .join_rev(JoinType::InnerJoin, aircraft::Relation::Flight.def())
        .select_only()
        .column(flight::Column::FlightId)
        .column(flight::Column::FlightNo)
        .column(flight::Column::DepartureAirport)
        .column(flight::Column::ArrivalAirport)
        .column(flight::Column::ScheduledDeparture)
        .column(flight::Column::ScheduledArrival)
        .column(flight::Column::Status)
        .column(aircraft::Column::Model)
        .column(aircraft::Column::Range)
        .column(aircraft::Column::Class);

    if let Some(deps) = dep_airports {
        query = query.filter(flight::Column::DepartureAirport.is_in(deps));
    }
    if let Some(arrs) = arr_airports {
        query = query.filter(flight::Column::ArrivalAirport.is_in(arrs));
    }
    if let Some(min_t) = min_dep {
        query = query.filter(flight::Column::ScheduledDeparture.gte(min_t));
    }
    if let Some(max_t) = max_dep {
        query = query.filter(flight::Column::ScheduledDeparture.lte(max_t));
    }
    if let Some(classes) = aircraft_classes {
        query = query.filter(aircraft::Column::Class.is_in(classes));
    }
    if let Some(rng) = min_range {
        query = query.filter(aircraft::Column::Range.gte(rng));
    }
    if let Some(stats) = statuses {
        query = query.filter(flight::Column::Status.is_in(stats));
    }
    if let Some((cur_t, cur_id)) = cursor {
        query = query.filter(
            Condition::any()
                .add(flight::Column::ScheduledDeparture.gt(cur_t))
                .add(
                    Condition::all()
                        .add(flight::Column::ScheduledDeparture.eq(cur_t))
                        .add(flight::Column::FlightId.gt(cur_id)),
                ),
        );
    }

    query
        .order_by_asc(flight::Column::ScheduledDeparture)
        .order_by_asc(flight::Column::FlightId)
        .limit(100)
        .into_model::<FacetedFlightResult>()
        .all(db)
        .await
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
pub async fn hq12_batch_upsert(
    db: &DatabaseConnection,
    models: Vec<flight_status_update::ActiveModel>,
) -> Result<InsertManyResult<flight_status_update::ActiveModel>, DbErr> {
    flight_status_update::Entity::insert_many(models)
        .on_conflict(
            OnConflict::column(flight_status_update::Column::FlightId)
                .update_columns([
                    flight_status_update::Column::Status,
                    flight_status_update::Column::ActualDeparture,
                    flight_status_update::Column::ActualArrival,
                    flight_status_update::Column::UpdateTs,
                ])
                .value(
                    flight_status_update::Column::Version,
                    Expr::col((
                        flight_status_update::Entity,
                        flight_status_update::Column::Version,
                    ))
                    .add(1),
                )
                .to_owned(),
        )
        .exec(db)
        .await
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
pub async fn hq13_optimistic_concurrency(db: &DatabaseConnection) -> Result<UpdateResult, DbErr> {
    flight::Entity::update_many()
        .col_expr(flight::Column::Status, Expr::value("Boarding"))
        .col_expr(
            flight::Column::Version,
            Expr::col(flight::Column::Version).add(1),
        )
        .filter(flight::Column::FlightId.between(1000, 1050))
        .filter(flight::Column::Version.eq(1))
        .exec(db)
        .await
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
pub async fn hq14_seat_allocation(
    db: &DatabaseConnection,
    target_flight_id: i32,
) -> Result<bool, DbErr> {
    db.transaction::<_, bool, DbErr>(|txn| {
        Box::pin(async move {
            let seat = flight_seat_inventory::Entity::find()
                .filter(flight_seat_inventory::Column::FlightId.eq(target_flight_id))
                .filter(flight_seat_inventory::Column::Status.eq("AVAILABLE"))
                .order_by_asc(flight_seat_inventory::Column::SeatNo)
                .lock_exclusive()
                .one(txn)
                .await?;

            if let Some(s) = seat {
                let mut active: flight_seat_inventory::ActiveModel = s.into();
                active.status = Set("RESERVED".to_string());
                active.passenger_name = Set(Some("Test Concurrent Flyer".to_string()));
                active.version = Set(active.version.unwrap() + 1);
                active.update(txn).await?;
                Ok(true)
            } else {
                Ok(false)
            }
        })
    })
    .await
    .map_err(|e| match e {
        TransactionError::Connection(err) => err,
        TransactionError::Transaction(err) => err,
    })
}

// HQ15: Distributed Financial / Points Transfer with 40001 Retry
pub async fn hq15_points_transfer_with_retry(
    db: &DatabaseConnection,
    from_id: i32,
    to_id: i32,
    points: i32,
) -> Result<(), DbErr> {
    let mut retries = 5;
    let mut backoff = std::time::Duration::from_millis(10);

    loop {
        let res = db
            .transaction::<_, (), DbErr>(|txn| {
                Box::pin(async move {
                    frequent_flyer::Entity::update_many()
                        .col_expr(
                            frequent_flyer::Column::AwardPoints,
                            Expr::col(frequent_flyer::Column::AwardPoints).sub(points),
                        )
                        .filter(frequent_flyer::Column::FrequentFlyerId.eq(from_id))
                        .exec(txn)
                        .await?;

                    frequent_flyer::Entity::update_many()
                        .col_expr(
                            frequent_flyer::Column::AwardPoints,
                            Expr::col(frequent_flyer::Column::AwardPoints).add(points),
                        )
                        .filter(frequent_flyer::Column::FrequentFlyerId.eq(to_id))
                        .exec(txn)
                        .await?;

                    Ok(())
                })
            })
            .await;

        match res {
            Ok(()) => return Ok(()),
            Err(e) => {
                let err_str = e.to_string();
                let is_40001 =
                    err_str.contains("40001") || err_str.contains("could not serialize");
                if is_40001 && retries > 0 {
                    retries -= 1;
                    tokio::time::sleep(backoff).await;
                    backoff *= 2;
                    continue;
                }
                return Err(match e {
                    TransactionError::Connection(err) => err,
                    TransactionError::Transaction(err) => err,
                });
            }
        }
    }
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
pub async fn hq16_hybrid_search(
    db: &DatabaseConnection,
) -> Result<Vec<HybridAirportResult>, DbErr> {
    let sql = r#"
        WITH text_ranking AS (
            SELECT airport_code, 
                   ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', 'London Heathrow international hub')) DESC) AS rank_text
            FROM airport
            WHERE search_tsv @@ plainto_tsquery('english', 'London Heathrow international hub')
            LIMIT 25
        ),
        vector_ranking AS (
            SELECT airport_code, 
                   ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM airport WHERE airport_code = 'LHR')) ASC) AS rank_vec
            FROM airport
            LIMIT 25
        ),
        airport_stats AS (
            SELECT departure_airport AS airport_code,
                   count(*) AS active_flights_count
            FROM flight
            WHERE scheduled_departure >= '2024-07-01 00:00:00+00' AND scheduled_departure < '2024-07-08 00:00:00+00'
            GROUP BY departure_airport
        )
        SELECT COALESCE(t.airport_code, v.airport_code) AS airport_code,
               a.airport_name, 
               a.city,
               COALESCE(ast.active_flights_count, 0) AS active_flights_count,
               round((COALESCE(1.0 / (60 + t.rank_text), 0.0) + COALESCE(1.0 / (60 + v.rank_vec), 0.0))::numeric, 5) AS rrf_score
            FROM text_ranking t
            FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code
            JOIN airport a ON a.airport_code = COALESCE(t.airport_code, v.airport_code)
            LEFT JOIN airport_stats ast ON ast.airport_code = COALESCE(t.airport_code, v.airport_code)
            ORDER BY rrf_score DESC
            LIMIT 25;
    "#;
    HybridAirportResult::find_by_statement(Statement::from_sql_and_values(
        DbBackend::Postgres,
        sql,
        [],
    ))
    .all(db)
    .await
}
