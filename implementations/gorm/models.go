package main

import (
	"time"
)

type Flight struct {
	FlightID           int32         `gorm:"column:flight_id;primaryKey" json:"flight_id"`
	FlightNo           string        `gorm:"column:flight_no" json:"flight_no"`
	ScheduledDeparture time.Time     `gorm:"column:scheduled_departure" json:"scheduled_departure"`
	ScheduledArrival   time.Time     `gorm:"column:scheduled_arrival" json:"scheduled_arrival"`
	DepartureAirport   string        `gorm:"column:departure_airport" json:"departure_airport"`
	ArrivalAirport     string        `gorm:"column:arrival_airport" json:"arrival_airport"`
	Status             string        `gorm:"column:status" json:"status"`
	AircraftCode       string        `gorm:"column:aircraft_code" json:"aircraft_code"`
	ActualDeparture    *time.Time    `gorm:"column:actual_departure" json:"actual_departure"`
	ActualArrival      *time.Time    `gorm:"column:actual_arrival" json:"actual_arrival"`
	UpdateTs           *time.Time    `gorm:"column:update_ts" json:"update_ts"`
	Version            int32         `gorm:"column:version" json:"version"`
	Aircraft           *Aircraft     `gorm:"foreignKey:AircraftCode;references:Code" json:"aircraft,omitempty"`
	BookingLegs        []BookingLeg  `gorm:"foreignKey:FlightID;references:FlightID" json:"booking_legs,omitempty"`
}

func (Flight) TableName() string { return "postgres_air.flight" }

type Airport struct {
	AirportCode string `gorm:"column:airport_code;primaryKey" json:"airport_code"`
	AirportName string `gorm:"column:airport_name" json:"airport_name"`
	City        string `gorm:"column:city" json:"city"`
	AirportTz   string `gorm:"column:airport_tz" json:"airport_tz"`
	Continent   string `gorm:"column:continent" json:"continent"`
	IsoCountry  string `gorm:"column:iso_country" json:"iso_country"`
	IsoRegion   string `gorm:"column:iso_region" json:"iso_region"`
	Intnl       bool   `gorm:"column:intnl" json:"intnl"`
}

func (Airport) TableName() string { return "postgres_air.airport" }

type Aircraft struct {
	Code     string  `gorm:"column:code;primaryKey" json:"code"`
	Model    string  `gorm:"column:model" json:"model"`
	Range    float64 `gorm:"column:range" json:"range"`
	Class    int32   `gorm:"column:class" json:"class"`
	Velocity float64 `gorm:"column:velocity" json:"velocity"`
}

func (Aircraft) TableName() string { return "postgres_air.aircraft" }

type Booking struct {
	BookingID   int64      `gorm:"column:booking_id;primaryKey" json:"booking_id"`
	BookingRef  string     `gorm:"column:booking_ref" json:"booking_ref"`
	BookingName *string    `gorm:"column:booking_name" json:"booking_name"`
	AccountID   *int32     `gorm:"column:account_id" json:"account_id"`
	Email       string     `gorm:"column:email" json:"email"`
	Phone       string     `gorm:"column:phone" json:"phone"`
	Price       *float64   `gorm:"column:price" json:"price"`
	UpdateTs    *time.Time `gorm:"column:update_ts" json:"update_ts"`
}

func (Booking) TableName() string { return "postgres_air.booking" }

type Passenger struct {
	PassengerID int64      `gorm:"column:passenger_id;primaryKey" json:"passenger_id"`
	BookingID   int64      `gorm:"column:booking_id" json:"booking_id"`
	BookingRef  *string    `gorm:"column:booking_ref" json:"booking_ref"`
	PassengerNo *int32     `gorm:"column:passenger_no" json:"passenger_no"`
	FirstName   string     `gorm:"column:first_name" json:"first_name"`
	LastName    string     `gorm:"column:last_name" json:"last_name"`
	AccountID   *int32     `gorm:"column:account_id" json:"account_id"`
	Age         *int32     `gorm:"column:age" json:"age"`
	UpdateTs    *time.Time `gorm:"column:update_ts" json:"update_ts"`
}

func (Passenger) TableName() string { return "postgres_air.passenger" }

type BookingLeg struct {
	BookingLegID int64         `gorm:"column:booking_leg_id;primaryKey" json:"booking_leg_id"`
	BookingID    int64         `gorm:"column:booking_id" json:"booking_id"`
	FlightID     int32         `gorm:"column:flight_id" json:"flight_id"`
	LegNum       *int32        `gorm:"column:leg_num" json:"leg_num"`
	IsReturning  *bool         `gorm:"column:is_returning" json:"is_returning"`
	UpdateTs     *time.Time    `gorm:"column:update_ts" json:"update_ts"`
	Booking      *Booking      `gorm:"foreignKey:BookingID;references:BookingID" json:"booking,omitempty"`
	BoardingPass *BoardingPass `gorm:"foreignKey:BookingLegID;references:BookingLegID" json:"boarding_pass,omitempty"`
}

