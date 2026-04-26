require 'rails_helper'

RSpec.describe 'Subscriptions group collapse', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'toggles collapse by button without selecting the group and restores state after reload' do
    parent = FactoryBot.create(:group, name: 'Parent', parent: nil, position: 1)
    child = FactoryBot.create(:group, name: 'Child', parent: parent, position: 1)
    FactoryBot.create(:subscription, title: 'Nested Sub', group: child, position: 1)

    visit root_path

    expect(page).to have_selector("li[data-item-type='group'][data-group-id='#{parent.id}']")

    toggle_selector = "li[data-item-type='group'][data-group-id='#{parent.id}'] .group-collapse-toggle"
    nested_container_selector = "li[data-item-type='group'][data-group-id='#{parent.id}'] > [data-tree-sort-container]"
    nested_selector = "#{nested_container_selector} > ul[data-tree-sort-list]"

    expect(page).to have_selector(nested_selector, visible: :all)

    find(toggle_selector, match: :first).click

    expect(page).to have_selector("#{nested_container_selector}[hidden]", visible: :all)

    collapsed_state = page.evaluate_script("document.querySelector(\"li[data-item-type='group'][data-group-id='#{parent.id}']\").dataset.collapsed")
    selected_count = page.evaluate_script("document.querySelectorAll(\"#subscriptions-pane li[data-selected='true']\").length")
    nested_hidden = page.evaluate_script("document.querySelector(\"#{nested_container_selector}\").hidden")

    expect(collapsed_state).to eq('true')
    expect(selected_count).to eq(0)
    expect(nested_hidden).to be(true)

    visit current_path

    expect(page).to have_selector("li[data-item-type='group'][data-group-id='#{parent.id}']", wait: 10)

    restored_state = page.evaluate_script("document.querySelector(\"li[data-item-type='group'][data-group-id='#{parent.id}']\").dataset.collapsed")
    restored_hidden = page.evaluate_script("document.querySelector(\"#{nested_container_selector}\").hidden")

    expect(restored_state).to eq('true')
    expect(restored_hidden).to be(true)

    find(toggle_selector, match: :first).click

    expect(page).to have_no_selector("#{nested_container_selector}[hidden]", visible: :all)

    reopened_state = page.evaluate_script("document.querySelector(\"li[data-item-type='group'][data-group-id='#{parent.id}']\").dataset.collapsed")
    reopened_hidden = page.evaluate_script("document.querySelector(\"#{nested_container_selector}\").hidden")

    expect(reopened_state).to eq('false')
    expect(reopened_hidden).to be(false)
  end
end
