{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

module Database.Opaleye.PostgresAir.Schema where

import Control.DeepSeq (NFData)
import Data.Int (Int32, Int64)
import Data.Profunctor.Product.TH (makeAdaptorAndInstanceInferrable)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import Opaleye
  ( Field, FieldNullable, Table, tableWithSchema, tableField
  , SqlInt4, SqlInt8, SqlText, SqlFloat8, SqlNumeric, SqlBool, SqlTimestamptz
  )

-- =========================================================================
-- Flight Table
-- =========================================================================
data Flight' fId fNo sDep sArr depAir arrAir st acCode actDep actArr updTs ver = Flight
  { flightId           :: fId
  , flightNo           :: fNo
  , scheduledDeparture :: sDep
  , scheduledArrival   :: sArr
  , departureAirport   :: depAir
  , arrivalAirport     :: arrAir
  , status             :: st
  , aircraftCode       :: acCode
  , actualDeparture    :: actDep
  , actualArrival      :: actArr
  , updateTs           :: updTs
  , version            :: ver
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pFlight" ''Flight')

type Flight = Flight' Int32 Text UTCTime UTCTime Text Text Text Text (Maybe UTCTime) (Maybe UTCTime) (Maybe UTCTime) Int32

type FlightField = Flight'
  (Field SqlInt4)
  (Field SqlText)
  (Field SqlTimestamptz)
  (Field SqlTimestamptz)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (FieldNullable SqlTimestamptz)
  (FieldNullable SqlTimestamptz)
  (FieldNullable SqlTimestamptz)
  (Field SqlInt4)

flightTable :: Table FlightField FlightField
flightTable = tableWithSchema "postgres_air" "flight" (pFlight Flight
  { flightId           = tableField "flight_id"
  , flightNo           = tableField "flight_no"
  , scheduledDeparture = tableField "scheduled_departure"
  , scheduledArrival   = tableField "scheduled_arrival"
  , departureAirport   = tableField "departure_airport"
  , arrivalAirport     = tableField "arrival_airport"
  , status             = tableField "status"
  , aircraftCode       = tableField "aircraft_code"
  , actualDeparture    = tableField "actual_departure"
  , actualArrival      = tableField "actual_arrival"
  , updateTs           = tableField "update_ts"
  , version            = tableField "version"
  })

-- =========================================================================
-- Airport Table
-- =========================================================================
data Airport' code name city tz cont isoC isoR intnl = Airport
  { airportCode :: code
  , airportName :: name
  , airportCity :: city
  , airportTz   :: tz
  , continent   :: cont
  , isoCountry  :: isoC
  , isoRegion   :: isoR
  , intnl       :: intnl
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pAirport" ''Airport')

type Airport = Airport' Text Text Text Text Text Text Text Bool

type AirportField = Airport'
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlBool)

airportTable :: Table AirportField AirportField
airportTable = tableWithSchema "postgres_air" "airport" (pAirport Airport
  { airportCode = tableField "airport_code"
  , airportName = tableField "airport_name"
  , airportCity = tableField "city"
  , airportTz   = tableField "airport_tz"
  , continent   = tableField "continent"
  , isoCountry  = tableField "iso_country"
  , isoRegion   = tableField "iso_region"
  , intnl       = tableField "intnl"
  })

-- =========================================================================
-- Aircraft Table
-- =========================================================================
data Aircraft' code model rng cls vel = Aircraft
  { aircraftCode_ :: code
  , aircraftModel :: model
  , aircraftRange :: rng
  , aircraftClass :: cls
  , velocity      :: vel
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pAircraft" ''Aircraft')

type Aircraft = Aircraft' Text Text Scientific Int32 Scientific

type AircraftField = Aircraft'
  (Field SqlText)
  (Field SqlText)
  (Field SqlNumeric)
  (Field SqlInt4)
  (Field SqlNumeric)

aircraftTable :: Table AircraftField AircraftField
aircraftTable = tableWithSchema "postgres_air" "aircraft" (pAircraft Aircraft
  { aircraftCode_ = tableField "code"
  , aircraftModel = tableField "model"
  , aircraftRange = tableField "range"
  , aircraftClass = tableField "class"
  , velocity      = tableField "velocity"
  })

-- =========================================================================
-- Booking Table
-- =========================================================================
data Booking' bId bRef bName accId email phone price updTs = Booking
  { bookingId   :: bId
  , bookingRef  :: bRef
  , bookingName :: bName
  , accountId   :: accId
  , email       :: email
  , phone       :: phone
  , price       :: price
  , bookingUpd  :: updTs
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pBooking" ''Booking')

type Booking = Booking' Int64 Text (Maybe Text) (Maybe Int32) Text Text (Maybe Scientific) (Maybe UTCTime)

type BookingField = Booking'
  (Field SqlInt8)
  (Field SqlText)
  (FieldNullable SqlText)
  (FieldNullable SqlInt4)
  (Field SqlText)
  (Field SqlText)
  (FieldNullable SqlNumeric)
  (FieldNullable SqlTimestamptz)

bookingTable :: Table BookingField BookingField
bookingTable = tableWithSchema "postgres_air" "booking" (pBooking Booking
  { bookingId   = tableField "booking_id"
  , bookingRef  = tableField "booking_ref"
  , bookingName = tableField "booking_name"
  , accountId   = tableField "account_id"
  , email       = tableField "email"
  , phone       = tableField "phone"
  , price       = tableField "price"
  , bookingUpd  = tableField "update_ts"
  })

-- =========================================================================
-- Passenger Table
-- =========================================================================
data Passenger' pId bId bRef pNo fName lName accId age updTs = Passenger
  { passengerId   :: pId
  , pBookingId    :: bId
  , pBookingRef   :: bRef
  , passengerNo   :: pNo
  , firstName     :: fName
  , lastName      :: lName
  , pAccountId    :: accId
  , passengerAge  :: age
  , passengerUpd  :: updTs
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pPassenger" ''Passenger')

type Passenger = Passenger' Int64 Int64 (Maybe Text) (Maybe Int32) Text Text (Maybe Int32) (Maybe Int32) (Maybe UTCTime)

type PassengerField = Passenger'
  (Field SqlInt8)
  (Field SqlInt8)
  (FieldNullable SqlText)
  (FieldNullable SqlInt4)
  (Field SqlText)
  (Field SqlText)
  (FieldNullable SqlInt4)
  (FieldNullable SqlInt4)
  (FieldNullable SqlTimestamptz)

passengerTable :: Table PassengerField PassengerField
passengerTable = tableWithSchema "postgres_air" "passenger" (pPassenger Passenger
  { passengerId   = tableField "passenger_id"
  , pBookingId    = tableField "booking_id"
  , pBookingRef   = tableField "booking_ref"
  , passengerNo   = tableField "passenger_no"
  , firstName     = tableField "first_name"
  , lastName      = tableField "last_name"
  , pAccountId    = tableField "account_id"
  , passengerAge  = tableField "age"
  , passengerUpd  = tableField "update_ts"
  })

-- =========================================================================
-- BookingLeg Table
-- =========================================================================
data BookingLeg' blId bId fId legNum isRet updTs = BookingLeg
  { bookingLegId :: blId
  , blBookingId  :: bId
  , blFlightId   :: fId
  , legNum       :: legNum
  , isReturning  :: isRet
  , bookingLegUp :: updTs
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pBookingLeg" ''BookingLeg')

type BookingLeg = BookingLeg' Int64 Int64 Int32 (Maybe Int32) (Maybe Bool) (Maybe UTCTime)

type BookingLegField = BookingLeg'
  (Field SqlInt8)
  (Field SqlInt8)
  (Field SqlInt4)
  (FieldNullable SqlInt4)
  (FieldNullable SqlBool)
  (FieldNullable SqlTimestamptz)

bookingLegTable :: Table BookingLegField BookingLegField
bookingLegTable = tableWithSchema "postgres_air" "booking_leg" (pBookingLeg BookingLeg
  { bookingLegId = tableField "booking_leg_id"
  , blBookingId  = tableField "booking_id"
  , blFlightId   = tableField "flight_id"
  , legNum       = tableField "leg_num"
  , isReturning  = tableField "is_returning"
  , bookingLegUp = tableField "update_ts"
  })

-- =========================================================================
-- BoardingPass Table
-- =========================================================================
data BoardingPass' passId pId blId seat bTime updTs = BoardingPass
  { passId       :: passId
  , bpPassengerId:: pId
  , bpBookingLeg :: blId
  , seat         :: seat
  , boardingTime :: bTime
  , passUpd      :: updTs
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pBoardingPass" ''BoardingPass')

type BoardingPass = BoardingPass' Int64 (Maybe Int64) (Maybe Int64) (Maybe Text) (Maybe UTCTime) (Maybe UTCTime)

type BoardingPassField = BoardingPass'
  (Field SqlInt8)
  (FieldNullable SqlInt8)
  (FieldNullable SqlInt8)
  (FieldNullable SqlText)
  (FieldNullable SqlTimestamptz)
  (FieldNullable SqlTimestamptz)

boardingPassTable :: Table BoardingPassField BoardingPassField
boardingPassTable = tableWithSchema "postgres_air" "boarding_pass" (pBoardingPass BoardingPass
  { passId        = tableField "pass_id"
  , bpPassengerId = tableField "passenger_id"
  , bpBookingLeg  = tableField "booking_leg_id"
  , seat          = tableField "seat"
  , boardingTime  = tableField "boarding_time"
  , passUpd       = tableField "update_ts"
  })

-- =========================================================================
-- Account Table
-- =========================================================================
data Account' accId login fName lName ffId updTs ver = Account
  { accAccountId :: accId
  , login        :: login
  , accFirstName :: fName
  , accLastName  :: lName
  , frequentFlyerId :: ffId
  , accUpd       :: updTs
  , accVersion   :: ver
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pAccount" ''Account')

type Account = Account' Int32 Text Text Text (Maybe Int32) (Maybe UTCTime) Int32

type AccountField = Account'
  (Field SqlInt4)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (FieldNullable SqlInt4)
  (FieldNullable SqlTimestamptz)
  (Field SqlInt4)

accountTable :: Table AccountField AccountField
accountTable = tableWithSchema "postgres_air" "account" (pAccount Account
  { accAccountId    = tableField "account_id"
  , login           = tableField "login"
  , accFirstName    = tableField "first_name"
  , accLastName     = tableField "last_name"
  , frequentFlyerId = tableField "frequent_flyer_id"
  , accUpd          = tableField "update_ts"
  , accVersion      = tableField "version"
  })

-- =========================================================================
-- FrequentFlyer Table
-- =========================================================================
data FrequentFlyer' ffId fName lName title card level pts email phone updTs = FrequentFlyer
  { ffFrequentFlyerId :: ffId
  , ffFirstName       :: fName
  , ffLastName        :: lName
  , ffTitle           :: title
  , cardNumber        :: card
  , ffLevel           :: level
  , awardPoints       :: pts
  , ffEmail           :: email
  , ffPhone           :: phone
  , ffUpd             :: updTs
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pFrequentFlyer" ''FrequentFlyer')

type FrequentFlyer = FrequentFlyer' Int32 Text Text Text Text Int32 Int32 Text Text (Maybe UTCTime)

type FrequentFlyerField = FrequentFlyer'
  (Field SqlInt4)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlText)
  (Field SqlInt4)
  (Field SqlInt4)
  (Field SqlText)
  (Field SqlText)
  (FieldNullable SqlTimestamptz)

frequentFlyerTable :: Table FrequentFlyerField FrequentFlyerField
frequentFlyerTable = tableWithSchema "postgres_air" "frequent_flyer" (pFrequentFlyer FrequentFlyer
  { ffFrequentFlyerId = tableField "frequent_flyer_id"
  , ffFirstName       = tableField "first_name"
  , ffLastName        = tableField "last_name"
  , ffTitle           = tableField "title"
  , cardNumber        = tableField "card_num"
  , ffLevel           = tableField "level"
  , awardPoints       = tableField "award_points"
  , ffEmail           = tableField "email"
  , ffPhone           = tableField "phone"
  , ffUpd             = tableField "update_ts"
  })

-- =========================================================================
-- Phone Table
-- =========================================================================
data Phone' phId accId phone phType prim updTs = Phone
  { phoneId      :: phId
  , phAccountId  :: accId
  , phoneNumber  :: phone
  , phoneType    :: phType
  , primaryPhone :: prim
  , phoneUpd     :: updTs
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pPhone" ''Phone')

type Phone = Phone' Int32 (Maybe Int32) (Maybe Text) (Maybe Text) (Maybe Bool) (Maybe UTCTime)

type PhoneField = Phone'
  (Field SqlInt4)
  (FieldNullable SqlInt4)
  (FieldNullable SqlText)
  (FieldNullable SqlText)
  (FieldNullable SqlBool)
  (FieldNullable SqlTimestamptz)

phoneTable :: Table PhoneField PhoneField
phoneTable = tableWithSchema "postgres_air" "phone" (pPhone Phone
  { phoneId      = tableField "phone_id"
  , phAccountId  = tableField "account_id"
  , phoneNumber  = tableField "phone"
  , phoneType    = tableField "phone_type"
  , primaryPhone = tableField "primary_phone"
  , phoneUpd     = tableField "update_ts"
  })

-- =========================================================================
-- FlightSeatInventory Table
-- =========================================================================
data FlightSeatInventory' fId seat pName accId resAt st ver = FlightSeatInventory
  { fsiFlightId      :: fId
  , fsiSeatNo        :: seat
  , fsiPassengerName :: pName
  , fsiAccountId     :: accId
  , fsiReservedAt    :: resAt
  , fsiStatus        :: st
  , fsiVersion       :: ver
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pFlightSeatInventory" ''FlightSeatInventory')

type FlightSeatInventory = FlightSeatInventory' Int32 Text (Maybe Text) (Maybe Int32) (Maybe UTCTime) Text Int32

type FlightSeatInventoryField = FlightSeatInventory'
  (Field SqlInt4)
  (Field SqlText)
  (FieldNullable SqlText)
  (FieldNullable SqlInt4)
  (FieldNullable SqlTimestamptz)
  (Field SqlText)
  (Field SqlInt4)

flightSeatInventoryTable :: Table FlightSeatInventoryField FlightSeatInventoryField
flightSeatInventoryTable = tableWithSchema "postgres_air" "flight_seat_inventory" (pFlightSeatInventory FlightSeatInventory
  { fsiFlightId      = tableField "flight_id"
  , fsiSeatNo        = tableField "seat_no"
  , fsiPassengerName = tableField "passenger_name"
  , fsiAccountId     = tableField "account_id"
  , fsiReservedAt    = tableField "reserved_at"
  , fsiStatus        = tableField "status"
  , fsiVersion       = tableField "version"
  })

-- =========================================================================
-- FlightStatusUpdate Table
-- =========================================================================
data FlightStatusUpdate' fId st actDep actArr updTs ver = FlightStatusUpdate
  { fsuFlightId        :: fId
  , fsuStatus          :: st
  , fsuActualDeparture :: actDep
  , fsuActualArrival   :: actArr
  , fsuUpdateTs        :: updTs
  , fsuVersion         :: ver
  } deriving (Show, Eq, Generic, NFData)

$(makeAdaptorAndInstanceInferrable "pFlightStatusUpdate" ''FlightStatusUpdate')

type FlightStatusUpdate = FlightStatusUpdate' Int32 Text (Maybe UTCTime) (Maybe UTCTime) (Maybe UTCTime) Int32

type FlightStatusUpdateField = FlightStatusUpdate'
  (Field SqlInt4)
  (Field SqlText)
  (FieldNullable SqlTimestamptz)
  (FieldNullable SqlTimestamptz)
  (FieldNullable SqlTimestamptz)
  (Field SqlInt4)

flightStatusUpdateTable :: Table FlightStatusUpdateField FlightStatusUpdateField
flightStatusUpdateTable = tableWithSchema "postgres_air" "flight_status_update" (pFlightStatusUpdate FlightStatusUpdate
  { fsuFlightId        = tableField "flight_id"
  , fsuStatus          = tableField "status"
  , fsuActualDeparture = tableField "actual_departure"
  , fsuActualArrival   = tableField "actual_arrival"
  , fsuUpdateTs        = tableField "update_ts"
  , fsuVersion         = tableField "version"
  })
