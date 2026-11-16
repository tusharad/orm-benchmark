// @generated automatically by Diesel CLI or manually specified for postgres_air

diesel::table! {
    account (account_id) {
        account_id -> Int4,
        login -> Text,
        first_name -> Text,
        last_name -> Text,
        frequent_flyer_id -> Nullable<Int4>,
        update_ts -> Nullable<Timestamptz>,
        version -> Int4,
    }
}

diesel::table! {
    frequent_flyer (frequent_flyer_id) {
        frequent_flyer_id -> Int4,
        first_name -> Text,
        last_name -> Text,
        title -> Text,
        card_num -> Text,
        level -> Int4,
        award_points -> Int4,
        email -> Text,
        phone -> Text,
        update_ts -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    phone (phone_id) {
        phone_id -> Int4,
        account_id -> Nullable<Int4>,
        #[sql_name = "phone"]
        phone_number -> Nullable<Text>,
        phone_type -> Nullable<Text>,
        primary_phone -> Nullable<Bool>,
        update_ts -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    booking (booking_id) {
        booking_id -> Int8,
        booking_ref -> Text,
        booking_name -> Nullable<Text>,
        account_id -> Nullable<Int4>,
        email -> Text,
        phone -> Text,
        update_ts -> Nullable<Timestamptz>,
        price -> Nullable<Numeric>,
    }
}

diesel::table! {
    passenger (passenger_id) {
        passenger_id -> Int4,
        booking_id -> Int4,
        booking_ref -> Nullable<Text>,
        passenger_no -> Nullable<Int4>,
        first_name -> Text,
        last_name -> Text,
        account_id -> Nullable<Int4>,
        update_ts -> Nullable<Timestamptz>,
        age -> Nullable<Int4>,
    }
}

diesel::table! {
    flight (flight_id) {
        flight_id -> Int4,
        flight_no -> Text,
        scheduled_departure -> Timestamptz,
        scheduled_arrival -> Timestamptz,
        departure_airport -> Text,
        arrival_airport -> Text,
        status -> Text,
        aircraft_code -> Text,
        actual_departure -> Nullable<Timestamptz>,
        actual_arrival -> Nullable<Timestamptz>,
        update_ts -> Nullable<Timestamptz>,
        version -> Int4,
    }
}

diesel::table! {
    booking_leg (booking_leg_id) {
        booking_leg_id -> Int4,
        booking_id -> Int4,
        flight_id -> Int4,
        leg_num -> Nullable<Int4>,
        is_returning -> Nullable<Bool>,
        update_ts -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    boarding_pass (pass_id) {
        pass_id -> Int4,
        passenger_id -> Nullable<Int8>,
        booking_leg_id -> Nullable<Int8>,
        seat -> Nullable<Text>,
        boarding_time -> Nullable<Timestamptz>,
        precheck -> Nullable<Bool>,
        update_ts -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    airport (airport_code) {
        airport_code -> Text,
        airport_name -> Text,
        city -> Text,
        airport_tz -> Text,
        continent -> Nullable<Text>,
        iso_country -> Nullable<Text>,
        iso_region -> Nullable<Text>,
        intnl -> Bool,
        update_ts -> Nullable<Timestamptz>,
        description -> Nullable<Text>,
    }
}

diesel::table! {
    aircraft (code) {
        code -> Text,
        model -> Nullable<Text>,
        range -> Numeric,
        class -> Int4,
        velocity -> Numeric,
    }
}

diesel::table! {
    flight_seat_inventory (flight_id, seat_no) {
        flight_id -> Int4,
        seat_no -> Text,
        passenger_name -> Nullable<Text>,
        account_id -> Nullable<Int4>,
        reserved_at -> Nullable<Timestamptz>,
        status -> Text,
        version -> Int4,
    }
}

diesel::table! {
    flight_status_update (flight_id) {
        flight_id -> Int4,
        status -> Text,
        actual_departure -> Nullable<Timestamptz>,
        actual_arrival -> Nullable<Timestamptz>,
        update_ts -> Timestamptz,
        version -> Int4,
    }
}

diesel::allow_tables_to_appear_in_same_query!(
    account,
    frequent_flyer,
    phone,
    booking,
    passenger,
    flight,
    booking_leg,
    boarding_pass,
    airport,
    aircraft,
    flight_seat_inventory,
    flight_status_update,
);
