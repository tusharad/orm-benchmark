{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Models where

import Control.DeepSeq (NFData)
import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import qualified Orville.PostgreSQL as O

-- Flight Entity
data Flight = Flight
  { flightId :: Int32
  , flightNo :: Text
  , scheduledDeparture :: UTCTime
  , scheduledArrival :: UTCTime
  , departureAirport :: Text
  , arrivalAirport :: Text
  , status :: Text
  , aircraftCode :: Text
  , actualDeparture :: Maybe UTCTime
  , actualArrival :: Maybe UTCTime
  , updateTs :: Maybe UTCTime
  , version :: Int32
  } deriving (Show, Eq, Generic, NFData)

flightIdField :: O.FieldDefinition O.NotNull Int32
flightIdField = O.integerField "flight_id"

flightNoField :: O.FieldDefinition O.NotNull Text
flightNoField = O.unboundedTextField "flight_no"

scheduledDepartureField :: O.FieldDefinition O.NotNull UTCTime
scheduledDepartureField = O.utcTimestampField "scheduled_departure"

scheduledArrivalField :: O.FieldDefinition O.NotNull UTCTime
scheduledArrivalField = O.utcTimestampField "scheduled_arrival"

departureAirportField :: O.FieldDefinition O.NotNull Text
departureAirportField = O.unboundedTextField "departure_airport"

arrivalAirportField :: O.FieldDefinition O.NotNull Text
arrivalAirportField = O.unboundedTextField "arrival_airport"

statusField :: O.FieldDefinition O.NotNull Text
statusField = O.unboundedTextField "status"

aircraftCodeField :: O.FieldDefinition O.NotNull Text
aircraftCodeField = O.unboundedTextField "aircraft_code"

actualDepartureField :: O.FieldDefinition O.Nullable (Maybe UTCTime)
actualDepartureField = O.nullableField (O.utcTimestampField "actual_departure")

actualArrivalField :: O.FieldDefinition O.Nullable (Maybe UTCTime)
actualArrivalField = O.nullableField (O.utcTimestampField "actual_arrival")

updateTsField :: O.FieldDefinition O.Nullable (Maybe UTCTime)
updateTsField = O.nullableField (O.utcTimestampField "update_ts")

versionField :: O.FieldDefinition O.NotNull Int32
versionField = O.integerField "version"

flightMarshaller :: O.SqlMarshaller Flight Flight
flightMarshaller =
  Flight
    <$> O.marshallField flightId flightIdField
    <*> O.marshallField flightNo flightNoField
    <*> O.marshallField scheduledDeparture scheduledDepartureField
    <*> O.marshallField scheduledArrival scheduledArrivalField
    <*> O.marshallField departureAirport departureAirportField
    <*> O.marshallField arrivalAirport arrivalAirportField
    <*> O.marshallField status statusField
    <*> O.marshallField aircraftCode aircraftCodeField
    <*> O.marshallField actualDeparture actualDepartureField
    <*> O.marshallField actualArrival actualArrivalField
    <*> O.marshallField updateTs updateTsField
    <*> O.marshallField version versionField

flightTable :: O.TableDefinition (O.HasKey Int32) Flight Flight
flightTable =
  O.mkTableDefinition
    "flight"
    (O.primaryKey flightIdField)
    flightMarshaller

-- Composite structures for benchmarks
data CompositeBookingRecord = CompositeBookingRecord
  { cbrBookingId :: Int64
  , cbrBookingRef :: Text
  , cbrPrice :: Maybe Double
  , cbrEmail :: Text
  , cbrPassengerId :: Int64
  , cbrFirstName :: Text
  , cbrLastName :: Text
  , cbrAge :: Maybe Int32
  , cbrBookingLegId :: Int64
  , cbrLegNum :: Maybe Int32
  , cbrIsReturning :: Maybe Bool
  , cbrFlightId :: Int32
  , cbrFlightNo :: Text
  , cbrDepartureAirport :: Text
  , cbrArrivalAirport :: Text
  , cbrScheduledDeparture :: UTCTime
  , cbrStatus :: Text
  } deriving (Show, Eq, Generic, NFData)

data RouteLedger = RouteLedger
  { rlOrigin :: Text
  , rlDestination :: Text
  , rlAircraftModel :: Text
  , rlTotalFlights :: Int64
  , rlTotalLegs :: Int64
  , rlTotalRevenue :: Double
  , rlAvgDelayMin :: Double
  , rlOnTimePct :: Double
  } deriving (Show, Eq, Generic, NFData)

data HubCentrality = HubCentrality
  { hcAirportCode :: Text
  , hcAirportName :: Text
  , hcCity :: Text
  , hcTotalDepartures :: Int64
  , hcTotalArrivals :: Int64
  , hcUniqueDestinations :: Int64
  , hcFleetDiversity :: Int64
  , hcAvgDepDelay :: Double
  , hcAvgArrDelay :: Double
  , hcHubCentralityScore :: Double
  } deriving (Show, Eq, Generic, NFData)

data CapacityRiskFlight = CapacityRiskFlight
  { crfFlightId :: Int32
  , crfFlightNo :: Text
  , crfDepAirport :: Text
  , crfArrAirport :: Text
  , crfScheduledDep :: UTCTime
  , crfAircraftModel :: Text
  , crfSeatsBooked :: Int64
  , crfEliteFlyerCnt :: Int64
  } deriving (Show, Eq, Generic, NFData)

data ConnectingRoute = ConnectingRoute
  { crHops :: Int32
  , crRoutePath :: Text
  , crJourneyStart :: UTCTime
  , crJourneyEnd :: UTCTime
  , crTotalElapsedMin :: Double
  , crTotalFlightMin :: Double
  } deriving (Show, Eq, Generic, NFData)

data DelayWindowAnalytics = DelayWindowAnalytics
  { dwaFlightId :: Int32
  , dwaFlightNo :: Text
  , dwaArrAirport :: Text
  , dwaScheduledDep :: UTCTime
  , dwaDelayMin :: Double
  , dwaRollingAvg5 :: Double
  , dwaDelayDiffPrev :: Maybe Double
  , dwaRollingStdDev10 :: Double
  , dwaSeverityRank :: Int64
  } deriving (Show, Eq, Generic, NFData)

data HybridSearchResult = HybridSearchResult
  { hsrAirportCode :: Text
  , hsrAirportName :: Text
  , hsrCity :: Text
  , hsrActiveFlights :: Int64
  , hsrRrfScore :: Double
  } deriving (Show, Eq, Generic, NFData)
