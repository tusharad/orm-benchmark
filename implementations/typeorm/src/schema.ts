import {
  Entity,
  PrimaryColumn,
  Column,
  VersionColumn
} from "typeorm";

@Entity({ name: "flight", schema: "postgres_air" })
export class Flight {
  @PrimaryColumn({ name: "flight_id", type: "integer" })
  flightId!: number;

  @Column({ name: "flight_no", type: "text" })
  flightNo!: string;

  @Column({ name: "scheduled_departure", type: "timestamptz" })
  scheduledDeparture!: Date;

  @Column({ name: "scheduled_arrival", type: "timestamptz" })
  scheduledArrival!: Date;

  @Column({ name: "departure_airport", type: "text" })
  departureAirport!: string;

  @Column({ name: "arrival_airport", type: "text" })
  arrivalAirport!: string;

  @Column({ name: "status", type: "text" })
  status!: string;

  @Column({ name: "aircraft_code", type: "text" })
  aircraftCode!: string;

  @Column({ name: "actual_departure", type: "timestamptz", nullable: true })
  actualDeparture?: Date | null;

  @Column({ name: "actual_arrival", type: "timestamptz", nullable: true })
  actualArrival?: Date | null;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;

  @VersionColumn({ name: "version", type: "integer" })
  version!: number;
}

@Entity({ name: "aircraft", schema: "postgres_air" })
export class Aircraft {
  @PrimaryColumn({ name: "code", type: "text" })
  code!: string;

  @Column({ name: "model", type: "text", nullable: true })
  model?: string | null;

  @Column({ name: "range", type: "numeric" })
  range!: number;

  @Column({ name: "class", type: "integer" })
  class!: number;

  @Column({ name: "velocity", type: "numeric" })
  velocity!: number;
}

@Entity({ name: "airport", schema: "postgres_air" })
export class Airport {
  @PrimaryColumn({ name: "airport_code", type: "text" })
  airportCode!: string;

  @Column({ name: "airport_name", type: "text" })
  airportName!: string;

  @Column({ name: "city", type: "text" })
  city!: string;

  @Column({ name: "airport_tz", type: "text" })
  airportTz!: string;

  @Column({ name: "continent", type: "text", nullable: true })
  continent?: string | null;

  @Column({ name: "iso_country", type: "text", nullable: true })
  isoCountry?: string | null;

  @Column({ name: "iso_region", type: "text", nullable: true })
  isoRegion?: string | null;

  @Column({ name: "intnl", type: "boolean" })
  intnl!: boolean;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;
}

@Entity({ name: "account", schema: "postgres_air" })
export class Account {
  @PrimaryColumn({ name: "account_id", type: "integer" })
  accountId!: number;

  @Column({ name: "login", type: "text" })
  login!: string;

  @Column({ name: "first_name", type: "text" })
  firstName!: string;

  @Column({ name: "last_name", type: "text" })
  lastName!: string;

  @Column({ name: "frequent_flyer_id", type: "integer", nullable: true })
  frequentFlyerId?: number | null;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;

  @VersionColumn({ name: "version", type: "integer" })
  version!: number;
}

@Entity({ name: "frequent_flyer", schema: "postgres_air" })
export class FrequentFlyer {
  @PrimaryColumn({ name: "frequent_flyer_id", type: "integer" })
  frequentFlyerId!: number;

  @Column({ name: "first_name", type: "text" })
  firstName!: string;

  @Column({ name: "last_name", type: "text" })
  lastName!: string;

  @Column({ name: "title", type: "text" })
  title!: string;

  @Column({ name: "card_num", type: "text" })
  cardNum!: string;

  @Column({ name: "level", type: "integer" })
  level!: number;

  @Column({ name: "award_points", type: "integer" })
  awardPoints!: number;

  @Column({ name: "email", type: "text" })
  email!: string;

  @Column({ name: "phone", type: "text" })
  phone!: string;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;
}

@Entity({ name: "phone", schema: "postgres_air" })
export class Phone {
  @PrimaryColumn({ name: "phone_id", type: "integer" })
  phoneId!: number;

  @Column({ name: "account_id", type: "integer", nullable: true })
  accountId?: number | null;

  @Column({ name: "phone", type: "text", nullable: true })
  phone?: string | null;

  @Column({ name: "phone_type", type: "text", nullable: true })
  phoneType?: string | null;

