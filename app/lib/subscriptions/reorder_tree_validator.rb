module Subscriptions
  class ReorderTreeValidator
    def self.call(raw_nodes:)
      new(raw_nodes:).call
    end

    def initialize(raw_nodes:)
      @raw_nodes = raw_nodes
    end

    def call
      return error('tree_nodes must be an array') unless @raw_nodes.is_a?(Array)

      nodes = normalize_nodes(@raw_nodes)
      return error('tree_nodes must not be empty') if nodes.empty?

      group_nodes = nodes.select { |n| n[:item_type] == 'group' }
      subscription_nodes = nodes.select { |n| n[:item_type] == 'subscription' }
      return error('item_type is invalid') if group_nodes.length + subscription_nodes.length != nodes.length

      group_ids = group_nodes.map { |n| n[:id] }
      subscription_ids = subscription_nodes.map { |n| n[:id] }
      return error('id is invalid') if invalid_or_duplicate_ids?(group_ids) || invalid_or_duplicate_ids?(subscription_ids)

      return error('tree_nodes must include every existing group id exactly once') unless group_ids.sort == Group.ordered.pluck(:id).sort
      return error('tree_nodes must include every existing subscription id exactly once') unless subscription_ids.sort == Subscription.ordered.pluck(:id).sort

      parent_ids = nodes.map { |n| n[:parent_group_id] }.compact
      return error('parent_group_id is invalid') unless (parent_ids - group_ids).empty?

      parent_ids_by_group = group_nodes.to_h { |n| [n[:id], n[:parent_group_id]] }
      return error('group hierarchy must not contain cycles') if cyclic_group_hierarchy?(parent_ids_by_group)

      siblings = nodes.group_by { |n| n[:parent_group_id] }
      siblings.each_value do |items|
        positions = items.map { |n| n[:position] }
        return error('position must be unique within the same parent') unless positions.uniq.length == positions.length
      end

      {
        ok: true,
        nodes: nodes,
        group_nodes: group_nodes,
        subscription_nodes: subscription_nodes,
      }
    end

    private

    def normalize_nodes(raw_nodes)
      raw_nodes.map do |node|
        {
          item_type: node[:item_type].to_s,
          id: node[:id].to_i,
          parent_group_id: node[:parent_group_id].presence&.to_i,
          position: node[:position].to_i,
        }
      end
    end

    def error(message)
      { ok: false, error: message }
    end

    def invalid_or_duplicate_ids?(ids)
      ids.any? { |id| id <= 0 } || ids.uniq.length != ids.length
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
  end
end
