$(function() {
  // This is to expand shortened text in tables
  $(document).on('click', 'td', function() {
    spans = $(this).children("span");
    if (spans.length > 0) {
      $span = $(spans[0]);
      if ($span && $span.attr('title')) {
        $span.text($span.attr('title'));
        $span.attr('title', '');
      }
    }
  });

  $(document).on('click', 'a[data-function]', function(){
    eval($(this).data('function'));
    return false;
  });
});

function $n(id) {
  return document.getElementsByName(id);
}

function toggle(id) {
  $('#' + id).toggle('fast');
}

function show(id) {
  if (arguments.length == 1) {
    $('#' + id).show('fast')
  } else {
    for(var i = 0; i < arguments.length; i++)
      $('#' + arguments[i]).show('fast');
  }
}

function hide(id) {
  if (arguments.length == 1) {
    $('#' + id).hide('fast');
  } else {
    for(var i = 0; i < arguments.length; i++)
      $('#' + arguments[i]).hide('fast');
  }
}

function flash(message) {
  $flash = $('.notice');
  if ($flash.length == 0) {
    $flash = $('span');
  }

  $flash.attr('class', 'notice');
  $flash.attr('style', 'position:fixed; top:4px; z-index:2');
  $flash.text(message);
  $flash.show();

  setTimeout(function() {
    $flash.hide();
  }, 3000);
}
