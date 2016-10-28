require 'google-civic/client'
require 'google-civic/error_on_retriable_response'

module GoogleCivic
  class << self
    # Alias for GoogleCivic::Client.new
    #
    # @return [GoogleCivic::Client]
    def new(options={})
      GoogleCivic::Client.new(options)
    end

    # Delegate to GoogleCivic::Client.new
    def method_missing(method, *args, &block)
      return super unless new.respond_to?(method)
      new.send(method, *args, &block)
    end

    def respond_to?(method, include_private=false)
      new.respond_to?(method, include_private) || super(method, include_private)
    end
  end
end