func (BookingLeg) TableName() string { return "postgres_air.booking_leg" }

type BoardingPass struct {
	PassID       int64      `gorm:"column:pass_id;primaryKey" json:"pass_id"`
	PassengerID  *int64     `gorm:"column:passenger_id" json:"passenger_id"`
	BookingLegID *int64     `gorm:"column:booking_leg_id" json:"booking_leg_id"`
	Seat         *string    `gorm:"column:seat" json:"seat"`
	BoardingTime *time.Time `gorm:"column:boarding_time" json:"boarding_time"`
	UpdateTs     *time.Time `gorm:"column:update_ts" json:"update_ts"`
}

func (BoardingPass) TableName() string { return "postgres_air.boarding_pass" }

type Account struct {
	AccountID       int32          `gorm:"column:account_id;primaryKey" json:"account_id"`
	Login           string         `gorm:"column:login" json:"login"`
	FirstName       string         `gorm:"column:first_name" json:"first_name"`
	LastName        string         `gorm:"column:last_name" json:"last_name"`
	FrequentFlyerID *int32         `gorm:"column:frequent_flyer_id" json:"frequent_flyer_id"`
	UpdateTs        *time.Time     `gorm:"column:update_ts" json:"update_ts"`
	Version         int32          `gorm:"column:version" json:"version"`
	FrequentFlyer   *FrequentFlyer `gorm:"foreignKey:FrequentFlyerID;references:FrequentFlyerID" json:"frequent_flyer,omitempty"`
	Phones          []Phone        `gorm:"foreignKey:AccountID;references:AccountID" json:"phones,omitempty"`
	Bookings        []Booking      `gorm:"foreignKey:AccountID;references:AccountID" json:"bookings,omitempty"`
}

func (Account) TableName() string { return "postgres_air.account" }

type FrequentFlyer struct {
	FrequentFlyerID int32      `gorm:"column:frequent_flyer_id;primaryKey" json:"frequent_flyer_id"`
	FirstName       string     `gorm:"column:first_name" json:"first_name"`
	LastName        string     `gorm:"column:last_name" json:"last_name"`
	Title           string     `gorm:"column:title" json:"title"`
	CardNum         string     `gorm:"column:card_num" json:"card_num"`
	Level           int32      `gorm:"column:level" json:"level"`
	AwardPoints     int32      `gorm:"column:award_points" json:"award_points"`
	Email           string     `gorm:"column:email" json:"email"`
	Phone           string     `gorm:"column:phone" json:"phone"`
	UpdateTs        *time.Time `gorm:"column:update_ts" json:"update_ts"`
}

func (FrequentFlyer) TableName() string { return "postgres_air.frequent_flyer" }

type Phone struct {
	PhoneID      int32      `gorm:"column:phone_id;primaryKey" json:"phone_id"`
	AccountID    *int32     `gorm:"column:account_id" json:"account_id"`
	Phone        *string    `gorm:"column:phone" json:"phone"`
	PhoneType    *string    `gorm:"column:phone_type" json:"phone_type"`
	PrimaryPhone *bool      `gorm:"column:primary_phone" json:"primary_phone"`
	UpdateTs     *time.Time `gorm:"column:update_ts" json:"update_ts"`
}

func (Phone) TableName() string { return "postgres_air.phone" }

type FlightSeatInventory struct {
	FlightID      int32      `gorm:"column:flight_id;primaryKey" json:"flight_id"`
	SeatNo        string     `gorm:"column:seat_no;primaryKey" json:"seat_no"`
	PassengerName *string    `gorm:"column:passenger_name" json:"passenger_name"`
	AccountID     *int32     `gorm:"column:account_id" json:"account_id"`
	ReservedAt    *time.Time `gorm:"column:reserved_at" json:"reserved_at"`
	Status        string     `gorm:"column:status" json:"status"`
	Version       int32      `gorm:"column:version" json:"version"`
}

func (FlightSeatInventory) TableName() string { return "postgres_air.flight_seat_inventory" }

type FlightStatusUpdate struct {
	FlightID        int32      `gorm:"column:flight_id;primaryKey" json:"flight_id"`
	Status          string     `gorm:"column:status" json:"status"`
	ActualDeparture *time.Time `gorm:"column:actual_departure" json:"actual_departure"`
	ActualArrival   *time.Time `gorm:"column:actual_arrival" json:"actual_arrival"`
	UpdateTs        *time.Time `gorm:"column:update_ts" json:"update_ts"`
	Version         int32      `gorm:"column:version" json:"version"`
}

func (FlightStatusUpdate) TableName() string { return "postgres_air.flight_status_update" }
