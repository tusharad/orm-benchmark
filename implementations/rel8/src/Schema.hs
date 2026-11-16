{-# language DeriveAnyClass #-}
{-# language DeriveGeneric #-}
{-# language DerivingStrategies #-}
{-# language DuplicateRecordFields #-}
{-# language OverloadedStrings #-}
{-# language StandaloneDeriving #-}
{-# language TypeFamilies #-}

module Schema where

import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import Rel8

-- 1. Flight
data Flight f = Flight
  { flightId :: Column f Int32
  , flightNo :: Column f Text
  , scheduledDeparture :: Column f UTCTime
  , scheduledArrival :: Column f UTCTime
  , departureAirport :: Column f Text
  , arrivalAirport :: Column f Text
  , status :: Column f Text
  , aircraftCode :: Column f Text
  , actualDeparture :: Column f (Maybe UTCTime)
  , actualArrival :: Column f (Maybe UTCTime)
  , updateTs :: Column f (Maybe UTCTime)
  , version :: Column f Int32
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Flight f)
deriving stock instance f ~ Result => Eq (Flight f)

flightSchema :: TableSchema (Flight Name)
flightSchema = TableSchema
  { name = QualifiedName "flight" (Just "postgres_air")
  , columns = Flight
      { flightId = "flight_id"
      , flightNo = "flight_no"
      , scheduledDeparture = "scheduled_departure"
      , scheduledArrival = "scheduled_arrival"
      , departureAirport = "departure_airport"
      , arrivalAirport = "arrival_airport"
      , status = "status"
      , aircraftCode = "aircraft_code"
      , actualDeparture = "actual_departure"
      , actualArrival = "actual_arrival"
      , updateTs = "update_ts"
      , version = "version"
      }
  }

-- 2. Aircraft
data Aircraft f = Aircraft
  { code :: Column f Text
  , model :: Column f (Maybe Text)
  , range :: Column f Scientific
  , class' :: Column f Int32
  , velocity :: Column f Scientific
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Aircraft f)
deriving stock instance f ~ Result => Eq (Aircraft f)

aircraftSchema :: TableSchema (Aircraft Name)
aircraftSchema = TableSchema
  { name = QualifiedName "aircraft" (Just "postgres_air")
  , columns = Aircraft
      { code = "code"
      , model = "model"
      , range = "range"
      , class' = "class"
      , velocity = "velocity"
      }
  }

-- 3. Airport
data Airport f = Airport
  { airportCode :: Column f Text
  , airportName :: Column f Text
  , city :: Column f Text
  , airportTz :: Column f Text
  , continent :: Column f (Maybe Text)
  , isoCountry :: Column f (Maybe Text)
  , isoRegion :: Column f (Maybe Text)
  , intnl :: Column f Bool
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Airport f)
deriving stock instance f ~ Result => Eq (Airport f)

airportSchema :: TableSchema (Airport Name)
airportSchema = TableSchema
  { name = QualifiedName "airport" (Just "postgres_air")
  , columns = Airport
      { airportCode = "airport_code"
      , airportName = "airport_name"
      , city = "city"
      , airportTz = "airport_tz"
      , continent = "continent"
      , isoCountry = "iso_country"
      , isoRegion = "iso_region"
      , intnl = "intnl"
      }
  }

-- 4. Account
data Account f = Account
  { accountId :: Column f Int32
  , login :: Column f Text
  , firstName :: Column f Text
  , lastName :: Column f Text
  , frequentFlyerId :: Column f (Maybe Int32)
  , updateTs :: Column f (Maybe UTCTime)
  , version :: Column f Int32
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Account f)
deriving stock instance f ~ Result => Eq (Account f)

accountSchema :: TableSchema (Account Name)
accountSchema = TableSchema
  { name = QualifiedName "account" (Just "postgres_air")
  , columns = Account
      { accountId = "account_id"
      , login = "login"
      , firstName = "first_name"
      , lastName = "last_name"
      , frequentFlyerId = "frequent_flyer_id"
      , updateTs = "update_ts"
      , version = "version"
      }
  }

-- 5. FrequentFlyer
data FrequentFlyer f = FrequentFlyer
  { frequentFlyerId :: Column f Int32
  , firstName :: Column f Text
  , lastName :: Column f Text
  , title :: Column f Text
  , cardNum :: Column f Text
  , level :: Column f Int32
  , awardPoints :: Column f Int32
  , email :: Column f Text
  , phone :: Column f Text
  , updateTs :: Column f (Maybe UTCTime)
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (FrequentFlyer f)
deriving stock instance f ~ Result => Eq (FrequentFlyer f)

frequentFlyerSchema :: TableSchema (FrequentFlyer Name)
frequentFlyerSchema = TableSchema
  { name = QualifiedName "frequent_flyer" (Just "postgres_air")
  , columns = FrequentFlyer
      { frequentFlyerId = "frequent_flyer_id"
      , firstName = "first_name"
      , lastName = "last_name"
      , title = "title"
      , cardNum = "card_num"
      , level = "level"
      , awardPoints = "award_points"
      , email = "email"
      , phone = "phone"
      , updateTs = "update_ts"
      }
  }

-- 6. Phone
data Phone f = Phone
  { phoneId :: Column f Int32
  , accountId :: Column f (Maybe Int32)
  , phone :: Column f (Maybe Text)
  , phoneType :: Column f (Maybe Text)
  , primaryPhone :: Column f (Maybe Bool)
  , updateTs :: Column f (Maybe UTCTime)
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Phone f)
deriving stock instance f ~ Result => Eq (Phone f)

phoneSchema :: TableSchema (Phone Name)
phoneSchema = TableSchema
  { name = QualifiedName "phone" (Just "postgres_air")
  , columns = Phone
      { phoneId = "phone_id"
      , accountId = "account_id"
      , phone = "phone"
      , phoneType = "phone_type"
      , primaryPhone = "primary_phone"
      , updateTs = "update_ts"
      }
  }

-- 7. Booking
data Booking f = Booking
  { bookingId :: Column f Int64
  , bookingRef :: Column f Text
  , bookingName :: Column f (Maybe Text)
  , accountId :: Column f (Maybe Int32)
  , email :: Column f Text
  , phone :: Column f Text
  , updateTs :: Column f (Maybe UTCTime)
  , price :: Column f (Maybe Scientific)
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Booking f)
deriving stock instance f ~ Result => Eq (Booking f)

bookingSchema :: TableSchema (Booking Name)
bookingSchema = TableSchema
  { name = QualifiedName "booking" (Just "postgres_air")
  , columns = Booking
      { bookingId = "booking_id"
      , bookingRef = "booking_ref"
      , bookingName = "booking_name"
      , accountId = "account_id"
      , email = "email"
      , phone = "phone"
      , updateTs = "update_ts"
      , price = "price"
      }
  }

-- 8. BookingLeg
data BookingLeg f = BookingLeg
  { bookingLegId :: Column f Int32
  , bookingId :: Column f Int32
  , flightId :: Column f Int32
  , legNum :: Column f (Maybe Int32)
  , isReturning :: Column f (Maybe Bool)
  , updateTs :: Column f (Maybe UTCTime)
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (BookingLeg f)
deriving stock instance f ~ Result => Eq (BookingLeg f)

bookingLegSchema :: TableSchema (BookingLeg Name)
bookingLegSchema = TableSchema
  { name = QualifiedName "booking_leg" (Just "postgres_air")
  , columns = BookingLeg
      { bookingLegId = "booking_leg_id"
      , bookingId = "booking_id"
      , flightId = "flight_id"
      , legNum = "leg_num"
      , isReturning = "is_returning"
      , updateTs = "update_ts"
      }
  }

-- 9. BoardingPass
data BoardingPass f = BoardingPass
  { passId :: Column f Int32
  , passengerId :: Column f (Maybe Int64)
  , bookingLegId :: Column f (Maybe Int64)
  , seat :: Column f (Maybe Text)
  , boardingTime :: Column f (Maybe UTCTime)
  , precheck :: Column f (Maybe Bool)
  , updateTs :: Column f (Maybe UTCTime)
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (BoardingPass f)
deriving stock instance f ~ Result => Eq (BoardingPass f)

boardingPassSchema :: TableSchema (BoardingPass Name)
boardingPassSchema = TableSchema
  { name = QualifiedName "boarding_pass" (Just "postgres_air")
  , columns = BoardingPass
      { passId = "pass_id"
      , passengerId = "passenger_id"
      , bookingLegId = "booking_leg_id"
      , seat = "seat"
      , boardingTime = "boarding_time"
      , precheck = "precheck"
      , updateTs = "update_ts"
      }
  }

-- 10. Passenger
data Passenger f = Passenger
  { passengerId :: Column f Int32
  , bookingId :: Column f Int32
  , bookingRef :: Column f (Maybe Text)
  , passengerNo :: Column f (Maybe Int32)
  , firstName :: Column f Text
  , lastName :: Column f Text
  , accountId :: Column f (Maybe Int32)
  , updateTs :: Column f (Maybe UTCTime)
  , age :: Column f (Maybe Int32)
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (Passenger f)
deriving stock instance f ~ Result => Eq (Passenger f)

passengerSchema :: TableSchema (Passenger Name)
passengerSchema = TableSchema
  { name = QualifiedName "passenger" (Just "postgres_air")
  , columns = Passenger
      { passengerId = "passenger_id"
      , bookingId = "booking_id"
      , bookingRef = "booking_ref"
      , passengerNo = "passenger_no"
      , firstName = "first_name"
      , lastName = "last_name"
      , accountId = "account_id"
      , updateTs = "update_ts"
      , age = "age"
      }
  }

-- 11. FlightSeatInventory
data FlightSeatInventory f = FlightSeatInventory
  { flightId :: Column f Int32
  , seatNo :: Column f Text
  , passengerName :: Column f (Maybe Text)
  , accountId :: Column f (Maybe Int32)
  , reservedAt :: Column f (Maybe UTCTime)
  , status :: Column f Text
  , version :: Column f Int32
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (FlightSeatInventory f)
deriving stock instance f ~ Result => Eq (FlightSeatInventory f)

flightSeatInventorySchema :: TableSchema (FlightSeatInventory Name)
flightSeatInventorySchema = TableSchema
  { name = QualifiedName "flight_seat_inventory" (Just "postgres_air")
  , columns = FlightSeatInventory
      { flightId = "flight_id"
      , seatNo = "seat_no"
      , passengerName = "passenger_name"
      , accountId = "account_id"
      , reservedAt = "reserved_at"
      , status = "status"
      , version = "version"
      }
  }

-- 12. FlightStatusUpdate
data FlightStatusUpdate f = FlightStatusUpdate
  { flightId :: Column f Int32
  , status :: Column f Text
  , actualDeparture :: Column f (Maybe UTCTime)
  , actualArrival :: Column f (Maybe UTCTime)
  , updateTs :: Column f UTCTime
  , version :: Column f Int32
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (FlightStatusUpdate f)
deriving stock instance f ~ Result => Eq (FlightStatusUpdate f)

flightStatusUpdateSchema :: TableSchema (FlightStatusUpdate Name)
flightStatusUpdateSchema = TableSchema
  { name = QualifiedName "flight_status_update" (Just "postgres_air")
  , columns = FlightStatusUpdate
      { flightId = "flight_id"
      , status = "status"
      , actualDeparture = "actual_departure"
      , actualArrival = "actual_arrival"
      , updateTs = "update_ts"
      , version = "version"
      }
  }
