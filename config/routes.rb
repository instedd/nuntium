ActionController::Routing::Routes.draw do |map|
  map.resources :rss, :only => [:index, :create]
  map.resources :incoming, :path_prefix => '/qst/:application_id', :only => [:index, :create]
  map.resources :outgoing, :path_prefix => '/qst/:application_id', :only => [:index]
  map.clickatel '/clickatell/:application_id/incoming', :controller => 'clickatell', :action => :index
  map.dtac '/dtac/geochat/incoming', :controller => 'dtac', :action => :index
  
  map.root :controller => 'home'
  
  map.create_application '/create_application', :controller => 'home', :action => :create_application
  map.login '/login', :controller => 'home', :action => :login
  map.logoff '/logoff', :controller => 'home', :action => :logoff
  map.home '/home', :controller => 'home', :action => :home
  map.edit_application '/application/edit', :controller => 'home', :action => :edit_application
  map.update_application '/application/update', :controller => 'home', :action => :update_application
  map.edit_channel '/channel/edit/:id', :controller => 'home', :action => :edit_channel
  map.update_channel '/channel/update/:id', :controller => 'home', :action => :update_channel
  map.update_twitter_channel '/channel/update/twitter/:id', :controller => 'home', :action => :update_twitter_channel
  map.delete_channel '/channel/delete/:id', :controller => 'home', :action => :delete_channel
  map.new_channel '/channel/new/:kind', :controller => 'home', :action => :new_channel
  map.create_twitter_channel '/channel/create/twitter', :controller => 'home', :action => :create_twitter_channel, :kind => 'twitter'
  map.create_channel '/channel/create/:kind', :controller => 'home', :action => :create_channel
  map.mark_ao_messages_as_cancelled '/mark_ao_messages_as_cancelled', :controller => 'home', :action => :mark_ao_messages_as_cancelled
  map.mark_at_messages_as_cancelled '/mark_at_messages_as_cancelled', :controller => 'home', :action => :mark_at_messages_as_cancelled
  
  map.twitter_callback '/twitter_callback', :controller => 'home', :action => :twitter_callback

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
end
