require 'builder'

module Subscriptions
  class OpmlExportService
    def self.call(scope:, include_groups:, selected_item_type:, selected_item_id:)
      new(
        scope: scope,
        include_groups: include_groups,
        selected_item_type: selected_item_type,
        selected_item_id: selected_item_id
      ).call
    end

    def initialize(scope:, include_groups:, selected_item_type:, selected_item_id:)
      @scope = scope.to_s == 'selected' ? 'selected' : 'all'
      @include_groups = include_groups
      @selected_item_type = selected_item_type.to_s
      @selected_item_id = selected_item_id.to_i
    end

    def call
      xml = +""
      builder = Builder::XmlMarkup.new(target: xml, indent: 2)
      builder.instruct!(:xml, version: '1.0', encoding: 'UTF-8')

      builder.opml(version: '2.0') do
        builder.head do
          builder.title('Renkon Subscriptions')
          builder.dateCreated(Time.current.iso8601)
        end

        builder.body do
          if @include_groups
            export_with_groups(builder)
          else
            export_flat(builder)
          end
        end
      end

      { xml: xml }
    end

    private

    def export_with_groups(builder)
      case @scope
      when 'selected'
        export_selected_with_groups(builder)
      else
        export_all_with_groups(builder)
      end
    end

    def export_flat(builder)
      subscriptions_for_scope.each do |subscription|
        build_subscription_outline(builder, subscription)
      end
    end

    def export_all_with_groups(builder)
      groups_by_parent = Group.ordered.group_by(&:parent_id)
      subscriptions_by_group = Subscription.ordered.group_by(&:group_id)

      groups_by_parent[nil].to_a.each do |group|
        build_group_outline(builder, group, groups_by_parent, subscriptions_by_group)
      end

      subscriptions_by_group[nil].to_a.each do |subscription|
        build_subscription_outline(builder, subscription)
      end
    end

    def export_selected_with_groups(builder)
      if @selected_item_type == 'group'
        group = Group.find(@selected_item_id)
        groups_by_parent = Group.ordered.group_by(&:parent_id)
        subscriptions_by_group = Subscription.ordered.group_by(&:group_id)
        build_group_outline(builder, group, groups_by_parent, subscriptions_by_group)
        return
      end

      subscription = Subscription.find(@selected_item_id)
      if subscription.group_id.nil?
        build_subscription_outline(builder, subscription)
        return
      end

      group_path = []
      current = subscription.group
      while current
        group_path.unshift(current)
        current = current.parent
      end

      build_group_path_with_single_subscription(builder, group_path, subscription)
    end

    def build_group_path_with_single_subscription(builder, group_path, subscription)
      root = group_path.shift
      return build_subscription_outline(builder, subscription) unless root

      builder.outline(text: root.name, title: root.name) do
        build_group_path_with_single_subscription_inner(builder, group_path, subscription)
      end
    end

    def build_group_path_with_single_subscription_inner(builder, group_path, subscription)
      current = group_path.shift
      if current
        builder.outline(text: current.name, title: current.name) do
          build_group_path_with_single_subscription_inner(builder, group_path, subscription)
        end
      else
        build_subscription_outline(builder, subscription)
      end
    end

    def build_group_outline(builder, group, groups_by_parent, subscriptions_by_group)
      builder.outline(text: group.name, title: group.name) do
        groups_by_parent[group.id].to_a.each do |child_group|
          build_group_outline(builder, child_group, groups_by_parent, subscriptions_by_group)
        end

        subscriptions_by_group[group.id].to_a.each do |subscription|
          build_subscription_outline(builder, subscription)
        end
      end
    end

    def build_subscription_outline(builder, subscription)
      attrs = {
        text: subscription.title,
        title: subscription.title,
        type: 'rss',
        xmlUrl: subscription.src,
      }
      attrs[:htmlUrl] = subscription.url if subscription.url.present?
      builder.outline(attrs)
    end

    def subscriptions_for_scope
      case @scope
      when 'selected'
        selected_subscriptions
      else
        Subscription.ordered.to_a
      end
    end

    def selected_subscriptions
      if @selected_item_type == 'subscription'
        [Subscription.find(@selected_item_id)]
      elsif @selected_item_type == 'group'
        group = Group.find(@selected_item_id)
        group_ids = descendant_group_ids(group)
        Subscription.where(group_id: group_ids).ordered.to_a
      else
        []
      end
    end

    def descendant_group_ids(group)
      ids = [group.id]
      stack = [group.id]

      while stack.any?
        parent_id = stack.pop
        child_ids = Group.where(parent_id: parent_id).pluck(:id)
        ids.concat(child_ids)
        stack.concat(child_ids)
      end

      ids
    end
  end
end
