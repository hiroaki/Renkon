class SubscriptionsController < ApplicationController
  include Factory

  before_action :set_subscription, only: %i[ edit update destroy fetch ]

  # FOR DEVELOPMENT
  def main
    load_grouped_subscriptions
    render layout: 'viewport_full'
  end

  # GET /subscriptions
  def index
    load_grouped_subscriptions
  end

  # GET /subscriptions/1
  def show
    @subscription = if params[:short] == 'true'
      Subscription.all_with_count_articles(unread: true).find(params[:id])
    else
      Subscription.find(params[:id])
    end
  end

  # GET /subscriptions/new
  def new
    @subscription = Subscription.new
  end

  # GET /subscriptions/1/edit
  def edit
  end

  # POST /subscriptions
  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      redirect_to @subscription, notice: "Subscription was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /subscriptions/1
  def update
    purge_after_update = @subscription.favicon.attached? && params[:subscription][:remove_favicon] == '1'
    fetch_favicon = params[:subscription][:fetch_favicon] == '1'

    # avoid warning "Unpermitted parameter"
    params[:subscription].delete(:remove_favicon)
    params[:subscription].delete(:fetch_favicon)

    if @subscription.update(subscription_params)
      if purge_after_update
        @subscription.favicon.purge_later
      end

      if fetch_favicon
        # TODO: purge が後になった場合...
        fetch_favicon_and_update_for(@subscription)
      end

      redirect_to @subscription, notice: "Subscription was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /subscriptions/1
  def destroy
    if @subscription.destroy
      if turbo_frame_request?
        # in turbo-frame "modal"
        flash.now[:notice] = 'Subscription was successfully destroyed.'
        @subscriptions = Subscription.all_with_count_articles(unread: true)
        respond_to do |format|
          format.turbo_stream
          format.html { render :destroy }
        end
      else
        redirect_to subscriptions_url, notice: 'Subscription was successfully destroyed.', status: :see_other
      end
    else
      flash.now[:notice] = 'Subscription destruction failed.'
      render :edit, status: :unprocessable_entity
    end
  end

  # fetch_subscription PATCH /subscriptions/:id/fetch(.:format)
  def fetch
    logger.info("params[:dry_run]=[#{params[:dry_run] ? 'true' : 'false'}]")
    unless params[:dry_run]
      fetch_and_merge_feed_entries_for_subscription(@subscription)
    end

    redirect_to subscription_url(@subscription, short: !!params[:short]), notice: "Subscription was successfully refreshed.", status: :see_other
  end

  # reorder_subscriptions PATCH /subscriptions/reorder(.:format)
  def reorder
    if params[:grouped_orders].present?
      return reorder_grouped_orders(params[:grouped_orders])
    end

    ordered_ids = params[:ordered_ids]

    unless ordered_ids.is_a?(Array)
      return render_reorder_error('ordered_ids must be an array')
    end

    ids = ordered_ids.map(&:to_i)

    if ids.empty?
      return render_reorder_error('ordered_ids must not be empty')
    end

    if ids.uniq.length != ids.length
      return render_reorder_error('ordered_ids must not include duplicates')
    end

    group_id = params[:group_id]&.to_i
    group = Group.find_by(id: group_id)

    if params[:group_id].present? && group.nil?
      return render_reorder_error('group_id is invalid')
    end

    scope = if group
      Subscription.ordered_within_group(group.id)
    else
      Subscription.ordered
    end

    all_ids = scope.pluck(:id)
    unless ids.sort == all_ids.sort
      return render_reorder_error('ordered_ids must include every existing subscription id exactly once')
    end

    Subscription.transaction do
      ids.each_with_index do |id, index|
        attributes = { position: index + 1 }
        attributes[:group_id] = group.id if group
        Subscription.where(id: id).update_all(attributes)
      end
    end

    head :no_content
  end

  # reorder_tree_subscriptions PATCH /subscriptions/reorder_tree(.:format)
  def reorder_tree
    raw_nodes = params[:tree_nodes]
    unless raw_nodes.is_a?(Array)
      return render_reorder_error('tree_nodes must be an array')
    end

    nodes = raw_nodes.map do |node|
      {
        item_type: node[:item_type].to_s,
        id: node[:id].to_i,
        parent_group_id: node[:parent_group_id].presence&.to_i,
        position: node[:position].to_i,
      }
    end

    if nodes.empty?
      return render_reorder_error('tree_nodes must not be empty')
    end

    group_nodes = nodes.select { |n| n[:item_type] == 'group' }
    subscription_nodes = nodes.select { |n| n[:item_type] == 'subscription' }

    if group_nodes.length + subscription_nodes.length != nodes.length
      return render_reorder_error('item_type is invalid')
    end

    group_ids = group_nodes.map { |n| n[:id] }
    subscription_ids = subscription_nodes.map { |n| n[:id] }

    if invalid_or_duplicate_ids?(group_ids) || invalid_or_duplicate_ids?(subscription_ids)
      return render_reorder_error('id is invalid')
    end

    unless group_ids.sort == Group.ordered.pluck(:id).sort
      return render_reorder_error('tree_nodes must include every existing group id exactly once')
    end

    unless subscription_ids.sort == Subscription.ordered.pluck(:id).sort
      return render_reorder_error('tree_nodes must include every existing subscription id exactly once')
    end

    parent_ids = nodes.map { |n| n[:parent_group_id] }.compact
    unless (parent_ids - group_ids).empty?
      return render_reorder_error('parent_group_id is invalid')
    end

    parent_ids_by_group = group_nodes.to_h { |n| [n[:id], n[:parent_group_id]] }
    if cyclic_group_hierarchy?(parent_ids_by_group)
      return render_reorder_error('group hierarchy must not contain cycles')
    end

    siblings = nodes.group_by { |n| n[:parent_group_id] }
    siblings.each_value do |items|
      positions = items.map { |n| n[:position] }
      return render_reorder_error('position must be unique within the same parent') unless positions.uniq.length == positions.length
    end

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
      render json: { error: message }, status: :unprocessable_entity
    end

    def invalid_or_duplicate_ids?(ids)
      ids.any? { |id| id <= 0 } || ids.uniq.length != ids.length
    end

    def cyclic_group_hierarchy?(parent_ids_by_group)
      parent_ids_by_group.keys.any? do |group_id|
        visited = {}
        current = group_id

        while current
          return true if visited[current]

          visited[current] = true
          current = parent_ids_by_group[current]
        end

        false
      end
    end

    def reorder_grouped_orders(raw_grouped_orders)
      unless raw_grouped_orders.is_a?(Array)
        return render_reorder_error('grouped_orders must be an array')
      end

      grouped_orders = raw_grouped_orders.map do |entry|
        group_id = entry[:group_id].to_i
        ordered_ids = Array(entry[:ordered_ids]).map(&:to_i)

        { group_id: group_id, ordered_ids: ordered_ids }
      end

      if grouped_orders.empty?
        return render_reorder_error('grouped_orders must not be empty')
      end

      group_ids = grouped_orders.map { |entry| entry[:group_id] }
      if group_ids.any? { |id| id <= 0 } || group_ids.uniq.length != group_ids.length
        return render_reorder_error('group_id is invalid')
      end

      unless Group.where(id: group_ids).count == group_ids.length
        return render_reorder_error('group_id is invalid')
      end

      ids = grouped_orders.flat_map { |entry| entry[:ordered_ids] }
      if ids.empty?
        return render_reorder_error('ordered_ids must not be empty')
      end

      if ids.uniq.length != ids.length
        return render_reorder_error('ordered_ids must not include duplicates')
      end

      all_ids = Subscription.ordered.pluck(:id)
      unless ids.sort == all_ids.sort
        return render_reorder_error('ordered_ids must include every existing subscription id exactly once')
      end

      Subscription.transaction do
        grouped_orders.each do |entry|
          entry[:ordered_ids].each_with_index do |id, index|
            Subscription.where(id: id).update_all(group_id: entry[:group_id], position: index + 1)
          end
        end
      end

      head :no_content
    end

    def load_grouped_subscriptions
      Group.default_root!
      @groups = Group.ordered.to_a
      @root_groups = @groups.select { |group| group.parent_id.nil? }
      @groups_by_parent_id = @groups.group_by(&:parent_id)

      grouped = Subscription
        .all_with_count_articles(unread: true)

      @subscriptions_by_group = grouped.group_by(&:group_id)
      @top_level_subscriptions = @subscriptions_by_group[nil] || []
    end
end
