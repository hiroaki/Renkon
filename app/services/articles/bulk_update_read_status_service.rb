module Articles
  class BulkUpdateReadStatusService
    def self.call(article_ids:, articles_by_id:, target_unread:)
      new(article_ids:, articles_by_id:, target_unread:).call
    end

    def initialize(article_ids:, articles_by_id:, target_unread:)
      @article_ids = article_ids
      @articles_by_id = articles_by_id
      @target_unread = target_unread
    end

    def call
      succeeded_ids = []
      failed_ids = []
      errors = {}

      @article_ids.each do |article_id|
        article = @articles_by_id[article_id]
        if article.nil?
          failed_ids << article_id
          errors[article_id.to_s] = 'article not found in the subscription'
          next
        end

        if article.update(unread: @target_unread)
          succeeded_ids << article_id
        else
          failed_ids << article_id
          errors[article_id.to_s] = article.errors.full_messages.join(', ').presence || 'failed to update read status'
        end
      end

      {
        succeeded_ids: succeeded_ids,
        failed_ids: failed_ids,
        errors: errors,
      }
    end
  end
end
