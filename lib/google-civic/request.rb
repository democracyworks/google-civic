require 'multi_json'

module GoogleCivic
  module Request
    def get(path,params={})
      response = connection.get do |request|
        request.url path
        params.each { |name, value| request.params[name] = value }
        request.params['key'] = @key
      end
      response.body
    end
  end
end
