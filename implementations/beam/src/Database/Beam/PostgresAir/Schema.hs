{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}

module Database.Beam.PostgresAir.Schema where

import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import Database.Beam
import Database.Beam.Postgres (Postgres)

-- 1. Airport Table
data AirportT f = Airport
  { _airportCode :: Columnar f Text
  , _airportName :: Columnar f Text
  , _airportCity :: Columnar f Text
  , _airportTz   :: Columnar f Text
  , _airportIntnl:: Columnar f Bool
  , _airportDesc :: Columnar f (Maybe Text)
  } deriving (Generic, Beamable)

type Airport = AirportT Identity
deriving instance Show Airport
deriving instance Eq Airport

instance Table AirportT where
  data PrimaryKey AirportT f = AirportId (Columnar f Text) deriving (Generic, Beamable)
  primaryKey = AirportId . _airportCode
type AirportId = PrimaryKey AirportT Identity
deriving instance Show AirportId
deriving instance Eq AirportId

-- 2. Flight Table
data FlightT f = Flight
  { _flightId           :: Columnar f Int32
  , _flightNo           :: Columnar f Text
  , _scheduledDeparture :: Columnar f UTCTime
  , _scheduledArrival   :: Columnar f UTCTime
  , _departureAirport   :: Columnar f Text
  , _arrivalAirport     :: Columnar f Text
  , _flightStatus       :: Columnar f Text
  , _flightAircraftCode :: Columnar f Text
  , _actualDeparture    :: Columnar f (Maybe UTCTime)
  , _actualArrival      :: Columnar f (Maybe UTCTime)
  , _flightVersion      :: Columnar f Int32
  } deriving (Generic, Beamable)

type Flight = FlightT Identity
deriving instance Show Flight
deriving instance Eq Flight

instance Table FlightT where
  data PrimaryKey FlightT f = FlightId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey = FlightId . _flightId
type FlightId = PrimaryKey FlightT Identity
deriving instance Show FlightId
deriving instance Eq FlightId

-- 3. Account Table
data AccountT f = Account
  { _accountId        :: Columnar f Int32
  , _accountLogin     :: Columnar f Text
  , _accountFirstName :: Columnar f Text
  , _accountLastName  :: Columnar f Text
  , _accountFfId      :: Columnar f (Maybe Int32)
  , _accountVersion   :: Columnar f Int32
  } deriving (Generic, Beamable)

type Account = AccountT Identity
deriving instance Show Account
deriving instance Eq Account

instance Table AccountT where
  data PrimaryKey AccountT f = AccountId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey = AccountId . _accountId
type AccountId = PrimaryKey AccountT Identity
deriving instance Show AccountId
deriving instance Eq AccountId

-- 4. FrequentFlyer Table
data FrequentFlyerT f = FrequentFlyer
  { _ffId          :: Columnar f Int32
  , _ffLevel       :: Columnar f Int32
  , _ffAwardPoints :: Columnar f Int32
  } deriving (Generic, Beamable)

type FrequentFlyer = FrequentFlyerT Identity
deriving instance Show FrequentFlyer
deriving instance Eq FrequentFlyer

instance Table FrequentFlyerT where
  data PrimaryKey FrequentFlyerT f = FrequentFlyerId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey = FrequentFlyerId . _ffId
type FrequentFlyerId = PrimaryKey FrequentFlyerT Identity
deriving instance Show FrequentFlyerId
deriving instance Eq FrequentFlyerId

-- 5. Booking Table
data BookingT f = Booking
  { _bookingId        :: Columnar f Int64
  , _bookingRef       :: Columnar f Text
  , _bookingName      :: Columnar f (Maybe Text)
  , _bookingAccountId :: Columnar f (Maybe Int32)
  , _bookingPrice     :: Columnar f (Maybe Scientific)
  } deriving (Generic, Beamable)

type Booking = BookingT Identity
deriving instance Show Booking
deriving instance Eq Booking

instance Table BookingT where
  data PrimaryKey BookingT f = BookingId (Columnar f Int64) deriving (Generic, Beamable)
  primaryKey = BookingId . _bookingId
type BookingId = PrimaryKey BookingT Identity
deriving instance Show BookingId
deriving instance Eq BookingId

-- 6. BookingLeg Table
data BookingLegT f = BookingLeg
  { _legBookingLegId :: Columnar f Int64
  , _legBookingId    :: Columnar f Int64
  , _legFlightId     :: Columnar f Int32
  , _legLegNum       :: Columnar f (Maybe Int32)
  } deriving (Generic, Beamable)

