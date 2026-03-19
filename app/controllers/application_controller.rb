class ApplicationController < ActionController::Base
  before_action :http_basic_authenticate, if: :enabled_basic_authenticate?

  protected

  def http_basic_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      auth_pairs.any? do |user, pswd|
        secure_eq(username, user) & secure_eq(password, pswd)
      end
    end
  end

  def enabled_basic_authenticate?
    !!ActiveModel::Type::Boolean.new.cast(ENV['ENABLED_BASIC_AUTH'])
  end

  def auth_pairs
    ENV['BASIC_AUTH_PAIRS'].to_s.split(',').map do |pair|
      pair.split(':', 2)
    end
  end

  def secure_eq(string_a, string_b)
    Rack::Utils.secure_compare(
      Digest::SHA256.hexdigest(string_a),
      Digest::SHA256.hexdigest(string_b)
    )
  end
end
