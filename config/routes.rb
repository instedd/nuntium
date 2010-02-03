ActionController::Routing::Routes.draw do |map|
  map.resources :rss, :only => [:index, :create]
  map.resources :incoming, :path_prefix => '/qst/:application_id', :only => [:index, :create]
  map.resources :outgoing, :path_prefix => '/qst/:application_id', :only => [:index]
  
  map.clickatel '/clickatell/:application_id/incoming', :controller => 'clickatell', :action => :index
  map.dtac '/dtac/:application_id/incoming', :controller => 'dtac', :action => :index
  
  map.root :controller => 'home'
  
  map.create_application '/create_application', :controller => 'home', :action => :create_application
  map.login '/login', :controller => 'home', :action => :login
  map.logoff '/logoff', :controller => 'home', :action => :logoff
  map.home '/home', :controller => 'home', :action => :home
  map.edit_application '/application/edit', :controller => 'home', :action => :edit_application
  map.update_application '/application/update', :controller => 'home', :action => :update_application
  map.update_application '/application/find_address_source', :controller => 'home', :action => :find_address_source
  map.edit_application_ao_routing '/application/ao_routing/edit', :controller => 'home', :action => :edit_application_ao_routing
  map.update_application_ao_routing '/application/ao_routing/update', :controller => 'home', :action => :update_application_ao_routing
  map.edit_application_at_routing '/application/at_routing/edit', :controller => 'home', :action => :edit_application_at_routing
  map.update_application_at_routing '/application/at_routing/update', :controller => 'home', :action => :update_application_at_routing

  # Twitter mappings must come before generic channel mapping
  map.create_twitter_channel '/channel/create/twitter', :controller => 'twitter', :action => :create_twitter_channel, :kind => 'twitter'
  map.update_twitter_channel '/channel/update/twitter/:id', :controller => 'twitter', :action => :update_twitter_channel
  map.twitter_callback '/twitter_callback', :controller => 'twitter', :action => :twitter_callback
    
  map.new_channel '/channel/new/:kind', :controller => 'channel', :action => :new_channel
  map.create_channel '/channel/create/:kind', :controller => 'channel', :action => :create_channel
  map.edit_channel '/channel/edit/:id', :controller => 'channel', :action => :edit_channel
  map.update_channel '/channel/update/:id', :controller => 'channel', :action => :update_channel
  map.delete_channel '/channel/delete/:id', :controller => 'channel', :action => :delete_channel  
  map.enable_channel '/channel/enable/:id', :controller => 'channel', :action => :enable_channel  
  map.disable_channel '/channel/disable/:id', :controller => 'channel', :action => :disable_channel  
  
  map.new_ao_message '/message/ao/new', :controller => 'message', :action => :new_ao_message
  map.create_ao_message '/message/ao/create', :controller => 'message', :action => :create_ao_message
  map.mark_ao_messages_as_cancelled '/message/ao/mark_as_cancelled', :controller => 'message', :action => :mark_ao_messages_as_cancelled
  map.mark_ao_messages_as_cancelled '/message/ao/reroute', :controller => 'message', :action => :reroute_ao_messages
  map.view_ao_message '/message/ao/:id', :controller => 'message', :action => :view_ao_message
  
  map.new_at_message '/message/at/new', :controller => 'message', :action => :new_at_message
  map.create_at_message '/message/at/create', :controller => 'message', :action => :create_at_message
  map.mark_at_messages_as_cancelled '/message/at/mark_as_cancelled', :controller => 'message', :action => :mark_at_messages_as_cancelled
  map.view_at_message '/message/at/:id', :controller => 'message', :action => :view_at_message
  
  map.send_ao '/send_ao', :controller => 'send_ao', :action => :create

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
