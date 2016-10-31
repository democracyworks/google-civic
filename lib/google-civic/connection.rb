require 'faraday_middleware'

module GoogleCivic
  # @private
  module Connection
    private

    def setup_retry(options)
      retry_options = options.delete(:retry) {|_| {}}
      unless retry_options.empty?
        retry_options[:exceptions] = [GoogleCivic::RetriableError]
      end
      retry_options
    end

    def connection(options={})
      retry_options = setup_retry(options)
      using_retry = !retry_options.empty?
      connection = Faraday.new(options.merge({:url => 'https://www.googleapis.com/civicinfo/v2/'})) do |builder|
        builder.request :json
        builder.request :url_encoded
        builder.use GoogleCivic::RetriesExhausted if using_retry
        builder.request(:retry, retry_options) if using_retry
        builder.response :logger
        builder.use FaradayMiddleware::Mashify
        builder.use FaradayMiddleware::ParseJson
        builder.use GoogleCivic::ErrorOnRetriableResponse if using_retry
        builder.adapter  Faraday.default_adapter
      end
      connection
    end
  end
end
