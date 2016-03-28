require 'rails_helper'

describe "Sites" do
  before do
    visit sites_path
  end
  it { expect(page).to have_content 'Sites' }
end
