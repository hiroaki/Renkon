require 'rails_helper'

RSpec.describe 'Subscriptions update', type: :request do
  describe 'PATCH /subscriptions/:id' do
    let(:base_params) do
      {
        subscription: {
          title: subscription.title,
          src: subscription.src,
          description: subscription.description,
          last_build_date: subscription.last_build_date,
          url: subscription.url,
        },
      }
    end

    context 'when favicon is attached' do
      let!(:subscription) { FactoryBot.create(:subscription, :with_favicon) }

      it 'prefers fetching favicon over removing favicon when both options are enabled' do
        expect_any_instance_of(SubscriptionsController).to receive(:fetch_favicon_and_update_for).with(subscription)
        expect_any_instance_of(ActiveStorage::Attached::One).not_to receive(:purge_later)

        patch subscription_path(subscription), params: base_params.deep_merge(
          subscription: {
            remove_favicon: '1',
            fetch_favicon: '1',
          },
        )

        expect(response).to have_http_status(:see_other)
      end

      it 'does not purge favicon even when fetch processing raises an error' do
        allow_any_instance_of(SubscriptionsController)
          .to receive(:fetch_favicon_and_update_for)
          .with(subscription)
          .and_raise(StandardError, 'fetch failed')

        expect_any_instance_of(ActiveStorage::Attached::One).not_to receive(:purge_later)

        expect {
          patch subscription_path(subscription), params: base_params.deep_merge(
            subscription: {
              remove_favicon: '1',
              fetch_favicon: '1',
            },
          )
        }.to raise_error(StandardError, 'fetch failed')
      end
    end

    context 'when favicon is not attached' do
      let!(:subscription) { FactoryBot.create(:subscription, favicon: nil) }

      it 'does not try to purge when remove_favicon is enabled' do
        expect_any_instance_of(ActiveStorage::Attached::One).not_to receive(:purge_later)

        patch subscription_path(subscription), params: base_params.deep_merge(
          subscription: {
            remove_favicon: '1',
            fetch_favicon: '0',
          },
        )

        expect(response).to have_http_status(:see_other)
      end
    end
  end
end
