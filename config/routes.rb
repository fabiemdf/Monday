Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  # Monday.com integration routes
  resources :monday, only: [ :index ]
  resources :clients, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  resources :claims, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  resources :leads, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  resources :insurance_companies do
    collection do
      get :columns
    end
  end
  resources :contacts, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    collection do
      get :columns
    end
  end
  resources :documents, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    collection do
      get :columns
    end
  end
end
