defmodule EctoAirBench.Schemas do
  defmodule Flight do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:flight_id, :id, autogenerate: false}
    schema "flight" do
      field :flight_no, :string
      field :scheduled_departure, :utc_datetime
      field :scheduled_arrival, :utc_datetime
      field :departure_airport, :string
      field :arrival_airport, :string
      field :status, :string
      field :aircraft_code, :string
      field :actual_departure, :utc_datetime
      field :actual_arrival, :utc_datetime
      field :update_ts, :utc_datetime
      field :version, :integer

      has_many :booking_legs, EctoAirBench.Schemas.BookingLeg, foreign_key: :flight_id, references: :flight_id
      belongs_to :aircraft, EctoAirBench.Schemas.Aircraft, foreign_key: :aircraft_code, references: :code, type: :string, define_field: false
    end
  end

  defmodule Booking do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:booking_id, :integer, autogenerate: false}
    schema "booking" do
      field :booking_ref, :string
      field :booking_name, :string
      field :account_id, :integer
      field :email, :string
      field :phone, :string
      field :update_ts, :utc_datetime
      field :price, :decimal

      has_many :booking_legs, EctoAirBench.Schemas.BookingLeg, foreign_key: :booking_id, references: :booking_id
      has_many :passengers, EctoAirBench.Schemas.Passenger, foreign_key: :booking_id, references: :booking_id
      belongs_to :account, EctoAirBench.Schemas.Account, foreign_key: :account_id, references: :account_id, define_field: false
    end
  end

  defmodule Passenger do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:passenger_id, :id, autogenerate: false}
    schema "passenger" do
      field :booking_id, :integer
      field :booking_ref, :string
      field :passenger_no, :integer
      field :first_name, :string
      field :last_name, :string
      field :account_id, :integer
      field :update_ts, :utc_datetime
      field :age, :integer

      belongs_to :booking, EctoAirBench.Schemas.Booking, foreign_key: :booking_id, references: :booking_id, define_field: false
      belongs_to :account, EctoAirBench.Schemas.Account, foreign_key: :account_id, references: :account_id, define_field: false
    end
  end

  defmodule BookingLeg do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:booking_leg_id, :id, autogenerate: false}
    schema "booking_leg" do
      field :booking_id, :integer
      field :flight_id, :integer
      field :leg_num, :integer
      field :is_returning, :boolean
      field :update_ts, :utc_datetime

      belongs_to :flight, EctoAirBench.Schemas.Flight, foreign_key: :flight_id, references: :flight_id, define_field: false
      belongs_to :booking, EctoAirBench.Schemas.Booking, foreign_key: :booking_id, references: :booking_id, define_field: false
      has_one :boarding_pass, EctoAirBench.Schemas.BoardingPass, foreign_key: :booking_leg_id, references: :booking_leg_id
    end
  end

  defmodule BoardingPass do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:pass_id, :id, autogenerate: false}
    schema "boarding_pass" do
      field :passenger_id, :integer
      field :booking_leg_id, :integer
      field :seat, :string
      field :boarding_time, :utc_datetime
      field :precheck, :boolean
      field :update_ts, :utc_datetime

      belongs_to :booking_leg, EctoAirBench.Schemas.BookingLeg, foreign_key: :booking_leg_id, references: :booking_leg_id, define_field: false
    end
  end

  defmodule Account do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:account_id, :id, autogenerate: false}
    schema "account" do
      field :login, :string
      field :first_name, :string
      field :last_name, :string
      field :frequent_flyer_id, :integer
      field :update_ts, :utc_datetime
      field :version, :integer

      has_one :frequent_flyer, EctoAirBench.Schemas.FrequentFlyer, foreign_key: :frequent_flyer_id, references: :frequent_flyer_id
      has_many :phones, EctoAirBench.Schemas.Phone, foreign_key: :account_id, references: :account_id
      has_many :bookings, EctoAirBench.Schemas.Booking, foreign_key: :account_id, references: :account_id
    end
  end

  defmodule FrequentFlyer do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:frequent_flyer_id, :id, autogenerate: false}
    schema "frequent_flyer" do
      field :first_name, :string
      field :last_name, :string
      field :title, :string
      field :card_num, :string
      field :level, :integer
      field :award_points, :integer
      field :email, :string
      field :phone, :string
      field :update_ts, :utc_datetime
    end
  end

  defmodule Phone do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:phone_id, :id, autogenerate: false}
    schema "phone" do
      field :account_id, :integer
      field :phone, :string
      field :phone_type, :string
      field :primary_phone, :boolean
      field :update_ts, :utc_datetime

      belongs_to :account, EctoAirBench.Schemas.Account, foreign_key: :account_id, references: :account_id, define_field: false
    end
  end

  defmodule Airport do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:airport_code, :string, autogenerate: false}
    schema "airport" do
      field :airport_name, :string
      field :city, :string
      field :airport_tz, :string
      field :continent, :string
      field :iso_country, :string
      field :iso_region, :string
      field :intnl, :boolean
      field :update_ts, :utc_datetime
      field :description, :string
    end
  end

  defmodule Aircraft do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:code, :string, autogenerate: false}
    schema "aircraft" do
      field :model, :string
      field :range, :decimal
      field :class, :integer
      field :velocity, :decimal
    end
  end

  defmodule FlightSeatInventory do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key false
    schema "flight_seat_inventory" do
      field :flight_id, :integer, primary_key: true
      field :seat_no, :string, primary_key: true
      field :passenger_name, :string
      field :account_id, :integer
      field :reserved_at, :utc_datetime
      field :status, :string
      field :version, :integer
    end
  end

  defmodule FlightStatusUpdate do
    use Ecto.Schema

    @schema_prefix "postgres_air"
    @primary_key {:flight_id, :id, autogenerate: false}
    schema "flight_status_update" do
      field :status, :string
      field :actual_departure, :utc_datetime
      field :actual_arrival, :utc_datetime
      field :update_ts, :utc_datetime
      field :version, :integer
    end
  end
end
