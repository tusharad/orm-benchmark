import {
  pgSchema,
  integer,
  bigint,
  text,
  timestamp,
  boolean,
  numeric,
} from 'drizzle-orm/pg-core';

export const postgresAir = pgSchema('postgres_air');

export const flight = postgresAir.table('flight', {
  flightId: integer('flight_id').primaryKey(),
  flightNo: text('flight_no').notNull(),
  scheduledDeparture: timestamp('scheduled_departure', { withTimezone: true, mode: 'date' }).notNull(),
  scheduledArrival: timestamp('scheduled_arrival', { withTimezone: true, mode: 'date' }).notNull(),
  departureAirport: text('departure_airport').notNull(),
  arrivalAirport: text('arrival_airport').notNull(),
  status: text('status').notNull(),
  aircraftCode: text('aircraft_code').notNull(),
  actualDeparture: timestamp('actual_departure', { withTimezone: true, mode: 'date' }),
  actualArrival: timestamp('actual_arrival', { withTimezone: true, mode: 'date' }),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
  version: integer('version').notNull(),
});

export const account = postgresAir.table('account', {
  accountId: integer('account_id').primaryKey(),
  login: text('login').notNull(),
  firstName: text('first_name').notNull(),
  lastName: text('last_name').notNull(),
  frequentFlyerId: integer('frequent_flyer_id'),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
  version: integer('version').notNull(),
});

export const frequentFlyer = postgresAir.table('frequent_flyer', {
  frequentFlyerId: integer('frequent_flyer_id').primaryKey(),
  firstName: text('first_name').notNull(),
  lastName: text('last_name').notNull(),
  title: text('title').notNull(),
  cardNum: text('card_num').notNull(),
  level: integer('level').notNull(),
  awardPoints: integer('award_points').notNull(),
  email: text('email').notNull(),
  phone: text('phone').notNull(),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
});

export const phone = postgresAir.table('phone', {
  phoneId: integer('phone_id').primaryKey(),
  accountId: integer('account_id'),
  phoneNumber: text('phone'),
  phoneType: text('phone_type'),
  primaryPhone: boolean('primary_phone'),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
});

export const booking = postgresAir.table('booking', {
  bookingId: bigint('booking_id', { mode: 'number' }).primaryKey(),
  bookingRef: text('booking_ref').notNull(),
  bookingName: text('booking_name'),
  accountId: integer('account_id'),
  email: text('email').notNull(),
  phone: text('phone').notNull(),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
  price: numeric('price'),
});

export const bookingLeg = postgresAir.table('booking_leg', {
  bookingLegId: integer('booking_leg_id').primaryKey(),
  bookingId: integer('booking_id').notNull(),
  flightId: integer('flight_id').notNull(),
  legNum: integer('leg_num'),
  isReturning: boolean('is_returning'),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
});

export const boardingPass = postgresAir.table('boarding_pass', {
  passId: integer('pass_id').primaryKey(),
  passengerId: bigint('passenger_id', { mode: 'number' }),
  bookingLegId: bigint('booking_leg_id', { mode: 'number' }),
  seat: text('seat'),
  boardingTime: timestamp('boarding_time', { withTimezone: true, mode: 'date' }),
  precheck: boolean('precheck'),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
});

export const passenger = postgresAir.table('passenger', {
  passengerId: integer('passenger_id').primaryKey(),
  bookingId: integer('booking_id').notNull(),
  bookingRef: text('booking_ref'),
  passengerNo: integer('passenger_no'),
  firstName: text('first_name').notNull(),
  lastName: text('last_name').notNull(),
  accountId: integer('account_id'),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
  age: integer('age'),
});

export const airport = postgresAir.table('airport', {
  airportCode: text('airport_code').primaryKey(),
  airportName: text('airport_name').notNull(),
  city: text('city').notNull(),
  airportTz: text('airport_tz').notNull(),
  continent: text('continent'),
  isoCountry: text('iso_country'),
  isoRegion: text('iso_region'),
  intnl: boolean('intnl').notNull(),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }),
  description: text('description'),
});

export const aircraft = postgresAir.table('aircraft', {
  code: text('code').primaryKey(),
  model: text('model'),
  range: numeric('range').notNull(),
  class: integer('class').notNull(),
  velocity: numeric('velocity').notNull(),
});

export const flightSeatInventory = postgresAir.table('flight_seat_inventory', {
  flightId: integer('flight_id').notNull(),
  seatNo: text('seat_no').notNull(),
  passengerName: text('passenger_name'),
  accountId: integer('account_id'),
  reservedAt: timestamp('reserved_at', { withTimezone: true, mode: 'date' }),
  status: text('status').notNull(),
  version: integer('version').notNull(),
});

export const flightStatusUpdate = postgresAir.table('flight_status_update', {
  flightId: integer('flight_id').primaryKey(),
  status: text('status').notNull(),
  actualDeparture: timestamp('actual_departure', { withTimezone: true, mode: 'date' }),
  actualArrival: timestamp('actual_arrival', { withTimezone: true, mode: 'date' }),
  updateTs: timestamp('update_ts', { withTimezone: true, mode: 'date' }).notNull(),
  version: integer('version').notNull(),
});
