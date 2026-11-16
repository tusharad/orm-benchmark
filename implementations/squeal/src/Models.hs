{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Models where

import Control.DeepSeq (NFData)
import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import qualified GHC.Generics as GHC
import qualified Generics.SOP as SOP

-- Flight Model
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
  } deriving stock (GHC.Generic, Show, Eq)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo, NFData)

-- Aircraft Model
data Aircraft = Aircraft
  { code :: Text
  , model :: Maybe Text
  , range :: Scientific
  , class' :: Int32
  , velocity :: Scientific
  } deriving stock (GHC.Generic, Show, Eq)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo, NFData)

-- Airport Model
data Airport = Airport
  { airport_code :: Text
  , airport_name :: Text
  , city :: Text
  , airport_tz :: Text
  , continent :: Maybe Text
  , iso_country :: Maybe Text
  , iso_region :: Maybe Text
  , intnl :: Bool
  , update_ts :: Maybe UTCTime
  } deriving stock (GHC.Generic, Show, Eq)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo, NFData)

-- Account Model
data Account = Account
  { account_id :: Int32
  , login :: Text
  , first_name :: Text
  , last_name :: Text
  , frequent_flyer_id :: Maybe Int32
  , update_ts :: Maybe UTCTime
  , version :: Int32
  } deriving stock (GHC.Generic, Show, Eq)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo, NFData)

-- Frequent Flyer Model
data FrequentFlyer = FrequentFlyer
  { frequent_flyer_id :: Int32
  , first_name :: Text
  , last_name :: Text
  , title :: Text
  , card_num :: Text
  , level :: Int32
  , award_points :: Int32
  , email :: Text
  , phone :: Text
  , update_ts :: Maybe UTCTime
  } deriving stock (GHC.Generic, Show, Eq)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo, NFData)

-- Composite Row for HQ02
data CompositeRow = CompositeRow
  { booking_id :: Int64
  , booking_ref :: Text
  , email :: Text
  , passenger_id :: Int32
  , first_name :: Text
  , last_name :: Text
  , booking_leg_id :: Int32
  , leg_num :: Maybe Int32
  , flight_id :: Int32
  , flight_no :: Text
  , scheduled_departure :: UTCTime
  , departure_airport :: Text
  , arrival_airport :: Text
  } deriving stock (GHC.Generic, Show, Eq)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo, NFData)

-- Deep Tree Row for HQ03
data DeepTreeRow = DeepTreeRow
  { flight_id :: Int32
  , flight_no :: Text
  , scheduled_departure :: UTCTime
  , booking_leg_id :: Int32
  , leg_num :: Maybe Int32
  , booking_id :: Int64
  , booking_ref :: Text
  , pass_id :: Maybe Int32
  , seat :: Maybe Text
  } deriving stock (GHC.Generic, Show, Eq)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo, NFData)
