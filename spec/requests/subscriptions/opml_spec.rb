require 'rails_helper'
require 'tempfile'

RSpec.describe 'Subscriptions OPML', type: :request do
  describe 'POST /subscriptions/opml_export_download' do
    let!(:root_group) { FactoryBot.create(:group, name: 'Tech', parent: nil, position: 1) }
    let!(:child_group) { FactoryBot.create(:group, name: 'Ruby', parent: root_group, position: 1) }
    let!(:top_subscription) { FactoryBot.create(:subscription, title: 'Top Feed', src: 'https://example.com/top.xml', group: nil, position: 1) }
    let!(:group_subscription) { FactoryBot.create(:subscription, title: 'Ruby Feed', src: 'https://example.com/ruby.xml', group: child_group, position: 1) }

    it 'exports all subscriptions with group outlines' do
      post opml_export_download_subscriptions_path, params: {
        scope: 'all',
        include_groups: '1',
      }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/xml')
      expect(response.body).to include('<opml version="2.0">')
      expect(response.body).to include('outline text="Tech"')
      expect(response.body).to include('outline text="Ruby"')
      expect(response.body).to include('xmlUrl="https://example.com/ruby.xml"')
      expect(response.body).to include('xmlUrl="https://example.com/top.xml"')
    end

    it 'exports only selected group subscriptions without top-level subscriptions' do
      post opml_export_download_subscriptions_path, params: {
        scope: 'selected',
        include_groups: '1',
        selected_item_type: 'group',
        selected_item_id: root_group.id,
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('outline text="Tech"')
      expect(response.body).to include('xmlUrl="https://example.com/ruby.xml"')
      expect(response.body).not_to include('xmlUrl="https://example.com/top.xml"')
    end

    it 'keeps export modal and shows error for invalid selected target' do
      post opml_export_download_subscriptions_path, params: {
        scope: 'selected',
        include_groups: '1',
        selected_item_type: 'group',
        selected_item_id: 999_999,
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Export OPML')
      expect(response.body).to include('Selected item was not found.')
    end
  end

  describe 'POST /subscriptions/opml_import_upload' do
    let!(:existing_subscription) do
      FactoryBot.create(:subscription, title: 'Existing Feed', src: 'https://example.com/existing.xml')
    end

    it 'imports new subscriptions and skips duplicates' do
      Tempfile.create(['subscriptions', '.opml']) do |file|
        file.write(<<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <opml version="2.0">
            <body>
              <outline text="News">
                <outline text="Existing Feed" type="rss" xmlUrl="https://example.com/existing.xml" />
                <outline text="New Feed" type="rss" xmlUrl="https://example.com/new.xml" htmlUrl="https://example.com/new" />
              </outline>
            </body>
          </opml>
        XML
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/xml')

        expect do
          post opml_import_upload_subscriptions_path,
            params: { file: uploaded_file },
            headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
        end.to change(Subscription, :count).by(1)
          .and change(Group, :count).by(1)
      end

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('turbo-stream')

      imported = Subscription.find_by(src: 'https://example.com/new.xml')
      expect(imported).to be_present
      expect(imported.group).to be_present
      expect(imported.group.name).to eq('News')
    end

    it 'returns unprocessable content for invalid xml' do
      Tempfile.create(['subscriptions', '.opml']) do |file|
        file.write('<opml><body><outline></body>')
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/xml')

        post opml_import_upload_subscriptions_path, params: { file: uploaded_file }
      end

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('could not be parsed')
    end

    it 'returns unprocessable content for oversized upload' do
      stub_const('Subscriptions::OpmlInputValidationService::DEFAULT_MAX_BYTES', 16)

      Tempfile.create(['subscriptions', '.opml']) do |file|
        file.write('<?xml version="1.0"?><opml><body>1234567890</body></opml>')
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/xml')

        post opml_import_upload_subscriptions_path, params: { file: uploaded_file }
      end

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('too large')
    end

    it 'returns unprocessable content for non-opml content' do
      Tempfile.create(['subscriptions', '.xml']) do |file|
        file.binmode
        file.write("\x00\x01\x02not-opml")
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'application/xml')

        post opml_import_upload_subscriptions_path, params: { file: uploaded_file }
      end

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('binary')
    end
  end
end
