function delete_channel(id, name) {
  if (confirm('Are you sure you want to delete the channel ' + name + '?')) {
    window.location = '/channel/delete/' + id;
  }
}

function toggle_visibility(id) {
  var elem = document.getElementById(id);
  if (elem.style.display != 'none') {
    elem.style.display = 'none';
  } else {
    elem.style.display = '';
  }
}