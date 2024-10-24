class ItemsController < ApplicationController
  before_action :set_channel, except: %i[ trash empty_trash ]
  before_action :set_item, only: %i[ show edit update destroy disable enable unread read ]

  # channel_items GET /channels/:channel_id/items(.:format)
  def index
    @items = @channel.items.enabled.all.order(pub_date: :desc)
  end

  # channel_item GET /channels/:channel_id/items/:id(.:format)
  def show
  end

  # new_channel_item GET /channels/:channel_id/items/new(.:format)
  def new
    @item = @channel.items.build
  end

  # edit_channel_item GET /channels/:channel_id/items/:id/edit(.:format)
  def edit
  end

  # channel_items POST /channels/:channel_id/items(.:format)
  def create
    @item = @channel.items.build(item_params)

    if @item.save
      redirect_to [@channel, @item], notice: "Item was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # channel_item PATCH|PUT /channels/:channel_id/items/:id(.:format)
  def update
    common_action_for_update(item_params)
  end

  # channel_item DELETE /channels/:channel_id/items/:id(.:format)
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

  # trash DELETE /trash(.:format)
  def empty_trash
    number_of_deleted = Item.empty_trash

    redirect_to(root_path,
      notice: "#{number_of_deleted} items were successfully deleted.",
      status: :see_other,
    )
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
