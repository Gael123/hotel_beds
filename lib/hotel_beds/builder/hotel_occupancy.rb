require "hotel_beds/core_ext/array"

using HotelBeds::CoreExt::Array

module HotelBeds
  module Builder
    class HotelOccupancy
      attr_accessor :rooms
      private :rooms=

      def initialize(rooms)
        self.rooms = rooms
        freeze
      end

      def child_ages
        rooms.map(&:child_ages).flatten_children
      end

      def adult_count
        rooms.map(&:adult_count).sum
      end

      def child_count
        rooms.map(&:child_count).sum
      end

      def to_h
        {
          RoomCount: rooms.size,
          Occupancy: {
            AdultCount: adult_count,
            ChildCount: child_count#,
            # GuestList: {
            #   Customer: 1.upto(adult_count).map {
            #     { :@type => "AD" }
            #   } + 1.upto(child_count).map { |i|
            #     { :@type => "CH", :Age => Integer(child_ages.fetch(i - 1)) }
            #   }
            # }
          }
        }
      end
    end
  end
end
