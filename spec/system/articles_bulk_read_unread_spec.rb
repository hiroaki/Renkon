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

    mark_read_button = find('button', text: 'Mark Read')
    mark_unread_button = find('button', text: 'Mark Unread')
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

    mark_read_button = find('button', text: 'Mark Read')
    mark_unread_button = find('button', text: 'Mark Unread')
    expect(mark_read_button.disabled?).to be(false)
    expect(mark_unread_button.disabled?).to be(false)

    mark_read_button.click

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='false']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='false']")

    mark_unread_button.click

    expect(page).to have_selector("li[data-article-id='#{article1.id}'][data-unread='true']")
    expect(page).to have_selector("li[data-article-id='#{article2.id}'][data-unread='true']")
  end
end
