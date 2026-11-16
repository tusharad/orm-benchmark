package main

import (
	"time"
)

type Flight struct {
	FlightID           int32      `sql:"flight_id"`
	FlightNo           string     `sql:"flight_no"`
	ScheduledDeparture time.Time  `sql:"scheduled_departure"`
	ScheduledArrival   time.Time  `sql:"scheduled_arrival"`
	DepartureAirport   string     `sql:"departure_airport"`
	ArrivalAirport     string     `sql:"arrival_airport"`
	Status             string     `sql:"status"`
	AircraftCode       string     `sql:"aircraft_code"`
	ActualDeparture    *time.Time `sql:"actual_departure"`
	ActualArrival      *time.Time `sql:"actual_arrival"`
	UpdateTs           *time.Time `sql:"update_ts"`
	Version            int32      `sql:"version"`
}

type Airport struct {
	AirportCode string `sql:"airport_code"`
	AirportName string `sql:"airport_name"`
	City        string `sql:"city"`
	AirportTz   string `sql:"airport_tz"`
	Continent   string `sql:"continent"`
	IsoCountry  string `sql:"iso_country"`
	IsoRegion   string `sql:"iso_region"`
	Intnl       bool   `sql:"intnl"`
}

type Aircraft struct {
	Code     string  `sql:"code"`
	Model    string  `sql:"model"`
	Range    float64 `sql:"range"`
	Class    int32   `sql:"class"`
	Velocity float64 `sql:"velocity"`
}

type Booking struct {
	BookingID   int64      `sql:"booking_id"`
	BookingRef  string     `sql:"booking_ref"`
	BookingName *string    `sql:"booking_name"`
	AccountID   *int32     `sql:"account_id"`
	Email       string     `sql:"email"`
	Phone       string     `sql:"phone"`
	Price       *float64   `sql:"price"`
	UpdateTs    *time.Time `sql:"update_ts"`
}

type Passenger struct {
	PassengerID int64      `sql:"passenger_id"`
	BookingID   int64      `sql:"booking_id"`
	BookingRef  *string    `sql:"booking_ref"`
	PassengerNo *int32     `sql:"passenger_no"`
	FirstName   string     `sql:"first_name"`
	LastName    string     `sql:"last_name"`
	AccountID   *int32     `sql:"account_id"`
	Age         *int32     `sql:"age"`
	UpdateTs    *time.Time `sql:"update_ts"`
}

type BookingLeg struct {
	BookingLegID int64      `sql:"booking_leg_id"`
	BookingID    int64      `sql:"booking_id"`
	FlightID     int32      `sql:"flight_id"`
	LegNum       *int32     `sql:"leg_num"`
	IsReturning  *bool      `sql:"is_returning"`
	UpdateTs     *time.Time `sql:"update_ts"`
}

type BoardingPass struct {
	PassID       int64      `sql:"pass_id"`
	PassengerID  *int64     `sql:"passenger_id"`
	BookingLegID *int64     `sql:"booking_leg_id"`
	Seat         *string    `sql:"seat"`
	BoardingTime *time.Time `sql:"boarding_time"`
	UpdateTs     *time.Time `sql:"update_ts"`
}

type Account struct {
	AccountID       int32      `sql:"account_id"`
	Login           string     `sql:"login"`
	FirstName       string     `sql:"first_name"`
	LastName        string     `sql:"last_name"`
	FrequentFlyerID *int32     `sql:"frequent_flyer_id"`
	UpdateTs        *time.Time `sql:"update_ts"`
}

type FrequentFlyer struct {
	FrequentFlyerID int32      `sql:"frequent_flyer_id"`
	Level           int32      `sql:"level"`
	AwardPoints     int32      `sql:"award_points"`
	Email           string     `sql:"email"`
	Phone           string     `sql:"phone"`
	UpdateTs        *time.Time `sql:"update_ts"`
}

type Phone struct {
	PhoneID      int32      `sql:"phone_id"`
	AccountID    int32      `sql:"account_id"`
	PhoneNumber  *string    `sql:"phone"`
	PhoneType    *string    `sql:"phone_type"`
	PrimaryPhone *bool      `sql:"primary_phone"`
	UpdateTs     *time.Time `sql:"update_ts"`
}

type FlightSeatInventory struct {
	FlightID      int32      `sql:"flight_id"`
	SeatNo        string     `sql:"seat_no"`
	PassengerName *string    `sql:"passenger_name"`
	AccountID     *int32     `sql:"account_id"`
	ReservedAt    *time.Time `sql:"reserved_at"`
	Status        string     `sql:"status"`
	Version       int32      `sql:"version"`
}

type FlightStatusUpdate struct {
	FlightID        int32      `sql:"flight_id"`
	Status          string     `sql:"status"`
	ActualDeparture *time.Time `sql:"actual_departure"`
	ActualArrival   *time.Time `sql:"actual_arrival"`
	UpdateTs        *time.Time `sql:"update_ts"`
	Version         int32      `sql:"version"`
}

