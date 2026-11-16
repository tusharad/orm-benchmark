"""
SQLAlchemy 2.0 Strongly-Typed Domain Models for Postgres Air Schema.
"""
from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Optional, List
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

class Base(DeclarativeBase):
    pass

class Aircraft(Base):
    __tablename__ = "aircraft"
    __table_args__ = {"schema": "postgres_air"}

    code: Mapped[str] = mapped_column(sa.Text, primary_key=True)
    model: Mapped[Optional[str]] = mapped_column(sa.Text)
    range: Mapped[Decimal] = mapped_column(sa.Numeric)
    class_: Mapped[int] = mapped_column("class", sa.Integer)
    velocity: Mapped[Decimal] = mapped_column(sa.Numeric)

class Airport(Base):
    __tablename__ = "airport"
    __table_args__ = {"schema": "postgres_air"}

    airport_code: Mapped[str] = mapped_column(sa.CHAR(3), primary_key=True)
    airport_name: Mapped[str] = mapped_column(sa.Text)
    city: Mapped[str] = mapped_column(sa.Text)
    airport_tz: Mapped[str] = mapped_column(sa.Text)
    continent: Mapped[Optional[str]] = mapped_column(sa.Text)
    iso_country: Mapped[Optional[str]] = mapped_column(sa.Text)
    iso_region: Mapped[Optional[str]] = mapped_column(sa.Text)
    intnl: Mapped[bool] = mapped_column(sa.Boolean)
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    description: Mapped[Optional[str]] = mapped_column(sa.Text)

class Flight(Base):
    __tablename__ = "flight"
    __table_args__ = {"schema": "postgres_air"}

    flight_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    flight_no: Mapped[str] = mapped_column(sa.Text)
    scheduled_departure: Mapped[datetime] = mapped_column(sa.TIMESTAMP(timezone=False))
    scheduled_arrival: Mapped[datetime] = mapped_column(sa.TIMESTAMP(timezone=False))
    departure_airport: Mapped[str] = mapped_column(sa.CHAR(3), sa.ForeignKey("postgres_air.airport.airport_code"))
    arrival_airport: Mapped[str] = mapped_column(sa.CHAR(3), sa.ForeignKey("postgres_air.airport.airport_code"))
    status: Mapped[str] = mapped_column(sa.Text)
    aircraft_code: Mapped[str] = mapped_column(sa.CHAR(3), sa.ForeignKey("postgres_air.aircraft.code"))
    actual_departure: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    actual_arrival: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    version: Mapped[int] = mapped_column(sa.Integer, default=1)

    aircraft: Mapped[Aircraft] = relationship("Aircraft")
    departure_airport_rel: Mapped[Airport] = relationship("Airport", foreign_keys=[departure_airport])
    arrival_airport_rel: Mapped[Airport] = relationship("Airport", foreign_keys=[arrival_airport])
    booking_legs: Mapped[List[BookingLeg]] = relationship("BookingLeg", back_populates="flight")

class Booking(Base):
    __tablename__ = "booking"
    __table_args__ = {"schema": "postgres_air"}

    booking_id: Mapped[int] = mapped_column(sa.BigInteger, primary_key=True)
    booking_ref: Mapped[str] = mapped_column(sa.Text)
    booking_name: Mapped[Optional[str]] = mapped_column(sa.Text)
    account_id: Mapped[Optional[int]] = mapped_column(sa.Integer, sa.ForeignKey("postgres_air.account.account_id"))
    email: Mapped[str] = mapped_column(sa.Text)
    phone: Mapped[str] = mapped_column(sa.Text)
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    price: Mapped[Optional[Decimal]] = mapped_column(sa.Numeric(7, 2))

    passengers: Mapped[List[Passenger]] = relationship("Passenger", back_populates="booking")
    booking_legs: Mapped[List[BookingLeg]] = relationship("BookingLeg", back_populates="booking")
    account: Mapped[Optional[Account]] = relationship("Account", back_populates="bookings")

