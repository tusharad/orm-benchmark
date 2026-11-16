{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Schema where

import Squeal.PostgreSQL

-- 1. Flight Table
type FlightColumns = '[
    "flight_id" ::: 'Def :=> 'NotNull 'PGint4
  , "flight_no" ::: 'NoDef :=> 'NotNull 'PGtext
  , "scheduled_departure" ::: 'NoDef :=> 'NotNull 'PGtimestamptz
  , "scheduled_arrival" ::: 'NoDef :=> 'NotNull 'PGtimestamptz
  , "departure_airport" ::: 'NoDef :=> 'NotNull 'PGtext
  , "arrival_airport" ::: 'NoDef :=> 'NotNull 'PGtext
  , "status" ::: 'NoDef :=> 'NotNull 'PGtext
  , "aircraft_code" ::: 'NoDef :=> 'NotNull 'PGtext
  , "actual_departure" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "actual_arrival" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "version" ::: 'Def :=> 'NotNull 'PGint4
  ]
type FlightConstraints = '[ "pk_flight" ::: 'PrimaryKey '["flight_id"] ]
type FlightTable = 'Table (FlightConstraints :=> FlightColumns)

-- 2. Aircraft Table
type AircraftColumns = '[
    "code" ::: 'NoDef :=> 'NotNull 'PGtext
  , "model" ::: 'NoDef :=> 'Null 'PGtext
  , "range" ::: 'NoDef :=> 'NotNull 'PGnumeric
  , "class" ::: 'NoDef :=> 'NotNull 'PGint4
  , "velocity" ::: 'NoDef :=> 'NotNull 'PGnumeric
  ]
type AircraftConstraints = '[ "pk_aircraft" ::: 'PrimaryKey '["code"] ]
type AircraftTable = 'Table (AircraftConstraints :=> AircraftColumns)

-- 3. Airport Table
type AirportColumns = '[
    "airport_code" ::: 'NoDef :=> 'NotNull 'PGtext
  , "airport_name" ::: 'NoDef :=> 'NotNull 'PGtext
  , "city" ::: 'NoDef :=> 'NotNull 'PGtext
  , "airport_tz" ::: 'NoDef :=> 'NotNull 'PGtext
  , "continent" ::: 'NoDef :=> 'Null 'PGtext
  , "iso_country" ::: 'NoDef :=> 'Null 'PGtext
  , "iso_region" ::: 'NoDef :=> 'Null 'PGtext
  , "intnl" ::: 'NoDef :=> 'NotNull 'PGbool
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  ]
type AirportConstraints = '[ "pk_airport" ::: 'PrimaryKey '["airport_code"] ]
type AirportTable = 'Table (AirportConstraints :=> AirportColumns)

-- 4. Account Table
type AccountColumns = '[
    "account_id" ::: 'Def :=> 'NotNull 'PGint4
  , "login" ::: 'NoDef :=> 'NotNull 'PGtext
  , "first_name" ::: 'NoDef :=> 'NotNull 'PGtext
  , "last_name" ::: 'NoDef :=> 'NotNull 'PGtext
  , "frequent_flyer_id" ::: 'NoDef :=> 'Null 'PGint4
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "version" ::: 'Def :=> 'NotNull 'PGint4
  ]
type AccountConstraints = '[ "pk_account" ::: 'PrimaryKey '["account_id"] ]
type AccountTable = 'Table (AccountConstraints :=> AccountColumns)

-- 5. Frequent Flyer Table
type FrequentFlyerColumns = '[
    "frequent_flyer_id" ::: 'Def :=> 'NotNull 'PGint4
  , "first_name" ::: 'NoDef :=> 'NotNull 'PGtext
  , "last_name" ::: 'NoDef :=> 'NotNull 'PGtext
  , "title" ::: 'NoDef :=> 'NotNull 'PGtext
  , "card_num" ::: 'NoDef :=> 'NotNull 'PGtext
  , "level" ::: 'NoDef :=> 'NotNull 'PGint4
  , "award_points" ::: 'NoDef :=> 'NotNull 'PGint4
  , "email" ::: 'NoDef :=> 'NotNull 'PGtext
  , "phone" ::: 'NoDef :=> 'NotNull 'PGtext
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  ]
type FrequentFlyerConstraints = '[ "pk_frequent_flyer" ::: 'PrimaryKey '["frequent_flyer_id"] ]
type FrequentFlyerTable = 'Table (FrequentFlyerConstraints :=> FrequentFlyerColumns)

-- 6. Phone Table
type PhoneColumns = '[
    "phone_id" ::: 'Def :=> 'NotNull 'PGint4
  , "account_id" ::: 'NoDef :=> 'Null 'PGint4
  , "phone" ::: 'NoDef :=> 'Null 'PGtext
  , "phone_type" ::: 'NoDef :=> 'Null 'PGtext
  , "primary_phone" ::: 'NoDef :=> 'Null 'PGbool
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  ]
type PhoneConstraints = '[ "pk_phone" ::: 'PrimaryKey '["phone_id"] ]
type PhoneTable = 'Table (PhoneConstraints :=> PhoneColumns)

