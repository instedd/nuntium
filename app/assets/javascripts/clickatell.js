function clickatell_channel_direction_changed() {
  var dir = parseInt($('select#channel_direction').val());

  // incoming
  if (dir & 1) {
    show('incoming_password_container', 'callback_incoming');
  } else {
    hide('incoming_password_container', 'callback_incoming');
  }

  // outgoing
  if (dir & 2) {
    show('user_container', 'password_container', 'from_container', 'callback_ack');
  } else {
    hide('user_container', 'password_container', 'from_container', 'callback_ack');
  }
}

function clickatell_view_credit(id) {
  $.ajax({
    type: "GET",
    url: '/clickatell/view_credit',
    data: {id: id},
    success: function(data) {
      alert(data)
    },
    error: function() {
      alert('An error happened while retreiving the clickatell credit :-(');
    }
  });
}
