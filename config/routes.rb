Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  root to: 'subscriptions#main'

  get 'trash', to: 'articles#trash'
  delete 'trash', to: 'articles#empty_trash'

  resources :subscriptions do
    collection do
      get :list
      patch :reorder_tree
      get :opml_export
      post :opml_export_download
      get :opml_import
      post :opml_import_upload
    end

    resources :articles do
      collection do
        patch :bulk_update_read_status
        patch :bulk_delete
      end

      member do
        patch :disable
        patch :enable
        patch :read
        patch :unread
      end
    end

    member do
      get :row
      patch :refresh_feed
      patch :refresh_feed_row
    end
  end

  resources :groups, only: %i[ new create edit update destroy ]
end
