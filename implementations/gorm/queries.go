package main

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type CompositeBookingRecord struct {
	BookingID          int64      `gorm:"column:booking_id"`
	BookingRef         string     `gorm:"column:booking_ref"`
	Price              *float64   `gorm:"column:price"`
	Email              string     `gorm:"column:email"`
	PassengerID        int64      `gorm:"column:passenger_id"`
	FirstName          string     `gorm:"column:first_name"`
	LastName           string     `gorm:"column:last_name"`
	Age                *int32     `gorm:"column:age"`
	BookingLegID       int64      `gorm:"column:booking_leg_id"`
	LegNum             *int32     `gorm:"column:leg_num"`
	IsReturning        *bool      `gorm:"column:is_returning"`
	FlightID           int32      `gorm:"column:flight_id"`
	FlightNo           string     `gorm:"column:flight_no"`
	DepartureAirport   string     `gorm:"column:departure_airport"`
	ArrivalAirport     string     `gorm:"column:arrival_airport"`
	ScheduledDeparture time.Time  `gorm:"column:scheduled_departure"`
	Status             string     `gorm:"column:status"`
}

type RouteProfitability struct {
	Origin          string  `gorm:"column:origin"`
	Destination     string  `gorm:"column:destination"`
	AircraftModel   string  `gorm:"column:aircraft_model"`
	TotalFlights    int64   `gorm:"column:total_flights"`
	TotalLegsBooked int64   `gorm:"column:total_legs_booked"`
	TotalRevenue    float64 `gorm:"column:total_revenue"`
	AvgDelayMinutes float64 `gorm:"column:avg_delay_minutes"`
	OnTimePct       float64 `gorm:"column:on_time_pct"`
}

type HubCentrality struct {
	AirportCode        string  `gorm:"column:airport_code"`
	AirportName        string  `gorm:"column:airport_name"`
	City               string  `gorm:"column:city"`
	TotalDepartures    int64   `gorm:"column:total_departures"`
	TotalArrivals      int64   `gorm:"column:total_arrivals"`
	UniqueDestinations int64   `gorm:"column:unique_destinations"`
	FleetDiversity     int64   `gorm:"column:fleet_diversity"`
	AvgDepDelay        float64 `gorm:"column:avg_dep_delay"`
	AvgArrDelay        float64 `gorm:"column:avg_arr_delay"`
	HubCentralityScore float64 `gorm:"column:hub_centrality_score"`
}

type FlightCapacity struct {
	FlightID           int32     `gorm:"column:flight_id"`
	FlightNo           string    `gorm:"column:flight_no"`
	DepartureAirport   string    `gorm:"column:departure_airport"`
	ArrivalAirport     string    `gorm:"column:arrival_airport"`
	ScheduledDeparture time.Time `gorm:"column:scheduled_departure"`
	AircraftModel      string    `gorm:"column:aircraft_model"`
	AircraftRange      float64   `gorm:"column:aircraft_range"`
	SeatsBooked        int64     `gorm:"column:seats_booked"`
	EliteFlyerCount    int64     `gorm:"column:elite_flyer_count"`
}

type Itinerary struct {
	Hops                int32     `gorm:"column:hops"`
	Route               string    `gorm:"column:route"`
	JourneyStart        time.Time `gorm:"column:journey_start"`
	JourneyEnd          time.Time `gorm:"column:journey_end"`
	TotalElapsedMinutes float64   `gorm:"column:total_elapsed_minutes"`
	TotalFlightMinutes  float64   `gorm:"column:total_flight_minutes"`
}

type WindowDelay struct {
	FlightID           int32     `gorm:"column:flight_id"`
	FlightNo           string    `gorm:"column:flight_no"`
	ArrivalAirport     string    `gorm:"column:arrival_airport"`
	ScheduledDeparture time.Time `gorm:"column:scheduled_departure"`
	DelayMinutes       float64   `gorm:"column:delay_minutes"`
	RollingAvgDelay5   float64   `gorm:"column:rolling_avg_delay_5"`
	DelayDiffPrev      *float64  `gorm:"column:delay_diff_prev"`
	RollingStddev10    float64   `gorm:"column:rolling_stddev_10"`
	SeverityRank       int64     `gorm:"column:severity_rank"`
}

