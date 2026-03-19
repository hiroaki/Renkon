require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  let(:ban_cache_key) { 'rack::attack:ban:127.0.0.1' }

  around do |example|
    original_enabled = Rack::Attack.enabled
    original_store = Rack::Attack.cache.store
    test_store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.enabled = true
    Rack::Attack.cache.store = test_store

    example.run
  ensure
    test_store.clear
    Rack::Attack.cache.store = original_store
    Rack::Attack.enabled = original_enabled
  end

  it 'returns 429 on throttle and while the ban is active' do
    throttle = Rack::Attack.throttles.fetch('req/ip')
    throttle_limit = throttle.limit
    throttle_period = throttle.period

    throttle_limit.times do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end

    get rails_health_check_path

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers['Retry-After']).to eq(throttle_period.to_s)
    expect(response.headers['X-Rack-Attack-Match-Type']).to be_nil
    expect(response.headers['X-Rack-Attack-Match-Name']).to be_nil
    expect(JSON.parse(response.body)).to eq(
      'error' => 'throttled',
      'message' => 'Too many requests'
    )
    expect(Rack::Attack.cache.store.read(ban_cache_key)).to eq('1')

    get rails_health_check_path

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers['Retry-After']).to eq('600')
    expect(response.headers['X-Rack-Attack-Match-Type']).to be_nil
    expect(response.headers['X-Rack-Attack-Match-Name']).to be_nil
    expect(JSON.parse(response.body)).to eq(
      'error' => 'blocked',
      'message' => 'Too many requests'
    )
  end
end