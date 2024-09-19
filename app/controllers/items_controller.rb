class ItemsController < ApplicationController
  before_action :set_channel, except: %i[ trash]
  before_action :set_item, only: %i[ show edit update destroy disable enable unread read ]

  # GET /items
  def index
    if turbo_frame_request?
      logger.info("TURBO_FRAME_REQUEST")
    end
    @items = @channel.items.enabled.all.order(pub_date: :desc)
  end

  # GET /items/1
  def show
  end

  # GET /items/new
  def new
    @item = @channel.items.build
  end

  # GET /items/1/edit
  def edit
  end

  # POST /items
  def create
    @item = @channel.items.build(item_params)

    if @item.save
      redirect_to [@channel, @item], notice: "Item was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /items/1
  def update
    common_action_for_update(item_params)
  end

  # DELETE /items/1
  def destroy
    @item.destroy!
    redirect_to channel_items_url(@channel), notice: "Item was successfully destroyed.", status: :see_other
  end

  # disable_channel_item PATCH /channels/:channel_id/items/:id/disable(.:format)
  def disable
    common_action_for_update(disabled: true)
  end

  # enable_channel_item PATCH /channels/:channel_id/items/:id/enable(.:format)
  def enable
    common_action_for_update(disabled: false)
  end

  # unread_channel_item PATCH /channels/:channel_id/items/:id/unread(.:format)
  def unread
    common_action_for_update(unread: true)
  end

  # read_channel_item PATCH /channels/:channel_id/items/:id/read(.:format)
  def read
    common_action_for_update(unread: false)
  end

  # trash GET /trash(.:format)
  def trash
    @items = Item.where(disabled: true).all
  end

  private
    def set_channel
      @channel = Channel.find(params[:channel_id])
    end

    def set_item
      @item = Item.find(params[:id])
    end

    def item_params
      permitted_item_params
    end

    def permitted_item_params
      params.require(:item).permit(:title, :url, :description, :unread, :disabled)
    end

    def common_action_for_update(params)
      if @item.update(params)
        redirect_to [@channel, @item], notice: "Item was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end
end
