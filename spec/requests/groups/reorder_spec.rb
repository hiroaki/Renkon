require 'rails_helper'

RSpec.describe 'Groups reorder', type: :request do
  describe 'PATCH /groups/reorder' do
    let!(:root) { FactoryBot.create(:group, name: 'Root', parent: nil, position: 1) }
    let!(:child_a) { FactoryBot.create(:group, name: 'Child A', parent: root, position: 1) }
    let!(:child_b) { FactoryBot.create(:group, name: 'Child B', parent: root, position: 2) }

    it 'returns unprocessable_entity when group_nodes is missing' do
      patch reorder_groups_path, params: {}

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('group_nodes must be an array')
    end

    it 'returns unprocessable_entity when ids are duplicated' do
      patch reorder_groups_path, params: {
        group_nodes: [
          { id: root.id, parent_id: nil, position: 1 },
          { id: child_a.id, parent_id: root.id, position: 1 },
          { id: child_a.id, parent_id: root.id, position: 2 },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('group id is invalid')
    end

    it 'returns unprocessable_entity when parent_id is invalid' do
      patch reorder_groups_path, params: {
        group_nodes: [
          { id: root.id, parent_id: nil, position: 1 },
          { id: child_a.id, parent_id: 999_999, position: 1 },
          { id: child_b.id, parent_id: root.id, position: 2 },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('parent_id is invalid')
    end

    it 'returns unprocessable_entity when hierarchy contains a cycle' do
      patch reorder_groups_path, params: {
        group_nodes: [
          { id: root.id, parent_id: child_a.id, position: 1 },
          { id: child_a.id, parent_id: root.id, position: 1 },
          { id: child_b.id, parent_id: root.id, position: 2 },
        ],
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['error']).to include('cycles')
    end

    it 'updates group parents and positions' do
      patch reorder_groups_path, params: {
        group_nodes: [
          { id: root.id, parent_id: nil, position: 1 },
          { id: child_a.id, parent_id: root.id, position: 2 },
          { id: child_b.id, parent_id: child_a.id, position: 1 },
        ],
      }

      expect(response).to have_http_status(:no_content)
      expect(child_a.reload.position).to eq(2)
      expect(child_b.reload.parent_id).to eq(child_a.id)
      expect(child_b.reload.position).to eq(1)
    end
  end
end
