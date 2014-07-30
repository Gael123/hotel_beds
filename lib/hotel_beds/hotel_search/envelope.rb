require "delegate"

module HotelBeds
  module HotelSearch
    class Envelope < SimpleDelegator
      def attributes
        {
          :@sessionId => session_id,
          :PaginationData => pagination_data,
          :Language => language,
          :CheckInDate => check_in_date,
          :CheckOutDate => check_out_date,
          :OccupancyList => occupancy_list
        }.merge(Hash(destination)).merge(Hash(hotels)).merge(Hash(extra_params))
      end

      private
      def extra_params
        { ExtraParamList: {
          ExtendedData: [{
            :@type => "EXT_ADDITIONAL_PARAM",
            :Name => "PARAM_KEY_PRICE_BREAKDOWN",
            :Value => "Y"
          }, {
            :@type => "EXT_ORDER",
            :Name => "ORDER_CONTRACT_PRICE",
            :Value => "ASC"
          }]
        } }
      end

      def pagination_data
        {
          :@pageNumber => Integer(page_number),
          :@itemsPerPage => Integer(items_per_page)
        }
      end

      def language
        String(__getobj__.language).upcase
      end

      def check_in_date
        { :@date => __getobj__.check_in_date.strftime("%Y%m%d") }
      end

      def check_out_date
        { :@date => __getobj__.check_out_date.strftime("%Y%m%d") }
      end

      def destination
        if __getobj__.destination
          { Destination: {
            :@code => String(__getobj__.destination).upcase,
            :@type => "SIMPLE"
          } }
        end
      end

      def hotels
        if Array(__getobj__.hotels).any?
          { HotelCodeList: {
            :@withinResults => "Y",
            :ProductCode => Array(__getobj__.hotels)
          } }
        end
      end

      def occupancy_list
        grouped_rooms = Array(rooms).group_by(&:group_key).values
        { HotelOccupancy: grouped_rooms.map(&method(:build_room)) }
      end

      def build_room(rooms)
        child_ages = rooms.map(&:child_ages).inject(Array.new, :+)
        adult_count = rooms.map(&:adult_count).inject(0, :+)
        child_count = rooms.map(&:child_count).inject(0, :+)
        {
          RoomCount: rooms.size,
          Occupancy: {
            AdultCount: adult_count,
            ChildCount: child_count,
            GuestList: {
              Customer: (1..adult_count).map {
                { :@type => "AD" }
              } + (1..child_count).map { |i|
                { :@type => "CH", :Age => Integer(child_ages[i - 1]) }
              }
            }
          }
        }
      end
    end
  end
end
