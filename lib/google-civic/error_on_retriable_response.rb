module GoogleCivic

  class RetriableError < Exception
    attr_reader :env, :response

    def initialize(env)
      @env = env
    end
  end

  class ErrorOnRetriableResponse < Faraday::Middleware

    SERVER_ERROR_CODES = (500...600)

    TEMPORARY_REASONS = Set.new(["concurrentLimitExceeded", "rateLimitExceeded",
                                 "servingLimitExceeded", "userRateLimitExceeded"])

    def initialize(app)
      super(app)
    end

    def call(env)
      response = @app.call(env)
      response.on_complete do |response_env|
        if retriable_error?(response)
          raise GoogleCivic::RetriableError.new(response_env)
        end
      end
    end

    def retriable_error?(response)
      server_error?(response.status) or
      temporary_rate_limit?(response)
    end

    def server_error?(status)
      SERVER_ERROR_CODES.include? status
    end

    def temporary_rate_limit?(response)
      if response.status == 403
        body = ::Hashie::Mash.new(::JSON.parse(response.body))
        if body.error? && body.error.errors?
          reasons = Set.new body.error.errors.collect(&:reason)
          TEMPORARY_REASONS.superset?(reasons)
        else
          false
        end
      else
        false
      end
    end
  end

  class RetriesExhausted < Faraday::Middleware

    dependency do
      require 'json' unless defined?(::JSON)
      require 'hashie/mash'
    end

    def initialize(app)
      super(app)
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue GoogleCivic::RetriableError => err
        response = ::Hashie::Mash.new({status: err.env.status, headers: err.env.response_headers,
                                       body: ::JSON.parse(err.env.body)})
      end
      response
    end
  end
end