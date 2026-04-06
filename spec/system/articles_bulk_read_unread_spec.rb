require 'rails_helper'

RSpec.describe 'Bulk read and unread actions', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'marks selected articles read and unread from top buttons' do
    subscription = FactoryBot.create(:subscription, title: 'Bulk Read Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Bulk Read Article 1', unread: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Bulk Read Article 2', unread: true)

    visit root_path

    click_list_item_in_subscriptions_pane('Bulk Read Subscription')
    expect(page).to have_selector("li[data-article-id='#{article1.id}']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}']")
    expect(page).to have_selector("li[data-subscription='#{subscription.id}'] span[data-unread-count]", text: '2')

    mark_read_button = find('[data-pane-focus-target="buttonMarkSelectedRead"]')
    mark_unread_button = find('[data-pane-focus-target="buttonMarkSelectedUnread"]')
    expect(mark_read_button.disabled?).to be(true)
    expect(mark_unread_button.disabled?).to be(true)

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");
        const pane = document.querySelector('#articles-pane');

        if (!article1 || !article2 || !pane) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';

        pane.dispatchEvent(new CustomEvent('changeSelectedLi', {
          detail: {
            selected: article1,
            selectedItems: [article1, article2],
            focusedItem: article2,
          },
          bubbles: true,
        }));
      })()
    JS

    mark_read_button = find('[data-pane-focus-target="buttonMarkSelectedRead"]')
    mark_unread_button = find('[data-pane-focus-target="buttonMarkSelectedUnread"]')
    expect(mark_read_button.disabled?).to be(false)
    expect(mark_unread_button.disabled?).to be(false)

    mark_read_button.click

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-subscription='#{subscription.id}'] span[data-unread-count].invisible", visible: :all)

    mark_unread_button.click

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-subscription='#{subscription.id}'] span[data-unread-count]", text: '2')
  end

  it 'toggles selected unread articles to read with r key' do
    subscription = FactoryBot.create(:subscription, title: 'R Toggle Subscription 1')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'R Toggle Article 1', unread: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'R Toggle Article 2', unread: true)

    visit root_path
    click_list_item_in_subscriptions_pane('R Toggle Subscription 1')

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");

        if (!article1 || !article2) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();

        const event = new KeyboardEvent('keydown', {
          key: 'r',
          bubbles: true,
        });

        article2.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='false']")
  end

  it 'toggles selected read articles to unread with r key' do
    subscription = FactoryBot.create(:subscription, title: 'R Toggle Subscription 2')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'R Toggle Article 3', unread: false)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'R Toggle Article 4', unread: false)

    visit root_path
    click_list_item_in_subscriptions_pane('R Toggle Subscription 2')

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");

        if (!article1 || !article2) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();

        const event = new KeyboardEvent('keydown', {
          key: 'r',
          bubbles: true,
        });

        article2.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='true']")
  end

  it 'sets all selected articles unread when read and unread are mixed with r key' do
    subscription = FactoryBot.create(:subscription, title: 'R Toggle Subscription 3')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'R Toggle Article 5', unread: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'R Toggle Article 6', unread: false)

    visit root_path
    click_list_item_in_subscriptions_pane('R Toggle Subscription 3')

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");

        if (!article1 || !article2) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();

        const event = new KeyboardEvent('keydown', {
          key: 'r',
          bubbles: true,
        });

        article2.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='true']")
  end

  it 'marks selected articles unread with u key' do
    subscription = FactoryBot.create(:subscription, title: 'U Shortcut Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'U Shortcut Article 1', unread: false)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'U Shortcut Article 2', unread: false)

    visit root_path
    click_list_item_in_subscriptions_pane('U Shortcut Subscription')

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");

        if (!article1 || !article2) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();

        const event = new KeyboardEvent('keydown', {
          key: 'u',
          bubbles: true,
        });

        article2.dispatchEvent(event);
      })()
    JS

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='true']")
  end

  it 'shows footer status when marking articles read is throttled' do
    subscription = FactoryBot.create(:subscription, title: 'Throttled Bulk Read Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Throttled Bulk Read Article 1', unread: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Throttled Bulk Read Article 2', unread: true)

    visit root_path

    click_list_item_in_subscriptions_pane('Throttled Bulk Read Subscription')
    expect(page).to have_selector("li[data-article-id='#{article1.id}']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}']")

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");
        const pane = document.querySelector('#articles-pane');

        if (!article1 || !article2 || !pane) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';

        pane.dispatchEvent(new CustomEvent('changeSelectedLi', {
          detail: {
            selected: article1,
            selectedItems: [article1, article2],
            focusedItem: article2,
          },
          bubbles: true,
        }));
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        const originalFetch = window.fetch.bind(window);

        window.fetch = async (input, init) => {
          const url = typeof input === 'string' ? input : input.url;
          if (url.includes('/bulk_update_read_status')) {
            return new Response(JSON.stringify({
              error: 'throttled',
              message: 'Rate limit exceeded, retry after some time'
            }), {
              status: 429,
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Retry-After': '7'
              }
            });
          }

          return originalFetch(input, init);
        };
      })()
    JS

    find('[data-pane-focus-target="buttonMarkSelectedRead"]').click

    expect(page).to have_selector('footer', text: "You're doing that too quickly. Please wait 7 seconds and try again.")
    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-subscription='#{subscription.id}'] span[data-unread-count]", text: '2')
  end
end
