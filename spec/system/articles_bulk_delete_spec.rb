require 'rails_helper'

RSpec.describe 'Bulk delete selected articles', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'deletes all selected articles by Backspace and selects the next remaining article' do
    subscription = FactoryBot.create(:subscription, title: 'Bulk Delete Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Bulk Article 1')
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Bulk Article 2')
    article3 = FactoryBot.create(:article, subscription: subscription, title: 'Bulk Article 3')

    visit root_path

    click_list_item_in_subscriptions_pane('Bulk Delete Subscription')
    expect(page).to have_selector('li[data-articles-target="listItem"]', count: 3)

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector('li[data-article-id="#{article1.id}"]');
        const article2 = document.querySelector('li[data-article-id="#{article2.id}"]');

        if (!article1 || !article2) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        const list = document.querySelector('ul[data-controller="articles"]');
        const focused = document.querySelector("li[data-article-id='#{article2.id}']");
        if (!list || !focused) return;

        const event = new KeyboardEvent('keydown', {
          key: 'Backspace',
          bubbles: true,
        });

        focused.dispatchEvent(event);
      })()
    JS

    expect(page).to have_no_selector("li[data-article-id='#{article1.id}']")
    expect(page).to have_no_selector("li[data-article-id='#{article2.id}']")
    expect(page).to have_selector("li[data-article-id='#{article3.id}']")

    remaining_item = find("li[data-article-id='#{article3.id}']", visible: :all)
    expect(remaining_item['data-selected']).to eq('true')
  end

  it 'caps queued deletes when Backspace keydown fires rapidly' do
    subscription = FactoryBot.create(:subscription, title: 'Rapid Delete Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Rapid Article 1')
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Rapid Article 2')
    article3 = FactoryBot.create(:article, subscription: subscription, title: 'Rapid Article 3')

    visit root_path

    click_list_item_in_subscriptions_pane('Rapid Delete Subscription')
    expect(page).to have_selector('li[data-articles-target="listItem"]', count: 3)

    page.execute_script(<<~JS)
      (() => {
        const focused = document.querySelector("li[data-article-id='#{article1.id}']")
        if (!focused) return

        focused.dataset.selected = 'true'
        focused.focus()

        for (let i = 0; i < 3; ++i) {
          focused.dispatchEvent(new KeyboardEvent('keydown', { key: 'Backspace', bubbles: true }))
        }
      })()
    JS

    expect(page).to have_no_selector("li[data-article-id='#{article1.id}']")
    expect(page).to have_no_selector("li[data-article-id='#{article2.id}']")
    expect(page).to have_selector("li[data-article-id='#{article3.id}']")
  end

  it 'shows footer status when bulk delete is throttled' do
    subscription = FactoryBot.create(:subscription, title: 'Throttled Delete Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Throttled Delete Article 1')
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Throttled Delete Article 2')
    article3 = FactoryBot.create(:article, subscription: subscription, title: 'Throttled Delete Article 3')

    visit root_path

    click_list_item_in_subscriptions_pane('Throttled Delete Subscription')
    expect(page).to have_selector('li[data-articles-target="listItem"]', count: 3)

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector('li[data-article-id="#{article1.id}"]');
        const article2 = document.querySelector('li[data-article-id="#{article2.id}"]');

        if (!article1 || !article2) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        const originalFetch = window.fetch.bind(window);

        window.fetch = async (input, init) => {
          const url = typeof input === 'string' ? input : input.url;
          if (url.includes('/bulk_delete')) {
            return new Response(JSON.stringify({
              error: 'throttled',
              message: 'Rate limit exceeded, retry after some time'
            }), {
              status: 429,
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Retry-After': '9'
              }
            });
          }

          return originalFetch(input, init);
        };
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        const focused = document.querySelector("li[data-article-id='#{article2.id}']");
        if (!focused) return;

        focused.dispatchEvent(new KeyboardEvent('keydown', {
          key: 'Backspace',
          bubbles: true,
        }));
      })()
    JS

    expect(page).to have_selector('footer', text: "You're doing that too quickly. Please wait 9 seconds and try again.")
    expect(page).to have_selector("li[data-article-id='#{article1.id}']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}']")
    expect(page).to have_selector("li[data-article-id='#{article3.id}']")
  end
end
