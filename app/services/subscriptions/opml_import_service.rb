require 'rexml/document'

module Subscriptions
  class OpmlImportService
    def self.call(opml_text:)
      new(opml_text:).call
    end

    def initialize(opml_text:)
      @opml_text = opml_text.to_s
      @created_subscriptions = 0
      @created_groups = 0
      @skipped_subscriptions = 0
      @invalid_subscriptions = 0
    end

    def call
      return error('The file is empty.') if @opml_text.strip.empty?

      document = REXML::Document.new(@opml_text)
      body = document.elements['opml/body']
      return error('OPML body is missing.') unless body

      Subscription.transaction do
        body.elements.each('outline') do |outline|
          import_outline(outline, nil)
        end
      end

      {
        ok: true,
        created_subscriptions: @created_subscriptions,
        created_groups: @created_groups,
        skipped_subscriptions: @skipped_subscriptions,
        invalid_subscriptions: @invalid_subscriptions,
      }
    rescue REXML::ParseException
      error('The OPML file could not be parsed.')
    end

    private

    def import_outline(outline, parent_group)
      if subscription_outline?(outline)
        import_subscription_outline(outline, parent_group)
        return
      end

      next_parent = parent_group
      group_name = extract_group_name(outline)
      if group_name.present?
        group = Group.find_or_initialize_by(name: group_name, parent_id: parent_group&.id)
        if group.new_record?
          group.save!
          @created_groups += 1
        end
        next_parent = group
      end

      outline.elements.each('outline') do |child_outline|
        import_outline(child_outline, next_parent)
      end
    end

    def subscription_outline?(outline)
      outline.attributes['xmlUrl'].present? || outline.attributes['xmlurl'].present?
    end

    def import_subscription_outline(outline, parent_group)
      src = (outline.attributes['xmlUrl'] || outline.attributes['xmlurl']).to_s.strip
      if src.blank?
        @invalid_subscriptions += 1
        return
      end

      if Subscription.exists?(src: src)
        @skipped_subscriptions += 1
        return
      end

      title = outline.attributes['title'].presence || outline.attributes['text'].presence || src
      url = (outline.attributes['htmlUrl'] || outline.attributes['htmlurl']).to_s.strip.presence

      Subscription.create!(
        title: title,
        src: src,
        url: url,
        group: parent_group
      )
      @created_subscriptions += 1
    end

    def extract_group_name(outline)
      outline.attributes['title'].presence || outline.attributes['text'].presence
    end

    def error(message)
      {
        ok: false,
        error: message,
        created_subscriptions: 0,
        created_groups: 0,
        skipped_subscriptions: 0,
        invalid_subscriptions: 0,
      }
    end
  end
end
