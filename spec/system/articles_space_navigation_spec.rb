require 'rails_helper'

RSpec.describe 'Space key behavior in articles pane', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'scrolls first, then marks selected article read and moves to next unread at bottom' do
    subscription = FactoryBot.create(:subscription, title: 'Space Single Subscription')
    article1 = FactoryBot.create(
      :article,
      subscription: subscription,
      title: 'Space Single Article 1',
      unread: true,
      description: long_description,
    )
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Space Single Article 2', unread: true)

    visit root_path
    page.driver.resize(1280, 340)

    click_list_item_in_subscriptions_pane('Space Single Subscription')
    click_list_item_in_articles_pane('Space Single Article 1')
    wait_for_contents('Space Single Article 1')

    dispatch_space(article1.id)

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='true']")
    expect(contents_scroll_top).to be > 0

    scroll_contents_to_bottom
    dispatch_space(article1.id)

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-selected='true']")
  end

  it 'at bottom marks multi-selected articles read and moves to next unread single item' do
    subscription = FactoryBot.create(:subscription, title: 'Space Multi Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Space Multi Article 1', unread: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Space Multi Article 2', unread: true)
    article3 = FactoryBot.create(:article, subscription: subscription, title: 'Space Multi Article 3', unread: true)

    visit root_path
    click_list_item_in_subscriptions_pane('Space Multi Subscription')
    click_list_item_in_articles_pane('Space Multi Article 1')

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");
        const pane = document.querySelector('#articles-pane');

        if (!article1 || !article2 || !pane) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();

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

    wait_for_contents('Space Multi Article 1')
    scroll_contents_to_bottom
    dispatch_space(article2.id)

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article3.id}'][data-selected='true']")
    expect(page).to have_no_selector("li[data-article-id='#{article1.id}'][data-selected='true']")
  end

  it 'at bottom keeps current selection when there is no next unread item' do
    subscription = FactoryBot.create(:subscription, title: 'Space No Next Unread')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Space No Next Article 1', unread: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Space No Next Article 2', unread: true)

    visit root_path
    click_list_item_in_subscriptions_pane('Space No Next Unread')
    click_list_item_in_articles_pane('Space No Next Article 1')

    page.execute_script(<<~JS)
      (() => {
        const article1 = document.querySelector("li[data-article-id='#{article1.id}']");
        const article2 = document.querySelector("li[data-article-id='#{article2.id}']");
        const pane = document.querySelector('#articles-pane');

        if (!article1 || !article2 || !pane) return;

        article1.dataset.selected = 'true';
        article2.dataset.selected = 'true';
        article2.focus();

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

    wait_for_contents('Space No Next Article 1')
    scroll_contents_to_bottom
    dispatch_space(article2.id)

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-selected='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-selected='true']")
  end

  def dispatch_space(article_id)
    page.execute_script(<<~JS)
      (() => {
        const article = document.querySelector("li[data-article-id='#{article_id}']");
        if (!article) return;

        const event = new KeyboardEvent('keydown', {
          key: ' ',
          code: 'Space',
          bubbles: true,
        });

        article.dispatchEvent(event);
      })()
    JS
  end

  def scroll_contents_to_bottom
    page.execute_script(<<~JS)
      (() => {
        const contentsPane = document.querySelector('#contents-pane');
        if (!contentsPane) return;
        contentsPane.scrollTop = contentsPane.scrollHeight;
      })()
    JS
  end

  def contents_scroll_top
    page.evaluate_script(<<~JS)
      (() => {
        const contentsPane = document.querySelector('#contents-pane');
        return contentsPane ? contentsPane.scrollTop : 0;
      })()
    JS
  end

  def wait_for_contents(title)
    within('turbo-frame#contents') do
      expect(page).to have_content(title)
    end
  end

  def long_description
    paragraph = '<p>Space scroll verification line.</p>'
    paragraph * 300
  end
end