type CompositeBookingRecord struct {
	BookingID          int64     `sql:"booking_id"`
	BookingRef         string    `sql:"booking_ref"`
	Price              *float64  `sql:"price"`
	Email              string    `sql:"email"`
	PassengerID        int64     `sql:"passenger_id"`
	FirstName          string    `sql:"first_name"`
	LastName           string    `sql:"last_name"`
	Age                *int32    `sql:"age"`
	BookingLegID       int64     `sql:"booking_leg_id"`
	LegNum             *int32    `sql:"leg_num"`
	IsReturning        *bool     `sql:"is_returning"`
	FlightID           int32     `sql:"flight_id"`
	FlightNo           string    `sql:"flight_no"`
	DepartureAirport   string    `sql:"departure_airport"`
	ArrivalAirport     string    `sql:"arrival_airport"`
	ScheduledDeparture time.Time `sql:"scheduled_departure"`
	Status             string    `sql:"status"`
}

type FlightGraphNode struct {
	Flight Flight
	Legs   []BookingLegNode
}

type BookingLegNode struct {
	Leg  BookingLeg
	Pass *BoardingPass
}

type RouteProfitability struct {
	Origin          string  `sql:"origin"`
	Destination     string  `sql:"destination"`
	AircraftModel   string  `sql:"aircraft_model"`
	TotalFlights    int64   `sql:"total_flights"`
	TotalLegsBooked int64   `sql:"total_legs_booked"`
	TotalRevenue    float64 `sql:"total_revenue"`
	AvgDelayMinutes float64 `sql:"avg_delay_minutes"`
	OnTimePct       float64 `sql:"on_time_pct"`
}

type HubCentrality struct {
	AirportCode        string  `sql:"airport_code"`
	AirportName        string  `sql:"airport_name"`
	City               string  `sql:"city"`
	TotalDepartures    int64   `sql:"total_departures"`
	TotalArrivals      int64   `sql:"total_arrivals"`
	UniqueDestinations int64   `sql:"unique_destinations"`
	FleetDiversity     int64   `sql:"fleet_diversity"`
	AvgDepDelay        float64 `sql:"avg_dep_delay"`
	AvgArrDelay        float64 `sql:"avg_arr_delay"`
	HubCentralityScore float64 `sql:"hub_centrality_score"`
}

type FlightCapacity struct {
	FlightID           int32     `sql:"flight_id"`
	FlightNo           string    `sql:"flight_no"`
	DepartureAirport   string    `sql:"departure_airport"`
	ArrivalAirport     string    `sql:"arrival_airport"`
	ScheduledDeparture time.Time `sql:"scheduled_departure"`
	AircraftModel      string    `sql:"aircraft_model"`
	AircraftRange      float64   `sql:"aircraft_range"`
	SeatsBooked        int64     `sql:"seats_booked"`
	EliteFlyerCount    int64     `sql:"elite_flyer_count"`
}

type Itinerary struct {
	Hops                int32     `sql:"hops"`
	Route               string    `sql:"route"`
	JourneyStart        time.Time `sql:"journey_start"`
	JourneyEnd          time.Time `sql:"journey_end"`
	TotalElapsedMinutes float64   `sql:"total_elapsed_minutes"`
	TotalFlightMinutes  float64   `sql:"total_flight_minutes"`
}

type WindowDelay struct {
	FlightID           int32     `sql:"flight_id"`
	FlightNo           string    `sql:"flight_no"`
	ArrivalAirport     string    `sql:"arrival_airport"`
	ScheduledDeparture time.Time `sql:"scheduled_departure"`
	DelayMinutes       float64   `sql:"delay_minutes"`
	RollingAvgDelay5   float64   `sql:"rolling_avg_delay_5"`
	DelayDiffPrev      *float64  `sql:"delay_diff_prev"`
	RollingStddev10    float64   `sql:"rolling_stddev_10"`
	SeverityRank       int64     `sql:"severity_rank"`
}

type FacetedFlight struct {
	FlightID           int32     `sql:"flight_id"`
	FlightNo           string    `sql:"flight_no"`
	DepartureAirport   string    `sql:"departure_airport"`
	ArrivalAirport     string    `sql:"arrival_airport"`
	ScheduledDeparture time.Time `sql:"scheduled_departure"`
	ScheduledArrival   time.Time `sql:"scheduled_arrival"`
	Status             string    `sql:"status"`
	AircraftModel      string    `sql:"aircraft_model"`
	AircraftRange      float64   `sql:"aircraft_range"`
	AircraftClass      int32     `sql:"aircraft_class"`
}

type HybridAirport struct {
	AirportCode        string  `sql:"airport_code"`
	AirportName        string  `sql:"airport_name"`
	City               string  `sql:"city"`
	ActiveFlightsCount int64   `sql:"active_flights_count"`
	RrfScore           float64 `sql:"rrf_score"`
}
