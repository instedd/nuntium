Nuntium::Application.routes.draw do
  resource :session do
    post :register
  end
  resources :applications do
    collection do
      put :routing_rules
    end
  end
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
  match '/clickatell/view_credit' => 'clickatell#view_credit', :as => :clickatel_credit

  post '/channels/twitter/create' => 'twitter#create', :as => :create_twitter_channel
  put '/channels/twitter/update/:id' => 'twitter#update', :as => :update_twitter_channel
  match '/twitter/view_rate_limit_status' => 'twitter#view_rate_limit_status', :as => :twitter_rate_limit_status

  match '/twitter/callback' => 'twitter#callback', :as => :twitter_callback

  match '/:account_name/:application_name/send_ao' => 'ao_messages#create_via_api', :as => :send_ao, :constraints => {:account_name => /.*/, :application_name => /.*/}

  post '/:account_id/qst/incoming' => 'qst_server#push', :as => :qst_push, :constraints => {:account_id => /.*/}
  get '/:account_id/qst/incoming' => 'qst_server#get_last_id', :as => :qst_get_last_id, :constraints => {:account_id => /.*/}
  get '/:account_id/qst/outgoing' => 'qst_server#pull', :as => :qst_pull, :constraints => {:account_id => /.*/}
  match '/:account_id/qst/setaddress' => 'qst_server#set_address', :as => :qst_set_address, :constraints => {:account_id => /.*/}

  get '/:account_name/:application_name/rss' => 'rss#index', :as => :rss, :constraints => {:account_name => /.*/, :application_name => /.*/}
  post '/:account_name/:application_name/rss' => 'rss#create', :as => :create_rss, :constraints => {:account_name => /.*/, :application_name => /.*/}

  match '/:account_id/dtac/incoming' => 'dtac#index', :as => :dtac, :constraints => {:account_id => /.*/}

  post '/:account_id/ipop/:channel_name/incoming' => 'ipop#index', :as => :ipop, :constraints => {:account_id => /.*/}
  post '/:account_id/ipop/:channel_name/ack' => 'ipop#ack', :as => :ipop_ack, :constraints => {:account_id => /.*/}

  match '/api/carriers' => 'api_carrier#index', :as => :carriers
  match '/api/carriers/:guid' => 'api_carrier#show', :as => :carrier

  match '/api/countries' => 'api_country#index', :as => :countries
  match '/api/countries/:iso' => 'api_country#show', :as => :country

  get '/api/channels' => 'api_channel#index', :as => :api_channels_index
  post '/api/channels' => 'api_channel#create', :as => :api_channels_create
  get '/api/channels/:name' => 'api_channel#show', :as => :api_channels_show
  put '/api/channels/:name' => 'api_channel#update', :as => :api_channels_update
  delete '/api/channels/:name' => 'api_channel#destroy', :as => :api_channels_destroy
  get '/api/candidate/channels' => 'api_channel#candidates', :as => :api_candidate_channels
  get '/api/channels/:name/twitter/friendships/create' => 'api_twitter_channel#friendship_create', :as => :api_twitter_follow

  match '/api/custom_attributes' => 'api_custom_attributes#show', :as => :api_custom_attributes_show, :via => :get
  match '/api/custom_attributes' => 'api_custom_attributes#create_or_update', :as => :api_custom_attributes_show, :via => :post

  get '/:account_name/:application_name/get_ao' => 'ao_messages#get_ao', :as => :get_ao, :constraints => {:account_name => /.*/, :application_name => /.*/}

  post '/tickets' => 'tickets#create'
  get '/tickets/:code' => 'tickets#show'

  root :to => 'applications#index'
end
