class SubscriptionsController < ApplicationController
  include Factory
  include SubscriptionsStreams

  before_action :set_subscription, only: %i[ edit update destroy refresh_feed refresh_feed_row ]
  before_action :set_row_subscription, only: %i[ row ]

  # FOR DEVELOPMENT
  def main
    load_grouped_subscriptions
    render layout: 'viewport_full'
  end

  # GET /subscriptions
  def index
    load_grouped_subscriptions
  end

  # GET /subscriptions/list
  def list
    load_grouped_subscriptions
    render :index
  end

  # GET /subscriptions/1
  def show
    @subscription = Subscription.find(params[:id])
  end

  # GET /subscriptions/1/row
  def row
  end

  # GET /subscriptions/new
  def new
    @subscription = Subscription.new
    @insert_context_type = params[:insert_context_type]
    @insert_context_id = params[:insert_context_id]
  end

  # GET /subscriptions/1/edit
  def edit
  end

  # POST /subscriptions
  def create
    @subscription = Subscription.new(subscription_params)
    apply_insert_context(@subscription)

    if @subscription.save
      if turbo_frame_request?
        render turbo_stream: stream_set_for_create(subscription: @subscription)
      else
        redirect_to @subscription, notice: "Subscription was successfully created."
      end
    else
      @insert_context_type = params[:insert_context_type]
      @insert_context_id = params[:insert_context_id]
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /subscriptions/1
  def update
    remove_favicon = params[:subscription][:remove_favicon] == '1'
    purge_after_update = @subscription.favicon.attached? && remove_favicon
    fetch_favicon = params[:subscription][:fetch_favicon] == '1'

    # avoid warning "Unpermitted parameter"
    params[:subscription].delete(:remove_favicon)
    params[:subscription].delete(:fetch_favicon)

    if @subscription.update(subscription_params)
      if fetch_favicon
        fetch_favicon_and_update_for(@subscription)
      elsif purge_after_update
        @subscription.favicon.purge_later
      end

      if turbo_frame_request?
        flash.now[:notice] = 'Subscription was successfully updated.'
        render turbo_stream: stream_set_for_update
      else
        redirect_to @subscription, notice: "Subscription was successfully updated.", status: :see_other
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /subscriptions/1
  def destroy
    if @subscription.destroy
      if turbo_frame_request?
        flash.now[:notice] = 'Subscription was successfully destroyed.'
        render turbo_stream: stream_set_for_destroy
      else
        redirect_to subscriptions_url, notice: 'Subscription was successfully destroyed.', status: :see_other
      end
    else
      flash.now[:notice] = 'Subscription destruction failed.'
      render :edit, status: :unprocessable_content
    end
  end

  # refresh_feed_subscription PATCH /subscriptions/:id/refresh_feed(.:format)
  def refresh_feed
    fetch_and_merge_feed_entries_for_subscription(@subscription)
    redirect_to subscription_url(@subscription), notice: "Subscription was successfully refreshed.", status: :see_other
  rescue FeedUtils::Error => error
    redirect_to subscription_url(@subscription), alert: error.message, status: :see_other
  end

  # refresh_feed_row_subscription PATCH /subscriptions/:id/refresh_feed_row(.:format)
  def refresh_feed_row
    fetch_and_merge_feed_entries_for_subscription(@subscription)
    redirect_to row_subscription_url(@subscription), status: :see_other
  rescue FeedUtils::Error => error
    render_refresh_feed_row_error(error)
  end

  # reorder_tree_subscriptions PATCH /subscriptions/reorder_tree(.:format)
  def reorder_tree
    validation = Subscriptions::ReorderTreeValidator.call(raw_nodes: params[:tree_nodes])
    unless validation[:ok]
      return render_reorder_error(validation[:error])
    end

    group_nodes = validation[:group_nodes]
    subscription_nodes = validation[:subscription_nodes]

    Subscription.transaction do
      group_nodes.each do |node|
        Group.where(id: node[:id]).update_all(parent_id: node[:parent_group_id], position: node[:position])
      end

      subscription_nodes.each do |node|
        Subscription.where(id: node[:id]).update_all(group_id: node[:parent_group_id], position: node[:position])
      end
    end

    head :no_content
  end

  # opml_export_subscriptions GET /subscriptions/opml_export(.:format)
  def opml_export
    set_opml_export_context
  end

  # opml_export_download_subscriptions POST /subscriptions/opml_export_download(.:format)
  def opml_export_download
    set_opml_export_context
    scope = params[:scope].to_s == 'selected' ? 'selected' : 'all'
    include_groups = ActiveModel::Type::Boolean.new.cast(params[:include_groups])

    if scope == 'selected' && !@selected_available
      flash.now[:alert] = 'Select a subscription or group before exporting selected items.'
      return render :opml_export, status: :unprocessable_content
    end

    result = Subscriptions::OpmlExportService.call(
      scope: scope,
      include_groups: include_groups,
      selected_item_type: params[:selected_item_type],
      selected_item_id: params[:selected_item_id]
    )

    send_data(
      result[:xml],
      type: 'application/xml; charset=utf-8',
      disposition: 'attachment',
      filename: "subscriptions-#{Time.current.strftime('%Y%m%d')}.opml"
    )
  rescue ActiveRecord::RecordNotFound
    flash.now[:alert] = 'Selected item was not found.'
    render :opml_export, status: :unprocessable_content
  end

  # opml_import_subscriptions GET /subscriptions/opml_import(.:format)
  def opml_import
  end

  # opml_import_upload_subscriptions POST /subscriptions/opml_import_upload(.:format)
  def opml_import_upload
    result = Subscriptions::OpmlImportUploadService.call(file: params[:file])
    unless result[:ok]
      flash.now[:alert] = result[:error]
      return render :opml_import, status: :unprocessable_content
    end

    @import_result = result
    render turbo_stream: [
      subscriptions_reload_stream,
      turbo_stream.replace(
        SubscriptionsStreams::MODAL_TARGET,
        render_to_string(template: 'subscriptions/opml_import', layout: false)
      ),
    ]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscription_params
      params.require(:subscription).permit(:title, :src, :description, :last_build_date, :url, :favicon)
    end

    def render_reorder_error(message)
      render json: { error: message }, status: :unprocessable_content
    end

    def render_refresh_feed_row_error(error)
      render json: {
        error: error.message,
        category: error.retryable? ? 'temporary' : 'permanent'
      }, status: error.retryable? ? :service_unavailable : :unprocessable_content
    end

    def set_row_subscription
      @subscription = Subscription.all_with_count_articles(unread: true).find(params[:id])
    end

    def load_grouped_subscriptions
      @groups = Group.ordered.to_a
      @root_groups = @groups.select { |group| group.parent_id.nil? }
      @groups_by_parent_id = @groups.group_by(&:parent_id)

      grouped = Subscription
        .all_with_count_articles(unread: true)

      @subscriptions_by_group = grouped.group_by(&:group_id)
      @top_level_subscriptions = @subscriptions_by_group[nil] || []
    end

    def set_opml_export_context
      @selected_item_type = params[:selected_item_type].to_s.presence
      @selected_item_id = params[:selected_item_id].to_i
      @selected_available = @selected_item_type.present? && @selected_item_id.positive?
    end

    def apply_insert_context(subscription)
      context_type = params[:insert_context_type].to_s
      context_id = params[:insert_context_id].to_i

      if context_type == 'subscription' && context_id > 0
        anchor = Subscription.find_by(id: context_id)
        return append_to_top_level(subscription) unless anchor

        parent_group_id = anchor.group_id
        insert_position = anchor.position.to_i + 1

        Subscription.transaction do
          shift_mixed_sibling_positions(parent_group_id, insert_position)
          subscription.group_id = parent_group_id
          subscription.position = insert_position
        end
        return
      end

      if context_type == 'group' && context_id > 0
        group = Group.find_by(id: context_id)
        return append_to_top_level(subscription) unless group

        subscription.group_id = group.id
        subscription.position = next_mixed_position(group.id)
        return
      end

      append_to_top_level(subscription)
    end

    def append_to_top_level(subscription)
      subscription.group_id = nil
      subscription.position = next_mixed_position(nil)
    end

    def next_mixed_position(parent_group_id)
      sibling_group_max = Group.where(parent_id: parent_group_id).maximum(:position) || 0
      sibling_subscription_max = Subscription.where(group_id: parent_group_id).maximum(:position) || 0
      [sibling_group_max, sibling_subscription_max].max + 1
    end

    def shift_mixed_sibling_positions(parent_group_id, from_position)
      Group.where(parent_id: parent_group_id)
        .where('position >= ?', from_position)
        .update_all('position = position + 1')

      Subscription.where(group_id: parent_group_id)
        .where('position >= ?', from_position)
        .update_all('position = position + 1')
    end
end
