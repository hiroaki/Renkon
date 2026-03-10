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
      expected_position = [
        Group.where(parent_id: parent_group.id).maximum(:position) || 0,
        Subscription.where(group_id: parent_group.id).maximum(:position) || 0,
      ].max + 1

      expect do
        post groups_path, params: { group: { name: 'Child', parent_id: parent_group.id } }
      end.to change(Group, :count).by(1)

      expect(response).to have_http_status(:see_other)
      created = Group.order(:id).last
      expect(created.parent_id).to eq(parent_group.id)
      expect(created.position).to eq(expected_position)
    end

    it 'returns unprocessable_content when name is blank' do
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

    it 'inserts after selected subscription when context is subscription' do
      parent = FactoryBot.create(:group, name: 'Parent', parent: nil, position: 1)
      anchor = FactoryBot.create(:subscription, group: parent, position: 1)
      trailing_group = FactoryBot.create(:group, name: 'Trailing Group', parent: parent, position: 2)
      trailing_subscription = FactoryBot.create(:subscription, group: parent, position: 3)

      post groups_path, params: {
        group: { name: 'Inserted Group', parent_id: nil },
        insert_context_type: 'subscription',
        insert_context_id: anchor.id,
      }

      expect(response).to have_http_status(:see_other)
      created = Group.order(:id).last
      expect(created.parent_id).to eq(parent.id)
      expect(created.position).to eq(2)
      expect(trailing_group.reload.position).to eq(3)
      expect(trailing_subscription.reload.position).to eq(4)
    end

    it 'appends inside selected group when context is group' do
      parent = FactoryBot.create(:group, name: 'Parent', parent: nil, position: 1)
      FactoryBot.create(:group, name: 'Child A', parent: parent, position: 1)
      FactoryBot.create(:subscription, group: parent, position: 2)

      post groups_path, params: {
        group: { name: 'Appended Child', parent_id: nil },
        insert_context_type: 'group',
        insert_context_id: parent.id,
      }

      expect(response).to have_http_status(:see_other)
      created = Group.order(:id).last
      expect(created.parent_id).to eq(parent.id)
      expect(created.position).to eq(3)
    end

    it 'appends at top-level end when no context is given' do
      FactoryBot.create(:group, name: 'Top A', parent: nil, position: 2)
      FactoryBot.create(:subscription, group: nil, position: 4)

      expected_position = [
        Group.where(parent_id: nil).maximum(:position) || 0,
        Subscription.where(group_id: nil).maximum(:position) || 0,
      ].max + 1

      post groups_path, params: { group: { name: 'Top Tail', parent_id: nil } }

      expect(response).to have_http_status(:see_other)
      created = Group.order(:id).last
      expect(created.parent_id).to be_nil
      expect(created.position).to eq(expected_position)
    end

  end
end
