{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Models where

import Control.DeepSeq (NFData)
import Data.Int (Int32, Int64)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import qualified Hasql.Decoders as D
import IHP.ModelSupport
import IHP.Hasql.FromRow (FromRowHasql(..))

-- Flight
data Flight = Flight
  { flightId           :: !Int32
  , flightNo           :: !Text
  , scheduledDeparture :: !UTCTime
  , scheduledArrival   :: !UTCTime
  , departureAirport   :: !Text
  , arrivalAirport     :: !Text
  , status             :: !Text
  , aircraftCode       :: !Text
  , actualDeparture    :: !(Maybe UTCTime)
  , actualArrival      :: !(Maybe UTCTime)
  , updateTs           :: !(Maybe UTCTime)
  , version            :: !Int32
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName Flight = "flight"
type instance GetModelByTableName "flight" = Flight
type instance PrimaryKey "flight" = Int32

instance Table Flight where
  columnNames =
    [ "flight_id"
    , "flight_no"
    , "scheduled_departure"
    , "scheduled_arrival"
    , "departure_airport"
    , "arrival_airport"
    , "status"
    , "aircraft_code"
    , "actual_departure"
    , "actual_arrival"
    , "update_ts"
    , "version"
    ]
  primaryKeyColumnNames = ["flight_id"]

instance FromRowHasql Flight where
  hasqlRowDecoder = Flight
    <$> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.timestamptz)
    <*> D.column (D.nonNullable D.timestamptz)
    <*> D.column (D.nonNullable D.bpchar)
    <*> D.column (D.nonNullable D.bpchar)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.bpchar)
    <*> D.column (D.nullable D.timestamptz)
    <*> D.column (D.nullable D.timestamptz)
    <*> D.column (D.nullable D.timestamptz)
    <*> D.column (D.nonNullable D.int4)

-- Booking
data Booking = Booking
  { bookingId   :: !Int64
  , bookingRef  :: !Text
  , bookingName :: !(Maybe Text)
  , accountId   :: !(Maybe Int32)
  , email       :: !Text
  , phone       :: !Text
  , updateTs    :: !(Maybe UTCTime)
  , price       :: !(Maybe Double)
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName Booking = "booking"
type instance GetModelByTableName "booking" = Booking
type instance PrimaryKey "booking" = Int64

instance Table Booking where
  columnNames = ["booking_id", "booking_ref", "booking_name", "account_id", "email", "phone", "update_ts", "price"]
  primaryKeyColumnNames = ["booking_id"]

instance FromRowHasql Booking where
  hasqlRowDecoder = Booking
    <$> D.column (D.nonNullable D.int8)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable D.int4)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.timestamptz)
    <*> D.column (D.nullable (fmap realToFrac D.numeric))

-- BookingLeg
data BookingLeg = BookingLeg
  { bookingLegId :: !Int32
  , bookingId    :: !Int32
  , flightId     :: !Int32
  , legNum       :: !(Maybe Int32)
  , isReturning  :: !(Maybe Bool)
  , updateTs     :: !(Maybe UTCTime)
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName BookingLeg = "booking_leg"
type instance GetModelByTableName "booking_leg" = BookingLeg
type instance PrimaryKey "booking_leg" = Int32

instance Table BookingLeg where
  columnNames = ["booking_leg_id", "booking_id", "flight_id", "leg_num", "is_returning", "update_ts"]
  primaryKeyColumnNames = ["booking_leg_id"]

instance FromRowHasql BookingLeg where
  hasqlRowDecoder = BookingLeg
    <$> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.int4)
    <*> D.column (D.nullable D.int4)
    <*> D.column (D.nullable D.bool)
    <*> D.column (D.nullable D.timestamptz)

