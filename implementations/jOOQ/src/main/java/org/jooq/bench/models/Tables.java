package org.jooq.bench.models;

import org.jooq.*;
import org.jooq.Record;
import org.jooq.impl.DSL;
import org.jooq.impl.SQLDataType;
import org.jooq.impl.TableImpl;

import java.math.BigDecimal;
import java.time.Instant;

public class Tables {

    public static final FlightTable FLIGHT = FlightTable.FLIGHT;
    public static final AircraftTable AIRCRAFT = AircraftTable.AIRCRAFT;
    public static final AirportTable AIRPORT = AirportTable.AIRPORT;
    public static final BookingTable BOOKING = BookingTable.BOOKING;
    public static final BookingLegTable BOOKING_LEG = BookingLegTable.BOOKING_LEG;
    public static final BoardingPassTable BOARDING_PASS = BoardingPassTable.BOARDING_PASS;
    public static final PassengerTable PASSENGER = PassengerTable.PASSENGER;
    public static final AccountTable ACCOUNT = AccountTable.ACCOUNT;
    public static final FrequentFlyerTable FREQUENT_FLYER = FrequentFlyerTable.FREQUENT_FLYER;
    public static final PhoneTable PHONE = PhoneTable.PHONE;
    public static final FlightSeatInventoryTable FLIGHT_SEAT_INVENTORY = FlightSeatInventoryTable.FLIGHT_SEAT_INVENTORY;
    public static final FlightStatusUpdateTable FLIGHT_STATUS_UPDATE = FlightStatusUpdateTable.FLIGHT_STATUS_UPDATE;

    public static class FlightTable extends TableImpl<Record> {
        public static final FlightTable FLIGHT = new FlightTable();

