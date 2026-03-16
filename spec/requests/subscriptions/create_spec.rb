require 'rails_helper'

RSpec.describe 'Subscriptions create', type: :request do
  describe 'POST /subscriptions' do
    let(:attrs) do
      {
        title: 'New Subscription',
        src: 'http://example.com/new.xml',
        description: '',
        last_build_date: nil,
        url: 'http://example.com',
      }
    end

    it 'inserts after selected subscription when context is subscription' do
      group = FactoryBot.create(:group, name: 'Parent Group', parent: nil, position: 1)
      first = FactoryBot.create(:subscription, group: group, position: 1)
      trailing_group = FactoryBot.create(:group, name: 'Trailing Group', parent: group, position: 2)
      trailing_subscription = FactoryBot.create(:subscription, group: group, position: 3)

      post subscriptions_path, params: {
        subscription: attrs,
        insert_context_type: 'subscription',
        insert_context_id: first.id,
      }

      expect(response).to have_http_status(:found)
      created = Subscription.order(:id).last
      expect(created.group_id).to eq(group.id)
      expect(created.position).to eq(2)
      expect(trailing_group.reload.position).to eq(3)
      expect(trailing_subscription.reload.position).to eq(4)
    end

    it 'appends at selected group end when context is group' do
      group = FactoryBot.create(:group, name: 'Target Group', parent: nil, position: 1)
      FactoryBot.create(:group, name: 'Child Group', parent: group, position: 1)
      FactoryBot.create(:subscription, group: group, position: 2)

      post subscriptions_path, params: {
        subscription: attrs,
        insert_context_type: 'group',
        insert_context_id: group.id,
      }

      expect(response).to have_http_status(:found)
      created = Subscription.order(:id).last
      expect(created.group_id).to eq(group.id)
      expect(created.position).to eq(3)
    end

    it 'appends at top-level end when no context is specified' do
      FactoryBot.create(:group, name: 'Top Group', parent: nil, position: 2)
      FactoryBot.create(:subscription, group: nil, position: 4)

      post subscriptions_path, params: { subscription: attrs }

      expect(response).to have_http_status(:found)
      created = Subscription.order(:id).last
      expect(created.group_id).to be_nil
      expect(created.position).to eq(5)
    end

    it 'returns modal close and create-flow turbo streams when created from modal frame' do
      post subscriptions_path,
        params: { subscription: attrs },
        headers: {
          'Turbo-Frame' => 'modal',
          'Accept' => 'text/vnd.turbo-stream.html',
        }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('turbo-stream action="replace" target="subscriptions"')
      expect(response.body).to include('turbo-stream action="update" target="subscription-create-flow-hook"')
      expect(response.body).to include('turbo-stream action="update" target="modal"')
    end
  end
end