-- Passenger
data Passenger = Passenger
  { passengerId :: !Int32
  , bookingId   :: !Int32
  , bookingRef  :: !(Maybe Text)
  , passengerNo :: !(Maybe Int32)
  , firstName   :: !Text
  , lastName    :: !Text
  , accountId   :: !(Maybe Int32)
  , updateTs    :: !(Maybe UTCTime)
  , age         :: !(Maybe Int32)
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName Passenger = "passenger"
type instance GetModelByTableName "passenger" = Passenger
type instance PrimaryKey "passenger" = Int32

instance Table Passenger where
  columnNames = ["passenger_id", "booking_id", "booking_ref", "passenger_no", "first_name", "last_name", "account_id", "update_ts", "age"]
  primaryKeyColumnNames = ["passenger_id"]

instance FromRowHasql Passenger where
  hasqlRowDecoder = Passenger
    <$> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.int4)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable D.int4)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.int4)
    <*> D.column (D.nullable D.timestamptz)
    <*> D.column (D.nullable D.int4)

-- BoardingPass
data BoardingPass = BoardingPass
  { passId       :: !Int64
  , passengerId  :: !Int32
  , bookingLegId :: !Int32
  , seat         :: !Text
  , boardingTime :: !(Maybe UTCTime)
  , precheck     :: !(Maybe Bool)
  , updateTs     :: !(Maybe UTCTime)
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName BoardingPass = "boarding_pass"
type instance GetModelByTableName "boarding_pass" = BoardingPass
type instance PrimaryKey "boarding_pass" = Int64

instance Table BoardingPass where
  columnNames = ["pass_id", "passenger_id", "booking_leg_id", "seat", "boarding_time", "precheck", "update_ts"]
  primaryKeyColumnNames = ["pass_id"]

instance FromRowHasql BoardingPass where
  hasqlRowDecoder = BoardingPass
    <$> D.column (D.nonNullable D.int8)
    <*> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.timestamptz)
    <*> D.column (D.nullable D.bool)
    <*> D.column (D.nullable D.timestamptz)

-- Airport
data Airport = Airport
  { airportCode :: !Text
  , airportName :: !Text
  , city        :: !Text
  , airportTz   :: !Text
  , continent   :: !Text
  , isoCountry  :: !Text
  , isoRegion   :: !Text
  , intnl       :: !Bool
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName Airport = "airport"
type instance GetModelByTableName "airport" = Airport
type instance PrimaryKey "airport" = Text

instance Table Airport where
  columnNames = ["airport_code", "airport_name", "city", "airport_tz", "continent", "iso_country", "iso_region", "intnl"]
  primaryKeyColumnNames = ["airport_code"]

instance FromRowHasql Airport where
  hasqlRowDecoder = Airport
    <$> D.column (D.nonNullable D.bpchar)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.bool)

-- Account
data Account = Account
  { accountId       :: !Int32
  , login           :: !Text
  , firstName       :: !Text
  , lastName        :: !Text
  , frequentFlyerId :: !(Maybe Int32)
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName Account = "account"
type instance GetModelByTableName "account" = Account
type instance PrimaryKey "account" = Int32

instance Table Account where
  columnNames = ["account_id", "login", "first_name", "last_name", "frequent_flyer_id"]
  primaryKeyColumnNames = ["account_id"]

instance FromRowHasql Account where
  hasqlRowDecoder = Account
    <$> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.int4)

-- FrequentFlyer
data FrequentFlyer = FrequentFlyer
  { frequentFlyerId :: !Int32
  , level           :: !Int32
  , awardPoints     :: !Int32
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName FrequentFlyer = "frequent_flyer"
type instance GetModelByTableName "frequent_flyer" = FrequentFlyer
type instance PrimaryKey "frequent_flyer" = Int32

instance Table FrequentFlyer where
  columnNames = ["frequent_flyer_id", "level", "award_points"]
  primaryKeyColumnNames = ["frequent_flyer_id"]

instance FromRowHasql FrequentFlyer where
  hasqlRowDecoder = FrequentFlyer
    <$> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.int4)

-- Phone
data Phone = Phone
  { phoneId   :: !Int32
  , accountId :: !Int32
  , phone     :: !Text
  , phoneType :: !Text
  } deriving (Show, Eq, Generic, NFData)

type instance GetTableName Phone = "phone"
type instance GetModelByTableName "phone" = Phone
type instance PrimaryKey "phone" = Int32

instance Table Phone where
  columnNames = ["phone_id", "account_id", "phone", "phone_type"]
  primaryKeyColumnNames = ["phone_id"]

instance FromRowHasql Phone where
  hasqlRowDecoder = Phone
    <$> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.int4)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
