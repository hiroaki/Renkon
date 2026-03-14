# Shared Turbo Stream builders for subscriptions-pane UI updates.
#
# Responsibilities:
# - Return reusable stream fragments for list/modal/articles/contents updates.
# - Keep CRUD success responses consistent across SubscriptionsController and GroupsController.
#
# Boundary:
# - Domain decisions (create/update/destroy success/failure) stay in each controller action.
# - This concern only builds stream payloads and does not perform business logic.
module SubscriptionsStreams
  private

    def subscriptions_reload_stream
      turbo_stream.replace('subscriptions', helpers.turbo_frame_tag('subscriptions', src: list_subscriptions_path))
    end

    def modal_close_stream
      turbo_stream.update('modal', '')
    end

    def create_flow_trigger_stream(subscription)
      turbo_stream.update(
        'subscription-create-flow-hook',
        partial: 'subscriptions/create_flow_trigger',
        locals: { subscription: subscription }
      )
    end

    def articles_reset_stream
      turbo_stream.replace('articles', helpers.turbo_frame_tag('articles'))
    end

    def contents_reset_stream
      turbo_stream.replace('contents', helpers.turbo_frame_tag('contents', autoscroll: true, data: { autoscroll_block: 'start' }))
    end
end