require 'rails_helper'

RSpec.describe 'Shift + Arrow selection in articles list', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'expands and shrinks selection range, then applies r shortcut to selected range' do
    subscription = FactoryBot.create(:subscription, title: 'Shift Arrow Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Shift Arrow Article 1', unread: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Shift Arrow Article 2', unread: true)
    article3 = FactoryBot.create(:article, subscription: subscription, title: 'Shift Arrow Article 3', unread: true)

    visit root_path
    click_list_item_in_subscriptions_pane('Shift Arrow Subscription')
    click_list_item_in_articles_pane('Shift Arrow Article 1')

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        if (!article1) return;

        const event = new KeyboardEvent('keydown', {
          key: 'ArrowDown',
          bubbles: true,
          shiftKey: true,
        });

        article1.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-selected='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-selected='true']")
    expect(page).to have_no_selector("li[data-article-id='#{article3.id}'][data-selected='true']")

    page.execute_script(<<~JS)
      (() => {
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");
        if (!article2) return;

        const event = new KeyboardEvent('keydown', {
          key: 'ArrowDown',
          bubbles: true,
          shiftKey: true,
        });

        article2.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-selected='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-selected='true']")
    expect(page).to have_selector("li[data-article-id='#{article3.id}'][data-selected='true']")

    page.execute_script(<<~JS)
      (() => {
        const article3 = document.querySelector("li[data-article-id='#{article3.id}']");
        if (!article3) return;

        const event = new KeyboardEvent('keydown', {
          key: 'ArrowUp',
          bubbles: true,
          shiftKey: true,
        });

        article3.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-selected='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-selected='true']")
    expect(page).to have_no_selector("li[data-article-id='#{article3.id}'][data-selected='true']")

    page.execute_script(<<~JS)
      (() => {
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");
        if (!article2) return;

        const event = new KeyboardEvent('keydown', {
          key: 'r',
          bubbles: true,
        });

        article2.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article3.id}'][data-unread='true']")
  end
end
