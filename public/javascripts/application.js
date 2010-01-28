function $n(id) {
  return document.getElementsByName(id);
}

function openCenteredWindow(url, name, width, height, features) {
  if(screen.width){
	  var winl = (screen.width-width)/2;
	  var wint = (screen.height-height)/2;
  } else {
		winl = 0;
		wint =0;
  }
  if (winl < 0) winl = 0;
  if (wint < 0) wint = 0;
  var settings = 'height=' + height + ',';
  settings += 'width=' + width + ',';
  settings += 'top=' + wint + ',';
  settings += 'left=' + winl + ',';
  settings += features;
  win = window.open(url, name, settings);
  win.window.focus();
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

function select_all(id) {
  var elems = $n(id);
  for(i = 0; i < elems.length; i++) {
    elems[i].checked = true;
  }
}

function select_none(id) {
  var elems = $n(id);
  for(i = 0; i < elems.length; i++) {
    elems[i].checked = false;
  }
}

function get_selected_count(id) {
  var elems = $n(id);
  var count = 0;
  for(i = 0; i < elems.length; i++) {
    if (elems[i].checked) count++;
  }
  return count;
}

function select_all_ao_messages() {
  select_all('ao_messages[]');
  if (total_ao_messages > current_ao_messages) {
    var e = $('#all_ao_messages_text');
    e.show();
    e.html('' + current_ao_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_all_pages_ao_messages()">Select all ' + total_ao_messages + ' messages</a>.');
  }
}

function select_all_pages_ao_messages() {
  $('#ao_all').value = 1;
  var e = $('#all_ao_messages_text');
  e.show();
  e.html('All ' + total_ao_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_none_ao_messages()">Clear selection</a>.');
}

function select_none_ao_messages() {
  select_none('ao_messages[]');
  $('#ao_all').val(0);
  $('#all_ao_messages_text').hide();
}

function select_all_at_messages() {
  select_all('at_messages[]');
  if (total_at_messages > current_at_messages) {
    var e = $('#all_at_messages_text');
    e.show();
    e.html('' + current_at_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_all_pages_at_messages()">Select all ' + total_at_messages + ' messages</a>.');
  }
}

function select_all_pages_at_messages() {
  $('#at_all').value = 1;
  var e = $('#all_at_messages_text');
  e.show();
  e.html('All ' + total_at_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_none_at_messages()">Clear selection</a>.');
}

function select_none_at_messages() {
  select_none('at_messages[]');
  $('#at_all').val(0);
  $('#all_at_messages_text').hide();
}

function mark_ao_messages_as_cancelled() {
  if (get_selected_count('ao_messages[]') == 0) {
    alert('No Application Originated messages were selected');
    return;
  }
  
  var form = document.getElementById('ao_messages_form');
  form.action = '/message/ao/mark_as_cancelled';
  form.submit();
}

function mark_at_messages_as_cancelled() {
  if (get_selected_count('at_messages[]') == 0) {
    alert('No Application Terminated messages were selected');
    return;
  }
  
  var form = document.getElementById('at_messages_form');
  form.action = '/message/at/mark_as_cancelled';
  form.submit();
}

function view_ao_message_log(id) {
  openCenteredWindow('/message/ao/' + id, 'log', 640, 480, 'scrollbars=yes');
}

function view_at_message_log(id) {
  openCenteredWindow('/message/at/' + id, 'log', 640, 480, 'scrollbars=yes');
}

function delete_channel(id, name) {
  if (confirm('Are you sure you want to delete the channel ' + name + '?')) {
    window.location = '/channel/delete/' + id;
  }
}

function create_channel(select) {
  if (!select.value) return;
  window.location = '/channel/new/' + select.value;
  select.value = '';
}

function clickatell_channel_direction_changed() {
  var dir = $('#channel_direction :selected').val();
  
  // incoming
  if (dir & 1) {
    show('incoming_password_container');
  } else {
    hide('incoming_password_container');
  }
  
  // outgoing
  if (dir & 2) { 
    show('user_container', 'password_container', 'from_container');
  } else {
    hide('user_container', 'password_container', 'from_container');
  }
}

// Find address source 
$(function() {
  var find_address_source = function() {
    $.get('/application/find_address_source', 
      {address: $('#address_source').val()},
      function(name) {
        if (name) {
          $('#address_source_result').html(name);
        } else {
          $('#address_source_result').html('No channel found');
        }
      });
  };
  
  $('#address_source').keydown(function(event) {
    if (event.keyCode == 13) {
      find_address_source();
      return false;
    } else if (event.keyCode != 37 && event.keyCode != 39) {
      $('#address_source_result').html('');
    }
  });
  $('#address_source_button').click(find_address_source);
});