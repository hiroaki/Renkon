require 'rails_helper'

RSpec.describe 'Footer status message', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'shows and clears error message from global status event' do
    visit root_path

    expect(page).to have_selector('footer', text: 'Status')

    page.execute_script(<<~JS)
      window.dispatchEvent(new CustomEvent('renkon:status-error', {
        detail: { message: "Couldn't save the new order. Please try again." }
      }))
    JS

    expect(page).to have_selector('footer', text: '!')
    expect(page).to have_selector('footer', text: "Couldn't save the new order. Please try again.")
    expect(page).to have_selector('footer button', text: 'x')

    find('footer button', text: 'x').click

    expect(page).to have_selector('footer', text: 'Status')
    expect(page).to have_no_selector('footer', text: "Couldn't save the new order. Please try again.")
  end
end
