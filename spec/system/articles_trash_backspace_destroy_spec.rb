require 'rails_helper'

RSpec.describe 'Backspace on trash list', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'hard deletes selected disabled articles and keeps the next article selected' do
    subscription = FactoryBot.create(:subscription, title: 'Trash Delete Subscription')
    article1 = FactoryBot.create(:article, subscription: subscription, title: 'Trash Article 1', disabled: true)
    article2 = FactoryBot.create(:article, subscription: subscription, title: 'Trash Article 2', disabled: true)
    article3 = FactoryBot.create(:article, subscription: subscription, title: 'Trash Article 3', disabled: true)

    visit root_path

    find('#trash [data-action="click->subscriptions#handlerEnterItem"]', visible: :all).click
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
        const focused = document.querySelector("li[data-article-id='#{article2.id}']");
        if (!focused) return;

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

    expect(Article.exists?(article1.id)).to be(false)
    expect(Article.exists?(article2.id)).to be(false)
    expect(Article.exists?(article3.id)).to be(true)
  end
end
