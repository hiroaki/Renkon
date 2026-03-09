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

    it 'renders top-level groups and subscriptions in mixed position order' do
      top_a = FactoryBot.create(:subscription, title: 'Top A', group: nil, position: 1)
      top_group = FactoryBot.create(:group, name: 'Top Group', parent: nil, position: 2)
      top_b = FactoryBot.create(:subscription, title: 'Top B', group: nil, position: 3)

      get subscriptions_path, params: { short: true }

      expect(response).to have_http_status(:ok)

      first_index = response.body.index("data-subscription=\"#{top_a.id}\"")
      group_index = response.body.index("data-group-id=\"#{top_group.id}\"")
      third_index = response.body.index("data-subscription=\"#{top_b.id}\"")

      expect(first_index).to be < group_index
      expect(group_index).to be < third_index
    end

      it 'renders subscriptions in nested child groups' do
        child_group = FactoryBot.create(:group, name: 'Child Group', parent: group, position: 1)
        nested_subscription = FactoryBot.create(:subscription, title: 'Nested', position: 1, group: child_group)

        get subscriptions_path, params: { short: true }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Child Group')
        expect(response.body).to include("data-subscription=\"#{nested_subscription.id}\"")
      end
  end
end
