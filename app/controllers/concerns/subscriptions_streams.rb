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
  MODAL_TARGET = 'modal'.freeze
  SUBSCRIPTIONS_TARGET = 'subscriptions'.freeze
  ARTICLES_TARGET = 'articles'.freeze
  CONTENTS_TARGET = 'contents'.freeze
  CREATE_FLOW_HOOK_TARGET = 'subscription-create-flow-hook'.freeze

  private

    def stream_set_for_create(subscription: nil)
      streams = [subscriptions_reload_stream]
      streams << create_flow_trigger_stream(subscription) if subscription
      streams << modal_close_stream
      streams
    end

    def stream_set_for_update
      [subscriptions_reload_stream, modal_close_stream]
    end

    def stream_set_for_destroy
      [
        subscriptions_reload_stream,
        articles_reset_stream,
        contents_reset_stream,
        modal_close_stream,
      ]
    end

    def subscriptions_reload_stream
      turbo_stream.replace(SUBSCRIPTIONS_TARGET, helpers.turbo_frame_tag(SUBSCRIPTIONS_TARGET, src: list_subscriptions_path))
    end

    def modal_close_stream
      turbo_stream.update(MODAL_TARGET, '')
    end

    def create_flow_trigger_stream(subscription)
      turbo_stream.update(
        CREATE_FLOW_HOOK_TARGET,
        partial: 'subscriptions/create_flow_trigger',
        locals: { subscription: subscription }
      )
    end

    def articles_reset_stream
      turbo_stream.replace(ARTICLES_TARGET, helpers.turbo_frame_tag(ARTICLES_TARGET))
    end

    def contents_reset_stream
      turbo_stream.replace(CONTENTS_TARGET, helpers.turbo_frame_tag(CONTENTS_TARGET, autoscroll: true, data: { autoscroll_block: 'start' }))
    end
end