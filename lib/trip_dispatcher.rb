require 'csv'
require 'time'

require_relative 'passenger'
require_relative 'trip'
require_relative 'driver'

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize(directory: './support')
      @passengers = Passenger.load_all(directory: directory)
      @trips = Trip.load_all(directory: directory)
      @drivers = Driver.load_all(directory: directory)
      connect_trips
    end

    def find_passenger(id)
      Passenger.validate_id(id)
      return @passengers.find { |passenger| passenger.id == id }
    end

    def find_driver(id)
      Driver.validate_id(id)
      return @drivers.find { |driver| driver.id == id }
    end

    def find_last_trip_id
      return @trips.last.id
    end

    def inspect
      # Make puts output more useful
      return "#<#{self.class.name}:0x#{object_id.to_s(16)} \
              #{trips.count} trips, \
              #{drivers.count} drivers, \
              #{passengers.count} passengers>"
    end

    def request_trip(passenger_id)
      assigned_driver = @drivers.find { |driver| driver.status == :AVAILABLE }
      raise ArgumentError, "No available drivers" if assigned_driver.nil?

      assigned_passenger = find_passenger(passenger_id)

      new_trip = Trip.new(
          id: find_last_trip_id + 1,
          passenger: assigned_passenger,
          passenger_id: passenger_id,
          start_time: Time.now,
          end_time: nil,
          cost: nil,
          rating: nil,
          driver: assigned_driver,
          driver_id: assigned_driver.id
      )

      assigned_driver.change_status

      new_trip.connect(assigned_passenger, assigned_driver)

      @trips << new_trip

      return new_trip
    end

    private

    def connect_trips
      @trips.each do |trip|
        passenger = find_passenger(trip.passenger_id)
        driver = find_driver(trip.driver_id)
        trip.connect(passenger, driver)
      end

      return trips
    end
  end
end