        public final TableField<Record, Integer> FLIGHT_ID = createField(DSL.name("flight_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, String> FLIGHT_NO = createField(DSL.name("flight_no"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Instant> SCHEDULED_DEPARTURE = createField(DSL.name("scheduled_departure"), SQLDataType.INSTANT.nullable(false));
        public final TableField<Record, Instant> SCHEDULED_ARRIVAL = createField(DSL.name("scheduled_arrival"), SQLDataType.INSTANT.nullable(false));
        public final TableField<Record, String> DEPARTURE_AIRPORT = createField(DSL.name("departure_airport"), SQLDataType.CHAR(3).nullable(false));
        public final TableField<Record, String> ARRIVAL_AIRPORT = createField(DSL.name("arrival_airport"), SQLDataType.CHAR(3).nullable(false));
        public final TableField<Record, String> STATUS = createField(DSL.name("status"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> AIRCRAFT_CODE = createField(DSL.name("aircraft_code"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Instant> ACTUAL_DEPARTURE = createField(DSL.name("actual_departure"), SQLDataType.INSTANT);
        public final TableField<Record, Instant> ACTUAL_ARRIVAL = createField(DSL.name("actual_arrival"), SQLDataType.INSTANT);
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);
        public final TableField<Record, Integer> VERSION = createField(DSL.name("version"), SQLDataType.INTEGER.nullable(false));

        public FlightTable() {
            super(DSL.name("postgres_air", "flight"));
        }

        private FlightTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public FlightTable as(String alias) {
            return new FlightTable(DSL.name(alias), this);
        }

        @Override
        public FlightTable as(Name alias) {
            return new FlightTable(alias, this);
        }
    }

    public static class AircraftTable extends TableImpl<Record> {
        public static final AircraftTable AIRCRAFT = new AircraftTable();

        public final TableField<Record, String> CODE = createField(DSL.name("code"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> MODEL = createField(DSL.name("model"), SQLDataType.VARCHAR);
        public final TableField<Record, BigDecimal> RANGE = createField(DSL.name("range"), SQLDataType.NUMERIC.nullable(false));
        public final TableField<Record, Integer> CLASS = createField(DSL.name("class"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, BigDecimal> VELOCITY = createField(DSL.name("velocity"), SQLDataType.NUMERIC.nullable(false));

        public AircraftTable() {
            super(DSL.name("postgres_air", "aircraft"));
        }

        private AircraftTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public AircraftTable as(String alias) {
            return new AircraftTable(DSL.name(alias), this);
        }

        @Override
        public AircraftTable as(Name alias) {
            return new AircraftTable(alias, this);
        }
    }

    public static class AirportTable extends TableImpl<Record> {
        public static final AirportTable AIRPORT = new AirportTable();

        public final TableField<Record, String> AIRPORT_CODE = createField(DSL.name("airport_code"), SQLDataType.CHAR(3).nullable(false));
        public final TableField<Record, String> AIRPORT_NAME = createField(DSL.name("airport_name"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> CITY = createField(DSL.name("city"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> AIRPORT_TZ = createField(DSL.name("airport_tz"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> CONTINENT = createField(DSL.name("continent"), SQLDataType.VARCHAR);
        public final TableField<Record, String> ISO_COUNTRY = createField(DSL.name("iso_country"), SQLDataType.VARCHAR);
        public final TableField<Record, String> ISO_REGION = createField(DSL.name("iso_region"), SQLDataType.VARCHAR);
        public final TableField<Record, Boolean> INTNL = createField(DSL.name("intnl"), SQLDataType.BOOLEAN.nullable(false));
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);
        public final TableField<Record, String> DESCRIPTION = createField(DSL.name("description"), SQLDataType.VARCHAR);

        public AirportTable() {
            super(DSL.name("postgres_air", "airport"));
        }

        private AirportTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public AirportTable as(String alias) {
            return new AirportTable(DSL.name(alias), this);
        }

        @Override
        public AirportTable as(Name alias) {
            return new AirportTable(alias, this);
        }
    }

    public static class BookingTable extends TableImpl<Record> {
        public static final BookingTable BOOKING = new BookingTable();

        public final TableField<Record, Long> BOOKING_ID = createField(DSL.name("booking_id"), SQLDataType.BIGINT.nullable(false));
        public final TableField<Record, String> BOOKING_REF = createField(DSL.name("booking_ref"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> BOOKING_NAME = createField(DSL.name("booking_name"), SQLDataType.VARCHAR);
        public final TableField<Record, Integer> ACCOUNT_ID = createField(DSL.name("account_id"), SQLDataType.INTEGER);
        public final TableField<Record, String> EMAIL = createField(DSL.name("email"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> PHONE = createField(DSL.name("phone"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);
        public final TableField<Record, BigDecimal> PRICE = createField(DSL.name("price"), SQLDataType.NUMERIC);

        public BookingTable() {
            super(DSL.name("postgres_air", "booking"));
        }

        private BookingTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public BookingTable as(String alias) {
            return new BookingTable(DSL.name(alias), this);
        }

        @Override
        public BookingTable as(Name alias) {
            return new BookingTable(alias, this);
        }
    }

    public static class BookingLegTable extends TableImpl<Record> {
        public static final BookingLegTable BOOKING_LEG = new BookingLegTable();

        public final TableField<Record, Integer> BOOKING_LEG_ID = createField(DSL.name("booking_leg_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, Long> BOOKING_ID = createField(DSL.name("booking_id"), SQLDataType.BIGINT.nullable(false));
        public final TableField<Record, Integer> FLIGHT_ID = createField(DSL.name("flight_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, Integer> LEG_NUM = createField(DSL.name("leg_num"), SQLDataType.INTEGER);
        public final TableField<Record, Boolean> IS_RETURNING = createField(DSL.name("is_returning"), SQLDataType.BOOLEAN);
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);

        public BookingLegTable() {
            super(DSL.name("postgres_air", "booking_leg"));
        }

        private BookingLegTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public BookingLegTable as(String alias) {
            return new BookingLegTable(DSL.name(alias), this);
        }

        @Override
        public BookingLegTable as(Name alias) {
            return new BookingLegTable(alias, this);
        }
    }

    public static class BoardingPassTable extends TableImpl<Record> {
        public static final BoardingPassTable BOARDING_PASS = new BoardingPassTable();

        public final TableField<Record, Integer> PASS_ID = createField(DSL.name("pass_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, Long> PASSENGER_ID = createField(DSL.name("passenger_id"), SQLDataType.BIGINT);
        public final TableField<Record, Long> BOOKING_LEG_ID = createField(DSL.name("booking_leg_id"), SQLDataType.BIGINT);
        public final TableField<Record, String> SEAT = createField(DSL.name("seat"), SQLDataType.VARCHAR);
        public final TableField<Record, Instant> BOARDING_TIME = createField(DSL.name("boarding_time"), SQLDataType.INSTANT);
        public final TableField<Record, Boolean> PRECHECK = createField(DSL.name("precheck"), SQLDataType.BOOLEAN);
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);

        public BoardingPassTable() {
            super(DSL.name("postgres_air", "boarding_pass"));
        }

        private BoardingPassTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public BoardingPassTable as(String alias) {
            return new BoardingPassTable(DSL.name(alias), this);
        }

        @Override
        public BoardingPassTable as(Name alias) {
            return new BoardingPassTable(alias, this);
        }
    }

    public static class PassengerTable extends TableImpl<Record> {
        public static final PassengerTable PASSENGER = new PassengerTable();

        public final TableField<Record, Integer> PASSENGER_ID = createField(DSL.name("passenger_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, Long> BOOKING_ID = createField(DSL.name("booking_id"), SQLDataType.BIGINT.nullable(false));
        public final TableField<Record, String> BOOKING_REF = createField(DSL.name("booking_ref"), SQLDataType.VARCHAR);
        public final TableField<Record, Integer> PASSENGER_NO = createField(DSL.name("passenger_no"), SQLDataType.INTEGER);
        public final TableField<Record, String> FIRST_NAME = createField(DSL.name("first_name"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> LAST_NAME = createField(DSL.name("last_name"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Integer> ACCOUNT_ID = createField(DSL.name("account_id"), SQLDataType.INTEGER);
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);
        public final TableField<Record, Integer> AGE = createField(DSL.name("age"), SQLDataType.INTEGER);

        public PassengerTable() {
            super(DSL.name("postgres_air", "passenger"));
        }

        private PassengerTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public PassengerTable as(String alias) {
            return new PassengerTable(DSL.name(alias), this);
        }

        @Override
        public PassengerTable as(Name alias) {
            return new PassengerTable(alias, this);
        }
    }

    public static class AccountTable extends TableImpl<Record> {
        public static final AccountTable ACCOUNT = new AccountTable();

        public final TableField<Record, Integer> ACCOUNT_ID = createField(DSL.name("account_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, String> LOGIN = createField(DSL.name("login"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> FIRST_NAME = createField(DSL.name("first_name"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> LAST_NAME = createField(DSL.name("last_name"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Integer> FREQUENT_FLYER_ID = createField(DSL.name("frequent_flyer_id"), SQLDataType.INTEGER);
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);
        public final TableField<Record, Integer> VERSION = createField(DSL.name("version"), SQLDataType.INTEGER.nullable(false));

        public AccountTable() {
            super(DSL.name("postgres_air", "account"));
        }

        private AccountTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public AccountTable as(String alias) {
            return new AccountTable(DSL.name(alias), this);
        }

        @Override
        public AccountTable as(Name alias) {
            return new AccountTable(alias, this);
        }
    }

    public static class FrequentFlyerTable extends TableImpl<Record> {
        public static final FrequentFlyerTable FREQUENT_FLYER = new FrequentFlyerTable();

        public final TableField<Record, Integer> FREQUENT_FLYER_ID = createField(DSL.name("frequent_flyer_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, String> FIRST_NAME = createField(DSL.name("first_name"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> LAST_NAME = createField(DSL.name("last_name"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> TITLE = createField(DSL.name("title"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> CARD_NUM = createField(DSL.name("card_num"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Integer> LEVEL = createField(DSL.name("level"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, Integer> AWARD_POINTS = createField(DSL.name("award_points"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, String> EMAIL = createField(DSL.name("email"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> PHONE = createField(DSL.name("phone"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);

        public FrequentFlyerTable() {
            super(DSL.name("postgres_air", "frequent_flyer"));
        }

        private FrequentFlyerTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public FrequentFlyerTable as(String alias) {
            return new FrequentFlyerTable(DSL.name(alias), this);
        }

        @Override
        public FrequentFlyerTable as(Name alias) {
            return new FrequentFlyerTable(alias, this);
        }
    }

    public static class PhoneTable extends TableImpl<Record> {
        public static final PhoneTable PHONE = new PhoneTable();

        public final TableField<Record, Integer> PHONE_ID = createField(DSL.name("phone_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, Integer> ACCOUNT_ID = createField(DSL.name("account_id"), SQLDataType.INTEGER);
        public final TableField<Record, String> PHONE_NUM = createField(DSL.name("phone"), SQLDataType.VARCHAR);
        public final TableField<Record, String> PHONE_TYPE = createField(DSL.name("phone_type"), SQLDataType.VARCHAR);
        public final TableField<Record, Boolean> PRIMARY_PHONE = createField(DSL.name("primary_phone"), SQLDataType.BOOLEAN);
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT);

        public PhoneTable() {
            super(DSL.name("postgres_air", "phone"));
        }

        private PhoneTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public PhoneTable as(String alias) {
            return new PhoneTable(DSL.name(alias), this);
        }

        @Override
        public PhoneTable as(Name alias) {
            return new PhoneTable(alias, this);
        }
    }

    public static class FlightSeatInventoryTable extends TableImpl<Record> {
        public static final FlightSeatInventoryTable FLIGHT_SEAT_INVENTORY = new FlightSeatInventoryTable();

        public final TableField<Record, Integer> FLIGHT_ID = createField(DSL.name("flight_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, String> SEAT_NO = createField(DSL.name("seat_no"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, String> PASSENGER_NAME = createField(DSL.name("passenger_name"), SQLDataType.VARCHAR);
        public final TableField<Record, Integer> ACCOUNT_ID = createField(DSL.name("account_id"), SQLDataType.INTEGER);
        public final TableField<Record, Instant> RESERVED_AT = createField(DSL.name("reserved_at"), SQLDataType.INSTANT);
        public final TableField<Record, String> STATUS = createField(DSL.name("status"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Integer> VERSION = createField(DSL.name("version"), SQLDataType.INTEGER.nullable(false));

        public FlightSeatInventoryTable() {
            super(DSL.name("postgres_air", "flight_seat_inventory"));
        }

        private FlightSeatInventoryTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public FlightSeatInventoryTable as(String alias) {
            return new FlightSeatInventoryTable(DSL.name(alias), this);
        }

        @Override
        public FlightSeatInventoryTable as(Name alias) {
            return new FlightSeatInventoryTable(alias, this);
        }
    }

    public static class FlightStatusUpdateTable extends TableImpl<Record> {
        public static final FlightStatusUpdateTable FLIGHT_STATUS_UPDATE = new FlightStatusUpdateTable();

        public final TableField<Record, Integer> FLIGHT_ID = createField(DSL.name("flight_id"), SQLDataType.INTEGER.nullable(false));
        public final TableField<Record, String> STATUS = createField(DSL.name("status"), SQLDataType.VARCHAR.nullable(false));
        public final TableField<Record, Instant> ACTUAL_DEPARTURE = createField(DSL.name("actual_departure"), SQLDataType.INSTANT);
        public final TableField<Record, Instant> ACTUAL_ARRIVAL = createField(DSL.name("actual_arrival"), SQLDataType.INSTANT);
        public final TableField<Record, Instant> UPDATE_TS = createField(DSL.name("update_ts"), SQLDataType.INSTANT.nullable(false));
        public final TableField<Record, Integer> VERSION = createField(DSL.name("version"), SQLDataType.INTEGER.nullable(false));

        public FlightStatusUpdateTable() {
            super(DSL.name("postgres_air", "flight_status_update"));
        }

        private FlightStatusUpdateTable(Name alias, Table<Record> aliased) {
            super(alias, null, aliased);
        }

        @Override
        public FlightStatusUpdateTable as(String alias) {
            return new FlightStatusUpdateTable(DSL.name(alias), this);
        }

        @Override
        public FlightStatusUpdateTable as(Name alias) {
            return new FlightStatusUpdateTable(alias, this);
        }
    }
}
