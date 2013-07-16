function toggleAccountsPopup() {
  var position = jQuery('#accounts_link').position();
  var $popup = jQuery('#accounts_popup');
  $popup.css({top: (position.top + 20) + 'px', left: position.left + 'px'});
  $popup.toggle();
}
