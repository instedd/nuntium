$ ->
  # All ajax errors show an error alert
  $(document).ajaxError (event, xhr, settings, error) ->
    if (xhr.status != 0 && xhr.readyState != 0)
      _.showErrorMessage "Oops... something went wrong :-(", "error"

  # Center initial alerts
  $alert = $('.alert-autoclose')
  if $alert.length > 0
    left = ($(window).width() / 2 - $alert.width() / 2)
    $alert.css('left', "#{left}px")

  # Hide all alerts after some time
  hideAlerts = ->
    $elem = $('.alert-autoclose')
    $elem.fadeOut -> $elem.remove()

  setTimeout(hideAlerts, 5000)