class BookingLeg(Base):
    __tablename__ = "booking_leg"
    __table_args__ = {"schema": "postgres_air"}

    booking_leg_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    booking_id: Mapped[int] = mapped_column(sa.Integer, sa.ForeignKey("postgres_air.booking.booking_id"))
    flight_id: Mapped[int] = mapped_column(sa.Integer, sa.ForeignKey("postgres_air.flight.flight_id"))
    leg_num: Mapped[Optional[int]] = mapped_column(sa.Integer)
    is_returning: Mapped[Optional[bool]] = mapped_column(sa.Boolean)
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))

    booking: Mapped[Booking] = relationship("Booking", back_populates="booking_legs")
    flight: Mapped[Flight] = relationship("Flight", back_populates="booking_legs")
    boarding_passes: Mapped[List[BoardingPass]] = relationship("BoardingPass", back_populates="booking_leg")

class Passenger(Base):
    __tablename__ = "passenger"
    __table_args__ = {"schema": "postgres_air"}

    passenger_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    booking_id: Mapped[int] = mapped_column(sa.Integer, sa.ForeignKey("postgres_air.booking.booking_id"))
    booking_ref: Mapped[Optional[str]] = mapped_column(sa.Text)
    passenger_no: Mapped[Optional[int]] = mapped_column(sa.Integer)
    first_name: Mapped[str] = mapped_column(sa.Text)
    last_name: Mapped[str] = mapped_column(sa.Text)
    account_id: Mapped[Optional[int]] = mapped_column(sa.Integer)
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    age: Mapped[Optional[int]] = mapped_column(sa.Integer)

    booking: Mapped[Booking] = relationship("Booking", back_populates="passengers")

class BoardingPass(Base):
    __tablename__ = "boarding_pass"
    __table_args__ = {"schema": "postgres_air"}

    pass_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    passenger_id: Mapped[Optional[int]] = mapped_column(sa.BigInteger)
    booking_leg_id: Mapped[Optional[int]] = mapped_column(sa.BigInteger, sa.ForeignKey("postgres_air.booking_leg.booking_leg_id"))
    seat: Mapped[Optional[str]] = mapped_column(sa.Text)
    boarding_time: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    precheck: Mapped[Optional[bool]] = mapped_column(sa.Boolean)
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))

    booking_leg: Mapped[Optional[BookingLeg]] = relationship("BookingLeg", back_populates="boarding_passes")

class FrequentFlyer(Base):
    __tablename__ = "frequent_flyer"
    __table_args__ = {"schema": "postgres_air"}

    frequent_flyer_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    first_name: Mapped[str] = mapped_column(sa.Text)
    last_name: Mapped[str] = mapped_column(sa.Text)
    title: Mapped[str] = mapped_column(sa.Text)
    card_num: Mapped[str] = mapped_column(sa.Text)
    level: Mapped[int] = mapped_column(sa.Integer)
    award_points: Mapped[int] = mapped_column(sa.Integer)
    email: Mapped[str] = mapped_column(sa.Text)
    phone: Mapped[str] = mapped_column(sa.Text)
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))

class Account(Base):
    __tablename__ = "account"
    __table_args__ = {"schema": "postgres_air"}

    account_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    login: Mapped[str] = mapped_column(sa.Text)
    first_name: Mapped[str] = mapped_column(sa.Text)
    last_name: Mapped[str] = mapped_column(sa.Text)
    frequent_flyer_id: Mapped[Optional[int]] = mapped_column(sa.Integer, sa.ForeignKey("postgres_air.frequent_flyer.frequent_flyer_id"))
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    version: Mapped[int] = mapped_column(sa.Integer, default=1)

    frequent_flyer: Mapped[Optional[FrequentFlyer]] = relationship("FrequentFlyer")
    phones: Mapped[List[Phone]] = relationship("Phone", back_populates="account")
    bookings: Mapped[List[Booking]] = relationship("Booking", back_populates="account")

