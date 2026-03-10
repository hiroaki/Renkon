class ArticlesController < ApplicationController
  before_action :set_subscription, except: %i[ trash empty_trash ]
  before_action :set_article_for_show, only: %i[ show ]
  before_action :set_article, only: %i[ edit update destroy disable enable unread read ]
  before_action :prepare_bulk_articles, only: %i[ bulk_update_read_status bulk_delete ]

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
    target_unread = normalize_boolean_param(params[:target_unread])
    if target_unread.nil?
      return render_bulk_error('target_unread must be true or false')
    end

    result = Articles::BulkUpdateReadStatusService.call(
      article_ids: @bulk_article_ids,
      articles_by_id: @bulk_articles_by_id,
      target_unread: target_unread,
    )

    render json: result, status: :ok
  end

  # bulk_delete_subscription_articles PATCH /subscriptions/:subscription_id/articles/bulk_delete(.:format)
  def bulk_delete
    result = Articles::BulkDeleteService.call(
      article_ids: @bulk_article_ids,
      articles_by_id: @bulk_articles_by_id,
    )

    render json: result, status: :ok
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
      @article = @subscription.articles.find(params[:id])
    end

    def set_article_for_show
      @article = @subscription.articles.find_by(id: params[:id])
      return if @article

      # During rapid delete operations, a stale contents-frame request can arrive
      # after the target article is gone. Treat this as empty contents, not an exception page.
      if turbo_frame_request?
        head :no_content
        return
      end

      raise ActiveRecord::RecordNotFound, "Couldn't find Article with 'id'=#{params[:id]}"
    end

    def prepare_bulk_articles
      article_ids_result = normalize_article_ids(params[:article_ids])
      if article_ids_result[:invalid].any?
        render_bulk_error('article_ids contains invalid id')
        return
      end

      if article_ids_result[:ids].empty?
        render_bulk_error('article_ids must not be empty')
        return
      end

      @bulk_article_ids = article_ids_result[:ids]
      @bulk_articles_by_id = @subscription.articles.where(id: @bulk_article_ids).index_by(&:id)
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
