class GroupsController < ApplicationController
  before_action :set_group, only: %i[ destroy ]

  def new
    @group = Group.new(parent_id: params[:parent_id])
  end

  def create
    @group = Group.new(group_params)

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
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /groups/:id
  def destroy
    @group.destroy!

    if request.xhr?
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

end
