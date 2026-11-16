import { EntitySchema } from '@mikro-orm/postgresql';

export interface IFlight {
  flightId: number;
  flightNo: string;
  scheduledDeparture: Date;
  scheduledArrival: Date;
  departureAirport: string;
  arrivalAirport: string;
  status: string;
  aircraftCode: string;
  actualDeparture?: Date;
  actualArrival?: Date;
  updateTs?: Date;
  version: number;
}

export const Flight = new EntitySchema<IFlight>({
  name: 'Flight',
  tableName: 'flight',
  schema: 'postgres_air',
  properties: {
    flightId: { type: 'number', primary: true, fieldName: 'flight_id' },
    flightNo: { type: 'string', fieldName: 'flight_no' },
    scheduledDeparture: { type: 'Date', fieldName: 'scheduled_departure' },
    scheduledArrival: { type: 'Date', fieldName: 'scheduled_arrival' },
    departureAirport: { type: 'string', fieldName: 'departure_airport' },
    arrivalAirport: { type: 'string', fieldName: 'arrival_airport' },
    status: { type: 'string' },
    aircraftCode: { type: 'string', fieldName: 'aircraft_code' },
    actualDeparture: { type: 'Date', nullable: true, fieldName: 'actual_departure' },
    actualArrival: { type: 'Date', nullable: true, fieldName: 'actual_arrival' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' },
    version: { type: 'number', version: true }
  }
});

export interface IAccount {
  accountId: number;
  login: string;
  firstName: string;
  lastName: string;
  frequentFlyerId?: number;
  updateTs?: Date;
  version: number;
}

export const Account = new EntitySchema<IAccount>({
  name: 'Account',
  tableName: 'account',
  schema: 'postgres_air',
  properties: {
    accountId: { type: 'number', primary: true, fieldName: 'account_id' },
    login: { type: 'string' },
    firstName: { type: 'string', fieldName: 'first_name' },
    lastName: { type: 'string', fieldName: 'last_name' },
    frequentFlyerId: { type: 'number', nullable: true, fieldName: 'frequent_flyer_id' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' },
    version: { type: 'number', version: true }
  }
});

export interface IFrequentFlyer {
  frequentFlyerId: number;
  firstName: string;
  lastName: string;
  title: string;
  cardNum: string;
  level: number;
  awardPoints: number;
  email: string;
  phone: string;
  updateTs?: Date;
}

export const FrequentFlyer = new EntitySchema<IFrequentFlyer>({
  name: 'FrequentFlyer',
  tableName: 'frequent_flyer',
  schema: 'postgres_air',
  properties: {
    frequentFlyerId: { type: 'number', primary: true, fieldName: 'frequent_flyer_id' },
    firstName: { type: 'string', fieldName: 'first_name' },
    lastName: { type: 'string', fieldName: 'last_name' },
    title: { type: 'string' },
    cardNum: { type: 'string', fieldName: 'card_num' },
    level: { type: 'number' },
    awardPoints: { type: 'number', fieldName: 'award_points' },
    email: { type: 'string' },
    phone: { type: 'string' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' }
  }
});

export interface IPhone {
  phoneId: number;
  accountId?: number;
  phoneNumber?: string;
  phoneType?: string;
  primaryPhone?: boolean;
  updateTs?: Date;
}

export const Phone = new EntitySchema<IPhone>({
  name: 'Phone',
  tableName: 'phone',
  schema: 'postgres_air',
  properties: {
    phoneId: { type: 'number', primary: true, fieldName: 'phone_id' },
    accountId: { type: 'number', nullable: true, fieldName: 'account_id' },
    phoneNumber: { type: 'string', nullable: true, fieldName: 'phone' },
    phoneType: { type: 'string', nullable: true, fieldName: 'phone_type' },
    primaryPhone: { type: 'boolean', nullable: true, fieldName: 'primary_phone' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' }
  }
});

export interface IBooking {
  bookingId: number;
  bookingRef: string;
  bookingName?: string;
  accountId?: number;
  email: string;
  phone: string;
  updateTs?: Date;
  price?: number;
}

export const Booking = new EntitySchema<IBooking>({
  name: 'Booking',
  tableName: 'booking',
  schema: 'postgres_air',
  properties: {
    bookingId: { type: 'number', primary: true, fieldName: 'booking_id' },
    bookingRef: { type: 'string', fieldName: 'booking_ref' },
    bookingName: { type: 'string', nullable: true, fieldName: 'booking_name' },
    accountId: { type: 'number', nullable: true, fieldName: 'account_id' },
    email: { type: 'string' },
    phone: { type: 'string' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' },
    price: { type: 'number', nullable: true }
  }
});

export interface IBookingLeg {
  bookingLegId: number;
  bookingId: number;
  flightId: number;
  legNum?: number;
  isReturning?: boolean;
  updateTs?: Date;
}

export const BookingLeg = new EntitySchema<IBookingLeg>({
  name: 'BookingLeg',
  tableName: 'booking_leg',
  schema: 'postgres_air',
  properties: {
    bookingLegId: { type: 'number', primary: true, fieldName: 'booking_leg_id' },
    bookingId: { type: 'number', fieldName: 'booking_id' },
    flightId: { type: 'number', fieldName: 'flight_id' },
    legNum: { type: 'number', nullable: true, fieldName: 'leg_num' },
    isReturning: { type: 'boolean', nullable: true, fieldName: 'is_returning' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' }
  }
});

export interface IBoardingPass {
  passId: number;
  passengerId?: number;
  bookingLegId?: number;
  seat?: string;
  boardingTime?: Date;
  precheck?: boolean;
  updateTs?: Date;
}

export const BoardingPass = new EntitySchema<IBoardingPass>({
  name: 'BoardingPass',
  tableName: 'boarding_pass',
  schema: 'postgres_air',
  properties: {
    passId: { type: 'number', primary: true, fieldName: 'pass_id' },
    passengerId: { type: 'number', nullable: true, fieldName: 'passenger_id' },
    bookingLegId: { type: 'number', nullable: true, fieldName: 'booking_leg_id' },
    seat: { type: 'string', nullable: true },
    boardingTime: { type: 'Date', nullable: true, fieldName: 'boarding_time' },
    precheck: { type: 'boolean', nullable: true },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' }
  }
});

export interface IPassenger {
  passengerId: number;
  bookingId: number;
  bookingRef?: string;
  passengerNo?: number;
  firstName: string;
  lastName: string;
  accountId?: number;
  updateTs?: Date;
  age?: number;
}

export const Passenger = new EntitySchema<IPassenger>({
  name: 'Passenger',
  tableName: 'passenger',
  schema: 'postgres_air',
  properties: {
    passengerId: { type: 'number', primary: true, fieldName: 'passenger_id' },
    bookingId: { type: 'number', fieldName: 'booking_id' },
    bookingRef: { type: 'string', nullable: true, fieldName: 'booking_ref' },
    passengerNo: { type: 'number', nullable: true, fieldName: 'passenger_no' },
    firstName: { type: 'string', fieldName: 'first_name' },
    lastName: { type: 'string', fieldName: 'last_name' },
    accountId: { type: 'number', nullable: true, fieldName: 'account_id' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' },
    age: { type: 'number', nullable: true }
  }
});

export interface IAirport {
  airportCode: string;
  airportName: string;
  city: string;
  airportTz: string;
  continent?: string;
  isoCountry?: string;
  isoRegion?: string;
  intnl: boolean;
  updateTs?: Date;
  description?: string;
}

export const Airport = new EntitySchema<IAirport>({
  name: 'Airport',
  tableName: 'airport',
  schema: 'postgres_air',
  properties: {
    airportCode: { type: 'string', primary: true, fieldName: 'airport_code' },
    airportName: { type: 'string', fieldName: 'airport_name' },
    city: { type: 'string' },
    airportTz: { type: 'string', fieldName: 'airport_tz' },
    continent: { type: 'string', nullable: true },
    isoCountry: { type: 'string', nullable: true, fieldName: 'iso_country' },
    isoRegion: { type: 'string', nullable: true, fieldName: 'iso_region' },
    intnl: { type: 'boolean' },
    updateTs: { type: 'Date', nullable: true, fieldName: 'update_ts' },
    description: { type: 'string', nullable: true }
  }
});

export interface IAircraft {
  code: string;
  model?: string;
  range: number;
  class: number;
  velocity: number;
}

export const Aircraft = new EntitySchema<IAircraft>({
  name: 'Aircraft',
  tableName: 'aircraft',
  schema: 'postgres_air',
  properties: {
    code: { type: 'string', primary: true },
    model: { type: 'string', nullable: true },
    range: { type: 'number' },
    class: { type: 'number' },
    velocity: { type: 'number' }
  }
});

export interface IFlightSeatInventory {
  flightId: number;
  seatNo: string;
  passengerName?: string;
  accountId?: number;
  reservedAt?: Date;
  status: string;
  version: number;
}

export const FlightSeatInventory = new EntitySchema<IFlightSeatInventory>({
  name: 'FlightSeatInventory',
  tableName: 'flight_seat_inventory',
  schema: 'postgres_air',
  properties: {
    flightId: { type: 'number', primary: true, fieldName: 'flight_id' },
    seatNo: { type: 'string', primary: true, fieldName: 'seat_no' },
    passengerName: { type: 'string', nullable: true, fieldName: 'passenger_name' },
    accountId: { type: 'number', nullable: true, fieldName: 'account_id' },
    reservedAt: { type: 'Date', nullable: true, fieldName: 'reserved_at' },
    status: { type: 'string' },
    version: { type: 'number', version: true }
  }
});

export interface IFlightStatusUpdate {
  flightId: number;
  status: string;
  actualDeparture?: Date;
  actualArrival?: Date;
  updateTs: Date;
  version: number;
}

export const FlightStatusUpdate = new EntitySchema<IFlightStatusUpdate>({
  name: 'FlightStatusUpdate',
  tableName: 'flight_status_update',
  schema: 'postgres_air',
  properties: {
    flightId: { type: 'number', primary: true, fieldName: 'flight_id' },
    status: { type: 'string' },
    actualDeparture: { type: 'Date', nullable: true, fieldName: 'actual_departure' },
    actualArrival: { type: 'Date', nullable: true, fieldName: 'actual_arrival' },
    updateTs: { type: 'Date', fieldName: 'update_ts' },
    version: { type: 'number', version: true }
  }
});

export const allEntities = [
  Flight,
  Account,
  FrequentFlyer,
  Phone,
  Booking,
  BookingLeg,
  BoardingPass,
  Passenger,
  Airport,
  Aircraft,
  FlightSeatInventory,
  FlightStatusUpdate
];
