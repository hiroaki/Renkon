module Articles
  class BulkDeleteService
    def self.call(article_ids:, articles_by_id:)
      new(article_ids:, articles_by_id:).call
    end

    def initialize(article_ids:, articles_by_id:)
      @article_ids = article_ids
      @articles_by_id = articles_by_id
    end

    def call
      disabled_ids = []
      destroyed_ids = []
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

        if article.disabled?
          if article.destroy
            destroyed_ids << article_id
            succeeded_ids << article_id
          else
            failed_ids << article_id
            errors[article_id.to_s] = article.errors.full_messages.join(', ').presence || 'failed to destroy article'
          end
        else
          if article.update(disabled: true)
            disabled_ids << article_id
            succeeded_ids << article_id
          else
            failed_ids << article_id
            errors[article_id.to_s] = article.errors.full_messages.join(', ').presence || 'failed to disable article'
          end
        end
      end

      {
        succeeded_ids: succeeded_ids,
        disabled_ids: disabled_ids,
        destroyed_ids: destroyed_ids,
        failed_ids: failed_ids,
        errors: errors,
      }
    end
  end
end
