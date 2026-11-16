require 'active_record'

class Flight < ActiveRecord::Base
  self.table_name = 'postgres_air.flight'
  self.primary_key = 'flight_id'

  belongs_to :aircraft, foreign_key: 'aircraft_code', primary_key: 'code', optional: true
  has_many :booking_legs, foreign_key: 'flight_id'
  belongs_to :departure_airport_rel, class_name: 'Airport', foreign_key: 'departure_airport', primary_key: 'airport_code', optional: true
  belongs_to :arrival_airport_rel, class_name: 'Airport', foreign_key: 'arrival_airport', primary_key: 'airport_code', optional: true
end

class Aircraft < ActiveRecord::Base
  self.table_name = 'postgres_air.aircraft'
  self.primary_key = 'code'

  def self.instance_method_already_implemented?(method_name)
    return true if method_name == 'class'
    super
  end

  has_many :flights, foreign_key: 'aircraft_code'
end

class Airport < ActiveRecord::Base
  self.table_name = 'postgres_air.airport'
  self.primary_key = 'airport_code'
end

class Account < ActiveRecord::Base
  self.table_name = 'postgres_air.account'
  self.primary_key = 'account_id'

  belongs_to :frequent_flyer, foreign_key: 'frequent_flyer_id', optional: true
  has_many :phones, foreign_key: 'account_id'
  has_many :bookings, foreign_key: 'account_id'
  has_many :passengers, foreign_key: 'account_id'
end

class FrequentFlyer < ActiveRecord::Base
  self.table_name = 'postgres_air.frequent_flyer'
  self.primary_key = 'frequent_flyer_id'

  has_many :accounts, foreign_key: 'frequent_flyer_id'
end

class Phone < ActiveRecord::Base
  self.table_name = 'postgres_air.phone'
  self.primary_key = 'phone_id'

  belongs_to :account, foreign_key: 'account_id', optional: true
end

class Booking < ActiveRecord::Base
  self.table_name = 'postgres_air.booking'
  self.primary_key = 'booking_id'

  belongs_to :account, foreign_key: 'account_id', optional: true
  has_many :booking_legs, foreign_key: 'booking_id'
  has_many :passengers, foreign_key: 'booking_id'
end

class BookingLeg < ActiveRecord::Base
  self.table_name = 'postgres_air.booking_leg'
  self.primary_key = 'booking_leg_id'

  belongs_to :booking, foreign_key: 'booking_id'
  belongs_to :flight, foreign_key: 'flight_id'
  has_many :boarding_passes, foreign_key: 'booking_leg_id'
end

class BoardingPass < ActiveRecord::Base
  self.table_name = 'postgres_air.boarding_pass'
  self.primary_key = 'pass_id'

  belongs_to :booking_leg, foreign_key: 'booking_leg_id', optional: true
  belongs_to :passenger, foreign_key: 'passenger_id', optional: true
end

class Passenger < ActiveRecord::Base
  self.table_name = 'postgres_air.passenger'
  self.primary_key = 'passenger_id'

  belongs_to :booking, foreign_key: 'booking_id'
  belongs_to :account, foreign_key: 'account_id', optional: true
  has_many :boarding_passes, foreign_key: 'passenger_id'
end

class FlightSeatInventory < ActiveRecord::Base
  self.table_name = 'postgres_air.flight_seat_inventory'
end

class FlightStatusUpdate < ActiveRecord::Base
  self.table_name = 'postgres_air.flight_status_update'
  self.primary_key = 'flight_id'
end
