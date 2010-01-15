function $(id) {
  return document.getElementById(id);
}

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
  var elem = $(id);
  if (elem.style.display != 'none') {
    elem.style.display = 'none';
  } else {
    elem.style.display = '';
  }
}

function show(id) {
  if (arguments.length == 1) {
    $(id).style.display = '';
  } else {
    for(var i = 0; i < arguments.length; i++)
      $(arguments[i]).style.display = '';
  }
}

function hide(id) {
  if (arguments.length == 1) {
    $(id).style.display = 'none';
  } else {
    for(var i = 0; i < arguments.length; i++)
      $(arguments[i]).style.display = 'none';
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
    var e = $('all_ao_messages_text');
    e.style.display = '';
    e.innerHTML = '' + current_ao_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_all_pages_ao_messages()">Select all ' + total_ao_messages + ' messages</a>.';
  }
}

function select_all_pages_ao_messages() {
  $('ao_all').value = 1;
  var e = $('all_ao_messages_text');
  e.style.display = '';
  e.innerHTML = 'All ' + total_ao_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_none_ao_messages()">Clear selection</a>.';
}

function select_none_ao_messages() {
  select_none('ao_messages[]');
  $('ao_all').value = 0;
  $('all_ao_messages_text').style.display = 'none';
}

function select_all_at_messages() {
  select_all('at_messages[]');
  if (total_at_messages > current_at_messages) {
    var e = $('all_at_messages_text');
    e.style.display = '';
    e.innerHTML = '' + current_at_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_all_pages_at_messages()">Select all ' + total_at_messages + ' messages</a>.';
  }
}

function select_all_pages_at_messages() {
  $('at_all').value = 1;
  var e = $('all_at_messages_text');
  e.style.display = '';
  e.innerHTML = 'All ' + total_at_messages + ' messages are selected. <a href="javascript:void(0)" onclick="select_none_at_messages()">Clear selection</a>.';
}

function select_none_at_messages() {
  select_none('at_messages[]');
  $('at_all').value = 0;
  $('all_at_messages_text').style.display = 'none';
}

function mark_ao_messages_as_cancelled() {
  if (get_selected_count('ao_messages[]') == 0) {
    alert('No Application Oriented messages were selected');
    return;
  }
  
  var form = $('ao_messages_form');
  form.action = '/message/ao/mark_as_cancelled';
  form.submit();
}

function mark_at_messages_as_cancelled() {
  if (get_selected_count('at_messages[]') == 0) {
    alert('No Application Terminated messages were selected');
    return;
  }
  
  var form = $('at_messages_form');
  form.action = '/message/at/mark_as_cancelled';
  form.submit();
}

function view_ao_message_log(id) {
  openCenteredWindow('/message/ao/' + id + '/log', 'log', 640, 480);
}

function view_at_message_log(id) {
  openCenteredWindow('/message/at/' + id + '/log', 'log', 640, 480);
}

function delete_channel(id, name) {
  if (confirm('Are you sure you want to delete the channel ' + name + '?')) {
    window.location = '/channel/delete/' + id;
  }
}

function clickatell_channel_direction_changed() {
  var dir = $('channel_direction').value;
  
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