module ApplicationHelper
  # turbo-frame リクエストの場合に、 turbo_frame_tag ヘルパーを与えられた引数をそのまま渡して呼び出します。
  # そうでない場合は block を capture して返します。
  def turbo_frame_tag_if_turbo_frame_request(*ids, **attributes, &block)
    if turbo_frame_request?
      turbo_frame_tag(*ids, **attributes, &block)
    elsif block_given?
      capture(&block)
    end
  end

  # turbo-frame リクエストの場合に target_id そのままを、そうでない場合に '_top' を返します。
  def turbo_frame_if_turbo_frame_request(target_id, default = '_top')
    turbo_frame_request? ? target_id : default
  end

  # turbo-frame リクエストではない場合に block を capture して返します。
  # turbo-frame リクエストの場合は nil を返します。
  def capture_unless_turbo_frame_request(&block)
    unless turbo_frame_request?
      capture(&block)
    end
  end

  # デフォルトの rss アイコン
  # https://icons.getbootstrap.jp/icons/rss/
  def default_favicon
    <<-END_OF_STRING
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="inline" viewBox="0 0 16 16">
      <path d="M14 1a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1zM2 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2z"/>
      <path d="M5.5 12a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0m-3-8.5a1 1 0 0 1 1-1c5.523 0 10 4.477 10 10a1 1 0 1 1-2 0 8 8 0 0 0-8-8 1 1 0 0 1-1-1m0 4a1 1 0 0 1 1-1 6 6 0 0 1 6 6 1 1 0 1 1-2 0 4 4 0 0 0-4-4 1 1 0 0 1-1-1"/>
    </svg>
    END_OF_STRING
    .html_safe
  end
end
