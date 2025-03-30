class SubscriptionsController < ApplicationController
  include Factory

  before_action :set_subscription, only: %i[ show edit update destroy fetch ]

  # FOR DEVELOPMENT
  def main
    @subscriptions = Subscription.all_with_count_articles(unread: true)
    render layout: 'viewport_full'
  end

  # GET /subscriptions
  def index
    @subscriptions = Subscription.all_with_count_articles(unread: true)
  end

  # GET /subscriptions/1
  def show
    # NOTE: 追加のパラメータ short: true をビューで使っています
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
        render
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscription_params
      params.require(:subscription).permit(:title, :src, :description, :last_build_date, :url, :favicon)
    end
end
