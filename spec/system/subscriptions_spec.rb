require 'rails_helper'
require 'webmock/rspec'

RSpec.describe "Subscriptions", type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  # Subscription create flow
  describe 'Subscription create flow' do
    let!(:subscription) { FactoryBot.create(:subscription) }
    let!(:subscription_with_favicon) { FactoryBot.create(:subscription, :with_favicon) }

    before do
      visit root_path
    end

    context "when the creation succeeds" do
      it "creates a new subscription" do
        expect(page).to have_link("New subscription")
        click_link "New subscription"
        expect(page).to have_selector("turbo-frame#modal", wait: 5)

        fill_in "Title", with: "Test Subscription"
        fill_in "Src", with: "https://example.com/feed"
        click_button "Create Subscription"

        expect(page).to have_content("Subscription was successfully created.")
        click_button "Close"
        expect(page).to have_selector("turbo-frame#modal", text: "")
      end
    end

    context "when the creation fails" do
      it "shows an error message when title is blank" do
        expect(page).to have_link("New subscription")
        click_link "New subscription"
        expect(page).to have_selector("turbo-frame#modal", wait: 5)

        fill_in "Title", with: "" # Title を空にする
        fill_in "Src", with: "https://example.com/feed"
        click_button "Create Subscription"

        # モーダルが閉じていないことを確認
        expect(page).to have_selector("turbo-frame#modal")

        # エラーメッセージの確認
        expect(page).to have_content("Title can't be blank")
      end
    end

    context "when closing the modal" do
      it "closes the modal when clicking cancel" do
        click_link "New subscription"
        expect(page).to have_selector("turbo-frame#modal", wait: 5)
        click_button "Cancel"
        expect(page).to have_selector("turbo-frame#modal", text: "")
      end

      it "closes the modal when clicking outside" do
        click_link "New subscription"
        expect(page).to have_selector("turbo-frame#modal", wait: 5)
        find("div[data-controller='modal']").click
        expect(page).to have_selector("turbo-frame#modal", text: "")
      end
    end
  end

  # Subscription update flow
  describe 'Subscription update flow' do
    let!(:subscription) { FactoryBot.create(:subscription) }
    let!(:subscription_with_favicon) { FactoryBot.create(:subscription, :with_favicon) }

    before do
      visit root_path
    end

    context "when the update succeeds" do
      it 'can update a subscription from the modal' do
        find("li[data-subscription='#{subscription.id}']").click
        find('[data-pane-focus-target="linkEditSubscription"]').click

        expect(page).to have_selector("turbo-frame#modal", wait: 5)
        fill_in 'subscription_title', with: 'Updated Subscription Title'
        fill_in 'subscription_url', with: 'http://updated-url.com'
        click_button 'Update Subscription'

        expect(page).to have_content('Updated Subscription Title')
        expect(page).to have_content('http://updated-url.com')

        click_button "Close"
        expect(page).to have_selector("turbo-frame#modal", text: "")
      end

      it 'can remove the favicon when updating a subscription' do
        find("li[data-subscription='#{subscription_with_favicon.id}']").click
        find('[data-pane-focus-target="linkEditSubscription"]').click

        expect(page).to have_selector("turbo-frame#modal", wait: 5)
        fill_in 'subscription_title', with: 'Updated Subscription Title'
        fill_in 'subscription_url', with: 'http://updated-url.com'
        check 'Remove favicon'
        click_button 'Update Subscription'

        expect(page).to have_content('Updated Subscription Title')
        expect(page).to have_content('http://updated-url.com')
        expect(page).to have_selector('svg[data-default-favicon="true"]')

        click_button "Close"
        expect(page).to have_selector("turbo-frame#modal", text: "")
      end
    end

    context "when the update fails" do
      it "shows an error message when title is blank" do
        find("li[data-subscription='#{subscription.id}']").click
        find('[data-pane-focus-target="linkEditSubscription"]').click

        expect(page).to have_selector("turbo-frame#modal", wait: 5)

        fill_in "subscription_title", with: "" # Title を空にする
        click_button "Update Subscription"

        # モーダルが閉じていないことを確認
        expect(page).to have_selector("turbo-frame#modal")

        # エラーメッセージの確認
        expect(page).to have_content("Title can't be blank")
      end
    end
  end

  # Subscription update flow with fetch favicon
  describe 'Subscription update flow with fetch favicon' do
    let!(:subscription) { FactoryBot.create(:subscription, favicon: nil) }

    before do
      visit root_path
    end

    it 'fetches and displays the favicon when Fetch favicon is enabled' do
      controller_instance = nil
      allow_any_instance_of(SubscriptionsController).to receive(:fetch_favicon_and_update_for) do |instance, sub|
        controller_instance = instance
      end

      find("li[data-subscription='#{subscription.id}']").click
      find('[data-pane-focus-target="linkEditSubscription"]').click

      expect(page).to have_selector("turbo-frame#modal", wait: 5)
      check 'Fetch favicon'
      click_button 'Update Subscription'

      expect(controller_instance).to have_received(:fetch_favicon_and_update_for).with(subscription)

      click_button "Close"
      expect(page).to have_selector("turbo-frame#modal", text: "")
    end
  end

  # Unread count updates after fetching articles
  describe 'Unread count updates after fetching articles' do
    let!(:subscription_a) { FactoryBot.create(:subscription, :with_articles, number_of_articles: 2, unread: true, src: "https://example.com/feed_a.xml") }
    let!(:subscription_b) { FactoryBot.create(:subscription, :with_articles, number_of_articles: 2, unread: true, src: "https://example.com/feed_b.xml") }

    before do
      stub_request(:get, "https://example.com/feed_a.xml").to_return(
        body: <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <rss version="2.0">
            <channel>
              <title>Feed A</title>
              <link>https://example.com/feed_a.xml</link>
              <description>No new articles</description>
            </channel>
          </rss>
        XML
      )

      stub_request(:get, "https://example.com/feed_b.xml").to_return(
        body: <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <rss version="2.0">
            <channel>
              <title>Feed B</title>
              <link>https://example.com/feed_b.xml</link>
              <description>New articles</description>
              <item>
                <title>New Article 1</title>
                <link>https://example.com/new_article_1</link>
                <description>First new article</description>
              </item>
              <item>
                <title>New Article 2</title>
                <link>https://example.com/new_article_2</link>
                <description>Second new article</description>
              </item>
            </channel>
          </rss>
        XML
      )
    end

    it "updates unread counts after fetching new articles" do
      visit root_path

      expect(page).to have_selector("li[data-subscription='#{subscription_a.id}'] span[data-unread-count]", text: "2")
      expect(page).to have_selector("li[data-subscription='#{subscription_b.id}'] span[data-unread-count]", text: "2")

      click_button "Refresh"

      expect(page).to have_selector("li[data-subscription='#{subscription_a.id}'] span[data-unread-count]", text: "2")
      expect(page).to have_selector("li[data-subscription='#{subscription_b.id}'] span[data-unread-count]", text: "4")
    end
  end
end
