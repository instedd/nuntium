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

  class User
    constructor: (data) ->
      @id = ko.observable data.id
      @name = ko.observable data.name
      @role = ko.observable(data.role ? _.find(params.user_accounts, (ua) => ua.user_id == @id()).role)

      @applications = ko.observableArray _.map params.applications, (app) => new UserApplication(@, app, _.find(params.user_applications, (ua) => ua.user_id == @id() && ua.application_id == app.id)?.role)
      @channels = ko.observableArray _.map params.channels, (chan) => new UserChannel(@, chan, _.find(params.user_channels, (uc) => uc.user_id == @id() && uc.channel_id == chan.id)?.role)

  class UserApplication
    constructor: (user, app, role) ->
      @user = user
      @application = app
      @name = app.name
      @role = ko.observable(role ? 'none')
      @computedRole = ko.computed => if @user.role() == "owner" then "owner" else @role()

  class UserChannel
    constructor: (user, chan, role) ->
      @user = user
      @channel = chan
      @name = chan.name
      @role = ko.observable(role ? 'none')
      @computedRole = ko.computed => if @user.role() == "owner" then "owner" else @role()

  window.model = new MembersViewModel
  ko.applyBindings model

  $('#new_email').autocomplete source: (request, response) ->
    $.get "/members/autocomplete", {term: request.term}, response
