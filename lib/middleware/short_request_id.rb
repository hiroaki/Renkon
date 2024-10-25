# FOR DEVELOPMENT ENVIRONMENT ONLY
module Middleware
  class ShortRequestId
    def initialize(app)
      @app = app
    end

    def call(env)
      env['X_SHORT_REQUEST_ID'] = SecureRandom.hex(4)
      @app.call(env)
    end
  end
end
