# Subscriptions や Articles のリストの <li> が持つリンクは A タグやボタンではなく、
# クリックはこのようにします。
module ListItemHelpers
  def click_list_item_in_subscriptions_pane(title)
    within('main > div#subscriptions-pane') do
      li = find('li', text: title)
      li.find('turbo-frame').click
    end
  end

  def click_list_item_in_articles_pane(title)
    within('main > div#articles-pane') do
      li = find('li', text: title)
      li.find('p:first-of-type').click
    end
  end
end