type BookingLeg = BookingLegT Identity
deriving instance Show BookingLeg
deriving instance Eq BookingLeg

instance Table BookingLegT where
  data PrimaryKey BookingLegT f = BookingLegId (Columnar f Int64) deriving (Generic, Beamable)
  primaryKey = BookingLegId . _legBookingLegId
type BookingLegId = PrimaryKey BookingLegT Identity
deriving instance Show BookingLegId
deriving instance Eq BookingLegId

-- 7. BoardingPass Table
data BoardingPassT f = BoardingPass
  { _bpPassId       :: Columnar f Int64
  , _bpPassengerId  :: Columnar f Int64
  , _bpBookingLegId :: Columnar f Int64
  , _bpSeat         :: Columnar f (Maybe Text)
  , _bpBoardingTime :: Columnar f (Maybe UTCTime)
  } deriving (Generic, Beamable)

type BoardingPass = BoardingPassT Identity
deriving instance Show BoardingPass
deriving instance Eq BoardingPass

instance Table BoardingPassT where
  data PrimaryKey BoardingPassT f = BoardingPassId (Columnar f Int64) deriving (Generic, Beamable)
  primaryKey = BoardingPassId . _bpPassId
type BoardingPassId = PrimaryKey BoardingPassT Identity
deriving instance Show BoardingPassId
deriving instance Eq BoardingPassId

-- 8. Passenger Table
data PassengerT f = Passenger
  { _passPassengerId :: Columnar f Int64
  , _passBookingId   :: Columnar f Int64
  , _passAccountId   :: Columnar f (Maybe Int32)
  , _passFirstName   :: Columnar f Text
  , _passLastName    :: Columnar f Text
  } deriving (Generic, Beamable)

type Passenger = PassengerT Identity
deriving instance Show Passenger
deriving instance Eq Passenger

instance Table PassengerT where
  data PrimaryKey PassengerT f = PassengerId (Columnar f Int64) deriving (Generic, Beamable)
  primaryKey = PassengerId . _passPassengerId
type PassengerId = PrimaryKey PassengerT Identity
deriving instance Show PassengerId
deriving instance Eq PassengerId

-- 9. Employee Table
data EmployeeT f = Employee
  { _empId         :: Columnar f Int32
  , _empFirstName  :: Columnar f Text
  , _empLastName   :: Columnar f Text
  , _empEmail      :: Columnar f Text
  , _empDepartment :: Columnar f Text
  , _empSalary     :: Columnar f Scientific
  , _empManagerId  :: Columnar f (Maybe Int32)
  } deriving (Generic, Beamable)

type Employee = EmployeeT Identity
deriving instance Show Employee
deriving instance Eq Employee

instance Table EmployeeT where
  data PrimaryKey EmployeeT f = EmployeeId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey = EmployeeId . _empId
type EmployeeId = PrimaryKey EmployeeT Identity
deriving instance Show EmployeeId
deriving instance Eq EmployeeId

-- 10. Aircraft Table
data AircraftT f = Aircraft
  { _acCode     :: Columnar f Text
  , _acModel    :: Columnar f (Maybe Text)
  , _acRange    :: Columnar f Scientific
  , _acClass    :: Columnar f Int32
  , _acVelocity :: Columnar f Scientific
  } deriving (Generic, Beamable)

type Aircraft = AircraftT Identity
deriving instance Show Aircraft
deriving instance Eq Aircraft

instance Table AircraftT where
  data PrimaryKey AircraftT f = AircraftId (Columnar f Text) deriving (Generic, Beamable)
  primaryKey = AircraftId . _acCode
type AircraftId = PrimaryKey AircraftT Identity
deriving instance Show AircraftId
deriving instance Eq AircraftId

-- 11. Phone Table
data PhoneT f = Phone
  { _phoneId        :: Columnar f Int32
  , _phoneAccountId :: Columnar f (Maybe Int32)
  , _phoneNum       :: Columnar f (Maybe Text)
  , _phoneType      :: Columnar f (Maybe Text)
  } deriving (Generic, Beamable)

type Phone = PhoneT Identity
deriving instance Show Phone
deriving instance Eq Phone

instance Table PhoneT where
  data PrimaryKey PhoneT f = PhoneId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey = PhoneId . _phoneId
type PhoneId = PrimaryKey PhoneT Identity
deriving instance Show PhoneId
deriving instance Eq PhoneId

