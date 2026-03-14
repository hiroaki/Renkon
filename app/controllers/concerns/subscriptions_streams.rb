module SubscriptionsStreams
  private

    def subscriptions_reload_stream
      turbo_stream.replace('subscriptions', helpers.turbo_frame_tag('subscriptions', src: list_subscriptions_path))
    end

    def modal_close_stream
      turbo_stream.update('modal', '')
    end

    def articles_reset_stream
      turbo_stream.replace('articles', helpers.turbo_frame_tag('articles'))
    end

    def contents_reset_stream
      turbo_stream.replace('contents', helpers.turbo_frame_tag('contents', autoscroll: true, data: { autoscroll_block: 'start' }))
    end
end