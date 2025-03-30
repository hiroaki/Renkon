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
end
