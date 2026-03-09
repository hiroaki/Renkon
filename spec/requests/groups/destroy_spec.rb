require 'rails_helper'

RSpec.describe 'Groups destroy', type: :request do
  describe 'DELETE /groups/:id' do
    let!(:root) { FactoryBot.create(:group, name: 'Root', position: 1) }
    let!(:child) { FactoryBot.create(:group, name: 'Child', parent: root, position: 1) }
    let!(:root_subscription) { FactoryBot.create(:subscription, group: root, position: 1) }
    let!(:child_subscription) { FactoryBot.create(:subscription, group: child, position: 1) }

    before do
      FactoryBot.create(:article, subscription: root_subscription)
      FactoryBot.create(:article, subscription: child_subscription)
    end

    it 'deletes the selected group with nested groups, subscriptions, and articles' do
      expect do
        delete group_path(root), headers: { 'X-Requested-With' => 'XMLHttpRequest' }
      end.to change(Group, :count).by(-2)
        .and change(Subscription, :count).by(-2)
        .and change(Article, :count).by(-2)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns turbo stream updates when destroyed from modal frame' do
      delete group_path(root), headers: {
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
