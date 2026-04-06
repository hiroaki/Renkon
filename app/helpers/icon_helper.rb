module IconHelper
  def icon_warning_triangle(css_class: 'size-4', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      safe_join([
        tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M12 9v4.5m0 3.75h.008v.008H12v-.008Zm10.5 1.157-9.75-16.875a.866.866 0 0 0-1.5 0L1.5 18.407A.866.866 0 0 0 2.25 19.5h19.5a.866.866 0 0 0 .75-1.093Z')
      ])
    end
  end

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

  def icon_empty_trash(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      safe_join([
        tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'm14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0'),
        tag.path(
          nil,
          'stroke-linecap' => 'round',
          'stroke-linejoin' => 'round',
          d: 'M19.5 3.75l.75 2.25 2.25.75-2.25.75-.75 2.25-.75-2.25-2.25-.75 2.25-.75.75-2.25'
        ),
        tag.path(
          nil,
          'stroke-linecap' => 'round',
          'stroke-linejoin' => 'round',
          d: 'M16.5 11.25l.375 1.125 1.125.375-1.125.375-.375 1.125-.375-1.125-1.125-.375 1.125-.375.375-1.125'
        )
      ])
    end
  end

  def icon_cog_8_tooth(css_class: 'size-6', **opts)
    content_tag(:svg, xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': '1.5', stroke: 'currentColor', class: css_class, 'aria-hidden': 'true', focusable: 'false', **opts) do
      safe_join([
        tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M10.343 3.94c.09-.542.56-.94 1.11-.94h1.093c.55 0 1.02.398 1.11.94l.149.894c.07.424.384.764.78.93.398.164.855.142 1.205-.108l.737-.527a1.125 1.125 0 0 1 1.45.12l.773.774c.39.389.44 1.002.12 1.45l-.527.737c-.25.35-.272.806-.107 1.204.165.397.505.71.93.78l.893.15c.543.09.94.559.94 1.109v1.094c0 .55-.397 1.02-.94 1.11l-.894.149c-.424.07-.764.383-.929.78-.165.398-.143.854.107 1.204l.527.738c.32.447.269 1.06-.12 1.45l-.774.773a1.125 1.125 0 0 1-1.449.12l-.738-.527c-.35-.25-.806-.272-1.203-.107-.398.165-.71.505-.781.929l-.149.894c-.09.542-.56.94-1.11.94h-1.094c-.55 0-1.019-.398-1.11-.94l-.148-.894c-.071-.424-.384-.764-.781-.93-.398-.164-.854-.142-1.204.108l-.738.527c-.447.32-1.06.269-1.45-.12l-.773-.774a1.125 1.125 0 0 1-.12-1.45l.527-.737c.25-.35.272-.806.108-1.204-.165-.397-.506-.71-.93-.78l-.894-.15c-.542-.09-.94-.56-.94-1.109v-1.094c0-.55.398-1.02.94-1.11l.894-.149c.424-.07.765-.383.93-.78.165-.398.143-.854-.108-1.204l-.526-.738a1.125 1.125 0 0 1 .12-1.45l.773-.773a1.125 1.125 0 0 1 1.45-.12l.737.527c.35.25.807.272 1.204.107.397-.165.71-.505.78-.929l.15-.894Z'),
        tag.path(nil, 'stroke-linecap' => 'round', 'stroke-linejoin' => 'round', d: 'M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z')
      ])
    end
  end
end
