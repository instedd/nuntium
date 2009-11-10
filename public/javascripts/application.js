function $(id) {
  return document.getElementById(id);
}

function $n(id) {
  return document.getElementsByName(id);
}

function toggle(id) {
  var elem = $(id);
  if (elem.style.display != 'none') {
    elem.style.display = 'none';
  } else {
    elem.style.display = '';
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
  $('all_at_messages_text').style.display = 'none';
}

function mark_ao_messages_as_cancelled() {
  if (get_selected_count('ao_messages[]') == 0) {
    alert('No Application Oriented messages were selected');
    return;
  }
  
  var form = $('ao_messages_form');
  form.action = '/mark_ao_messages_as_cancelled';
  form.submit();
}

function mark_at_messages_as_cancelled() {
  if (get_selected_count('at_messages[]') == 0) {
    alert('No Application Terminated messages were selected');
    return;
  }
  
  var form = $('at_messages_form');
  form.action = '/mark_at_messages_as_cancelled';
  form.submit();
}

function delete_channel(id, name) {
  if (confirm('Are you sure you want to delete the channel ' + name + '?')) {
    window.location = '/channel/delete/' + id;
  }
}
