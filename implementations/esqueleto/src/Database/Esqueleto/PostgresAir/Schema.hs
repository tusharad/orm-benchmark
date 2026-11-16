{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Database.Esqueleto.PostgresAir.Schema where

import Control.DeepSeq (NFData(..))
import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import Database.Persist.Sql
import Database.Persist.TH
import GHC.Generics (Generic)

share [mkPersist sqlSettings] [persistLowerCase|
Flight sql=flight
    flightId Int32 sql=flight_id
    flightNo Text sql=flight_no
    scheduledDeparture UTCTime sql=scheduled_departure
    scheduledArrival UTCTime sql=scheduled_arrival
    departureAirport Text sql=departure_airport
    arrivalAirport Text sql=arrival_airport
    status Text sql=status
    aircraftCode Text sql=aircraft_code
    actualDeparture UTCTime Maybe sql=actual_departure
    actualArrival UTCTime Maybe sql=actual_arrival
    updateTs UTCTime Maybe sql=update_ts
    version Int32 sql=version
    Primary flightId
    deriving Show Eq Generic

Airport sql=airport
    airportCode Text sql=airport_code
    airportName Text sql=airport_name
    city Text sql=city
    airportTz Text sql=airport_tz
    continent Text sql=continent
    isoCountry Text sql=iso_country
    isoRegion Text sql=iso_region
    intnl Bool sql=intnl
    Primary airportCode
    deriving Show Eq Generic

Aircraft sql=aircraft
    code Text sql=code
    model Text sql=model
    range Double sql=range
    class_ Int32 sql=class
    velocity Double sql=velocity
    Primary code
    deriving Show Eq Generic

Booking sql=booking
    bookingId Int64 sql=booking_id
    bookingRef Text sql=booking_ref
    bookingName Text Maybe sql=booking_name
    accountId Int32 Maybe sql=account_id
    email Text sql=email
    phone Text sql=phone
    price Double Maybe sql=price
    updateTs UTCTime Maybe sql=update_ts
    Primary bookingId
    deriving Show Eq Generic

Passenger sql=passenger
    passengerId Int64 sql=passenger_id
    bookingId Int64 sql=booking_id
    bookingRef Text Maybe sql=booking_ref
    passengerNo Int32 Maybe sql=passenger_no
    firstName Text sql=first_name
    lastName Text sql=last_name
    accountId Int32 Maybe sql=account_id
    age Int32 Maybe sql=age
    updateTs UTCTime Maybe sql=update_ts
    Primary passengerId
    deriving Show Eq Generic

BookingLeg sql=booking_leg
    bookingLegId Int64 sql=booking_leg_id
    bookingId Int64 sql=booking_id
    flightId Int32 sql=flight_id
    legNum Int32 Maybe sql=leg_num
    isReturning Bool Maybe sql=is_returning
    updateTs UTCTime Maybe sql=update_ts
    Primary bookingLegId
    deriving Show Eq Generic

BoardingPass sql=boarding_pass
    passId Int64 sql=pass_id
    passengerId Int64 Maybe sql=passenger_id
    bookingLegId Int64 Maybe sql=booking_leg_id
    seat Text Maybe sql=seat
    boardingTime UTCTime Maybe sql=boarding_time
    updateTs UTCTime Maybe sql=update_ts
    Primary passId
    deriving Show Eq Generic

Account sql=account
    accountId Int32 sql=account_id
    login Text sql=login
    firstName Text sql=first_name
    lastName Text sql=last_name
    frequentFlyerId Int32 Maybe sql=frequent_flyer_id
    updateTs UTCTime Maybe sql=update_ts
    version Int32 sql=version
    Primary accountId
    deriving Show Eq Generic

FrequentFlyer sql=frequent_flyer
    frequentFlyerId Int32 sql=frequent_flyer_id
    firstName Text sql=first_name
    lastName Text sql=last_name
    title Text sql=title
    cardNum Text sql=card_num
    level Int32 sql=level
    awardPoints Int32 sql=award_points
    email Text sql=email
    phone Text sql=phone
    updateTs UTCTime Maybe sql=update_ts
    Primary frequentFlyerId
    deriving Show Eq Generic

Phone sql=phone
    phoneId Int32 sql=phone_id
    accountId Int32 Maybe sql=account_id
    phone Text Maybe sql=phone
    phoneType Text Maybe sql=phone_type
    primaryPhone Bool Maybe sql=primary_phone
    updateTs UTCTime Maybe sql=update_ts
    Primary phoneId
    deriving Show Eq Generic

FlightSeatInventory sql=flight_seat_inventory
    flightId Int32 sql=flight_id
    seatNo Text sql=seat_no
    passengerName Text Maybe sql=passenger_name
    accountId Int32 Maybe sql=account_id
    reservedAt UTCTime Maybe sql=reserved_at
    status Text sql=status
    version Int32 sql=version
    Primary flightId seatNo
    deriving Show Eq Generic

FlightStatusUpdate sql=flight_status_update
    flightId Int32 sql=flight_id
    status Text sql=status
    actualDeparture UTCTime Maybe sql=actual_departure
    actualArrival UTCTime Maybe sql=actual_arrival
    updateTs UTCTime Maybe sql=update_ts
    version Int32 sql=version
    Primary flightId
    deriving Show Eq Generic
|]

instance NFData Flight
instance NFData Airport
instance NFData Aircraft
instance NFData Booking
instance NFData Passenger
instance NFData BookingLeg
instance NFData BoardingPass
instance NFData Account
instance NFData FrequentFlyer
instance NFData Phone
instance NFData FlightSeatInventory
instance NFData FlightStatusUpdate
