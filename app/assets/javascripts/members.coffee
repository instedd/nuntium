@initMembers = (params) ->
  class MembersViewModel
    constructor: ->
      @users = ko.observableArray _.map params.users, (user) -> new User(user)

    addUser: =>
      $.post "/members/add", email: $('#new_email').val(), (data) =>
        if data.ok
          @users.push(new User(data.user))
          $('#new_email').val('')
        else
          alert "Error: #{data.error}"

    removeUser: (user) =>
      @users.remove user
      $.post "/members/remove", id: user.id

  class User
    constructor: (data) ->
      @id = data.id
      @name = data.name
      @role = ko.observable(data.role ? _.find(params.user_accounts, (ua) => ua.user_id == @id).role)

      @applications = ko.observableArray _.map params.applications, (app) => new UserApplication(@, app, _.find(params.user_applications, (ua) => ua.user_id == @id && ua.application_id == app.id)?.role)
      @channels = ko.observableArray _.map params.channels, (chan) => new UserChannel(@, chan, _.find(params.user_channels, (uc) => uc.user_id == @id && uc.channel_id == chan.id)?.role)

      @role.subscribe =>
        new_subrole = if @role() == 'admin' then 'admin' else 'none'

        _.each @applications(), (app) ->
          app.silence = true
          app.role(new_subrole)
          app.silence = false
          true

        _.each @channels(), (chan) ->
          chan.silence = true
          chan.role(new_subrole)
          chan.silence = false
          true

        $.post "/members/set_user_role", id: @id, role: @role()

  class UserApplication
    constructor: (user, app, role) ->
      @user = user
      @application = app
      @name = app.name
      @role = ko.observable((if @user.role() == "admin" then "admin" else role) ? 'none')

      @role.subscribe =>
        return if @silence

        $.post "/members/set_user_application_role", user_id: @user.id, application_id: @application.id, role: @role()

  class UserChannel
    constructor: (user, chan, role) ->
      @user = user
      @channel = chan
      @name = chan.name
      @role = ko.observable((if @user.role() == "admin" then "admin" else role) ? 'none')

      @role.subscribe =>
        return if @silence

        $.post "/members/set_user_channel_role", user_id: @user.id, channel_id: @channel.id, role: @role()

  window.model = new MembersViewModel
  ko.applyBindings model

  $('#new_email').autocomplete source: (request, response) ->
    $.get "/members/autocomplete", {term: request.term}, response
