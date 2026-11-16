{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Models where

import Control.DeepSeq (NFData)
import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

data Flight = Flight
  { flight_id :: Int32
  , flight_no :: Text
  , scheduled_departure :: UTCTime
  , scheduled_arrival :: UTCTime
  , departure_airport :: Text
  , arrival_airport :: Text
  , status :: Text
  , aircraft_code :: Text
  , actual_departure :: Maybe UTCTime
  , actual_arrival :: Maybe UTCTime
  , update_ts :: Maybe UTCTime
  , version :: Int32
  } deriving (Generic, NFData, Show, Eq)

data CompositeBookingRecord = CompositeBookingRecord
  { booking_id :: Int64
  , booking_ref :: Text
  , price :: Maybe Scientific
  , email :: Text
  , passenger_id :: Int32
  , first_name :: Text
  , last_name :: Text
  , age :: Maybe Int32
  , booking_leg_id :: Int32
  , leg_num :: Maybe Int32
  , is_returning :: Maybe Bool
  , flight_id :: Int32
  , flight_no :: Text
  , departure_airport :: Text
  , arrival_airport :: Text
  , scheduled_departure :: UTCTime
  , status :: Text
  } deriving (Generic, NFData, Show, Eq)

data BookingLegNode = BookingLegNode
  { leg_id :: Int32
  , flight_id :: Int32
  , pass_id :: Maybe Int32
  } deriving (Generic, NFData, Show, Eq)

data FlightGraphNode = FlightGraphNode
  { flight_id :: Int32
  , flight_no :: Text
  , legs :: [BookingLegNode]
  } deriving (Generic, NFData, Show, Eq)

data AccountDetail = AccountDetail
  { account_id :: Int32
  , login :: Text
  , first_name :: Text
  , last_name :: Text
  , ff_level :: Maybe Int32
  , award_points :: Maybe Int32
  , phone_id :: Maybe Int32
  , phone_number :: Maybe Text
  , phone_type :: Maybe Text
  , booking_id :: Maybe Int64
  , booking_ref :: Maybe Text
  , price :: Maybe Scientific
  , passenger_id :: Maybe Int32
  , passenger_first_name :: Maybe Text
  , passenger_last_name :: Maybe Text
  } deriving (Generic, NFData, Show, Eq)

data RouteProfitability = RouteProfitability
  { origin :: Text
  , destination :: Text
  , aircraft_model :: Maybe Text
  , total_flights :: Int64
  , total_legs_booked :: Int64
  , total_revenue :: Maybe Scientific
  , avg_delay_minutes :: Maybe Scientific
  , on_time_pct :: Maybe Scientific
  } deriving (Generic, NFData, Show, Eq)

data HubCentrality = HubCentrality
  { airport_code :: Text
  , airport_name :: Text
  , city :: Text
  , total_departures :: Int64
  , total_arrivals :: Int64
  , unique_destinations :: Int64
  , fleet_diversity :: Int64
  , avg_dep_delay :: Scientific
  , avg_arr_delay :: Scientific
  , hub_centrality_score :: Scientific
  } deriving (Generic, NFData, Show, Eq)

data FlightCapacity = FlightCapacity
  { flight_id :: Int32
  , flight_no :: Text
  , departure_airport :: Text
  , arrival_airport :: Text
  , scheduled_departure :: UTCTime
  , aircraft_model :: Maybe Text
  , aircraft_range :: Scientific
  , seats_booked :: Int64
  , elite_flyer_count :: Int64
  } deriving (Generic, NFData, Show, Eq)

data Itinerary = Itinerary
  { hops :: Int32
  , route :: Text
  , journey_start :: UTCTime
  , journey_end :: UTCTime
  , total_elapsed_minutes :: Maybe Scientific
  , total_flight_minutes :: Maybe Scientific
  } deriving (Generic, NFData, Show, Eq)

data WindowDelay = WindowDelay
  { flight_id :: Int32
  , flight_no :: Text
  , arrival_airport :: Text
  , scheduled_departure :: UTCTime
  , delay_minutes :: Maybe Scientific
  , rolling_avg_delay_5 :: Maybe Scientific
  , delay_diff_prev :: Maybe Scientific
  , rolling_stddev_10 :: Maybe Scientific
  , severity_rank :: Int64
  } deriving (Generic, NFData, Show, Eq)

data FacetedFlight = FacetedFlight
  { flight_id :: Int32
  , flight_no :: Text
  , departure_airport :: Text
  , arrival_airport :: Text
  , scheduled_departure :: UTCTime
  , scheduled_arrival :: UTCTime
  , status :: Text
  , aircraft_model :: Maybe Text
  , aircraft_range :: Scientific
  , aircraft_class :: Int32
  } deriving (Generic, NFData, Show, Eq)

data HybridAirport = HybridAirport
  { airport_code :: Text
  , airport_name :: Text
  , city :: Text
  , active_flights_count :: Int64
  , rrf_score :: Scientific
  } deriving (Generic, NFData, Show, Eq)
