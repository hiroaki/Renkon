require 'rails_helper'

RSpec.describe 'Groups update', type: :request do
  describe 'GET /groups/:id/edit' do
    let!(:group) { FactoryBot.create(:group, name: 'Old Name') }

    it 'renders successfully' do
      get edit_group_path(group)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Editing group')
      expect(response.body).not_to include('Parent group')
    end
  end

  describe 'PATCH /groups/:id' do
    let!(:parent) { FactoryBot.create(:group, name: 'Parent') }
    let!(:other_parent) { FactoryBot.create(:group, name: 'Other Parent') }
    let!(:group) { FactoryBot.create(:group, name: 'Target', parent: parent) }

    it 'updates only group name' do
      patch group_path(group), params: { group: { name: 'Renamed', parent_id: other_parent.id } }

      expect(response).to have_http_status(:see_other)
      expect(group.reload.name).to eq('Renamed')
      expect(group.reload.parent_id).to eq(parent.id)
    end

    it 'returns turbo stream updates when edited from modal frame' do
      patch group_path(group),
        params: { group: { name: 'Renamed in Modal' } },
        headers: {
          'Turbo-Frame' => 'modal',
          'Accept' => 'text/vnd.turbo-stream.html',
        }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('turbo-stream action="replace" target="subscriptions"')
      expect(response.body).to include('turbo-stream action="update" target="modal"')
    end

    it 'returns unprocessable_entity when name is blank' do
      patch group_path(group), params: { group: { name: '' } }

      expect(response).to have_http_status(422)
      expect(response.body).to include("Name can&#39;t be blank")
    end
  end
end
