use bigdecimal::BigDecimal;
use chrono::{DateTime, TimeZone, Utc};
use diesel::prelude::*;

use crate::models::*;
use crate::schema::*;

// HQ01: Massive Entity Deserialization (10,000 Wide Rows)
pub fn hq01_massive_deserialization(conn: &mut PgConnection) -> QueryResult<Vec<Flight>> {
    use crate::schema::flight::dsl::*;
    flight
        .order(flight_id.asc())
        .limit(10000)
        .load::<Flight>(conn)
}

// HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
pub fn hq02_wide_multi_join(conn: &mut PgConnection) -> QueryResult<Vec<CompositeJoinedRecord>> {
    booking::table
        .inner_join(passenger::table.on(passenger::booking_id.eq(diesel::dsl::sql::<diesel::sql_types::Integer>("booking.booking_id::integer"))))
        .inner_join(booking_leg::table.on(booking_leg::booking_id.eq(diesel::dsl::sql::<diesel::sql_types::Integer>("booking.booking_id::integer"))))
        .inner_join(flight::table.on(flight::flight_id.eq(booking_leg::flight_id)))
        .filter(booking::booking_id.between(100000i64, 105000i64))
        .order((booking::booking_id.asc(), passenger::passenger_id.asc(), booking_leg::booking_leg_id.asc()))
        .limit(5000)
        .select((
            booking::booking_id, booking::booking_ref, booking::price, booking::email,
            passenger::passenger_id, passenger::first_name, passenger::last_name, passenger::age,
            booking_leg::booking_leg_id, booking_leg::leg_num, booking_leg::is_returning,
            flight::flight_id, flight::flight_no, flight::departure_airport, flight::arrival_airport,
            flight::scheduled_departure, flight::status,
        ))
        .load::<CompositeJoinedRecord>(conn)
}

// HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
pub fn hq03_deep_hierarchical_graph(conn: &mut PgConnection) -> QueryResult<Vec<FlightGraph>> {
    let rows = flight::table
        .inner_join(booking_leg::table.on(flight::flight_id.eq(booking_leg::flight_id)))
        .inner_join(booking::table.on(booking::booking_id.eq(diesel::dsl::sql::<diesel::sql_types::BigInt>("booking_leg.booking_id"))))
        .left_join(boarding_pass::table.on(boarding_pass::booking_leg_id.eq(diesel::dsl::sql::<diesel::sql_types::Nullable<diesel::sql_types::BigInt>>("booking_leg.booking_leg_id"))))
        .filter(flight::flight_id.between(2000, 2025))
        .order((flight::flight_id.asc(), booking_leg::booking_leg_id.asc(), boarding_pass::pass_id.asc()))
        .select((
            flight::flight_id, flight::flight_no, flight::departure_airport, flight::arrival_airport, flight::scheduled_departure,
            booking_leg::booking_leg_id, booking_leg::leg_num,
            booking::booking_id, booking::booking_ref, booking::price,
            boarding_pass::pass_id.nullable(), boarding_pass::seat.nullable(), boarding_pass::boarding_time.nullable(),
        ))
        .load::<FlightGraphFlatRow>(conn)?;

    let mut map: std::collections::BTreeMap<i32, FlightGraph> = std::collections::BTreeMap::new();
    for row in rows {
        let fg = map.entry(row.flight_id).or_insert_with(|| FlightGraph {
            flight_id: row.flight_id,
            flight_no: row.flight_no.clone(),
            departure_airport: row.departure_airport.clone(),
            arrival_airport: row.arrival_airport.clone(),
            scheduled_departure: row.scheduled_departure,
            legs: Vec::new(),
        });

        if let Some(existing_leg) = fg.legs.iter_mut().find(|l| l.booking_leg_id == row.booking_leg_id) {
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
pub fn hq04_account_relationship_graph(conn: &mut PgConnection) -> QueryResult<Vec<AccountGraph>> {
    let rows = account::table
        .left_join(frequent_flyer::table.on(account::frequent_flyer_id.eq(frequent_flyer::frequent_flyer_id.nullable())))
        .left_join(phone::table.on(phone::account_id.eq(account::account_id.nullable())))
        .left_join(booking::table.on(booking::account_id.eq(account::account_id.nullable())))
        .left_join(passenger::table.on(passenger::booking_id.eq(diesel::dsl::sql::<diesel::sql_types::Integer>("booking.booking_id::integer"))))
        .filter(account::account_id.between(50000, 50200))
        .order((account::account_id.asc(), phone::phone_id.asc(), booking::booking_id.asc(), passenger::passenger_id.asc()))
        .select((
            account::account_id, account::login, account::first_name, account::last_name,
            frequent_flyer::frequent_flyer_id.nullable(), frequent_flyer::level.nullable(), frequent_flyer::award_points.nullable(),
            phone::phone_id.nullable(), phone::phone_number.nullable(), phone::phone_type.nullable(),
            booking::booking_id.nullable(), booking::booking_ref.nullable(), booking::price.nullable(),
            passenger::passenger_id.nullable(), passenger::first_name.nullable(), passenger::last_name.nullable(),
        ))
        .load::<AccountGraphFlatRow>(conn)?;

    let mut map: std::collections::BTreeMap<i32, AccountGraph> = std::collections::BTreeMap::new();
    for row in rows {
        let acc = map.entry(row.account_id).or_insert_with(|| {
            let ff = if let (Some(ff_id), Some(level), Some(award_points)) = (row.ff_id, row.ff_level, row.ff_award_points) {
                Some(FrequentFlyerNode { ff_id, level, award_points })
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
pub fn hq05_route_financial_ledger(conn: &mut PgConnection) -> QueryResult<Vec<RouteFinancialLedger>> {
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
    diesel::sql_query(sql).load::<RouteFinancialLedger>(conn)
}

// HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
pub fn hq06_chained_ctes_hub_centrality(conn: &mut PgConnection) -> QueryResult<Vec<HubCentralityRecord>> {
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
    diesel::sql_query(sql).load::<HubCentralityRecord>(conn)
}

// HQ07: Correlated At-Capacity Subquery + Loyalty Cross-Check
pub fn hq07_correlated_subqueries(conn: &mut PgConnection) -> QueryResult<Vec<AtCapacityFlightRecord>> {
    let start_date = Utc.with_ymd_and_hms(2024, 7, 1, 0, 0, 0).unwrap();
    let end_date = Utc.with_ymd_and_hms(2024, 7, 3, 0, 0, 0).unwrap();

    flight::table
        .inner_join(aircraft::table.on(flight::aircraft_code.eq(aircraft::code)))
        .filter(flight::scheduled_departure.ge(start_date))
        .filter(flight::scheduled_departure.lt(end_date))
        .filter(aircraft::class.ge(2))
        .filter(diesel::dsl::sql::<diesel::sql_types::Bool>(
            "(SELECT count(*) FROM booking_leg bl WHERE bl.flight_id = flight.flight_id) > 40"
        ))
        .filter(diesel::dsl::sql::<diesel::sql_types::Bool>(
            "EXISTS (SELECT 1 FROM flight route_f WHERE route_f.departure_airport = flight.departure_airport AND route_f.arrival_airport = flight.arrival_airport AND route_f.status = 'Canceled' AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00')"
        ))
        .order(diesel::dsl::sql::<diesel::sql_types::BigInt>("(SELECT count(*) FROM booking_leg bl WHERE bl.flight_id = flight.flight_id)").desc())
        .limit(100)
        .select((
            flight::flight_id,
            flight::flight_no,
            flight::departure_airport,
            flight::arrival_airport,
            flight::scheduled_departure,
            aircraft::model.nullable(),
            aircraft::range,
            diesel::dsl::sql::<diesel::sql_types::BigInt>("(SELECT count(*) FROM booking_leg bl WHERE bl.flight_id = flight.flight_id)"),
            diesel::dsl::sql::<diesel::sql_types::BigInt>("(SELECT count(*) FROM booking_leg bl JOIN passenger p ON bl.booking_id = p.booking_id JOIN account a ON p.account_id = a.account_id JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id WHERE bl.flight_id = flight.flight_id AND ff.level >= 3)"),
        ))
        .load::<AtCapacityFlightRecord>(conn)
}

// HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
pub fn hq08_recursive_multi_hop(conn: &mut PgConnection) -> QueryResult<Vec<FlightPathResult>> {
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
    diesel::sql_query(sql).load::<FlightPathResult>(conn)
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
pub fn hq09_window_statistical_dispersion(conn: &mut PgConnection) -> QueryResult<Vec<FlightDelayDispersion>> {
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
    diesel::sql_query(sql).load::<FlightDelayDispersion>(conn)
}

// HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
pub fn hq10_keyset_pagination(
    conn: &mut PgConnection,
    cursor_time: DateTime<Utc>,
    cursor_id: i32,
) -> QueryResult<Vec<KeysetFlight>> {
    use crate::schema::flight::dsl::*;
    flight
        .filter(
            scheduled_departure.gt(cursor_time)
                .or(scheduled_departure.eq(cursor_time).and(flight_id.gt(cursor_id)))
        )
        .order((scheduled_departure.asc(), flight_id.asc()))
        .limit(50)
        .select((flight_id, flight_no, departure_airport, arrival_airport, scheduled_departure, status))
        .load::<KeysetFlight>(conn)
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
pub fn hq11_dynamic_faceted_search(
    conn: &mut PgConnection,
    dep_airports: Option<Vec<String>>,
    arr_airports: Option<Vec<String>>,
    min_dep: Option<DateTime<Utc>>,
    max_dep: Option<DateTime<Utc>>,
    aircraft_classes: Option<Vec<i32>>,
    min_range: Option<BigDecimal>,
    statuses: Option<Vec<String>>,
    start_hour: Option<i32>,
    end_hour: Option<i32>,
    cursor: Option<(DateTime<Utc>, i32)>,
) -> QueryResult<Vec<FacetedFlightResult>> {
    let mut query = flight::table
        .inner_join(aircraft::table.on(flight::aircraft_code.eq(aircraft::code)))
        .select((
            flight::flight_id, flight::flight_no, flight::departure_airport, flight::arrival_airport,
            flight::scheduled_departure, flight::scheduled_arrival, flight::status,
            aircraft::model.nullable(), aircraft::range, aircraft::class,
        ))
        .into_boxed();

    if let Some(deps) = dep_airports {
        query = query.filter(flight::departure_airport.eq_any(deps));
    }
    if let Some(arrs) = arr_airports {
        query = query.filter(flight::arrival_airport.eq_any(arrs));
    }
    if let Some(min_t) = min_dep {
        query = query.filter(flight::scheduled_departure.ge(min_t));
    }
    if let Some(max_t) = max_dep {
        query = query.filter(flight::scheduled_departure.le(max_t));
    }
    if let Some(classes) = aircraft_classes {
        query = query.filter(aircraft::class.eq_any(classes));
    }
    if let Some(rng) = min_range {
        query = query.filter(aircraft::range.ge(rng));
    }
    if let Some(stats) = statuses {
        query = query.filter(flight::status.eq_any(stats));
    }
    if let (Some(sh), Some(eh)) = (start_hour, end_hour) {
        query = query.filter(
            diesel::dsl::sql::<diesel::sql_types::Bool>(&format!(
                "EXTRACT(HOUR FROM flight.scheduled_departure) BETWEEN {} AND {}", sh, eh
            ))
        );
    }
    if let Some((cur_t, cur_id)) = cursor {
        query = query.filter(
            flight::scheduled_departure.gt(cur_t)
                .or(flight::scheduled_departure.eq(cur_t).and(flight::flight_id.gt(cur_id)))
        );
    }

    query
        .order((flight::scheduled_departure.asc(), flight::flight_id.asc()))
        .limit(100)
        .load::<FacetedFlightResult>(conn)
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
pub fn hq12_batch_upsert(
    conn: &mut PgConnection,
    batch: &[NewFlightStatusUpdate],
) -> QueryResult<usize> {
    use crate::schema::flight_status_update::dsl::*;
    
    diesel::insert_into(flight_status_update)
        .values(batch)
        .on_conflict(flight_id)
        .do_update()
        .set((
            status.eq(diesel::pg::upsert::excluded(status)),
            actual_departure.eq(diesel::pg::upsert::excluded(actual_departure)),
            actual_arrival.eq(diesel::pg::upsert::excluded(actual_arrival)),
            update_ts.eq(diesel::pg::upsert::excluded(update_ts)),
            version.eq(version + 1),
        ))
        .execute(conn)
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
pub fn hq13_optimistic_concurrency(conn: &mut PgConnection) -> QueryResult<usize> {
    use crate::schema::flight::dsl::*;
    
    diesel::update(
        flight
            .filter(flight_id.between(1000, 1050))
            .filter(version.eq(1))
    )
    .set((
        status.eq("Boarding"),
        version.eq(version + 1),
        update_ts.eq(diesel::dsl::now),
    ))
    .execute(conn)
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
pub fn hq14_seat_allocation(conn: &mut PgConnection, target_flight_id: i32) -> QueryResult<bool> {
    use crate::schema::flight_seat_inventory::dsl::*;

    conn.transaction::<bool, diesel::result::Error, _>(|conn| {
        let seat = flight_seat_inventory
            .filter(flight_id.eq(target_flight_id))
            .filter(status.eq("AVAILABLE"))
            .order(seat_no.asc())
            .limit(1)
            .for_update()
            .select((flight_id, seat_no, version))
            .first::<FlightSeatInventoryRow>(conn)
            .optional()?;

        match seat {
            Some(s) => {
                let affected = diesel::update(
                    flight_seat_inventory
                        .filter(flight_id.eq(s.flight_id))
                        .filter(seat_no.eq(&s.seat_no))
                        .filter(version.eq(s.version))
                )
                .set((
                    status.eq("RESERVED"),
                    passenger_name.eq(Some("Test Concurrent Flyer".to_string())),
                    reserved_at.eq(diesel::dsl::now),
                    version.eq(version + 1),
                ))
                .execute(conn)?;
                Ok(affected > 0)
            }
            None => Ok(false),
        }
    })
}

// HQ15: Distributed Financial / Points Transfer with 40001 Retry
pub fn hq15_points_transfer_with_retry(
    conn: &mut PgConnection,
    from_id: i32,
    to_id: i32,
    points: i32,
) -> Result<(), diesel::result::Error> {
    use crate::schema::frequent_flyer::dsl::*;
    let mut retries = 5;
    let mut backoff_ms = 10;

    loop {
        let res = conn.build_transaction()
            .serializable()
            .run::<_, diesel::result::Error, _>(|conn| {
                diesel::update(frequent_flyer.filter(frequent_flyer_id.eq(from_id)))
                    .set(award_points.eq(award_points - points))
                    .execute(conn)?;

                diesel::update(frequent_flyer.filter(frequent_flyer_id.eq(to_id)))
                    .set(award_points.eq(award_points + points))
                    .execute(conn)?;

                Ok(())
            });

        match res {
            Ok(()) => return Ok(()),
            Err(e) => {
                let is_40001 = match &e {
                    diesel::result::Error::DatabaseError(diesel::result::DatabaseErrorKind::SerializationFailure, _) => true,
                    _ => false,
                };
                if is_40001 && retries > 0 {
                    retries -= 1;
                    std::thread::sleep(std::time::Duration::from_millis(backoff_ms));
                    backoff_ms *= 2;
                    continue;
                }
                return Err(e);
            }
        }
    }
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
pub fn hq16_hybrid_search(conn: &mut PgConnection) -> QueryResult<Vec<HybridAirportResult>> {
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
    diesel::sql_query(sql).load::<HybridAirportResult>(conn)
}
