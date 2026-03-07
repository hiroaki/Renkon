class GroupsController < ApplicationController
  before_action :set_group, only: %i[ destroy ]

  def new
    @group = Group.new(parent_id: params[:parent_id])
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to subscriptions_path, notice: 'Group was successfully created.', status: :see_other
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

  # reorder_groups PATCH /groups/reorder(.:format)
  def reorder
    raw_nodes = params[:group_nodes]

    unless raw_nodes.is_a?(Array)
      return render_reorder_error('group_nodes must be an array')
    end

    nodes = raw_nodes.map do |node|
      {
        id: node[:id].to_i,
        parent_id: node[:parent_id].presence&.to_i,
        position: node[:position].to_i,
      }
    end

    if nodes.empty?
      return render_reorder_error('group_nodes must not be empty')
    end

    ids = nodes.map { |node| node[:id] }
    if ids.any? { |id| id <= 0 } || ids.uniq.length != ids.length
      return render_reorder_error('group id is invalid')
    end

    all_ids = Group.ordered.pluck(:id)
    unless ids.sort == all_ids.sort
      return render_reorder_error('group_nodes must include every existing group id exactly once')
    end

    parent_ids = nodes.map { |node| node[:parent_id] }.compact
    unless (parent_ids - all_ids).empty?
      return render_reorder_error('parent_id is invalid')
    end

    parent_ids_by_group = nodes.to_h { |node| [node[:id], node[:parent_id]] }
    if cyclic_group_hierarchy?(parent_ids_by_group)
      return render_reorder_error('group hierarchy must not contain cycles')
    end

    grouped_positions = nodes.group_by { |node| node[:parent_id] }
    grouped_positions.each_value do |siblings|
      positions = siblings.map { |node| node[:position] }
      next if positions.uniq.length == positions.length

      return render_reorder_error('position must be unique within the same parent')
    end

    Group.transaction do
      nodes.each do |node|
        Group.where(id: node[:id]).update_all(parent_id: node[:parent_id], position: node[:position])
      end
    end

    head :no_content
  end

  private

    def set_group
      @group = Group.find(params[:id])
    end

    def group_params
      params.require(:group).permit(:name, :parent_id)
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

    def render_reorder_error(message)
      render json: { error: message }, status: :unprocessable_entity
    end
end
