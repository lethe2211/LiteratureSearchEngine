Search::Application.routes.draw do
  root controller: "static_pages", action: "search", interface: 1
  get "static_pages/search" => redirect("/static_pages/search/1")
  get "static_pages/search/:interface" => "static_pages#search"
  get "static_pages/search/:userid/:interface" => "static_pages#search"
  get "static_pages/result/:interface" => "static_pages#result"
  get "static_pages/result/:userid/:interface" => "static_pages#result"
  get "static_pages/graph/:interface" => "static_pages#graph"

  get "citation/citation/:cluster_id" => "citation#citation"
  get "citation/citedby/:cluster_id" => "citation#citedby"
  get "citation/bibliography/:cluster_id" => "citation#bibliography"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
