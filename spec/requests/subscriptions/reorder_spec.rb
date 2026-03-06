require 'rails_helper'

RSpec.describe 'Subscriptions reorder', type: :request do
  describe 'PATCH /subscriptions/reorder' do
    let!(:first) { FactoryBot.create(:subscription, position: 1) }
    let!(:second) { FactoryBot.create(:subscription, position: 2) }
    let!(:third) { FactoryBot.create(:subscription, position: 3) }

    it 'returns unprocessable_entity when ordered_ids is missing' do
      patch reorder_subscriptions_path, params: {}

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('ordered_ids must be an array')
    end

    it 'returns unprocessable_entity when ordered_ids has duplicates' do
      patch reorder_subscriptions_path, params: { ordered_ids: [first.id, first.id, third.id] }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('duplicates')
    end

    it 'returns unprocessable_entity when ordered_ids does not cover all subscriptions' do
      patch reorder_subscriptions_path, params: { ordered_ids: [first.id, second.id] }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('every existing subscription id exactly once')
    end

    it 'updates positions in the specified order' do
      patch reorder_subscriptions_path, params: { ordered_ids: [third.id, first.id, second.id] }

      expect(response).to have_http_status(:no_content)
      expect(Subscription.ordered.pluck(:id)).to eq([third.id, first.id, second.id])
      expect(third.reload.position).to eq(1)
      expect(first.reload.position).to eq(2)
      expect(second.reload.position).to eq(3)
    end
  end
end
