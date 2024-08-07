class ChannelsController < ApplicationController
  before_action :set_channel, only: %i[ show edit update destroy fetch items ]

  # GET /channels
  def index
    @channels = Channel.all
  end

  # GET /channels/1
  def show
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
    @channel.fetch
  end

  # items_channel GET /channels/:id/items(.:format)
  def items
    rss = fetch
    @items = rss.items
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_channel
      @channel = Channel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def channel_params
      params.require(:channel).permit(:title, :link, :description, :last_build_date)
    end
end
