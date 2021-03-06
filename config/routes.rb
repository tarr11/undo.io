Todo::Application.routes.draw do

  resources :team_product_requests, :except =>[:destroy, :show, :update]

  root :to => 'home#index'
  resources :oauth_consumers do
    member do
      get :callback
      get :callback2
      match 'client/*endpoint' => 'oauth_consumers#client'
    end
  end
  devise_for :users, :controllers =>{:sessions => "sessions", :registrations => "registrations" }
  match '/settings' => 'user#update', :via => [:put, :post]
  match '/settings' => 'user#show'
  match '/team' => 'home#team'
  match '/please_confirm' => 'home#please_confirm'

  match '/email' => 'email#post', :via => :post
  resources :todo_files
  match "public:path" => "home#public_view", :constraints => {:path=> /.*/}, :via => :get
  match 'file/complete_task' => 'task_folder#mark_task_completed', :via => [:put, :post]

  match "file/new" => "task_folder#create", :via=> :post
  match ":username:path" => "task_folder#folder_view", :constraints => {:path=> /.*/}, :via => :get
  match ":username:path" => "task_folder#new_file", :constraints => {:path=> /.*/}, :via => [:post]
  match ":username:path" => "task_folder#update", :constraints => {:path=> /.*/}, :via => [:put]
  match ":username:path" => "task_folder#delete", :constraints => {:path=> /.*/}, :via => [:delete]
  match ":username:path" => "task_folder#task_view", :constraints => {:path=> /.*/}

  match ":username/:path" => "task_folder#move", :constraints => {
      :path=> /.*/
  }, :via => :post

  match ":username" => "task_folder#folder_view", :via => :get

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with settings:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end


  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end


