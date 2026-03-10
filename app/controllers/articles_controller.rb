class ArticlesController < ApplicationController
  before_action :set_subscription, except: %i[ trash empty_trash ]
  before_action :set_article, only: %i[ show edit update destroy disable enable unread read ]

  # article_articles GET /articles/:article_id/articles(.:format)
  def index
    @articles = @subscription.articles.enabled.all.order(pub_date: :desc)
  end

  # article_article GET /articles/:article_id/articles/:id(.:format)
  def show
  end

  # new_article_article GET /articles/:article_id/articles/new(.:format)
  def new
    @article = @subscription.articles.build
  end

  # edit_article_article GET /articles/:article_id/articles/:id/edit(.:format)
  def edit
  end

  # article_articles POST /articles/:article_id/articles(.:format)
  def create
    @article = @subscription.articles.build(article_params)

    if @article.save
      redirect_to [@subscription, @article], notice: "Article was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # article_article PATCH|PUT /articles/:article_id/articles/:id(.:format)
  def update
    common_action_for_update(article_params)
  end

  # article_article DELETE /articles/:article_id/articles/:id(.:format)
  def destroy
    @article.destroy!
    redirect_to subscription_articles_url(@subscription), notice: "Article was successfully destroyed.", status: :see_other
  end

  # disable_article_article PATCH /articles/:article_id/articles/:id/disable(.:format)
  def disable
    common_action_for_update(disabled: true)
  end

  # enable_article_article PATCH /articles/:article_id/articles/:id/enable(.:format)
  def enable
    common_action_for_update(disabled: false)
  end

  # unread_article_article PATCH /articles/:article_id/articles/:id/unread(.:format)
  def unread
    common_action_for_update(unread: true)
  end

  # read_article_article PATCH /articles/:article_id/articles/:id/read(.:format)
  def read
    common_action_for_update(unread: false)
  end

  # bulk_update_read_status_subscription_articles PATCH /subscriptions/:subscription_id/articles/bulk_update_read_status(.:format)
  def bulk_update_read_status
    article_ids_result = normalize_article_ids(params[:article_ids])
    if article_ids_result[:invalid].any?
      return render_bulk_error('article_ids contains invalid id')
    end

    article_ids = article_ids_result[:ids]
    if article_ids.empty?
      return render_bulk_error('article_ids must not be empty')
    end

    target_unread = normalize_boolean_param(params[:target_unread])
    if target_unread.nil?
      return render_bulk_error('target_unread must be true or false')
    end

    articles_by_id = @subscription.articles.where(id: article_ids).index_by(&:id)

    succeeded_ids = []
    failed_ids = []
    errors = {}

    article_ids.each do |article_id|
      article = articles_by_id[article_id]
      if article.nil?
        failed_ids << article_id
        errors[article_id.to_s] = 'article not found in the subscription'
        next
      end

      if article.update(unread: target_unread)
        succeeded_ids << article_id
      else
        failed_ids << article_id
        errors[article_id.to_s] = article.errors.full_messages.join(', ').presence || 'failed to update read status'
      end
    end

    render json: {
      succeeded_ids: succeeded_ids,
      failed_ids: failed_ids,
      errors: errors,
    }, status: :ok
  end

  # bulk_delete_subscription_articles PATCH /subscriptions/:subscription_id/articles/bulk_delete(.:format)
  def bulk_delete
    article_ids_result = normalize_article_ids(params[:article_ids])
    if article_ids_result[:invalid].any?
      return render_bulk_error('article_ids contains invalid id')
    end

    article_ids = article_ids_result[:ids]
    if article_ids.empty?
      return render_bulk_error('article_ids must not be empty')
    end

    articles_by_id = @subscription.articles.where(id: article_ids).index_by(&:id)

    disabled_ids = []
    destroyed_ids = []
    succeeded_ids = []
    failed_ids = []
    errors = {}

    article_ids.each do |article_id|
      article = articles_by_id[article_id]
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

    render json: {
      succeeded_ids: succeeded_ids,
      disabled_ids: disabled_ids,
      destroyed_ids: destroyed_ids,
      failed_ids: failed_ids,
      errors: errors,
    }, status: :ok
  end

  # trash GET /trash(.:format)
  def trash
    @articles = Article.where(disabled: true).all
  end

  # trash DELETE /trash(.:format)
  def empty_trash
    number_of_deleted = Article.empty_trash

    redirect_to(subscriptions_path,
      notice: "#{number_of_deleted} disabled articles were successfully deleted.",
      status: :see_other,
    )
  end

  private
    def set_subscription
      @subscription = Subscription.find(params[:subscription_id])
    end

    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      permitted_article_params
    end

    def permitted_article_params
      params.require(:article).permit(:title, :url, :description, :unread, :disabled)
    end

    def common_action_for_update(params)
      if @article.update(params)
        redirect_to [@subscription, @article], notice: "Article was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def render_bulk_error(message)
      render json: { error: message }, status: :unprocessable_entity
    end

    def normalize_article_ids(raw_ids)
      return { ids: [], invalid: ['not-array'] } unless raw_ids.is_a?(Array)

      ids = []
      invalid = []

      raw_ids.each do |raw_id|
        normalized = Integer(raw_id, exception: false)
        if normalized.nil? || normalized <= 0
          invalid << raw_id
        else
          ids << normalized
        end
      end

      { ids: ids.uniq, invalid: invalid }
    end

    def normalize_boolean_param(raw)
      return true if raw == true || raw.to_s == 'true'
      return false if raw == false || raw.to_s == 'false'

      nil
    end
end
