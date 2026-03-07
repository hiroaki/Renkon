require 'rails_helper'

RSpec.describe 'Subscriptions sortable tree', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  it 'persists top-level mixed order after nested sortable move' do
    group = FactoryBot.create(:group, name: 'Group A', parent: nil, position: 1)
    first = FactoryBot.create(:subscription, title: 'Top First', group: nil, position: 1)
    second = FactoryBot.create(:subscription, title: 'Top Second', group: nil, position: 2)
    FactoryBot.create(:subscription, title: 'In Group', group: group, position: 1)

    visit root_path

    expect(page).to have_selector('turbo-frame#subscriptions ul[data-controller*="subscriptions-tree-sort"]')

    # Simulate a nested-sort result directly in DOM, then persist through the same API used by DnD.
    page.execute_script(<<~JS)
      (() => {
        const rootList = document.querySelector('turbo-frame#subscriptions ul[data-controller*="subscriptions-tree-sort"]')
        const firstNode = rootList.querySelector('li[data-subscription="#{first.id}"]')
        const secondNode = rootList.querySelector('li[data-subscription="#{second.id}"]')
        rootList.insertBefore(secondNode, firstNode)
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        const scope = document.querySelector('turbo-frame#subscriptions')

        const treeNodes = Array.from(scope.querySelectorAll('li[data-item-type="group"], li[data-item-type="subscription"]'))
          .map((node) => {
            const itemType = node.dataset.itemType
            const id = itemType === 'group' ? Number(node.dataset.groupId) : Number(node.dataset.subscription)
            const parentGroupLi = node.parentElement.closest('li[data-item-type="group"][data-group-id]')
            const parentGroupId = parentGroupLi ? Number(parentGroupLi.dataset.groupId) : null
            const siblings = Array.from(node.parentElement.children)
              .filter((elem) => elem.matches('li[data-item-type="group"], li[data-item-type="subscription"]'))

            return {
              item_type: itemType,
              id,
              parent_group_id: parentGroupId,
              position: siblings.indexOf(node) + 1,
            }
          })

        const csrfMeta = document.querySelector('meta[name="csrf-token"]')
        const csrf = csrfMeta ? csrfMeta.content : ''

        fetch('#{reorder_tree_subscriptions_path}', {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-Token': csrf,
          },
          body: JSON.stringify({ tree_nodes: treeNodes }),
        }).then(() => {
          document.body.dataset.reorderTreeDone = 'true'
        }).catch(() => {
          document.body.dataset.reorderTreeDone = 'error'
        })
      })()
    JS

    expect(page).to have_selector('body[data-reorder-tree-done="true"]')

    expect(page).to have_content('Top First')

    visit current_path

    top_nodes = page.all('turbo-frame#subscriptions ul[data-controller*="subscriptions-tree-sort"] > li[data-item-type="subscription"]', minimum: 2).map do |li|
      li['data-subscription'].to_i
    end

    expect(top_nodes.first(2)).to eq([second.id, first.id])
  end
end
