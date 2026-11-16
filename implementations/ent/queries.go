package main

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"entgo.io/ent/dialect"
	entsql "entgo.io/ent/dialect/sql"
)

// HQ01: Massive Entity Deserialization (10,000 Wide Rows)
func HQ01(ctx context.Context, db *sql.DB) ([]Flight, error) {
	query, args := entsql.Dialect(dialect.Postgres).
		Select("flight_id", "flight_no", "scheduled_departure", "scheduled_arrival",
			"departure_airport", "arrival_airport", "status", "aircraft_code",
			"actual_departure", "actual_arrival", "update_ts", "version").
		From(entsql.Table("flight").Schema("postgres_air")).
		OrderBy(entsql.Asc("flight_id")).
		Limit(10000).
		Query()

	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var flights []Flight
	if err := entsql.ScanSlice(rows, &flights); err != nil {
		return nil, err
	}
	return flights, nil
}

// HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
func HQ02(ctx context.Context, db *sql.DB) ([]CompositeBookingRecord, error) {
	rawSQL := `
SELECT b.booking_id, b.booking_ref, b.price, b.email,
       p.passenger_id, p.first_name, p.last_name, p.age,
       bl.booking_leg_id, bl.leg_num, bl.is_returning,
       f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport,
       f.scheduled_departure, f.status
FROM postgres_air.booking b
JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id
JOIN postgres_air.flight f ON bl.flight_id = f.flight_id
WHERE b.booking_id BETWEEN 100000 AND 105000
ORDER BY b.booking_id ASC, p.passenger_id ASC, bl.booking_leg_id ASC
LIMIT 5000;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var records []CompositeBookingRecord
	if err := entsql.ScanSlice(rows, &records); err != nil {
		return nil, err
	}
	return records, nil
}

// HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
func HQ03(ctx context.Context, db *sql.DB) ([]FlightGraphNode, error) {
	rawSQL := `
SELECT f.flight_id, f.flight_no, f.scheduled_departure, f.scheduled_arrival,
       f.departure_airport, f.arrival_airport, f.status, f.aircraft_code,
       f.actual_departure, f.actual_arrival, f.update_ts, f.version,
       bl.booking_leg_id, bl.booking_id, bl.flight_id, bl.leg_num, bl.is_returning, bl.update_ts,
       bp.pass_id, bp.passenger_id, bp.booking_leg_id, bp.seat, bp.boarding_time, bp.update_ts
FROM postgres_air.flight f
JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
LEFT JOIN postgres_air.boarding_pass bp ON bl.booking_leg_id = bp.booking_leg_id
WHERE f.flight_id BETWEEN 2000 AND 2025
ORDER BY f.flight_id ASC, bl.booking_leg_id ASC, COALESCE(bp.pass_id, 0) ASC;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	flightMap := make(map[int32]*FlightGraphNode)
	var orderedFlights []int32

	for rows.Next() {
		var f Flight
		var bl BookingLeg
		var bp BoardingPass

		err := rows.Scan(
			&f.FlightID, &f.FlightNo, &f.ScheduledDeparture, &f.ScheduledArrival,
			&f.DepartureAirport, &f.ArrivalAirport, &f.Status, &f.AircraftCode,
			&f.ActualDeparture, &f.ActualArrival, &f.UpdateTs, &f.Version,
			&bl.BookingLegID, &bl.BookingID, &bl.FlightID, &bl.LegNum, &bl.IsReturning, &bl.UpdateTs,
			&bp.PassID, &bp.PassengerID, &bp.BookingLegID, &bp.Seat, &bp.BoardingTime, &bp.UpdateTs,
		)
		if err != nil {
			return nil, err
		}

		node, exists := flightMap[f.FlightID]
		if !exists {
			node = &FlightGraphNode{Flight: f, Legs: make([]BookingLegNode, 0)}
			flightMap[f.FlightID] = node
			orderedFlights = append(orderedFlights, f.FlightID)
		}

		var passPtr *BoardingPass
		if bp.PassID != 0 {
			passPtr = &bp
		}
		node.Legs = append(node.Legs, BookingLegNode{Leg: bl, Pass: passPtr})
	}

	result := make([]FlightGraphNode, len(orderedFlights))
	for i, id := range orderedFlights {
		result[i] = *flightMap[id]
	}
	return result, nil
}

