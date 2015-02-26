require 'faraday_middleware'

module GoogleCivic
  # @private
  module Connection
    private

    def connection(options={})
      connection = Faraday.new(options.merge({:url => 'https://www.googleapis.com/civicinfo/v2/'})) do |builder|
        builder.request :json
        builder.request :url_encoded
        builder.response :logger
        builder.use FaradayMiddleware::Mashify
        builder.use FaradayMiddleware::ParseJson
        builder.adapter  Faraday.default_adapter
      end
      connection
    end
  end
end
