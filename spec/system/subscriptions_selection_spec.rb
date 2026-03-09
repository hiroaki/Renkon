require 'rails_helper'

RSpec.describe 'Subscriptions selection', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'marks only the selected group as selected' do
    parent_group = FactoryBot.create(:group, name: 'Parent Group', parent: nil, position: 1)
    child_group = FactoryBot.create(:group, name: 'Child Group', parent: parent_group, position: 1)
    FactoryBot.create(:subscription, title: 'Child Subscription', group: child_group, position: 1)

    visit root_path

    expect(page).to have_selector('turbo-frame#subscriptions')
    expect(page).to have_selector("li[data-item-type='group'][data-group-id='#{parent_group.id}']", wait: 10)

    find("li[data-item-type='group'][data-group-id='#{parent_group.id}'] .group-select-label", match: :first).click

    selected_ids = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#subscriptions-pane li[data-selected="true"]'))
        .map((li) => li.dataset.groupId || li.dataset.subscription || li.id)
    JS

    expect(selected_ids).to eq([parent_group.id.to_s])
  end
end
