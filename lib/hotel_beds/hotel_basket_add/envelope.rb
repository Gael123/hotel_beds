require "hotel_beds/action/envelope"
require "hotel_beds/builder/hotel_occupancy"

module HotelBeds
  module HotelBasketAdd
    class Envelope < HotelBeds::Action::Envelope
      def attributes
        {
          Language: language,
          Service: {
            :"@xsi:type" => "ServiceHotel",
            :"@availToken" => service.availability_token,
            :ContractList => { Contract: {
              Name: service.contract_name,
              IncomingOffice: { :@code => service.contract_incoming_office_code }
            } },
            :DateFrom => { :@date => service.check_in_date.strftime("%Y%m%d") },
            :DateTo => { :@date => service.check_out_date.strftime("%Y%m%d") },
            :HotelInfo => {
              :"@xsi:type" => "ProductHotel",
              Code: service.hotel_code,
              Destination: {
                :@code => service.destination_code,
                :@type => "SIMPLE"
              }
            },
            :AvailableRoom => available_rooms
          }
        }
      end

      private
      def available_rooms
        Array(service.rooms).group_by(&:group_key).values.map do |rooms|
          {
            HotelOccupancy: build_room(rooms),
            HotelRoom: {
                :"@onRequest" => "N",

              Board: {
                :@code => rooms.first.board_code,
                :@type => "SIMPLE"
              },
              RoomType: {
                :@characteristic => rooms.first.room_type_characteristic,
                :@code => rooms.first.room_type_code,
                :@type => "SIMPLE"
              },
            }
          }
        end
      end

      def build_room(rooms)
        HotelBeds::Builder::HotelOccupancy.new(rooms).to_h
      end
    end
  end
end
