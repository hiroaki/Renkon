# spec/system/articles_spec.rb
require 'rails_helper'

RSpec.describe 'Articles', type: :system do
  let!(:subscription) { FactoryBot.create(:subscription) }
  let!(:article) { FactoryBot.create(:article, subscription: subscription) }

  before do
    driven_by(:cuprite_custom)
  end

  it '記事を新規作成する' do
    visit new_subscription_article_path(subscription)

    fill_in 'Title', with: '新しい記事'
    fill_in 'Url', with: 'http://example.com'
    click_button 'Create Article'

    expect(page).to have_content('Article was successfully created.')
    expect(page).to have_content('新しい記事')
  end

  it '記事の新規作成が失敗する場合' do
    visit new_subscription_article_path(subscription)

    fill_in 'Title', with: ''
    fill_in 'Url', with: ''
    click_button 'Create Article'

    expect(page).to have_content('Title can\'t be blank')
    expect(page).to have_content('Url can\'t be blank')
  end

  it '記事を編集する' do
    visit edit_subscription_article_path(subscription, article)

    fill_in 'Title', with: '更新された記事'
    click_button 'Update Article'

    expect(page).to have_content('Article was successfully updated.')
    expect(page).to have_content('更新された記事')
  end

  it '記事の編集が失敗する場合' do
    visit edit_subscription_article_path(subscription, article)

    fill_in 'Title', with: ''
    click_button 'Update Article'

    expect(page).to have_content('Title can\'t be blank')
  end

  it '記事を削除する' do # show 画面
    visit subscription_article_path(subscription, article)

    accept_confirm "Are you sure?" do
      click_button "Destroy"
    end

    expect(page).to have_content('Article was successfully destroyed.')
    expect(page).not_to have_content(article.title)
  end

  it '記事を削除する' do # edit 画面
    visit edit_subscription_article_path(subscription, article)

    accept_confirm "Are you sure?" do
      click_button "Destroy this article"
    end

    expect(page).to have_content('Article was successfully destroyed.')
    expect(page).not_to have_content(article.title)
  end

  it '記事を表示する' do
    visit subscription_article_path(subscription, article)

    expect(page).to have_content(article.title)
    expect(page).to have_content(article.url)
  end

  it '記事の一覧を表示する' do
    visit subscription_articles_path(subscription)

    expect(page).to have_content(article.title)
  end

  it '記事を無効化する' do
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Disable'
    end

    expect(page).to have_content('Article was successfully updated.')
    expect(article.reload.disabled).to be_truthy
  end

  it '記事の無効化が失敗する場合' do
    allow_any_instance_of(Article).to receive(:update).and_return(false)
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Disable'
    end

    expect(page).to have_content('Editing article')
  end

  it '記事を有効化する' do
    article.update(disabled: true)
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Enable'
    end

    expect(page).to have_content('Article was successfully updated.')
    expect(article.reload.disabled).to be_falsey
  end

  it '記事の有効化が失敗する場合' do
    article.update(disabled: true)
    allow_any_instance_of(Article).to receive(:update).and_return(false)
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Enable'
    end

    expect(page).to have_content('Editing article')
  end

  it '記事を未読にする' do
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Mark Unread'
    end

    expect(page).to have_content('Article was successfully updated.')
    expect(article.reload.unread).to be_truthy
  end

  it '記事を未読にするのが失敗する場合' do
    allow_any_instance_of(Article).to receive(:update).and_return(false)
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Mark Unread'
    end

    expect(page).to have_content('Editing article')
  end

  it '記事を既読にする' do
    article.update(unread: true)
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Mark Read'
    end

    expect(page).to have_content('Article was successfully updated.')
    expect(article.reload.unread).to be_falsey
  end

  it '記事を既読にするのが失敗する場合' do
    article.update(unread: true)
    allow_any_instance_of(Article).to receive(:update).and_return(false)
    visit subscription_article_path(subscription, article)
    accept_confirm "Are you sure?" do
      click_button 'Mark Read'
    end

    expect(page).to have_content('Editing article')
  end

  it '記事を更新する' do
    visit edit_subscription_article_path(subscription, article)

    fill_in 'Title', with: '更新された記事'
    click_button 'Update Article'

    expect(page).to have_content('Article was successfully updated.')
    expect(page).to have_content('更新された記事')
  end

  it '記事の更新が失敗する場合' do
    allow_any_instance_of(Article).to receive(:update).and_return(false)
    visit edit_subscription_article_path(subscription, article)

    fill_in 'Title', with: '更新された記事'
    click_button 'Update Article'

    expect(page).to have_content('Editing article')
  end
end

RSpec.describe 'Trash', type: :system do
  let!(:subscription) { FactoryBot.create(:subscription) }
  let!(:article1) { FactoryBot.create(:article, subscription: subscription, disabled: true) }
  let!(:article2) { FactoryBot.create(:article, subscription: subscription, disabled: true) }
  let!(:article3) { FactoryBot.create(:article, subscription: subscription, disabled: false) }
  let!(:article4) { FactoryBot.create(:article, subscription: subscription, disabled: false) }

  before do
    driven_by(:cuprite_custom)
  end

  context 'ゴミ箱ページでの操作' do
    it '/trash にアクセスし、無効化された記事が表示されることを確認する' do
      visit trash_path

      expect(page).to have_content(article1.title)
      expect(page).to have_content(article2.title)
      expect(page).not_to have_content(article3.title)
      expect(page).not_to have_content(article4.title)
    end

    it 'ゴミ箱を空にする' do
      visit trash_path

      accept_confirm "Are you sure?" do
        click_button 'Empty trash'
      end

      expect(page).to have_current_path(subscriptions_path)
      expect(page).to have_content('2 disabled articles were successfully deleted.')

      expect(Article.where(disabled: true).count).to eq(0)
      expect(Article.where(disabled: false).count).to eq(2)
    end
  end

  context 'メイン画面からゴミ箱を空にする' do
    it 'メイン画面からゴミ箱を空にする' do
      visit root_path

      find('li#trash span[data-link-to-url="/trash"]', text: 'Trash').click

      within('#articles-pane') do
        expect(page).to have_content(article1.title)
        expect(page).to have_content(article2.title)
        expect(page).not_to have_content(article3.title)
        expect(page).not_to have_content(article4.title)
      end

      first('#articles-pane li').click

      within('#contents-pane') do
        expect(page).to have_content(article1.title)
      end

      accept_confirm "Are you sure you want to empty the trash?" do
        click_button 'Empty Trash'
      end

      # within('#articles-pane') do
      #   expect(page).to have_no_content('')
      # end
      expect(find('#articles-pane').text.strip).to eq('')


      # within('#contents-pane') do
      #   expect(page).to have_no_content('')
      # end
      expect(find('#contents-pane').text.strip).to eq('')

      find('li#trash span[data-link-to-url="/trash"]', text: 'Trash').click

      # within('#articles-pane') do
      #   expect(page).to have_no_content('')
      # end
      expect(find('#articles-pane').text.strip).to eq('')

      expect(Article.where(disabled: true).count).to eq(0)
      expect(Article.where(disabled: false).count).to eq(2)
    end
  end
end
