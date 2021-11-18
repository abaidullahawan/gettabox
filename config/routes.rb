# frozen_string_literal: true

Rails.application.routes.draw do
  resources :import_mappings
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  resources :email_templates
  resources :general_settings
  resources :seasons do
    collection do
      post 'import', to: 'seasons#import'
      post 'bulk_method', to: 'seasons#bulk_method'
      get 'archive', to: 'seasons#archive'
      post 'restore', to: 'seasons#restore'
      post 'permanent_delete', to: 'seasons#permanent_delete'
      post 'season_by_name', to: 'seasons#search_season_by_name'
    end
  end
  devise_for :users
  resources :users, except: [:create] do
    collection do
      post 'user_create', to: 'users#create'
      post 'import', to: 'users#import'
      post 'bulk_method', to: 'users#bulk_method'
      get 'archive', to: 'users#archive'
      post 'restore', to: 'users#restore'
    end
  end

  resources :products do
    collection do
      post 'import', to: 'products#import'
      post 'bulk_method', to: 'products#bulk_method'
      get 'archive', to: 'products#archive'
      post 'restore', to: 'products#restore'
      post 'permanent_delete', to: 'products#permanent_delete'
      post 'products_by_title', to: 'products#search_products_by_title'
      post 'products_by_sku', to: 'products#search_products_by_sku'
      post 'check_category', to: 'products#search_category'
    end
  end

  resources :categories do
    collection do
      post 'import', to: 'categories#import'
      post 'bulk_method', to: 'categories#bulk_method'
      get 'archive', to: 'categories#archive'
      post 'restore', to: 'categories#restore'
      post 'permanent_delete', to: 'categories#permanent_delete'
      post 'category_by_title', to: 'categories#search_category_by_title'
    end
  end

  resources :purchase_orders do
    collection do
      post 'import', to: 'purchase_orders#import'
      post 'bulk_method', to: 'purchase_orders#bulk_method'
      get 'archive', to: 'purchase_orders#archive'
      post 'restore', to: 'purchase_orders#restore'
      post 'send_email', to: 'purchase_orders#send_mail_to_supplier'
    end
  end

  resources :purchase_deliveries do
    collection do
      post 'import', to: 'purchase_deliveries#import'
      post 'bulk_method', to: 'purchase_deliveries#bulk_method'
      get 'archive', to: 'purchase_deliveries#archive'
      post 'restore', to: 'purchase_deliveries#restore'
      post 'permanent_delete', to: 'purchase_deliveries#permanent_delete'
    end
  end

  resources :system_users do
    collection do
      post 'import', to: 'system_users#import'
      post 'bulk_method', to: 'system_users#bulk_method'
      get 'archive', to: 'system_users#archive'
      post 'restore', to: 'system_users#restore'
      post 'system_user_by_name', to: 'system_users#search_system_user_by_name'
    end
  end

  get '/home', to: 'home#dashboard'
  get '/settings', to: 'settings#index'

  resources :product_mappings
  resources :extra_field_names
  resources :order_dispatches
  post 'product_file', to: 'products#import_product_file'

  # Order Dispatch Routes
  get 'all_order_data', to: 'order_dispatches#all_order_data'
  get 'get_response_orders', to: 'order_dispatches#get_response_orders'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root 'home#dashboard'

  # Dashboard Routes
  get '/dashboard/sales', to: 'dashboards#sales', as: :dashboard_sales
  get '/dashboard/ecommerce', to: 'dashboards#ecommerce', as: :dashboard_ecommerce
  get '/dashboard/analytics', to: 'dashboards#analytics', as: :dashboard_analytics
  get '/dashboard/crm', to: 'dashboards#crm', as: :dashboard_crm
  get '/dashboard/project', to: 'dashboards#project', as: :dashboard_project
  get '/dashboard/search', to: 'dashboards#search', as: :dashboard_search

  # Discussions Routes
  get '/discussions/inbox', to: 'discussions#inbox', as: :discussions_inbox
  get '/discussions/chat', to: 'discussions#chat', as: :discussions_chat

  # Todos Routes
  get '/todos/lists', to: 'todos#lists', as: :todos_lists
  get '/todos/notes', to: 'todos#notes', as: :todos_notes

  # UI Components Routes
  get '/ui_components/ui_alerts', to: 'ui_components#ui_alerts', as: :ui_alerts
  get '/ui_components/ui_badges', to: 'ui_components#ui_badges', as: :ui_badges
  get '/ui_components/ui_buttons', to: 'ui_components#ui_buttons', as: :ui_buttons
  get '/ui_components/ui_cards', to: 'ui_components#ui_cards', as: :ui_cards
  get '/ui_components/ui_dropdowns', to: 'ui_components#ui_dropdowns', as: :ui_dropdowns
  get '/ui_components/ui_forms', to: 'ui_components#ui_forms', as: :ui_forms
  get '/ui_components/ui_list_groups', to: 'ui_components#ui_list_groups', as: :ui_list_groups
  get '/ui_components/ui_modals', to: 'ui_components#ui_modals', as: :ui_modals
  get '/ui_components/ui_progress_bars', to: 'ui_components#ui_progress_bars', as: :ui_progress_bars
  get '/ui_components/ui_tables', to: 'ui_components#ui_tables', as: :ui_tables
  get '/ui_components/ui_tabs', to: 'ui_components#ui_tabs', as: :ui_tabs
  get '/ui_components/feather_icons', to: 'ui_components#feather_icons', as: :feather_icons
  get '/ui_components/line_icons', to: 'ui_components#line_icons', as: :line_icons
  get '/ui_components/icofont_icons', to: 'ui_components#icofont_icons', as: :icofont_icons

  # Charts Routes
  get '/charts/line', to: 'charts#line', as: :charts_line
  get '/charts/area', to: 'charts#area', as: :charts_area
  get '/charts/column', to: 'charts#column', as: :charts_column
  get '/charts/bar', to: 'charts#bar', as: :charts_bar
  get '/charts/mixed', to: 'charts#mixed', as: :charts_mixed
  get '/charts/pie', to: 'charts#pie', as: :charts_pie

  # Pages Routes
  get 'pages/users_card', to: 'pages#users_card', as: :pages_users_card
  get 'pages/notifications', to: 'pages#notifications', as: :pages_notifications
  get 'pages/timeline', to: 'pages#timeline', as: :pages_timeline
  get 'pages/invoice_template', to: 'pages#invoice_template', as: :pages_invoice_template
  get 'pages/gallery', to: 'pages#gallery', as: :pages_gallery
  get 'pages/faq', to: 'pages#faq', as: :pages_faq
  get 'pages/pricing', to: 'pages#pricing', as: :pages_pricing
  get 'pages/profile', to: 'pages#profile', as: :pages_profile
  get 'pages/profile_settings', to: 'pages#profile_settings', as: :pages_profile_settings
  get 'pages/error', to: 'pages#error', as: :pages_error

  # Auth Routes
  get 'auth/signup', to: 'auth#signup', as: :auth_signup
  get 'auth/signin', to: 'auth#signin', as: :auth_signin
  get 'auth/forgot_password', to: 'auth#forgot_password', as: :auth_forgot_password
end