  @Column({ name: "primary_phone", type: "boolean", nullable: true })
  primaryPhone?: boolean | null;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;
}

@Entity({ name: "booking", schema: "postgres_air" })
export class Booking {
  @PrimaryColumn({ name: "booking_id", type: "bigint" })
  bookingId!: string;

  @Column({ name: "booking_ref", type: "text" })
  bookingRef!: string;

  @Column({ name: "booking_name", type: "text", nullable: true })
  bookingName?: string | null;

  @Column({ name: "account_id", type: "integer", nullable: true })
  accountId?: number | null;

  @Column({ name: "email", type: "text" })
  email!: string;

  @Column({ name: "phone", type: "text" })
  phone!: string;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;

  @Column({ name: "price", type: "numeric", nullable: true })
  price?: number | null;
}

@Entity({ name: "booking_leg", schema: "postgres_air" })
export class BookingLeg {
  @PrimaryColumn({ name: "booking_leg_id", type: "integer" })
  bookingLegId!: number;

  @Column({ name: "booking_id", type: "integer" })
  bookingId!: number;

  @Column({ name: "flight_id", type: "integer" })
  flightId!: number;

  @Column({ name: "leg_num", type: "integer", nullable: true })
  legNum?: number | null;

  @Column({ name: "is_returning", type: "boolean", nullable: true })
  isReturning?: boolean | null;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;
}

@Entity({ name: "boarding_pass", schema: "postgres_air" })
export class BoardingPass {
  @PrimaryColumn({ name: "pass_id", type: "integer" })
  passId!: number;

  @Column({ name: "passenger_id", type: "bigint", nullable: true })
  passengerId?: string | null;

  @Column({ name: "booking_leg_id", type: "bigint", nullable: true })
  bookingLegId?: string | null;

  @Column({ name: "seat", type: "text", nullable: true })
  seat?: string | null;

  @Column({ name: "boarding_time", type: "timestamptz", nullable: true })
  boardingTime?: Date | null;

  @Column({ name: "precheck", type: "boolean", nullable: true })
  precheck?: boolean | null;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;
}

@Entity({ name: "passenger", schema: "postgres_air" })
export class Passenger {
  @PrimaryColumn({ name: "passenger_id", type: "integer" })
  passengerId!: number;

  @Column({ name: "booking_id", type: "integer" })
  bookingId!: number;

  @Column({ name: "booking_ref", type: "text", nullable: true })
  bookingRef?: string | null;

  @Column({ name: "passenger_no", type: "integer", nullable: true })
  passengerNo?: number | null;

  @Column({ name: "first_name", type: "text" })
  firstName!: string;

  @Column({ name: "last_name", type: "text" })
  lastName!: string;

  @Column({ name: "account_id", type: "integer", nullable: true })
  accountId?: number | null;

  @Column({ name: "update_ts", type: "timestamptz", nullable: true })
  updateTs?: Date | null;

  @Column({ name: "age", type: "integer", nullable: true })
  age?: number | null;
}

@Entity({ name: "flight_seat_inventory", schema: "postgres_air" })
export class FlightSeatInventory {
  @PrimaryColumn({ name: "flight_id", type: "integer" })
  flightId!: number;

  @PrimaryColumn({ name: "seat_no", type: "text" })
  seatNo!: string;

  @Column({ name: "passenger_name", type: "text", nullable: true })
  passengerName?: string | null;

  @Column({ name: "account_id", type: "integer", nullable: true })
  accountId?: number | null;

  @Column({ name: "reserved_at", type: "timestamptz", nullable: true })
  reservedAt?: Date | null;

  @Column({ name: "status", type: "text" })
  status!: string;

  @VersionColumn({ name: "version", type: "integer" })
  version!: number;
}

@Entity({ name: "flight_status_update", schema: "postgres_air" })
export class FlightStatusUpdate {
  @PrimaryColumn({ name: "flight_id", type: "integer" })
  flightId!: number;

  @Column({ name: "status", type: "text" })
  status!: string;

  @Column({ name: "actual_departure", type: "timestamptz", nullable: true })
  actualDeparture?: Date | null;

  @Column({ name: "actual_arrival", type: "timestamptz", nullable: true })
  actualArrival?: Date | null;

  @Column({ name: "update_ts", type: "timestamptz" })
  updateTs!: Date;

  @VersionColumn({ name: "version", type: "integer" })
  version!: number;
}
