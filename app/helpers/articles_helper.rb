module ArticlesHelper
	def article_list_item_data(article)
		{
			article_id: article.id,
			url_content: subscription_article_path(article.subscription, article),
			url_destroy: subscription_article_path(article.subscription, article),
			url_bulk_delete: bulk_delete_subscription_articles_path(article.subscription),
			url_bulk_update_read_status: bulk_update_read_status_subscription_articles_path(article.subscription),
			subscription: article.subscription_id,
			articles_target: 'listItem',
			url_source: article.url,
			disabled: article.disabled?.to_s,
			unread: article.unread?.to_s,
			url_read: read_subscription_article_path(article.subscription, article),
			url_unread: unread_subscription_article_path(article.subscription, article),
			url_disable: disable_subscription_article_path(article.subscription, article),
		}
	end
end
