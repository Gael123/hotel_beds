require "savon"

module HotelBeds
  class Connection
    attr_accessor :client, :configuration
    private :client, :client=, :configuration=

    def initialize(configuration)
      self.configuration = configuration
      self.client = initialize_client
      freeze
    end

    def perform(operation)
      message = operation.message
      message[operation.namespace] = message.fetch(operation.namespace).merge({
        :@xmlns => "http://www.hotelbeds.com/schemas/2005/06/messages",
        :"@xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        :"@xsi:schemaLocation" => "http://www.hotelbeds.com/schemas/2005/06/messages #{operation.namespace}.xsd",
        :@echoToken => operation.echo_token,
        :@sessionId => operation.session_id,
        :Credentials => {
          User: configuration.username,
          Password: configuration.password
        }
      })
      # send the call
      response = client.call(operation.method, {
        soap_action: "",
        attributes: {
          :"xmlns:hb" => "http://axis.frontend.hydra.hotelbeds.com",
          :"xsi:type" => "xsd:string",
        },
        message: message
      })
      # parse the response
      operation.parse_response(response)
    end
    
    private
    def initialize_client
      Savon::Client.new do |config|
        # http requests
        config.endpoint(configuration.endpoint)
        config.proxy(configuration.proxy) if configuration.proxy?
        config.headers "Accept-Encoding" => "gzip, deflate"

        # soap specifics
        config.env_namespace :soapenv
        config.namespace "http://schemas.xmlsoap.org/soap/envelope/"
        config.namespaces({
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "soapenv:encodingStyle" => "http://schemas.xmlsoap.org/soap/encoding/"
        })
        config.namespace_identifier :hb
        config.convert_request_keys_to :none

        # request timeout
        config.open_timeout(configuration.request_timeout)
        config.read_timeout(configuration.response_timeout)

        # request building
        config.encoding "UTF-8"

        # logging
        if configuration.enable_logging?
          config.log true
          config.log_level :debug
          config.pretty_print_xml true
          config.filters [:password]
        end
      end
    end
  end
end