-- 12. FlightSeatInventory Table
data FlightSeatInventoryT f = FlightSeatInventory
  { _fsiFlightId      :: Columnar f Int32
  , _fsiSeatNo        :: Columnar f Text
  , _fsiPassengerName :: Columnar f (Maybe Text)
  , _fsiAccountId     :: Columnar f (Maybe Int32)
  , _fsiReservedAt    :: Columnar f (Maybe UTCTime)
  , _fsiStatus        :: Columnar f Text
  , _fsiVersion       :: Columnar f Int32
  } deriving (Generic, Beamable)

type FlightSeatInventory = FlightSeatInventoryT Identity
deriving instance Show FlightSeatInventory
deriving instance Eq FlightSeatInventory

instance Table FlightSeatInventoryT where
  data PrimaryKey FlightSeatInventoryT f = FlightSeatInventoryId (Columnar f Int32) (Columnar f Text) deriving (Generic, Beamable)
  primaryKey x = FlightSeatInventoryId (_fsiFlightId x) (_fsiSeatNo x)
type FlightSeatInventoryId = PrimaryKey FlightSeatInventoryT Identity
deriving instance Show FlightSeatInventoryId
deriving instance Eq FlightSeatInventoryId

-- 13. FlightStatusUpdate Table
data FlightStatusUpdateT f = FlightStatusUpdate
  { _fsuFlightId        :: Columnar f Int32
  , _fsuStatus          :: Columnar f Text
  , _fsuActualDeparture :: Columnar f (Maybe UTCTime)
  , _fsuActualArrival   :: Columnar f (Maybe UTCTime)
  , _fsuUpdateTs        :: Columnar f UTCTime
  , _fsuVersion         :: Columnar f Int32
  } deriving (Generic, Beamable)

type FlightStatusUpdate = FlightStatusUpdateT Identity
deriving instance Show FlightStatusUpdate
deriving instance Eq FlightStatusUpdate

instance Table FlightStatusUpdateT where
  data PrimaryKey FlightStatusUpdateT f = FlightStatusUpdateId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey = FlightStatusUpdateId . _fsuFlightId
type FlightStatusUpdateId = PrimaryKey FlightStatusUpdateT Identity
deriving instance Show FlightStatusUpdateId
deriving instance Eq FlightStatusUpdateId

-- Database Definition
data PostgresAirDb f = PostgresAirDb
  { _airports            :: f (TableEntity AirportT)
  , _flights             :: f (TableEntity FlightT)
  , _accounts            :: f (TableEntity AccountT)
  , _frequentFlyers      :: f (TableEntity FrequentFlyerT)
  , _bookings            :: f (TableEntity BookingT)
  , _bookingLegs         :: f (TableEntity BookingLegT)
  , _boardingPasses      :: f (TableEntity BoardingPassT)
  , _passengers          :: f (TableEntity PassengerT)
  , _employees           :: f (TableEntity EmployeeT)
  , _aircrafts           :: f (TableEntity AircraftT)
  , _phones              :: f (TableEntity PhoneT)
  , _seatInventories     :: f (TableEntity FlightSeatInventoryT)
  , _flightStatusUpdates :: f (TableEntity FlightStatusUpdateT)
  } deriving Generic

instance Database be PostgresAirDb