-- 7. Booking Table
type BookingColumns = '[
    "booking_id" ::: 'Def :=> 'NotNull 'PGint8
  , "booking_ref" ::: 'NoDef :=> 'NotNull 'PGtext
  , "booking_name" ::: 'NoDef :=> 'Null 'PGtext
  , "account_id" ::: 'NoDef :=> 'Null 'PGint4
  , "email" ::: 'NoDef :=> 'NotNull 'PGtext
  , "phone" ::: 'NoDef :=> 'NotNull 'PGtext
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "price" ::: 'NoDef :=> 'Null 'PGnumeric
  ]
type BookingConstraints = '[ "pk_booking" ::: 'PrimaryKey '["booking_id"] ]
type BookingTable = 'Table (BookingConstraints :=> BookingColumns)

-- 8. Booking Leg Table
type BookingLegColumns = '[
    "booking_leg_id" ::: 'Def :=> 'NotNull 'PGint4
  , "booking_id" ::: 'NoDef :=> 'NotNull 'PGint4
  , "flight_id" ::: 'NoDef :=> 'NotNull 'PGint4
  , "leg_num" ::: 'NoDef :=> 'Null 'PGint4
  , "is_returning" ::: 'NoDef :=> 'Null 'PGbool
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  ]
type BookingLegConstraints = '[ "pk_booking_leg" ::: 'PrimaryKey '["booking_leg_id"] ]
type BookingLegTable = 'Table (BookingLegConstraints :=> BookingLegColumns)

-- 9. Boarding Pass Table
type BoardingPassColumns = '[
    "pass_id" ::: 'Def :=> 'NotNull 'PGint4
  , "passenger_id" ::: 'NoDef :=> 'Null 'PGint8
  , "booking_leg_id" ::: 'NoDef :=> 'Null 'PGint8
  , "seat" ::: 'NoDef :=> 'Null 'PGtext
  , "boarding_time" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "precheck" ::: 'NoDef :=> 'Null 'PGbool
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  ]
type BoardingPassConstraints = '[ "pk_boarding_pass" ::: 'PrimaryKey '["pass_id"] ]
type BoardingPassTable = 'Table (BoardingPassConstraints :=> BoardingPassColumns)

-- 10. Passenger Table
type PassengerColumns = '[
    "passenger_id" ::: 'Def :=> 'NotNull 'PGint4
  , "booking_id" ::: 'NoDef :=> 'NotNull 'PGint4
  , "booking_ref" ::: 'NoDef :=> 'Null 'PGtext
  , "passenger_no" ::: 'NoDef :=> 'Null 'PGint4
  , "first_name" ::: 'NoDef :=> 'NotNull 'PGtext
  , "last_name" ::: 'NoDef :=> 'NotNull 'PGtext
  , "account_id" ::: 'NoDef :=> 'Null 'PGint4
  , "update_ts" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "age" ::: 'NoDef :=> 'Null 'PGint4
  ]
type PassengerConstraints = '[ "pk_passenger" ::: 'PrimaryKey '["passenger_id"] ]
type PassengerTable = 'Table (PassengerConstraints :=> PassengerColumns)

-- 11. Flight Seat Inventory Table
type FlightSeatInventoryColumns = '[
    "flight_id" ::: 'NoDef :=> 'NotNull 'PGint4
  , "seat_no" ::: 'NoDef :=> 'NotNull 'PGtext
  , "passenger_name" ::: 'NoDef :=> 'Null 'PGtext
  , "account_id" ::: 'NoDef :=> 'Null 'PGint4
  , "reserved_at" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "status" ::: 'NoDef :=> 'NotNull 'PGtext
  , "version" ::: 'Def :=> 'NotNull 'PGint4
  ]
type FlightSeatInventoryConstraints = '[ "pk_flight_seat_inventory" ::: 'PrimaryKey '["flight_id", "seat_no"] ]
type FlightSeatInventoryTable = 'Table (FlightSeatInventoryConstraints :=> FlightSeatInventoryColumns)

-- 12. Flight Status Update Table
type FlightStatusUpdateColumns = '[
    "flight_id" ::: 'NoDef :=> 'NotNull 'PGint4
  , "status" ::: 'NoDef :=> 'NotNull 'PGtext
  , "actual_departure" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "actual_arrival" ::: 'NoDef :=> 'Null 'PGtimestamptz
  , "update_ts" ::: 'NoDef :=> 'NotNull 'PGtimestamptz
  , "version" ::: 'Def :=> 'NotNull 'PGint4
  ]
type FlightStatusUpdateConstraints = '[ "pk_flight_status_update" ::: 'PrimaryKey '["flight_id"] ]
type FlightStatusUpdateTable = 'Table (FlightStatusUpdateConstraints :=> FlightStatusUpdateColumns)

-- Postgres Air Schema
type PostgresAirSchema = '[
    "flight" ::: FlightTable
  , "aircraft" ::: AircraftTable
  , "airport" ::: AirportTable
  , "account" ::: AccountTable
  , "frequent_flyer" ::: FrequentFlyerTable
  , "phone" ::: PhoneTable
  , "booking" ::: BookingTable
  , "booking_leg" ::: BookingLegTable
  , "boarding_pass" ::: BoardingPassTable
  , "passenger" ::: PassengerTable
  , "flight_seat_inventory" ::: FlightSeatInventoryTable
  , "flight_status_update" ::: FlightStatusUpdateTable
  ]

-- Database Schema (qualified with postgres_air, with fallback to public)
type DB = '[
    "postgres_air" ::: PostgresAirSchema
  , "public" ::: '[]
  ]
