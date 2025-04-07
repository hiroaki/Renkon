require "rails_helper"

RSpec.describe "Content pane behavior", type: :system do
  let!(:subscription1) { FactoryBot.create(:subscription, title: "Subscription One") }
  let!(:subscription2) { FactoryBot.create(:subscription, title: "Subscription Two") }

  let!(:article1_s1) { FactoryBot.create(:article, subscription: subscription1, title: "Article 1 from S1", description: "Content 1") }
  let!(:article2_s1) { FactoryBot.create(:article, subscription: subscription1, title: "Article 2 from S1", description: "Content 2") }

  let!(:article1_s2) { FactoryBot.create(:article, subscription: subscription2, title: "Article 1 from S2", description: "Another Content") }
  let!(:article2_s2) { FactoryBot.create(:article, subscription: subscription2, title: "Article 2 from S2", description: "More Content") }

  before do
    driven_by(:cuprite_custom)
    visit root_path
  end

  it "clears the content pane when switching subscriptions" do
    find("li[data-subscription='#{subscription1.id}']").click
    expect(page).to have_content("Article 1 from S1")

    click_list_item_in_articles_pane('Article 1 from S1')
    expect(page).to have_selector("#contents-pane", text: "Content 1")

    find("li[data-subscription='#{subscription2.id}']").click
    expect(page).to have_selector("#contents-pane", text: "")
    within("#contents-pane") do
      expect(page).not_to have_text("Content 1")
    end
  end
end
