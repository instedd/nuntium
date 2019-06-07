# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

Nuntium::Application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: 'omniauth_callbacks'}
  guisso_for :user
  mount InsteddTelemetry::Engine => "/instedd_telemetry"

  authenticate :user do
    mount Pigeon::Engine => '/pigeon_engine', as: "pigeon_engine"
  end

  resources :accounts do
    member do
      get :select
    end
    collection do
      post :reclaim
    end
  end

  resources :reclaims

  resources :applications do
    collection do
      put :routing_rules
    end
    member do
      get :logs
    end
  end
  resources :channels do
    member do
      get :enable
      get :disable
      get :pause
      get :resume
      get :whitelist
      get :logs
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
  resources :members do
    collection do
      get :autocomplete
      post :add
      post :remove
      post :set_user_role
      post :set_user_application_role
      post :set_user_channel_role
    end
  end
  resources :visualizations, :only => :index do
    get :messages_state_by_day, :on => :collection
  end
  resources :channels_ui, only: [:new, :create, :show, :update] do
  end

  scope '/pigeon' do
    get '/new' => 'pigeon#new', as: 'new_pigeon'
    post '/create' => 'pigeon#create', as: 'create_pigeon'
  end

  scope '/:account_id/clickatell', :constraints => {:account_id => /.*/} do
    match '/incoming' => 'clickatell#index', :as => :clickatell
    match '/ack' => 'clickatell#ack', :as => :clickatell_ack, :constraints => {:account_id => /.*/}
  end

  match '/clickatell/view_credit' => 'clickatell#view_credit', :as => :clickatel_credit

  scope '/:account_id/:channel_id/nexmo/:callback_token', :constraints => {:account_id => /.*/, :channel_id => /.*/} do
    match '/incoming' => 'nexmo#incoming', :as => :nexmo_incoming, :constraints => {:account_id => /.*/, :channel_id => /.*/}
    match '/ack' => 'nexmo#ack', :as => :nexmo_ack, :constraints => {:account_id => /.*/, :channel_id => /.*/}
  end

  scope '/:account_name/:channel_name/:secret_token/chikka', :constraints => {:account_name => /.*/, :channel_name => /.*/} do
    post '/incoming' => 'chikka#incoming', :as => :chikka_incoming
    post '/ack' => 'chikka#ack', :as => :chikka_ack
  end

  scope '/:account_name/:channel_name/:secret_token/geopoll', :constraints => {:account_name => /.*/, :channel_name => /.*/} do
    post '/incoming' => 'geopoll#incoming', :as => :geopoll_incoming
  end

  scope '/:account_name/:channel_name/:secret_token/africas_talking', :constraints => {:account_name => /.*/, :channel_name => /.*/} do
    post '/incoming' => 'africas_talking#incoming', :as => :africas_talking_incoming
    post '/delivery_reports' => 'africas_talking#delivery_reports', :as => :africas_talking_delivery_reports
  end

  scope '/channels/twitter' do
    post '/create' => 'twitter#create', :as => :create_twitter_channel
    put '/update/:id' => 'twitter#update', :as => :update_twitter_channel
  end

  scope '/:account_id/shujaa', :constraints => {:account_id => /.*/} do
    match '/incoming/:callback_guid' => 'shujaa#index', :as => :shujaa
  end

  scope '/twitter' do
    match '/callback' => 'twitter#callback', :as => :twitter_callback
  end

  scope '/:account_id/qst', :constraints => {:account_id => /.*/}  do
    post '/incoming' => 'qst_server#push', :as => :qst_push
    get '/incoming' => 'qst_server#get_last_id', :as => :qst_get_last_id, :constraints => {:account_id => /.*/}
    match '/outgoing' => 'qst_server#pull', :as => :qst_pull, :constraints => {:account_id => /.*/}
    match '/setaddress' => 'qst_server#set_address', :as => :qst_set_address, :constraints => {:account_id => /.*/}
  end

  scope '/:account_name/:application_name', :constraints => {:account_name => /.*/, :application_name => /.*/} do
    get '/rss' => 'rss#index', :as => :rss, :format => 'xml'
    post '/rss' => 'rss#create', :as => :create_rss, :constraints => {:account_name => /.*/, :application_name => /.*/}

    match '/send_ao' => 'ao_messages#create_via_api', :as => :send_ao, :constraints => {:account_name => /.*/, :application_name => /.*/}
    get '/get_ao' => 'ao_messages#get_ao', :as => :get_ao, :constraints => {:account_name => /.*/, :application_name => /.*/}
  end

  match '/:account_id/dtac/incoming' => 'dtac#index', :as => :dtac, :constraints => {:account_id => /.*/}
  # TODO: are these necessary/correct? taken from production environment
  match '/dtac/geochat/incoming' => 'dtac#index', :account_id => 'instedd'
  match '/dtac/:account_id/incoming' => 'dtac#index'

  scope '/:account_id/ipop/:channel_name', :constraints => {:account_id => /.*/} do
    post '/incoming' => 'ipop#index', :as => :ipop
    post '/ack' => 'ipop#ack', :as => :ipop_ack, :constraints => {:account_id => /.*/}
  end

  scope '/:account_id/twilio', :constraints => {:account_id => /.*/} do
    match '/incoming' => 'twilio#index', :as => :twilio
    match '/ack' => 'twilio#ack', :as => :twilio_ack
  end

  scope '/api' do
    scope '/carriers' do
      match '/' => 'api_carrier#index', :as => :carriers
      match '/:guid' => 'api_carrier#show', :as => :carrier
    end

    scope '/countries' do
      match '/' => 'api_country#index', :as => :countries
      match '/:iso' => 'api_country#show', :as => :country
    end

    scope '/channels' do
      get '/' => 'api_channel#index', :as => :api_channels_index
      post '/' => 'api_channel#create', :as => :api_channels_create
      get '/:name' => 'api_channel#show', :as => :api_channels_show
      put '/:name' => 'api_channel#update', :as => :api_channels_update
      delete '/:name' => 'api_channel#destroy', :as => :api_channels_destroy
      get '/:name/twitter/friendships/create' => 'api_twitter_channel#friendship_create', :as => :api_twitter_follow
      get '/:name/twitter/authorize' => 'api_twitter_channel#authorize', :as => :api_twitter_authorize
      get '/:name/xmpp/add_contact' => 'api_xmpp_channel#add_contact', :as => :api_xmpp_add_contact
    end

    get '/candidate/channels' => 'api_channel#candidates', :as => :api_candidate_channels

    scope '/custom_attributes' do
      get '/' => 'api_custom_attributes#show', :as => :api_custom_attributes_show
      post '/' => 'api_custom_attributes#create_or_update', :as => :api_custom_attributes_show
    end

    resources :ao_messages, only: [:create], controller: 'api_ao_messages'
    resources :applications, controller: 'api_applications'
    resources :accounts, controller: 'api_accounts'
  end

  scope '/tickets' do
    post '/' => 'tickets#create'
    get '/:code' => 'tickets#show'
  end

  root :to => 'applications#index'
end
