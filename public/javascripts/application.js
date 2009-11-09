function $(id) {
  return document.getElementById(id);
}

function toggle(id) {
  var elem = $(id);
  if (elem.style.display != 'none') {
    elem.style.display = 'none';
  } else {
    elem.style.display = '';
  }
}

function delete_channel(id, name) {
  if (confirm('Are you sure you want to delete the channel ' + name + '?')) {
    window.location = '/channel/delete/' + id;
  }
}
