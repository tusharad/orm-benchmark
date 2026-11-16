CREATE SCHEMA IF NOT EXISTS postgres_air;

CREATE TABLE postgres_air.aircraft (
    code text PRIMARY KEY,
    model text,
    range numeric NOT NULL,
    class integer NOT NULL,
    velocity numeric NOT NULL
);

CREATE TABLE postgres_air.airport (
    airport_code character(3) PRIMARY KEY,
    airport_name text NOT NULL,
    city text NOT NULL,
    airport_tz text NOT NULL,
    continent text,
    iso_country text,
    iso_region text,
    intnl boolean NOT NULL,
    update_ts timestamp with time zone,
    description text,
    search_tsv text
);

CREATE TABLE postgres_air.flight (
    flight_id integer PRIMARY KEY,
    flight_no text NOT NULL,
    scheduled_departure timestamp with time zone NOT NULL,
    scheduled_arrival timestamp with time zone NOT NULL,
    departure_airport character(3) NOT NULL REFERENCES postgres_air.airport(airport_code),
    arrival_airport character(3) NOT NULL REFERENCES postgres_air.airport(airport_code),
    status text NOT NULL,
    aircraft_code character(3) NOT NULL,
    actual_departure timestamp with time zone,
    actual_arrival timestamp with time zone,
    update_ts timestamp with time zone,
    version integer DEFAULT 1 NOT NULL
);

CREATE TABLE postgres_air.account (
    account_id integer PRIMARY KEY,
    login text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    frequent_flyer_id integer,
    update_ts timestamp with time zone,
    version integer DEFAULT 1 NOT NULL
);

CREATE TABLE postgres_air.frequent_flyer (
    frequent_flyer_id integer PRIMARY KEY,
    first_name text NOT NULL,
    last_name text NOT NULL,
    title text NOT NULL,
    card_num text NOT NULL,
    level integer NOT NULL,
    award_points integer NOT NULL,
    email text NOT NULL,
    phone text NOT NULL,
    update_ts timestamp with time zone
);

CREATE TABLE postgres_air.phone (
    phone_id integer PRIMARY KEY,
    account_id integer REFERENCES postgres_air.account(account_id),
    phone text,
    phone_type text,
    primary_phone boolean,
    update_ts timestamp with time zone
);

CREATE TABLE postgres_air.booking (
    booking_id bigint PRIMARY KEY,
    booking_ref text NOT NULL,
    booking_name text,
    account_id integer REFERENCES postgres_air.account(account_id),
    email text NOT NULL,
    phone text NOT NULL,
    update_ts timestamp with time zone,
    price numeric(7,2)
);

CREATE TABLE postgres_air.booking_leg (
    booking_leg_id integer PRIMARY KEY,
    booking_id bigint NOT NULL REFERENCES postgres_air.booking(booking_id),
    flight_id integer NOT NULL REFERENCES postgres_air.flight(flight_id),
    leg_num integer,
    is_returning boolean,
    update_ts timestamp with time zone
);

CREATE TABLE postgres_air.passenger (
    passenger_id integer PRIMARY KEY,
    booking_id bigint NOT NULL REFERENCES postgres_air.booking(booking_id),
    booking_ref text,
    passenger_no integer,
    first_name text NOT NULL,
    last_name text NOT NULL,
    account_id integer REFERENCES postgres_air.account(account_id),
    update_ts timestamp with time zone,
    age integer
);

CREATE TABLE postgres_air.boarding_pass (
    pass_id integer PRIMARY KEY,
    passenger_id bigint,
    booking_leg_id bigint REFERENCES postgres_air.booking_leg(booking_leg_id),
    seat text,
    boarding_time timestamp with time zone,
    precheck boolean,
    update_ts timestamp with time zone
);

CREATE TABLE postgres_air.flight_seat_inventory (
    flight_id integer NOT NULL REFERENCES postgres_air.flight(flight_id),
    seat_no text NOT NULL,
    passenger_name text,
    account_id integer,
    reserved_at timestamp with time zone,
    status text NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    PRIMARY KEY (flight_id, seat_no)
);

CREATE TABLE postgres_air.flight_status_update (
    flight_id integer PRIMARY KEY,
    status text NOT NULL,
    actual_departure timestamp with time zone,
    actual_arrival timestamp with time zone,
    update_ts timestamp with time zone NOT NULL,
    version integer DEFAULT 1 NOT NULL
);
