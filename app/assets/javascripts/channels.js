function create_channel(select) {
  if (!select.value) return;
  window.location = '/channels/new?kind=' + select.value;
  select.value = '';
}

function filter_channels_by_kind(select) {
  kind = select.value;
  count = -1;
  $('#channels tr').each(function() {
      count++;
      if (count < 2) return;
      $this = $(this);
      row_kind = $this.children().eq(1).text();
      if (kind == '' || kind == row_kind) {
        $this.show();
      } else {
        $this.hide();
      }
  });
}

function enable_channel(id, name) {
  change_channel_state(id, name, false, 'enable', 'enabled', 'Enabling', ['enable'], ['disable', 'pause']);
}

function pause_channel(id, name) {
  change_channel_state(id, name, false, 'pause', 'paused', 'Pausing', ['pause', 'disable'], ['resume']);
}

function resume_channel(id, name) {
  change_channel_state(id, name, false, 'resume', 'enabled', 'Resuming', ['resume'], ['disable', 'pause']);
}

function disable_channel(id, name) {
  change_channel_state(id, name, true, 'disable', 'disabled', 'Disabling', ['disable', 'pause'], ['enable']);
}

function change_channel_state(id, name, want_confirm, action, state, paction, to_hide, to_show) {
  if (want_confirm && !confirm("Are you sure you want to " + action + " the channel " + name))
    return;

  flash(paction + " channel " + name + "...");

  $.ajax({
    type: "GET",
    url: '/channels/' + id + '/' + action,
    success: function(data) {
      $("#chan-" + id + " .img").attr('src', '/assets/' + state + '.png');
      for(var i = 0; i < to_hide.length; i++) {
        $("#chan-" + id + " ." + to_hide[i]).hide();
      }
      for(var i = 0; i < to_show.length; i++) {
        $("#chan-" + id + " ." + to_show[i]).show();
      }
      flash(data);
    },
    error: function() {
      flash('An error happened while changing the channel ' + name + ' state to ' + state + ' :-(');
    }
  });
}
