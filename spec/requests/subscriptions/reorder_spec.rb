require 'rails_helper'

RSpec.describe 'Subscriptions reorder', type: :request do
  describe 'PATCH /subscriptions/reorder_tree' do
    let!(:group) { FactoryBot.create(:group, name: 'Main') }
    let!(:first) { FactoryBot.create(:subscription, group: group, position: 1) }
    let!(:second) { FactoryBot.create(:subscription, group: group, position: 2) }
    let!(:third) { FactoryBot.create(:subscription, group: group, position: 3) }

    it 'returns unprocessable_content when tree_nodes is missing' do
      patch reorder_tree_subscriptions_path, params: {}

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('tree_nodes must be an array')
    end

    it 'returns unprocessable_content when subscription ids have duplicates' do
      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: group.id, position: 2 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 3 },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('id is invalid')
    end

    it 'updates positions in mixed order with groups and subscriptions' do
      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: group.id, position: 2 },
          { item_type: 'subscription', id: second.id, parent_group_id: group.id, position: 3 },
        ],
      }

      expect(response).to have_http_status(:no_content)
      expect(Subscription.ordered_within_group(group.id).pluck(:id)).to eq([third.id, first.id, second.id])
    end

    it 'moves subscriptions across groups with tree_nodes payload' do
      other_group = FactoryBot.create(:group, name: 'Other')
      outsider = FactoryBot.create(:subscription, group: other_group, position: 1)

      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'group', id: other_group.id, parent_group_id: nil, position: 2 },
          { item_type: 'subscription', id: second.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 2 },
          { item_type: 'subscription', id: outsider.id, parent_group_id: other_group.id, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: other_group.id, position: 2 },
        ],
      }

      expect(response).to have_http_status(:no_content)
      expect(Subscription.ordered_within_group(group.id).pluck(:id)).to eq([second.id, third.id])
      expect(Subscription.ordered_within_group(other_group.id).pluck(:id)).to eq([outsider.id, first.id])
      expect(first.reload.group_id).to eq(other_group.id)
    end

    it 'returns unprocessable_content when parent_group_id is invalid' do
      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: 999_999, position: 1 },
          { item_type: 'subscription', id: second.id, parent_group_id: group.id, position: 2 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 3 },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('parent_group_id is invalid')
    end

    it 'moves a subscription to top-level' do
      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: nil, position: 2 },
          { item_type: 'subscription', id: second.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 2 },
        ],
      }

      expect(response).to have_http_status(:no_content)
      expect(first.reload.group_id).to be_nil
      expect(first.reload.position).to eq(2)
      expect(Subscription.ordered_within_group(group.id).pluck(:id)).to eq([second.id, third.id])
    end

    it 'updates group parent hierarchy through the same payload' do
      parent = FactoryBot.create(:group, name: 'Parent', parent: nil, position: 2)
      child = FactoryBot.create(:group, name: 'Child', parent: nil, position: 3)
      outsider = FactoryBot.create(:subscription, group: parent, position: 1)

      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'group', id: parent.id, parent_group_id: nil, position: 2 },
          { item_type: 'group', id: child.id, parent_group_id: parent.id, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: second.id, parent_group_id: group.id, position: 2 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 3 },
          { item_type: 'subscription', id: outsider.id, parent_group_id: parent.id, position: 2 },
        ],
      }

      expect(response).to have_http_status(:no_content)
      expect(child.reload.parent_id).to eq(parent.id)
      expect(child.reload.position).to eq(1)
    end

    it 'returns unprocessable_content when group hierarchy contains cycles' do
      parent = FactoryBot.create(:group, name: 'Parent', parent: nil, position: 2)
      child = FactoryBot.create(:group, name: 'Child', parent: parent, position: 1)
      outsider = FactoryBot.create(:subscription, group: parent, position: 1)

      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'group', id: parent.id, parent_group_id: child.id, position: 1 },
          { item_type: 'group', id: child.id, parent_group_id: parent.id, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: second.id, parent_group_id: group.id, position: 2 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 3 },
          { item_type: 'subscription', id: outsider.id, parent_group_id: parent.id, position: 2 },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('cycles')
    end

    it 'returns unprocessable_content when sibling positions are duplicated across mixed items' do
      patch reorder_tree_subscriptions_path, params: {
        tree_nodes: [
          { item_type: 'group', id: group.id, parent_group_id: nil, position: 1 },
          { item_type: 'subscription', id: first.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: second.id, parent_group_id: group.id, position: 1 },
          { item_type: 'subscription', id: third.id, parent_group_id: group.id, position: 3 },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('position must be unique')
    end
  end
end