postgresAirDb :: DatabaseSettings Postgres PostgresAirDb
postgresAirDb = defaultDbSettings `withDbModification` dbModification
  { _airports = setEntityName "airport" <> modifyTableFields tableModification
      { _airportCode = fieldNamed "airport_code"
      , _airportName = fieldNamed "airport_name"
      , _airportCity = fieldNamed "city"
      , _airportTz   = fieldNamed "airport_tz"
      , _airportIntnl= fieldNamed "intnl"
      , _airportDesc = fieldNamed "description"
      }
  , _flights = setEntityName "flight" <> modifyTableFields tableModification
      { _flightId           = fieldNamed "flight_id"
      , _flightNo           = fieldNamed "flight_no"
      , _scheduledDeparture = fieldNamed "scheduled_departure"
      , _scheduledArrival   = fieldNamed "scheduled_arrival"
      , _departureAirport   = fieldNamed "departure_airport"
      , _arrivalAirport     = fieldNamed "arrival_airport"
      , _flightStatus       = fieldNamed "status"
      , _flightAircraftCode = fieldNamed "aircraft_code"
      , _actualDeparture    = fieldNamed "actual_departure"
      , _actualArrival      = fieldNamed "actual_arrival"
      , _flightVersion      = fieldNamed "version"
      }
  , _accounts = setEntityName "account" <> modifyTableFields tableModification
      { _accountId        = fieldNamed "account_id"
      , _accountLogin     = fieldNamed "login"
      , _accountFirstName = fieldNamed "first_name"
      , _accountLastName  = fieldNamed "last_name"
      , _accountFfId      = fieldNamed "frequent_flyer_id"
      , _accountVersion   = fieldNamed "version"
      }
  , _frequentFlyers = setEntityName "frequent_flyer" <> modifyTableFields tableModification
      { _ffId          = fieldNamed "frequent_flyer_id"
      , _ffLevel       = fieldNamed "level"
      , _ffAwardPoints = fieldNamed "award_points"
      }
  , _bookings = setEntityName "booking" <> modifyTableFields tableModification
      { _bookingId        = fieldNamed "booking_id"
      , _bookingRef       = fieldNamed "booking_ref"
      , _bookingName      = fieldNamed "booking_name"
      , _bookingAccountId = fieldNamed "account_id"
      , _bookingPrice     = fieldNamed "price"
      }
  , _bookingLegs = setEntityName "booking_leg" <> modifyTableFields tableModification
      { _legBookingLegId = fieldNamed "booking_leg_id"
      , _legBookingId    = fieldNamed "booking_id"
      , _legFlightId     = fieldNamed "flight_id"
      , _legLegNum       = fieldNamed "leg_num"
      }
  , _boardingPasses = setEntityName "boarding_pass" <> modifyTableFields tableModification
      { _bpPassId       = fieldNamed "pass_id"
      , _bpPassengerId  = fieldNamed "passenger_id"
      , _bpBookingLegId = fieldNamed "booking_leg_id"
      , _bpSeat         = fieldNamed "seat"
      , _bpBoardingTime = fieldNamed "boarding_time"
      }
  , _passengers = setEntityName "passenger" <> modifyTableFields tableModification
      { _passPassengerId = fieldNamed "passenger_id"
      , _passBookingId   = fieldNamed "booking_id"
      , _passAccountId   = fieldNamed "account_id"
      , _passFirstName   = fieldNamed "first_name"
      , _passLastName    = fieldNamed "last_name"
      }
  , _employees = setEntityName "employee" <> modifyTableFields tableModification
      { _empId         = fieldNamed "employee_id"
      , _empFirstName  = fieldNamed "first_name"
      , _empLastName   = fieldNamed "last_name"
      , _empEmail      = fieldNamed "email"
      , _empDepartment = fieldNamed "department"
      , _empSalary     = fieldNamed "salary"
      , _empManagerId  = fieldNamed "manager_id"
      }
  , _aircrafts = setEntityName "aircraft" <> modifyTableFields tableModification
      { _acCode     = fieldNamed "code"
      , _acModel    = fieldNamed "model"
      , _acRange    = fieldNamed "range"
      , _acClass    = fieldNamed "class"
      , _acVelocity = fieldNamed "velocity"
      }
  , _phones = setEntityName "phone" <> modifyTableFields tableModification
      { _phoneId        = fieldNamed "phone_id"
      , _phoneAccountId = fieldNamed "account_id"
      , _phoneNum       = fieldNamed "phone"
      , _phoneType      = fieldNamed "phone_type"
      }
  , _seatInventories = setEntityName "flight_seat_inventory" <> modifyTableFields tableModification
      { _fsiFlightId      = fieldNamed "flight_id"
      , _fsiSeatNo        = fieldNamed "seat_no"
      , _fsiPassengerName = fieldNamed "passenger_name"
      , _fsiAccountId     = fieldNamed "account_id"
      , _fsiReservedAt    = fieldNamed "reserved_at"
      , _fsiStatus        = fieldNamed "status"
      , _fsiVersion       = fieldNamed "version"
      }
  , _flightStatusUpdates = setEntityName "flight_status_update" <> modifyTableFields tableModification
      { _fsuFlightId        = fieldNamed "flight_id"
      , _fsuStatus          = fieldNamed "status"
      , _fsuActualDeparture = fieldNamed "actual_departure"
      , _fsuActualArrival   = fieldNamed "actual_arrival"
      , _fsuUpdateTs        = fieldNamed "update_ts"
      , _fsuVersion         = fieldNamed "version"
      }
  }
