require 'rails_helper'

RSpec.describe 'Subscriptions index', type: :request do
  describe 'GET /subscriptions' do
    let!(:group) { FactoryBot.create(:group, name: 'Main Group') }

    it 'renders subscriptions in position order' do
      first = FactoryBot.create(:subscription, title: 'First', position: 10, group: group)
      second = FactoryBot.create(:subscription, title: 'Second', position: 20, group: group)
      third = FactoryBot.create(:subscription, title: 'Third', position: 30, group: group)

      get subscriptions_path, params: { short: true }

      expect(response).to have_http_status(:ok)

      rendered_ids = response.body.scan(/data-subscription="(\d+)"/).flatten.map(&:to_i)
      expect(rendered_ids).to eq([first.id, second.id, third.id])
    end

    it 'uses id as a tie-breaker when position is equal' do
      older = FactoryBot.create(:subscription, title: 'Older', position: 1, group: group)
      newer = FactoryBot.create(:subscription, title: 'Newer', position: 1, group: group)

      get subscriptions_path, params: { short: true }

      expect(response).to have_http_status(:ok)

      rendered_ids = response.body.scan(/data-subscription="(\d+)"/).flatten.map(&:to_i)
      expect(rendered_ids).to eq([older.id, newer.id])
    end

    it 'renders group headers' do
      FactoryBot.create(:subscription, title: 'In Group', position: 1, group: group)

      get subscriptions_path, params: { short: true }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Main Group')
    end
  end
end
