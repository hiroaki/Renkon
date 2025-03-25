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

  describe "Articles Pane" do
    context "when the page is initially loaded" do
      it "is empty" do
        visit root_path
        within('main > div#articles-pane') do
          expect(page).not_to have_content(/\S/)
        end
      end
    end

    context "when a Subscription is clicked" do
      before do
        # Create sample subscription and articles
        @subscription = FactoryBot.create(:subscription, title: "Sample Subscription")
        @articles = FactoryBot.create_list(:article, 20, subscription: @subscription, title: "Sample Article")
      end

      it "displays the correct number of Articles" do
        visit root_path

        # Click the subscription item (using turbo-frame tag inside an li element)
        within('main > div#subscriptions-pane') do
          li = find('li', text: 'Sample Subscription')
          li.find('turbo-frame').click
        end

        within('main > div#articles-pane') do
          expect(page).to have_selector('li[data-articles-target="listItem"]', count: 20)
        end
      end

      it "allows scrolling to access all Article items" do
        visit root_path

        # Click the subscription item (using turbo-frame tag inside an li element)
        within('main > div#subscriptions-pane') do
          li = find('li', text: 'Sample Subscription')
          li.find('turbo-frame').click
        end

        # Set window height
        page.driver.resize(1280, 300)

        within('main > div#articles-pane') do
          parent_div_selector = '#articles-pane > div:first-child'
          last_li_selector = '#articles-pane > div ul li:last-child'

          last_li = find(last_li_selector, visible: :all)
          parent_div = find(parent_div_selector, visible: :all)

          # **1. Confirm that the last <li> is not visible immediately after the page is loaded**
          hidden_before_scroll = page.evaluate_script(<<~JS)
            (() => {
              let parentDivSelector = '#articles-pane > div:first-child';
              let lastLiSelector = '#articles-pane > div ul li:last-child';

              let parentDiv = document.querySelector(parentDivSelector);
              let lastLi = document.querySelector(lastLiSelector);

              if (!parentDiv || !lastLi) return false;

              let parentDivBottom = parentDiv.getBoundingClientRect().bottom;
              let lastLiBottom = lastLi.getBoundingClientRect().bottom;

              return parentDivBottom < lastLiBottom ? true : false;
            })()
          JS

          expect(hidden_before_scroll).to be true

          # **2. Scroll to display the element**
          page.execute_script(<<~JS)
            (() => {
              let parentDivSelector = '#articles-pane > div:first-child';
              let parentDiv = document.querySelector(parentDivSelector);
              if (parentDiv) parentDiv.scrollTop = parentDiv.scrollHeight;
            })()
          JS

          # **3. Confirm that it can be clicked after scrolling**
          expect { last_li.click }.not_to raise_error
        end
      end
    end
  end

  describe "Contents Pane" do
    context "when a Subscription is clicked and an Article is clicked" do
      before do
        # Create a sample subscription and article
        @subscription = FactoryBot.create(:subscription, title: "Sample Subscription")
        @article = FactoryBot.create(:article, subscription: @subscription, title: "Sample Article", description: "<p>This is a detailed description of the article. " * 20 + "</p>")
      end

      it "displays the article content when an article is clicked" do
        visit root_path

        # Click the subscription item (using turbo-frame tag inside an li element)
        within('main > div#subscriptions-pane') do
          li = find('li', text: 'Sample Subscription')
          li.find('turbo-frame').click
        end

        # Click the article item to display its content
        within('main > div#articles-pane') do
          li = find('li', text: 'Sample Article')
          li.find('p:first-of-type').click
        end

        within('turbo-frame#contents') do
          expect(page).to have_content("Sample Article")
          expect(page).to have_content("This is a detailed description of the article.")
        end
      end

      it "ensures the contents pane is scrollable and the last line is visible" do
        visit root_path

        # Click the subscription item (using turbo-frame tag inside an li element)
        within('main > div#subscriptions-pane') do
          li = find('li', text: 'Sample Subscription')
          li.find('turbo-frame').click
        end

        # Click the article item to display its content
        within('main > div#articles-pane') do
          li = find('li', text: 'Sample Article')
          li.find('p:first-of-type').click
        end

        # ウィンドウの高さを設定
        page.driver.resize(1280, 300)

        # within('turbo-frame#contents') do
          parent_div_selector = '#contents-pane'
          last_p_selector = '#actual-contents p:last-child'

          parent_div = find(parent_div_selector, visible: :all)

          # **1. ページ表示直後に最後の <p> が見えていないことを確認**
          hidden_before_scroll = page.evaluate_script(<<~JS)
            (() => {
              let parentDiv = document.querySelector('#contents-pane');
              let lastP = document.querySelector('#actual-contents p:last-child');

              if (!parentDiv || !lastP) return false;

              let parentDivBottom = parentDiv.getBoundingClientRect().bottom;
              let lastPBottom = lastP.getBoundingClientRect().bottom;

              return parentDivBottom < lastPBottom ? true : false;
            })()
          JS

          expect(hidden_before_scroll).to be true

          # **2. スクロールして要素を表示**
          page.execute_script(<<~JS)
            (() => {
              let parentDiv = document.querySelector('#contents-pane');
              if (parentDiv) parentDiv.scrollTop = parentDiv.scrollHeight;
            })()
          JS

          # **3. スクロール後に最後の行が見えることを確認**
          visible_after_scroll = page.evaluate_script(<<~JS)
            (() => {
              let parentDiv = document.querySelector('#contents-pane');
              let lastP = document.querySelector('#actual-contents p:last-child');

              if (!parentDiv || !lastP) return false;

              let parentDivBottom = parentDiv.getBoundingClientRect().bottom;
              let lastPBottom = lastP.getBoundingClientRect().bottom;

              return parentDivBottom >= lastPBottom ? true : false;
            })()
          JS

          expect(visible_after_scroll).to be true
        #end
      end
    end
  end

end