// HQ04: Account Relationship Graph with Optional Sub-Entities
func HQ04(ctx context.Context, db *sql.DB) ([]Account, error) {
	query, args := entsql.Dialect(dialect.Postgres).
		Select("account_id", "login", "first_name", "last_name", "frequent_flyer_id", "update_ts").
		From(entsql.Table("account").Schema("postgres_air")).
		Where(entsql.And(
			entsql.GTE("account_id", 50000),
			entsql.LTE("account_id", 50200),
		)).
		OrderBy(entsql.Asc("account_id")).
		Query()

	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var accounts []Account
	if err := entsql.ScanSlice(rows, &accounts); err != nil {
		return nil, err
	}
	return accounts, nil
}

// HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
func HQ05(ctx context.Context, db *sql.DB) ([]RouteProfitability, error) {
	rawSQL := `
SELECT orig.airport_code AS origin,
       dest.airport_code AS destination,
       ac.model AS aircraft_model,
       count(DISTINCT f.flight_id) AS total_flights,
       count(bl.booking_leg_id) AS total_legs_booked,
       round(sum(b.price)::numeric, 2) AS total_revenue,
       round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60)::numeric, 2) AS avg_delay_minutes,
       round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2) AS on_time_pct
FROM postgres_air.flight f
JOIN postgres_air.airport orig ON f.departure_airport = orig.airport_code
JOIN postgres_air.airport dest ON f.arrival_airport = dest.airport_code
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00' AND f.scheduled_departure < '2024-07-04 00:00:00+00'
GROUP BY orig.airport_code, dest.airport_code, ac.model
HAVING count(DISTINCT f.flight_id) >= 3
ORDER BY total_revenue DESC
LIMIT 50;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []RouteProfitability
	if err := entsql.ScanSlice(rows, &results); err != nil {
		return nil, err
	}
	return results, nil
}

// HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
func HQ06(ctx context.Context, db *sql.DB) ([]HubCentrality, error) {
	rawSQL := `
WITH flight_volumes AS (
    SELECT departure_airport AS airport_code,
           count(*) AS departures_count,
           round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS avg_dep_delay
    FROM postgres_air.flight
    WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00'
      AND actual_departure IS NOT NULL
    GROUP BY departure_airport
),
arrival_volumes AS (
    SELECT arrival_airport AS airport_code,
           count(*) AS arrivals_count,
           round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2) AS avg_arr_delay
    FROM postgres_air.flight
    WHERE scheduled_arrival >= '2024-06-01 00:00:00+00' AND scheduled_arrival < '2024-07-01 00:00:00+00'
      AND actual_arrival IS NOT NULL
    GROUP BY arrival_airport
),
route_connectivity AS (
    SELECT departure_airport AS airport_code,
           count(DISTINCT arrival_airport) AS unique_destinations,
           count(DISTINCT aircraft_code) AS fleet_diversity
    FROM postgres_air.flight
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
FROM postgres_air.airport a
JOIN flight_volumes fv ON a.airport_code = fv.airport_code
JOIN arrival_volumes av ON a.airport_code = av.airport_code
JOIN route_connectivity rc ON a.airport_code = rc.airport_code
ORDER BY hub_centrality_score DESC
LIMIT 50;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []HubCentrality
	if err := entsql.ScanSlice(rows, &results); err != nil {
		return nil, err
	}
	return results, nil
}

// HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
func HQ07(ctx context.Context, db *sql.DB) ([]FlightCapacity, error) {
	rawSQL := `
SELECT f.flight_id,
       f.flight_no,
       f.departure_airport,
       f.arrival_airport,
       f.scheduled_departure,
       ac.model AS aircraft_model,
       ac.range AS aircraft_range,
       (SELECT count(*) 
        FROM postgres_air.booking_leg bl 
        WHERE bl.flight_id = f.flight_id) AS seats_booked,
       (SELECT count(*)
        FROM postgres_air.booking_leg bl
        JOIN postgres_air.passenger p ON bl.booking_id = p.booking_id
        JOIN postgres_air.account a ON p.account_id = a.account_id
        JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
        WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS elite_flyer_count
FROM postgres_air.flight f
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00'
  AND f.scheduled_departure < '2024-07-03 00:00:00+00'
  AND ac.class >= 2
  AND (
      SELECT count(*) 
      FROM postgres_air.booking_leg bl 
      WHERE bl.flight_id = f.flight_id
  ) > 40
  AND EXISTS (
      SELECT 1 
      FROM postgres_air.flight route_f 
      WHERE route_f.departure_airport = f.departure_airport 
        AND route_f.arrival_airport = f.arrival_airport 
        AND route_f.status = 'Canceled'
        AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00'
  )
ORDER BY seats_booked DESC
LIMIT 100;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []FlightCapacity
	if err := entsql.ScanSlice(rows, &results); err != nil {
		return nil, err
	}
	return results, nil
}

// HQ08: Recursive Multi-Hop Flight Connection Graph Search (1- to 3-Hop Paths)
func HQ08(ctx context.Context, db *sql.DB) ([]Itinerary, error) {
	rawSQL := `
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
    FROM postgres_air.flight f
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
    JOIN postgres_air.flight next_f ON fp.arrival_airport = next_f.departure_airport
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
LIMIT 25;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []Itinerary
	if err := entsql.ScanSlice(rows, &results); err != nil {
		return nil, err
	}
	return results, nil
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
func HQ09(ctx context.Context, db *sql.DB) ([]WindowDelay, error) {
	rawSQL := `
WITH flight_delays AS (
    SELECT flight_id,
           flight_no,
           departure_airport,
           arrival_airport,
           scheduled_departure,
           actual_departure,
           round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS delay_minutes
    FROM postgres_air.flight
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
LIMIT 5000;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []WindowDelay
	if err := entsql.ScanSlice(rows, &results); err != nil {
		return nil, err
	}
	return results, nil
}

// HQ10: High-Throughput Keyset (Cursor) Pagination over Composite Tuple
func HQ10(ctx context.Context, db *sql.DB, cursorTime *time.Time, cursorID *int32) ([]Flight, error) {
	cTime := time.Date(2024, 7, 15, 12, 0, 0, 0, time.UTC)
	if cursorTime != nil {
		cTime = *cursorTime
	}
	var cID int32 = 10500
	if cursorID != nil {
		cID = *cursorID
	}

	query, args := entsql.Dialect(dialect.Postgres).
		Select("flight_id", "flight_no", "scheduled_departure", "scheduled_arrival",
			"departure_airport", "arrival_airport", "status", "aircraft_code",
			"actual_departure", "actual_arrival", "update_ts", "version").
		From(entsql.Table("flight").Schema("postgres_air")).
		Where(entsql.Or(
			entsql.GT("scheduled_departure", cTime),
			entsql.And(
				entsql.EQ("scheduled_departure", cTime),
				entsql.GT("flight_id", cID),
			),
		)).
		OrderBy(entsql.Asc("scheduled_departure"), entsql.Asc("flight_id")).
		Limit(50).
		Query()

	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var flights []Flight
	if err := entsql.ScanSlice(rows, &flights); err != nil {
		return nil, err
	}
	return flights, nil
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
func HQ11(ctx context.Context, db *sql.DB,
	depAirports []string,
	arrAirports []string,
	tStart *time.Time,
	tEnd *time.Time,
	classes []int32,
	minRange *float64,
	statuses []string,
	hMin *int,
	hMax *int,
	cursorTime *time.Time,
	cursorID *int32,
) ([]FacetedFlight, error) {
	if len(depAirports) == 0 {
		depAirports = []string{"JFK", "BOS", "EWR"}
	}
	if len(arrAirports) == 0 {
		arrAirports = []string{"LAX", "SFO", "SEA"}
	}
	t0 := time.Date(2024, 7, 1, 0, 0, 0, 0, time.UTC)
	if tStart != nil {
		t0 = *tStart
	}
	t1 := time.Date(2024, 7, 15, 23, 59, 59, 0, time.UTC)
	if tEnd != nil {
		t1 = *tEnd
	}
	if len(classes) == 0 {
		classes = []int32{1, 2, 3}
	}
	rng := 2000.0
	if minRange != nil {
		rng = *minRange
	}
	if len(statuses) == 0 {
		statuses = []string{"On time", "Delayed"}
	}
	hourMin := 6
	if hMin != nil {
		hourMin = *hMin
	}
	hourMax := 21
	if hMax != nil {
		hourMax = *hMax
	}
	cTime := time.Date(2024, 7, 1, 6, 0, 0, 0, time.UTC)
	if cursorTime != nil {
		cTime = *cursorTime
	}
	var cID int32 = 500
	if cursorID != nil {
		cID = *cursorID
	}

	rawSQL := `
SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport,
       f.scheduled_departure, f.scheduled_arrival, f.status,
       ac.model AS aircraft_model, ac.range AS aircraft_range, ac.class AS aircraft_class
FROM postgres_air.flight f
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
WHERE f.departure_airport = ANY($1)
  AND f.arrival_airport = ANY($2)
  AND f.scheduled_departure >= $3
  AND f.scheduled_departure <= $4
  AND ac.class = ANY($5)
  AND ac.range >= $6
  AND f.status = ANY($7)
  AND EXTRACT(HOUR FROM f.scheduled_departure) BETWEEN $8 AND $9
  AND (f.scheduled_departure > $10 OR (f.scheduled_departure = $10 AND f.flight_id > $11))
ORDER BY f.scheduled_departure ASC, f.flight_id ASC
LIMIT 100;`

	rows, err := db.QueryContext(ctx, rawSQL,
		depAirports, arrAirports, t0, t1, classes, rng, statuses, hourMin, hourMax, cTime, cID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []FacetedFlight
	if err := entsql.ScanSlice(rows, &results); err != nil {
		return nil, err
	}
	return results, nil
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
func HQ12(ctx context.Context, db *sql.DB) (int64, error) {
	var sb strings.Builder
	sb.WriteString(`
INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version)
VALUES `)
	now := time.Now().UTC()
	for i := 1; i <= 2500; i++ {
		if i > 1 {
			sb.WriteString(",")
		}
		sb.WriteString(fmt.Sprintf("(%d, 'Departed', '2024-07-01 08:05:00+00', '2024-07-01 11:15:00+00', '%s', 1)",
			i, now.Format(time.RFC3339Nano)))
	}
	sb.WriteString(`
ON CONFLICT (flight_id) DO UPDATE SET
    status = EXCLUDED.status,
    actual_departure = EXCLUDED.actual_departure,
    actual_arrival = EXCLUDED.actual_arrival,
    update_ts = EXCLUDED.update_ts,
    version = postgres_air.flight_status_update.version + 1;`)

	res, err := db.ExecContext(ctx, sb.String())
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
func HQ13(ctx context.Context, db *sql.DB) (int64, error) {
	updateSQL := `
UPDATE postgres_air.flight
SET status = 'Boarding', version = version + 1, update_ts = NOW()
WHERE flight_id >= 1000 AND flight_id <= 1050 AND version = 1;`

	resetSQL := `
UPDATE postgres_air.flight
SET status = 'Departed', version = 1
WHERE flight_id >= 1000 AND flight_id <= 1050;`

	res, err := db.ExecContext(ctx, updateSQL)
	if err != nil {
		return 0, err
	}
	affected, err := res.RowsAffected()
	if err != nil {
		return 0, err
	}
	_, _ = db.ExecContext(ctx, resetSQL)
	return affected, nil
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
func HQ14(ctx context.Context, db *sql.DB, flightID int32) (string, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer func() {
		if r := recover(); r != nil {
			_ = tx.Rollback()
		}
	}()

	var seatNo string
	var version int32
	err = tx.QueryRowContext(ctx,
		"SELECT seat_no, version FROM postgres_air.flight_seat_inventory WHERE flight_id = $1 AND status = 'AVAILABLE' LIMIT 1 FOR UPDATE",
		flightID).Scan(&seatNo, &version)
	if err != nil {
		_ = tx.Rollback()
		return "", err
	}

	now := time.Now().UTC()
	_, err = tx.ExecContext(ctx,
		`UPDATE postgres_air.flight_seat_inventory
         SET status = 'RESERVED', passenger_name = 'Test Concurrent Flyer', reserved_at = $1, version = version + 1
         WHERE flight_id = $2 AND seat_no = $3 AND version = $4`,
		now, flightID, seatNo, version)
	if err != nil {
		_ = tx.Rollback()
		return "", err
	}

	if err := tx.Commit(); err != nil {
		return "", err
	}
	return seatNo, nil
}

// HQ15: Distributed Financial / Points Transfer with 40001 Retry
func HQ15(ctx context.Context, db *sql.DB, fromID, toID, points int32, maxRetries int) (bool, error) {
	for attempt := 1; attempt <= maxRetries; attempt++ {
		tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
		if err != nil {
			return false, err
		}

		_, err1 := tx.ExecContext(ctx, "UPDATE postgres_air.frequent_flyer SET award_points = award_points - $1 WHERE frequent_flyer_id = $2", points, fromID)
		_, err2 := tx.ExecContext(ctx, "UPDATE postgres_air.frequent_flyer SET award_points = award_points + $1 WHERE frequent_flyer_id = $2", points, toID)

		if err1 != nil || err2 != nil {
			_ = tx.Rollback()
			if isSerializationErr(err1) || isSerializationErr(err2) {
				time.Sleep(time.Duration(attempt*10) * time.Millisecond)
				continue
			}
			return false, fmt.Errorf("transfer error: %v, %v", err1, err2)
		}

		if err := tx.Commit(); err != nil {
			if isSerializationErr(err) {
				time.Sleep(time.Duration(attempt*10) * time.Millisecond)
				continue
			}
			return false, err
		}

		// Revert
		revertTx, err := db.BeginTx(ctx, nil)
		if err == nil {
			_, _ = revertTx.ExecContext(ctx, "UPDATE postgres_air.frequent_flyer SET award_points = award_points + $1 WHERE frequent_flyer_id = $2", points, fromID)
			_, _ = revertTx.ExecContext(ctx, "UPDATE postgres_air.frequent_flyer SET award_points = award_points - $1 WHERE frequent_flyer_id = $2", points, toID)
			_ = revertTx.Commit()
		}
		return true, nil
	}
	return false, fmt.Errorf("exceeded max retries")
}

func isSerializationErr(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "40001") || strings.Contains(msg, "could not serialize access")
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
func HQ16(ctx context.Context, db *sql.DB) ([]HybridAirport, error) {
	rawSQL := `
WITH text_ranking AS (
    SELECT airport_code, 
           ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', 'London Heathrow international hub')) DESC) AS rank_text
    FROM postgres_air.airport
    WHERE search_tsv @@ plainto_tsquery('english', 'London Heathrow international hub')
    LIMIT 25
),
vector_ranking AS (
    SELECT airport_code, 
           ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = 'LHR')) ASC) AS rank_vec
    FROM postgres_air.airport
    LIMIT 25
),
airport_stats AS (
    SELECT departure_airport AS airport_code,
           count(*) AS active_flights_count
    FROM postgres_air.flight
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
JOIN postgres_air.airport a ON a.airport_code = COALESCE(t.airport_code, v.airport_code)
LEFT JOIN airport_stats ast ON ast.airport_code = COALESCE(t.airport_code, v.airport_code)
ORDER BY rrf_score DESC
LIMIT 25;`

	rows, err := db.QueryContext(ctx, rawSQL)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []HybridAirport
	if err := entsql.ScanSlice(rows, &results); err != nil {
		return nil, err
	}
	return results, nil
}
