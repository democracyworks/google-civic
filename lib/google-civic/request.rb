require 'multi_json'

module GoogleCivic
  module Request
    def get(path,params={},connection_opts={})
      response = connection(connection_opts).get do |request|
        request.url path
        params.each { |name, value| request.params[name] = value }
        request.params['key'] = @key
      end
      response.body
    end
  end
end
