require 'rails_helper'
require 'stringio'
require 'webmock/rspec'

include ActiveJob::TestHelper

describe DownloadSubscriptionFaviconJob, type: :job do
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:image_url) { 'https://example.com/favicon.ico' }
  let(:image_data) { "fake image data" }
  let(:content_type) { "image/x-icon" }

  # 成功時のレスポンススタブ
  before do
    stub_request(:get, image_url)
      .to_return(status: 200, body: image_data, headers: { 'Content-Type' => content_type })
  end

  it 'downloads and attaches the favicon to the subscription' do
    expect {
      described_class.perform_later(subscription, image_url)
    }.to have_enqueued_job(DownloadSubscriptionFaviconJob)

    perform_enqueued_jobs
    expect(subscription.favicon.attached?).to be true
    expect(subscription.favicon.blob.filename.to_s).to eq('favicon.ico')
    expect(subscription.favicon.blob.content_type).to be_in(['image/x-icon', 'image/vnd.microsoft.icon'])
  end

  context 'when the download fails' do
    shared_examples 'logs an error and does not attach favicon' do |status_code|
      before do
        stub_request(:get, image_url).to_return(status: status_code)
      end

      it "does not attach a favicon when the response is #{status_code}" do
        expect {
          described_class.perform_later(subscription, image_url)
        }.to have_enqueued_job(DownloadSubscriptionFaviconJob)

        perform_enqueued_jobs

        expect(subscription.favicon.attached?).to be false
      end

      it "logs an error when the response is #{status_code}" do
        expect_any_instance_of(Rails.logger.class).to receive(:error).with(/Failed to download for subscription/)

        described_class.perform_later(subscription, image_url)
        perform_enqueued_jobs
      end
    end

    include_examples 'logs an error and does not attach favicon', 404
    include_examples 'logs an error and does not attach favicon', 500
  end
end
