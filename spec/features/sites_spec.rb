require 'rails_helper'

describe "Sites RESTful" do
  feature "index" do # describe ... :type => :feature
    background do
      Site.create(name: "apple", feed_url: "http://www.apple.com/")
      Site.create(name: "google", feed_url: "http://www.google.com/")
    end
    scenario 'have contents' do
      visit sites_path
      expect(page).to have_content 'apple'
      expect(page).to have_content 'google'
    end
  end

  feature "show" do
    given(:item) { Site.create(name: "apple", feed_url: "http://www.apple.com/") }
    scenario 'have contents' do
      visit site_path(item)
      expect(page).to have_content 'apple'
      expect(page).not_to have_content 'google'
    end
  end

  feature "edit" do
    given(:item) { Site.create(name: "apple", feed_url: "http://www.apple.com/") }
    scenario 'have contents' do
      visit edit_site_path(item)
      expect(page).to have_field("Name", with: item.name)
      expect(page).to have_field("Feed url", with: item.feed_url)
    end
  end

  feature "new" do
    scenario 'have contents' do
      visit new_site_path
      expect(page.find_field("Name").value).to be_blank
      expect(page.find_field("Feed url").value).to be_blank
    end
  end

  feature "update" do
    given(:item) { Site.create(name: "apple", feed_url: "http://www.apple.com/") }
    background do
      visit edit_site_path(item)
      fill_in 'site[name]', with: value
      click_on 'Update site'
    end
    context "valid data" do
      given(:value) { 'アップル' }
      scenario 'have contents' do
        expect(page).not_to have_content 'name: apple'
        expect(page).to have_content "name: #{value}"
      end
    end
    context "invalid data" do
      given(:value) { '' }
      scenario 'have contents' do
        expect(page).to have_content 'Name can\'t be blank'
      end
    end
  end

  feature "create" do
    background do
      visit new_site_path
      fill_in 'site[name]', with: value
      fill_in 'site[feed_url]', with: 'http://www.microsoft.com/'
      click_on 'Create new site'
    end
    context "valid data" do
      given(:value) { 'microsoft' }
      scenario 'have contents' do
        expect(page).not_to have_content 'name: apple'
        expect(page).to have_content 'name: microsoft'
      end
    end
    context "invalid data" do
      given(:value) { '' }
      scenario 'have contents' do
        expect(page).to have_content 'Name can\'t be blank'
      end
    end
  end

  feature "destroy" do
    scenario do
      pending "not implemented yet"
      fail
    end
  end
end
