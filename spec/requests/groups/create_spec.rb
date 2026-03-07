require 'rails_helper'

RSpec.describe 'Groups create', type: :request do
  describe 'GET /groups/new' do
    it 'renders successfully' do
      get new_group_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('New group')
    end
  end

  describe 'POST /groups' do
    let!(:parent_group) { FactoryBot.create(:group, name: 'Parent') }

    it 'creates a group with parent' do
      expect do
        post groups_path, params: { group: { name: 'Child', parent_id: parent_group.id } }
      end.to change(Group, :count).by(1)

      expect(response).to have_http_status(:see_other)
      expect(Group.order(:id).last.parent_id).to eq(parent_group.id)
    end

    it 'returns unprocessable_entity when name is blank' do
      expect do
        post groups_path, params: { group: { name: '', parent_id: parent_group.id } }
      end.not_to change(Group, :count)

      expect(response).to have_http_status(422)
      expect(response.body).to include('Name can&#39;t be blank')
    end

    it 'returns turbo stream updates when created from modal frame' do
      post groups_path,
        params: { group: { name: 'From Modal', parent_id: parent_group.id } },
        headers: {
          'Turbo-Frame' => 'modal',
          'Accept' => 'text/vnd.turbo-stream.html',
        }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('turbo-stream action="replace" target="subscriptions"')
      expect(response.body).to include('turbo-stream action="update" target="modal"')
    end
  end
end
