require 'rails_helper'

RSpec.describe 'Subscriptions reorder', type: :request do
  describe 'PATCH /subscriptions/reorder' do
    let!(:group) { FactoryBot.create(:group, name: 'Main') }
    let!(:first) { FactoryBot.create(:subscription, group: group, position: 1) }
    let!(:second) { FactoryBot.create(:subscription, group: group, position: 2) }
    let!(:third) { FactoryBot.create(:subscription, group: group, position: 3) }

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

    it 'returns unprocessable_entity when group_id is invalid' do
      patch reorder_subscriptions_path, params: { group_id: -1, ordered_ids: [first.id, second.id, third.id] }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('group_id is invalid')
    end

    it 'reorders only subscriptions in the specified group' do
      other_group = FactoryBot.create(:group, name: 'Other')
      outsider = FactoryBot.create(:subscription, group: other_group, position: 1)

      patch reorder_subscriptions_path, params: {
        group_id: group.id,
        ordered_ids: [second.id, third.id, first.id],
      }

      expect(response).to have_http_status(:no_content)
      expect(Subscription.ordered_within_group(group.id).pluck(:id)).to eq([second.id, third.id, first.id])
      expect(outsider.reload.position).to eq(1)
    end

    it 'moves subscriptions across groups with grouped_orders payload' do
      other_group = FactoryBot.create(:group, name: 'Other')
      outsider = FactoryBot.create(:subscription, group: other_group, position: 1)

      patch reorder_subscriptions_path, params: {
        grouped_orders: [
          { group_id: group.id, ordered_ids: [second.id] },
          { group_id: other_group.id, ordered_ids: [outsider.id, third.id, first.id] },
        ],
      }

      expect(response).to have_http_status(:no_content)
      expect(Subscription.ordered_within_group(group.id).pluck(:id)).to eq([second.id])
      expect(Subscription.ordered_within_group(other_group.id).pluck(:id)).to eq([outsider.id, third.id, first.id])
      expect(first.reload.group_id).to eq(other_group.id)
      expect(first.reload.position).to eq(3)
    end

    it 'returns unprocessable_entity when grouped_orders has duplicate ids' do
      patch reorder_subscriptions_path, params: {
        grouped_orders: [
          { group_id: group.id, ordered_ids: [first.id, first.id, second.id, third.id] },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('duplicates')
    end

    it 'moves subscriptions into a nested child group' do
      child_group = FactoryBot.create(:group, name: 'Child', parent: group, position: 1)
      child_subscription = FactoryBot.create(:subscription, group: child_group, position: 1)

      patch reorder_subscriptions_path, params: {
        grouped_orders: [
          { group_id: group.id, ordered_ids: [third.id] },
          { group_id: child_group.id, ordered_ids: [child_subscription.id, first.id, second.id] },
        ],
      }

      expect(response).to have_http_status(:no_content)
      expect(Subscription.ordered_within_group(group.id).pluck(:id)).to eq([third.id])
      expect(Subscription.ordered_within_group(child_group.id).pluck(:id)).to eq([child_subscription.id, first.id, second.id])
      expect(first.reload.group_id).to eq(child_group.id)
      expect(first.reload.position).to eq(2)
    end
  end
end
