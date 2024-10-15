class ChannelsController < ApplicationController
  include Factory

  before_action :set_channel, only: %i[ show edit update destroy fetch ]

  # FOR DEVELOPMENT
  def main
    @channels = Channel.all_with_count_items(unread: true)
    render layout: 'viewport_full'
  end

  # GET /channels
  def index
    @channels = Channel.all_with_count_items(unread: true)
  end

  # GET /channels/1
  def show
    # NOTE: 追加のパラメータ short: true をビューで使っています
  end

  # GET /channels/new
  def new
    @channel = Channel.new
  end

  # GET /channels/1/edit
  def edit
  end

  # POST /channels
  def create
    @channel = Channel.new(channel_params)

    if @channel.save
      redirect_to @channel, notice: "Channel was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /channels/1
  def update
    if @channel.update(channel_params)
      redirect_to @channel, notice: "Channel was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /channels/1
  def destroy
    @channel.destroy!
    redirect_to channels_url, notice: "Channel was successfully destroyed.", status: :see_other
  end

  # fetch_channel GET /channels/:id/fetch(.:format)
  def fetch
    fetch_and_merge_feed_entries_for_channel(@channel)
    redirect_to channel_url(@channel, short: !!params[:short]), status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_channel
      @channel = Channel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def channel_params
      params.require(:channel).permit(:title, :src, :description, :last_build_date, :url)
    end
end
