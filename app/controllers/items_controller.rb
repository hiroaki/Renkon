class ItemsController < ApplicationController
  before_action :set_channel
  before_action :set_item, only: %i[ show edit update destroy ]

  # GET /items
  def index
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
    if @item.update(item_params)
      redirect_to [@channel, @item], notice: "Item was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /items/1
  def destroy
    @item.destroy!
    redirect_to channel_items_url(@channel), notice: "Item was successfully destroyed.", status: :see_other
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
      params.require(:item).permit(:title, :link, :description, :unread, :disabled)
    end
end
