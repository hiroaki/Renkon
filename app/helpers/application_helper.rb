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
end