type FacetedFlight struct {
	FlightID           int32     `gorm:"column:flight_id"`
	FlightNo           string    `gorm:"column:flight_no"`
	DepartureAirport   string    `gorm:"column:departure_airport"`
	ArrivalAirport     string    `gorm:"column:arrival_airport"`
	ScheduledDeparture time.Time `gorm:"column:scheduled_departure"`
	ScheduledArrival   time.Time `gorm:"column:scheduled_arrival"`
	Status             string    `gorm:"column:status"`
	AircraftModel      string    `gorm:"column:aircraft_model"`
	AircraftRange      float64   `gorm:"column:aircraft_range"`
	AircraftClass      int32     `gorm:"column:aircraft_class"`
}

type HybridAirport struct {
	AirportCode        string  `gorm:"column:airport_code"`
	AirportName        string  `gorm:"column:airport_name"`
	City               string  `gorm:"column:city"`
	ActiveFlightsCount int64   `gorm:"column:active_flights_count"`
	RrfScore           float64 `gorm:"column:rrf_score"`
}

// HQ01: Massive Entity Deserialization (10,000 Wide Rows)
func HQ01(db *gorm.DB) ([]Flight, error) {
	var flights []Flight
	err := db.Order("flight_id ASC").Limit(10000).Find(&flights).Error
	return flights, err
}

// HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
func HQ02(db *gorm.DB) ([]CompositeBookingRecord, error) {
	var records []CompositeBookingRecord
	err := db.Table("postgres_air.booking b").
		Select("b.booking_id, b.booking_ref, b.price, b.email, p.passenger_id, p.first_name, p.last_name, p.age, bl.booking_leg_id, bl.leg_num, bl.is_returning, f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, f.scheduled_departure, f.status").
		Joins("JOIN postgres_air.passenger p ON b.booking_id = p.booking_id").
		Joins("JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id").
		Joins("JOIN postgres_air.flight f ON bl.flight_id = f.flight_id").
		Where("b.booking_id BETWEEN ? AND ?", 100000, 105000).
		Order("b.booking_id ASC, p.passenger_id ASC, bl.booking_leg_id ASC").
		Limit(5000).
		Scan(&records).Error
	return records, err
}

// HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
func HQ03(db *gorm.DB) ([]Flight, error) {
	var flights []Flight
	err := db.Where("flight_id BETWEEN ? AND ?", 2000, 2025).
		Order("flight_id ASC").
		Preload("BookingLegs.Booking").
		Preload("BookingLegs.BoardingPass").
		Find(&flights).Error
	return flights, err
}

// HQ04: Account Relationship Graph with Optional Sub-Entities
func HQ04(db *gorm.DB) ([]Account, error) {
	var accounts []Account
	err := db.Where("account_id BETWEEN ? AND ?", 50000, 50200).
		Order("account_id ASC").
		Preload("FrequentFlyer").
		Preload("Phones").
		Preload("Bookings").
		Find(&accounts).Error
	return accounts, err
}

// HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
func HQ05(db *gorm.DB) ([]RouteProfitability, error) {
	var results []RouteProfitability
	err := db.Table("postgres_air.flight f").
		Select("orig.airport_code AS origin, dest.airport_code AS destination, ac.model AS aircraft_model, count(DISTINCT f.flight_id) AS total_flights, count(bl.booking_leg_id) AS total_legs_booked, round(sum(b.price)::numeric, 2) AS total_revenue, round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60)::numeric, 2) AS avg_delay_minutes, round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2) AS on_time_pct").
		Joins("JOIN postgres_air.airport orig ON f.departure_airport = orig.airport_code").
		Joins("JOIN postgres_air.airport dest ON f.arrival_airport = dest.airport_code").
		Joins("JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code").
		Joins("JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id").
		Joins("JOIN postgres_air.booking b ON bl.booking_id = b.booking_id").
		Where("f.scheduled_departure >= '2024-07-01 00:00:00+00' AND f.scheduled_departure < '2024-07-04 00:00:00+00'").
		Group("orig.airport_code, dest.airport_code, ac.model").
		Having("count(DISTINCT f.flight_id) >= 3").
		Order("total_revenue DESC").
		Limit(50).
		Scan(&results).Error
	return results, err
}

// HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
func HQ06(db *gorm.DB) ([]HubCentrality, error) {
	var results []HubCentrality
	sql := `
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
	err := db.Raw(sql).Scan(&results).Error
	return results, err
}

// HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
func HQ07(db *gorm.DB) ([]FlightCapacity, error) {
	var results []FlightCapacity
	sql := `
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
	err := db.Raw(sql).Scan(&results).Error
	return results, err
}

// HQ08: Recursive Multi-Hop Flight Connection Graph Search (1- to 3-Hop Paths)
func HQ08(db *gorm.DB) ([]Itinerary, error) {
	var results []Itinerary
	sql := `
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
	err := db.Raw(sql).Scan(&results).Error
	return results, err
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
func HQ09(db *gorm.DB) ([]WindowDelay, error) {
	var results []WindowDelay
	sql := `
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
	err := db.Raw(sql).Scan(&results).Error
	return results, err
}

// HQ10: High-Throughput Keyset (Cursor) Pagination over Composite Tuple
func HQ10(db *gorm.DB, cursorTime *time.Time, cursorID *int32) ([]Flight, error) {
	cTime := time.Date(2024, 7, 15, 12, 0, 0, 0, time.UTC)
	if cursorTime != nil {
		cTime = *cursorTime
	}
	var cID int32 = 10500
	if cursorID != nil {
		cID = *cursorID
	}

	var flights []Flight
	err := db.Where("scheduled_departure > ? OR (scheduled_departure = ? AND flight_id > ?)", cTime, cTime, cID).
		Order("scheduled_departure ASC, flight_id ASC").
		Limit(50).
		Find(&flights).Error
	return flights, err
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
func HQ11(db *gorm.DB,
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

	q := db.Table("postgres_air.flight f").
		Select("f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, f.scheduled_departure, f.scheduled_arrival, f.status, ac.model AS aircraft_model, ac.range AS aircraft_range, ac.class AS aircraft_class").
		Joins("JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code")

	if len(depAirports) > 0 {
		q = q.Where("f.departure_airport IN ?", depAirports)
	}
	if len(arrAirports) > 0 {
		q = q.Where("f.arrival_airport IN ?", arrAirports)
	}
	q = q.Where("f.scheduled_departure >= ?", t0)
	q = q.Where("f.scheduled_departure <= ?", t1)
	if len(classes) > 0 {
		q = q.Where("ac.class IN ?", classes)
	}
	q = q.Where("ac.range >= ?", rng)
	if len(statuses) > 0 {
		q = q.Where("f.status IN ?", statuses)
	}
	q = q.Where("EXTRACT(HOUR FROM f.scheduled_departure) BETWEEN ? AND ?", hourMin, hourMax)
	q = q.Where("f.scheduled_departure > ? OR (f.scheduled_departure = ? AND f.flight_id > ?)", cTime, cTime, cID)

	var results []FacetedFlight
	err := q.Order("f.scheduled_departure ASC, f.flight_id ASC").Limit(100).Scan(&results).Error
	return results, err
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
func HQ12(db *gorm.DB) (int64, error) {
	now := time.Now().UTC()
	updates := make([]FlightStatusUpdate, 2500)
	dep := time.Date(2024, 7, 1, 8, 5, 0, 0, time.UTC)
	arr := time.Date(2024, 7, 1, 11, 15, 0, 0, time.UTC)

	for i := 0; i < 2500; i++ {
		updates[i] = FlightStatusUpdate{
			FlightID:        int32(i + 1),
			Status:          "Departed",
			ActualDeparture: &dep,
			ActualArrival:   &arr,
			UpdateTs:        &now,
			Version:         1,
		}
	}

	result := db.Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "flight_id"}},
		DoUpdates: clause.Assignments(map[string]interface{}{
			"status":           "Departed",
			"actual_departure": dep,
			"actual_arrival":   arr,
			"update_ts":        now,
			"version":          gorm.Expr("postgres_air.flight_status_update.version + 1"),
		}),
	}).CreateInBatches(&updates, 500)

	return result.RowsAffected, result.Error
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
func HQ13(db *gorm.DB) (int64, error) {
	now := time.Now().UTC()
	res := db.Model(&Flight{}).
		Where("flight_id BETWEEN ? AND ? AND version = 1", 1000, 1050).
		Updates(map[string]interface{}{
			"status":    "Boarding",
			"version":   gorm.Expr("version + 1"),
			"update_ts": now,
		})

	affected := res.RowsAffected

	// Reset for future benchmark iterations
	db.Model(&Flight{}).
		Where("flight_id BETWEEN ? AND ?", 1000, 1050).
		Updates(map[string]interface{}{
			"status":  "Departed",
			"version": 1,
		})

	return affected, res.Error
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
func HQ14(db *gorm.DB, flightID int32) (string, error) {
	tx := db.Begin()
	if tx.Error != nil {
		return "", tx.Error
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	var seat FlightSeatInventory
	err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("flight_id = ? AND status = 'AVAILABLE'", flightID).
		First(&seat).Error

	if err != nil {
		tx.Rollback()
		return "", err
	}

	now := time.Now().UTC()
	passengerName := "Test Concurrent Flyer"
	err = tx.Model(&FlightSeatInventory{}).
		Where("flight_id = ? AND seat_no = ? AND version = ?", seat.FlightID, seat.SeatNo, seat.Version).
		Updates(map[string]interface{}{
			"status":         "RESERVED",
			"passenger_name": passengerName,
			"reserved_at":    now,
			"version":        seat.Version + 1,
		}).Error

	if err != nil {
		tx.Rollback()
		return "", err
	}

	commitErr := tx.Commit().Error
	return seat.SeatNo, commitErr
}

// HQ15: Distributed Financial / Points Transfer with 40001 Retry
func HQ15(db *gorm.DB, fromID, toID, points int32, maxRetries int) (bool, error) {
	for attempt := 1; attempt <= maxRetries; attempt++ {
		tx := db.Begin(&sql.TxOptions{Isolation: sql.LevelSerializable})
		if tx.Error != nil {
			return false, tx.Error
		}

		err1 := tx.Model(&FrequentFlyer{}).
			Where("frequent_flyer_id = ?", fromID).
			Update("award_points", gorm.Expr("award_points - ?", points)).Error

		err2 := tx.Model(&FrequentFlyer{}).
			Where("frequent_flyer_id = ?", toID).
			Update("award_points", gorm.Expr("award_points + ?", points)).Error

		if err1 != nil || err2 != nil {
			tx.Rollback()
			if isSerializationError(err1) || isSerializationError(err2) {
				time.Sleep(time.Duration(attempt*10) * time.Millisecond)
				continue
			}
			return false, fmt.Errorf("transfer error: %v, %v", err1, err2)
		}

		commitErr := tx.Commit().Error
		if commitErr != nil {
			if isSerializationError(commitErr) {
				time.Sleep(time.Duration(attempt*10) * time.Millisecond)
				continue
			}
			return false, commitErr
		}

		// Revert points back for idempotent benchmark runs
		db.Model(&FrequentFlyer{}).Where("frequent_flyer_id = ?", fromID).Update("award_points", gorm.Expr("award_points + ?", points))
		db.Model(&FrequentFlyer{}).Where("frequent_flyer_id = ?", toID).Update("award_points", gorm.Expr("award_points - ?", points))

		return true, nil
	}
	return false, fmt.Errorf("exceeded max retries")
}

func isSerializationError(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "40001") || strings.Contains(msg, "could not serialize access")
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
func HQ16(db *gorm.DB) ([]HybridAirport, error) {
	var results []HybridAirport
	sql := `
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
	err := db.Raw(sql).Scan(&results).Error
	return results, err
}
