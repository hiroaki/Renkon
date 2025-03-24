require 'rails_helper'

RSpec.describe "Main Page", type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  describe "Header Pane" do
    it "displays 'Renkon' text" do
      visit root_path
      expect(page).to have_selector('nav', text: 'Renkon')
    end

    it "has a 'Refresh' button" do
      visit root_path
      expect(page).to have_selector('button', text: 'Refresh')
    end

    it "has a 'New subscription' link" do
      visit root_path
      expect(page).to have_link('New subscription', href: new_subscription_path)
    end

    it "has an 'Edit subscription' link" do
      visit root_path
      expect(page).to have_link('Edit subscription', href: '#')
    end

    it "has an 'Empty Trash' button" do
      visit root_path
      expect(page).to have_selector('button', text: 'Empty Trash')
    end
  end

  describe "Subscriptions Pane" do
    context "when there are no Subscription records" do
      it "displays only 'Trash'" do
        visit root_path
        within('main > div:first-of-type') do
          expect(page).to have_content('Trash')
          expect(page).not_to have_selector('li.subscription')
        end
      end
    end

    context "when there are Subscription records" do
      before do
        # Create sample subscriptions
        @subscriptions = FactoryBot.create_list(:subscription, 20, title: "Sample Subscription")
      end

      it "displays 'Trash' and the list of Subscriptions" do
        visit root_path
        within('main > div:first-of-type') do
          expect(page).to have_content('Trash')
          @subscriptions.each do |subscription|
            expect(page).to have_content(subscription.title)
          end
        end
      end

      it "allows scrolling to access all Subscription items" do
        visit root_path

        # ウィンドウの高さを設定
        page.driver.resize(1280, 300)

        within('main > div:first-of-type') do
          parent_div_selector = '#subscriptions-pane > div:first-child'
          last_li_selector = '#subscriptions-pane > div ul li:last-child'

          last_li = find(last_li_selector, visible: :all)
          parent_div = find(parent_div_selector, visible: :all)

          # **1. ページ表示直後に最後の <li> が見えていないことを確認**
          hidden_before_scroll = page.evaluate_script(<<~JS)
            (() => {
              let parentDivSelector = '#subscriptions-pane > div:first-child';
              let lastLiSelector = '#subscriptions-pane > div ul li:last-child';

              let parentDiv = document.querySelector(parentDivSelector);
              let lastLi = document.querySelector(lastLiSelector);

              if (!parentDiv || !lastLi) return false;

              let parentDivBottom = parentDiv.getBoundingClientRect().bottom;
              let lastLiBottom = lastLi.getBoundingClientRect().bottom;

              return parentDivBottom < lastLiBottom ? true : false;
            })()
          JS

          expect(hidden_before_scroll).to be true

          # **2. スクロールして要素を表示**
          page.execute_script(<<~JS)
            (() => {
              let parentDivSelector = '#subscriptions-pane > div:first-child';
              let parentDiv = document.querySelector(parentDivSelector);
              if (parentDiv) parentDiv.scrollTop = parentDiv.scrollHeight;
            })()
          JS

          # **3. スクロール後にクリックできることを確認**
          expect { last_li.click }.not_to raise_error
        end
      end
    end
  end
end