class Phone(Base):
    __tablename__ = "phone"
    __table_args__ = {"schema": "postgres_air"}

    phone_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    account_id: Mapped[Optional[int]] = mapped_column(sa.Integer, sa.ForeignKey("postgres_air.account.account_id"))
    phone: Mapped[Optional[str]] = mapped_column(sa.Text)
    phone_type: Mapped[Optional[str]] = mapped_column(sa.Text)
    primary_phone: Mapped[Optional[bool]] = mapped_column(sa.Boolean)
    update_ts: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))

    account: Mapped[Optional[Account]] = relationship("Account", back_populates="phones")

class FlightSeatInventory(Base):
    __tablename__ = "flight_seat_inventory"
    __table_args__ = {"schema": "postgres_air"}

    flight_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    seat_no: Mapped[str] = mapped_column(sa.Text, primary_key=True)
    passenger_name: Mapped[Optional[str]] = mapped_column(sa.Text)
    account_id: Mapped[Optional[int]] = mapped_column(sa.Integer)
    reserved_at: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    status: Mapped[str] = mapped_column(sa.Text)
    version: Mapped[int] = mapped_column(sa.Integer, default=1)

class FlightStatusUpdate(Base):
    __tablename__ = "flight_status_update"
    __table_args__ = {"schema": "postgres_air"}

    flight_id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    status: Mapped[str] = mapped_column(sa.Text)
    actual_departure: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    actual_arrival: Mapped[Optional[datetime]] = mapped_column(sa.TIMESTAMP(timezone=False))
    update_ts: Mapped[datetime] = mapped_column(sa.TIMESTAMP(timezone=False))
    version: Mapped[int] = mapped_column(sa.Integer, default=1)

# Strongly-Typed Composite / Analytical Models for Benchmark Results
@dataclass
class CompositeBookingRecord:
    booking_id: int
    booking_ref: str
    price: Optional[Decimal]
    email: str
    passenger_id: int
    first_name: str
    last_name: str
    age: Optional[int]
    booking_leg_id: int
    leg_num: Optional[int]
    is_returning: Optional[bool]
    flight_id: int
    flight_no: str
    departure_airport: str
    arrival_airport: str
    scheduled_departure: datetime
    status: str

@dataclass
class RouteFinancialLedger:
    origin: str
    destination: str
    aircraft_model: Optional[str]
    total_flights: int
    total_legs_booked: int
    total_revenue: Decimal
    avg_delay_minutes: Decimal
    on_time_pct: Decimal

@dataclass
class HubCentralityRecord:
    airport_code: str
    airport_name: str
    city: str
    total_departures: int
    total_arrivals: int
    unique_destinations: int
    fleet_diversity: int
    avg_dep_delay: Decimal
    avg_arr_delay: Decimal
    hub_centrality_score: Decimal

@dataclass
class AtCapacityFlightRecord:
    flight_id: int
    flight_no: str
    departure_airport: str
    arrival_airport: str
    scheduled_departure: datetime
    aircraft_model: Optional[str]
    aircraft_range: Decimal
    seats_booked: int
    elite_flyer_count: int

@dataclass
class FlightPathResult:
    hops: int
    route: str
    journey_start: datetime
    journey_end: datetime
    total_elapsed_minutes: Decimal
    total_flight_minutes: Decimal

@dataclass
class FlightDelayDispersion:
    flight_id: int
    flight_no: str
    arrival_airport: str
    scheduled_departure: datetime
    delay_minutes: Optional[Decimal]
    rolling_avg_delay_5: Optional[Decimal]
    delay_diff_prev: Optional[Decimal]
    rolling_stddev_10: Optional[Decimal]
    severity_rank: int

@dataclass
class KeysetFlight:
    flight_id: int
    flight_no: str
    departure_airport: str
    arrival_airport: str
    scheduled_departure: datetime
    status: str

@dataclass
class FacetedFlightResult:
    flight_id: int
    flight_no: str
    departure_airport: str
    arrival_airport: str
    scheduled_departure: datetime
    scheduled_arrival: datetime
    status: str
    aircraft_model: Optional[str]
    aircraft_range: Decimal
    aircraft_class: int

@dataclass
class HybridAirportResult:
    airport_code: str
    airport_name: str
    city: str
    active_flights_count: int
    rrf_score: Decimal
