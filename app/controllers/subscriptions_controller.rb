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
        .where(group_id: @groups.map(&:id))

      @subscriptions_by_group = grouped.group_by(&:group_id)
    end
end
