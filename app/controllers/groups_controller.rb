class GroupsController < ApplicationController
  before_action :set_group, only: %i[ edit update destroy ]

  def new
    @group = Group.new(parent_id: params[:parent_id])
    @insert_context_type = params[:insert_context_type]
    @insert_context_id = params[:insert_context_id]
  end

  def create
    @group = Group.new(group_params)
    apply_insert_context(@group)

    if @group.save
      if turbo_frame_request?
        flash.now[:notice] = 'Group was successfully created.'
        render turbo_stream: [
          turbo_stream.replace('subscriptions', helpers.turbo_frame_tag('subscriptions', src: subscriptions_path(short: true))),
          turbo_stream.update('modal', ''),
        ]
      else
        redirect_to subscriptions_path, notice: 'Group was successfully created.', status: :see_other
      end
    else
      @insert_context_type = params[:insert_context_type]
      @insert_context_id = params[:insert_context_id]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_update_params)
      if turbo_frame_request?
        flash.now[:notice] = 'Group was successfully updated.'
        render turbo_stream: [
          turbo_stream.replace('subscriptions', helpers.turbo_frame_tag('subscriptions', src: subscriptions_path(short: true))),
          turbo_stream.update('modal', ''),
        ]
      else
        redirect_to subscriptions_path, notice: 'Group was successfully updated.', status: :see_other
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /groups/:id
  def destroy
    @group.destroy!

    if turbo_frame_request?
      flash.now[:notice] = 'Group was successfully destroyed.'
      render turbo_stream: [
        turbo_stream.replace('subscriptions', helpers.turbo_frame_tag('subscriptions', src: subscriptions_path(short: true))),
        turbo_stream.update('modal', ''),
      ]
    elsif request.xhr?
      head :no_content
    else
      redirect_to subscriptions_url, notice: 'Group was successfully destroyed.', status: :see_other
    end
  end

  private

    def set_group
      @group = Group.find(params[:id])
    end

    def group_params
      params.require(:group).permit(:name, :parent_id)
    end

    def group_update_params
      params.require(:group).permit(:name)
    end

    def apply_insert_context(group)
      context_type = params[:insert_context_type].to_s
      context_id = params[:insert_context_id].to_i

      if context_type == 'subscription' && context_id > 0
        anchor = Subscription.find_by(id: context_id)
        return append_group_to_top_level(group) unless anchor

        parent_group_id = anchor.group_id
        insert_position = anchor.position.to_i + 1

        Group.transaction do
          shift_mixed_sibling_positions(parent_group_id, insert_position)
          group.parent_id = parent_group_id
          group.position = insert_position
        end
        return
      end

      if context_type == 'group' && context_id > 0
        parent_group = Group.find_by(id: context_id)
        return append_group_to_top_level(group) unless parent_group

        group.parent_id = parent_group.id
        group.position = next_mixed_position(parent_group.id)
        return
      end

      # Backward-compatible fallback when parent is explicitly posted (e.g. API/tests).
      if group.parent_id.present?
        group.position = next_mixed_position(group.parent_id)
        return
      end

      append_group_to_top_level(group)
    end

    def append_group_to_top_level(group)
      group.parent_id = nil
      group.position = next_mixed_position(nil)
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
