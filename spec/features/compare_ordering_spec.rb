require "hotel_beds"
require "securerandom"

RSpec.describe "ordering a hotel room" do
  describe "#response" do
    before(:all) do
      @client = HotelBeds::Client.new({
        endpoint: :test,
        username: ENV.fetch("HOTEL_BEDS_USERNAME"),
        password: ENV.fetch("HOTEL_BEDS_PASSWORD"),
        proxy: ENV.fetch("HOTEL_BEDS_PROXY", nil),
        :enable_logging => true
      })
      @check_in_date = Date.new(2015, 03, 13)
      @check_out_date = Date.new(2015, 03, 15)
      @search_operation = @client.perform_hotel_search({
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        rooms: [{ adult_count: 1 }],
        hotel_codes: ["115929"],
        destination_code: "PVG"
      })
      if @search_operation.errors.any?
        raise StandardError, @search_operation.errors.full_messages.join("\n")
      end
      @search_response = @search_operation.response

      f = File.open("comelive_2-HotelValuedAvailRS.xml", "w")
      f.write(@search_response.body)
      f.close

      hotel = @search_response.hotels.first
      rooms = hotel.available_rooms.first

      @basket_operation = @client.add_hotel_room_to_basket({
        service: {
          check_in_date: @check_in_date,
          check_out_date: @check_out_date,
          availability_token: hotel.availability_token,
          hotel_code: hotel.code,
          destination_code: hotel.destination.code,
          contract_name: hotel.contract.name,
          contract_incoming_office_code: hotel.contract.incoming_office_code,
          rooms: rooms
        }
      })
      if @basket_operation.errors.any?
        raise StandardError, @basket_operation.errors.full_messages.join("\n")
      end
      @basket_response = @basket_operation.response

      f = File.open("comelive_4-ServiceAddRS.xml", "w")
      f.write(@basket_response.body)
      f.close






      @agency_reference = "AgentUnqiueNumber"
      @checkout_operation = @client.confirm_purchase({
        purchase: {
          agency_reference: @agency_reference,
          token: @basket_response.purchase.token,
          holder: {
            id: "1",
            type: :adult,
            name: "TestA",
            last_name: "TestA",
            age: "30"
          },
          services: @basket_response.purchase.services.map { |service|
            {
              id: service.id,
              type: service.type,
              customers: [
                { id: "1", type: :adult, name: "TestA", last_name: "TestA", age: "30" }
            #,{ id: "2", type: :adult, name: "Jane", last_name: "Smith", age: "40" }
              ]
            }
          }
        }
      })

      @checkout_response = @checkout_operation.response
      f = File.open("comelive_6-PurchaseConfirmRS.xml", "w")
      f.write(@basket_response.body)
      f.close

      if @checkout_operation.errors.any?
        @flush_operation = @client.flush_purchase({
          purchase_token: @basket_response.purchase.token
        })
        if @flush_operation.errors.any?
          raise StandardError, @flush_operation.errors.full_messages.join("\n")
        end

        raise StandardError, @checkout_operation.errors.full_messages.join("\n")
      end
      @checkout_response = @checkout_operation.response
    end

    describe "basket response" do
      let(:response) { @basket_response }

      subject { response }

      it "should be a success" do
        expect(subject).to be_success
      end

      describe "#purchase" do
        subject { response.purchase }

        it "should have a service" do
          expect(subject.services).to_not be_empty
        end
      end

      describe "#purchase.services" do
        subject { response.purchase.services }

        it "should alway have a contract" do
          subject.each do |service|
            expect(service.contract).to_not be_nil
          end
        end
      end

      describe "#purchase.services.available_rooms" do
        subject do
          response.purchase.services.map(&:available_rooms).inject(Array.new, :+)
        end

        it "should have a cancellation policy" do
          subject.each do |room|
            expect(room.cancellation_policies).to_not be_empty
          end
        end
      end
    end

    describe "checkout response" do
      let(:response) { @checkout_response }

      subject { response }

      it "should be a success" do
        expect(subject).to be_success
      end

      describe "#purchase" do
        subject { response.purchase }

        it "should have a reference" do
          expect(subject.reference).to_not be_nil
          expect(subject.reference.file_number).to_not be_empty
        end

        it "should have a service" do
          expect(subject.services).to_not be_empty
        end

        it "should have a agency reference" do
          expect(subject.agency_reference).to eq(@agency_reference)
        end
      end
    end
  end
end
