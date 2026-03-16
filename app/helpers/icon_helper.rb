module IconHelper
  def icon_refresh(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99')
    end
  end

  def icon_mark_read(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M10.125 2.25h-4.5c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125v-9M10.125 2.25h.375a9 9 0 0 1 9 9v.375M10.125 2.25A3.375 3.375 0 0 1 13.5 5.625v1.5c0 .621.504 1.125 1.125 1.125h1.5a3.375 3.375 0 0 1 3.375 3.375M9 15l2.25 2.25L15 12')
    end
  end

  def icon_mark_unread(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z')
    end
  end

  def icon_new_subscription(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M12.75 19.5v-.75a7.5 7.5 0 0 0-7.5-7.5H4.5m0-6.75h.75c7.87 0 14.25 6.38 14.25 14.25v.75M6 18.75a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z')
    end
  end

  def icon_edit_subscription(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'm11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z')
    end
  end

  def icon_new_group(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M12 10.5v6m3-3H9m4.06-7.19-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z')
    end
  end

  def icon_edit_group(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'm11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z')
    end
  end

  def icon_trash(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'm14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0')
    end
  end
end
