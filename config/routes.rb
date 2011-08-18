Nuntium::Application.routes.draw do
  resource :session do
    post :application_routing_rules, :on => :member
    post :register
  end
  resources :applications
  resources :channels do
    member do
      get :enable
      get :disable
      get :pause
      get :resume
    end
  end
  resources :ao_messages do
    member do
      get :thread
    end
    collection do
      post :mark_as_cancelled
      post :reroute
      post :simulate_route
      get :rgviz
    end
  end
  resources :at_messages do
    member do
      get :thread
    end
    collection do
      post :mark_as_cancelled
      post :simulate_route
      get :rgviz
    end
  end
  resources :logs
  resources :custom_attributes, :except => :show
  resource :interactions
  resource :settings
  resources :visualizations, :only => :index do
    get :messages_state_by_day, :on => :collection
  end

  match '/:account_id/clickatell/incoming' => 'clickatell#index', :as => :clickatell, :constraints => {:account_id => /.*/}
  match '/:account_id/clickatell/ack' => 'clickatell#ack', :as => :clickatell_ack, :constraints => {:account_id => /.*/}

  post '/channels/twitter/create' => 'twitter#create', :as => :create_twitter_channel
  put '/channels/twitter/update/:id' => 'twitter#update', :as => :update_twitter_channel

  match '/twitter/callback' => 'twitter#callback', :as => :twitter_callback

  match '/:account_name/:application_name/send_ao' => 'ao_messages#create_via_api', :as => :send_ao, :constraints => {:account_name => /.*/, :application_name => /.*/}

  get '/:account_id/qst/outgoing' => 'outgoing#index', :as => :outgoing, :constraints => {:account_id => /.*/}

  get '/:account_name/:application_name/rss' => 'rss#index', :as => :rss, :constraints => {:account_name => /.*/, :application_name => /.*/}
  post '/:account_name/:application_name/rss' => 'rss#create', :as => :create_rss, :constraints => {:account_name => /.*/, :application_name => /.*/}

  match '/:account_id/dtac/incoming' => 'dtac#index', :as => :dtac, :constraints => {:account_id => /.*/}

  post '/:account_id/ipop/:channel_name/incoming' => 'ipop#index', :as => :ipop, :constraints => {:account_id => /.*/}
  post '/:account_id/ipop/:channel_name/ack' => 'ipop#ack', :as => :ipop_ack, :constraints => {:account_id => /.*/}

  root :to => 'applications#index'

 #match '/' => 'home#index'
 #match '/interactions' => 'home#interactions', :as => :interactions
 #match '/settings' => 'home#settings', :as => :settings
 #match '/applications' => 'home#applications', :as => :applications
 #match '/channels' => 'home#channels', :as => :channels
 #match '/ao_messages' => 'home#ao_messages', :as => :ao_messages
 #match '/at_messages' => 'home#at_messages', :as => :at_messages
 #match '/logs' => 'home#logs', :as => :logs
 #match '/visualizations' => 'home#visualizations', :as => :visualizations

 #match '/clickatell/view_credit' => 'clickatell#view_credit', :as => :clickatel_credit
 #match '/create_account' => 'home#create_account', :as => :create_account
 #match '/login' => 'home#login', :as => :login
 #match '/logoff' => 'home#logoff', :as => :logoff
 #match '/account/update' => 'home#update_account', :as => :update_account
 #match '/account/update_application_routing_rules' => 'home#update_application_routing_rules', :as => :update_application_routing_rules
 #match '/channel/twitter/create' => 'twitter#create_twitter_channel', :as => :create_twitter_channel, :kind => 'twitter'
 #match '/channel/twitter/update/:id' => 'twitter#update_twitter_channel', :as => :update_twitter_channel
 #match '/twitter/view_rate_limit_status' => 'twitter#view_rate_limit_status', :as => :twitter_rate_limit_status
 #match '/channel/new/:kind' => 'channel#new_channel', :as => :new_channel
 #match '/channel/create/:kind' => 'channel#create_channel', :as => :create_channel
 #match '/channel/edit/:id' => 'channel#edit_channel', :as => :edit_channel
 #match '/channel/update/:id' => 'channel#update_channel', :as => :update_channel
 #match '/channel/delete/:id' => 'channel#delete_channel', :as => :delete_channel
 #match '/channel/enable/:id' => 'channel#enable_channel', :as => :enable_channel
 #match '/channel/disable/:id' => 'channel#disable_channel', :as => :disable_channel
 #match '/channel/pause/:id' => 'channel#pause_channel', :as => :pause_channel
 #match '/channel/resume/:id' => 'channel#resume_channel', :as => :unpause_channel
 #match '/application/new' => 'home#new_application', :as => :new_application
 #match '/application/create' => 'home#create_application', :as => :create_application
 #match '/application/edit/:id' => 'home#edit_application', :as => :edit_application
 #match '/application/update/:id' => 'home#update_application', :as => :update_application
 #match '/application/delete/:id' => 'home#delete_application', :as => :delete_application
 #match '/message/thread' => 'message#view_thread', :as => :view_thread
 #match '/message/ao/new' => 'message#new_ao_message', :as => :new_ao_message
 #match '/message/ao/create' => 'message#create_ao_message', :as => :create_ao_message
 #match '/message/ao/mark_as_cancelled' => 'message#mark_ao_messages_as_cancelled', :as => :mark_ao_messages_as_cancelled
 #match '/message/ao/reroute' => 'message#reroute_ao_messages', :as => :mark_ao_messages_as_cancelled
 #match '/message/ao/candidate_channels' => 'message#candidate_channels', :as => :candidate_channels
 #match '/message/ao/simulate_route' => 'message#simulate_route_ao', :as => :simulate_route_ao
 #match '/message/at/simulate_route' => 'message#simulate_route_at', :as => :simulate_route_at
 #match '/message/ao/:id' => 'message#view_ao_message', :as => :view_ao_message
 #match '/messages/ao/rgviz' => 'message#ao_rgviz', :as => :ao_rgviz
 #match '/message/at/new' => 'message#new_at_message', :as => :new_at_message
 #match '/message/at/create' => 'message#create_at_message', :as => :create_at_message
 #match '/message/at/mark_as_cancelled' => 'message#mark_at_messages_as_cancelled', :as => :mark_at_messages_as_cancelled
 #match '/message/at/:id' => 'message#view_at_message', :as => :view_at_message
 #match '/messages/at/rgviz' => 'message#at_rgviz', :as => :at_rgviz
 #match '/visualization/ao/state_by_day' => 'visualization#ao_state_by_day', :as => :visualization_ao_state_by_day
 #match '/visualization/at/state_by_day' => 'visualization#at_state_by_day', :as => :visualization_at_state_by_day
 #post '/tickets(.:format)' => 'tickets#create'
 #get '/tickets/:code(.:format)' => 'tickets#show'

 #match '/api/countries(.:format)' => 'api_country#index', :as => :countries
 #match '/api/countries/:iso(.:format)' => 'api_country#show', :as => :country
 #match '/api/carriers(.:format)' => 'api_carrier#index', :as => :carriers
 #match '/api/carriers/:guid(.:format)' => 'api_carrier#show', :as => :carrier
 #match '/api/channels(.:format)' => 'api_channel#index', :as => :api_channels_index, :via => :get
 #match '/api/channels(.:format)' => 'api_channel#create', :as => :api_channels_create, :via => :post
 #match '/api/channels/:name(.:format)' => 'api_channel#show', :as => :api_channels_show, :via => :get
 #match '/api/channels/:name(.:format)' => 'api_channel#update', :as => :api_channels_update, :via => :put
 #match '/api/channels/:name' => 'api_channel#destroy', :as => :api_channels_destroy, :via => :delete
 #match '/api/candidate/channels(.:format)' => 'api_channel#candidates', :as => :api_candidate_channels, :via => :get
 #match '/api/channels/:name/twitter/friendships/create' => 'api_twitter_channel#friendship_create', :as => :api_twitter_follow, :via => :get
 #match '/api/custom_attributes' => 'api_custom_attributes#show', :as => :api_custom_attributes_show, :via => :get
 #match '/api/custom_attributes' => 'api_custom_attributes#create_or_update', :as => :api_custom_attributes_show, :via => :post

 #match '/:account_id/clickatell/incoming' => 'clickatell#index', :as => :clickatel, :constraints => {:account_id => /.*/}
 #match '/:account_id/clickatell/ack' => 'clickatell#ack', :as => :clickatel_ack, :constraints => {:account_id => /.*/}
 #match '/:account_id/qst/setaddress' => 'address#update', :as => :qst_set_address, :constraints => {:account_id => /.*/}

 #match '/:account_name/:application_name/send_ao' => 'send_ao#create', :as => :send_ao, :constraints => {:account_name => /.*/, :application_name => /.*/}
 #match '/:account_name/:application_name/get_ao' => 'get_ao#index', :as => :get_ao, :constraints => {:account_name => /.*/, :application_name => /.*/}

 #post '/:account_id/qst/incoming' => 'incoming#create', :as => :incoming, :constraints => {:account_id => /.*/}
 #match '/:account_id/qst/incoming' => 'incoming#index', :as => :incoming, :constraints => {:account_id => /.*/}
end
