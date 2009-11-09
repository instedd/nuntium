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
