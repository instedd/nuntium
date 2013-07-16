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
  $('#ao_all').val(1);
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
  $('#at_all').val(1);
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
  var count = get_selected_count('ao_messages[]');
  if (count == 0) {
    alert('No Application Originated messages were selected');
    return;
  }

  if ($('#ao_all').val() == 1) {
    count = total_ao_messages;
  }

  if (!confirm('' + count + ' Application Originated message' + (count == 1 ? '' : 's') + ' will be cancelled. Are you sure?'))
    return;

  var form = document.getElementById('ao_messages_form');
  form.action = '/ao_messages/mark_as_cancelled';
  form.method = 'POST'
  form.submit();
}

function mark_at_messages_as_cancelled() {
  var count = get_selected_count('at_messages[]');
  if (count == 0) {
    alert('No Application Terminated messages were selected');
    return;
  }

  if ($('#at_all').val() == 1) {
    count = total_at_messages;
  }

  if (!confirm('' + count + ' Application Terminated message' + (count == 1 ? '' : 's') + ' will be cancelled. Are you sure?'))
    return;

  var form = document.getElementById('at_messages_form');
  form.action = '/at_messages/mark_as_cancelled';
  form.method = 'POST';
  form.submit();
}

function reroute_ao_messages() {
  var count = get_selected_count('ao_messages[]');
  if (count == 0) {
    alert('No Application Originated messages were selected');
    return;
  }

  if ($('#ao_all').val() == 1) {
    count = total_ao_messages;
  }

  if (!confirm('' + count + ' Application Originated message' + (count == 1 ? '' : 's') + ' will be re-routed. Are you sure?'))
    return;

  var form = document.getElementById('ao_messages_form');
  form.action = '/ao_messages/reroute';
  form.method = 'POST';
  form.submit();
}
