function $n(id) {
  return document.getElementsByName(id);
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
    e.show();// === address source ===
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
  form.action = '/message/ao/mark_as_cancelled';
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
  form.action = '/message/at/mark_as_cancelled';
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
  form.action = '/message/ao/reroute';
  form.submit();
}

function create_channel(select) {
  if (!select.value) return;
  window.location = '/channel/new/' + select.value;
  select.value = '';
}

// === clickatell ===

function clickatell_channel_direction_changed() {
  var dir = $('#channel_direction :selected').val();
  
  // incoming
  if (dir & 1) {
    show('incoming_password_container', 'callback_urls');
  } else {
    hide('incoming_password_container', 'callback_urls');
  }
  
  // outgoing
  if (dir & 2) { 
    show('user_container', 'password_container', 'from_container');
  } else {
    hide('user_container', 'password_container', 'from_container');
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

// === twitter ===

function twitter_view_rate_limit_status(id) {
  $.ajax({
    type: "GET",
    url: '/twitter/view_rate_limit_status', 
    data: {id: id},
    success: function(data) {
      alert(data)
    },
    error: function() {
      alert('An error happened while retreiving the twitter rate limit status :-(');
    }
  });
}

// === channel custom attributes ===

function channel_custom_attribute_changed(select) {
  select = $(select);
  li = select.parent();
  first_select = $(li.children()[0]);
  first_select.attr('name', 'custom_attribute_name[]'); 
  
  li_value = li.children('.value');
  
  cloned_li = li.clone();
  $(cloned_li.children()[0]).val('');
  
  value = select.val();
  switch(value) {
  case '':
    li_value.html('');
    break;
  case 'application':
    var html = ' = ';
    html += applications_select();
    html += ' &nbsp; ' + remove_custom_attribute_link();
    li_value.html(html);
    break;
  case 'country':
    get_countries({
      success: function(countries) {
        var html = ' = ';
        html += countries_select(countries, 'custom_attribute_value[]');
        html += ' &nbsp; ' + remove_custom_attribute_link();
        li_value.html(html);
      },
      error: function() {
        li_value.html('An error happened :-(');
      }
    });
    break;
  case 'carrier':
    get_countries({
      success: function(countries) {
        var html = ' = ';
        html += countries_select(countries, 'countries', 'channel_custom_attribute_country_changed(this)');
        html += '<span class="value2"></span>';
        html += ' &nbsp; ' + remove_custom_attribute_link();
        li_value.html(html);
      },
      error: function() {
        li_value.html('An error happened :-(');
      }
    });
    break;
  case 'custom':
    first_select.attr('name', 'doesnt_matter');
    
    var html = 'Name: <input type="text" name="custom_attribute_name[]"> Value: <input type="text" name="custom_attribute_value[]">';
    html += ' &nbsp; ' + remove_custom_attribute_link();
    li_value.html(html);
    break;
  }
  
  ul = li.parent();
  lis = ul.children();
  last_li = lis[lis.length - 1];
  
  if ($($(last_li).children()[0]).val()) {
    $("#custom_attributes").append(cloned_li);
  }
}

function channel_custom_attribute_country_changed(select) {
  select = $(select);
  country = select.val();
  li = select.parent();
  li_value2 = li.children('.value2');
  
  if (!country) {
    li_value2.html('');
    return;
  }
  
  get_carriers(country, {
    success: function(carriers) {
      li_value2.html(carriers_select(carriers));
    },
    error: function() {
      li_value2.html('An error happened :-(');
    }
  });
}

function remove_custom_attribute(a) {
  $(a).parent().parent().remove();
}

function remove_custom_attribute_link() {
  return '<a href="javascript:void(0)" onclick="remove_custom_attribute(this)">Remove</a>';
}

// === Utility functions ===
function get_countries(map) {
  $.ajax({
    type: "GET",
    url: '/api/countries.json',
    dataType: 'json', 
    success: map.success,
    error: map.error,
  });
}

function get_carriers(country_id, map) {
  $.ajax({
    type: "GET",
    url: '/api/carriers.json?country_id=' + country_id,
    dataType: 'json', 
    success: map.success,
    error: map.error,
  });
}

function applications_select() {
  var html = '';
  html += '<select name="custom_attribute_value[]">';
  html += '<option value="">Select an application...</option>';
  for(var i = 0; i < applications.length; i++) {
    html += '<option>' + applications[i] + '</option>';
  }
  html += '</select>';
  return html;
}

function countries_select(countries, name, onchange) {
  var html = '';
  html += '<select name="' + name + '"';
  if (onchange) {
    html += 'onchange="' + onchange + '"';
  }
  html += '>';
  html += '<option value="">Select a country...</option>';
  for(var i = 0; i < countries.length; i++) {
    html += '<option value="' + countries[i].iso2 + '">' + countries[i].name + '</option>';
  }
  html += '</select>';
  return html;
}

function carriers_select(carriers) {
  var html = '';
  html += '<select name="custom_attribute_value[]">';
  html += '<option value="">Select a carrier...</option>';
  for(var i = 0; i < carriers.length; i++) {
    html += '<option value="' + carriers[i].guid + '">' + carriers[i].name + '</option>';
  }
  html += '</select>';
  return html;
}

// ======= rules engine ui ===========

var rules_nextId = 0;
function rules_newId() { rules_nextId++; return rules_nextId; }

function add_rule_ui(ctx, prefix, rule) {
	var table = jQuery('table', ctx);
	
	var rule_id = rules_newId();
	var rule_prefix = prefix + '[' + rule_id + ']'
	
	var row = jQuery('<tr><td><a href="#" class="remove-rule">[x]</a></td><td><a href="#" class="add-matching">add matching</a></td><td><a href="#" class="add-action">add action</a></td><td><input type="checkbox" name="' + rule_prefix +'[stop]" value="yes"></td></tr>');
	table.append(row);
	var add_matching = jQuery('.add-matching', row);
	var add_action = jQuery('.add-action', row);
	
	jQuery('.remove-rule', row).click(function(){ row.remove(); return false; });
	add_matching.click(function(){ add_matching_ui(rule_id, add_matching, rule_prefix, null); return false; });
	add_action.click(function(){ add_action_ui(rule_id, add_action, rule_prefix, null); return false; });
	
	if (rule != null) {		
		// load existing matchings
		jQuery(rule.matchings).each(function(_, matching){
			add_matching_ui(rule_id, add_matching, rule_prefix, matching);
		});
		// load existing actions
		jQuery(rule.actions).each(function(_, action){
			add_action_ui(rule_id, add_action, rule_prefix, action);
		})
		// load stop value
		if (rule.stop) {
			jQuery('input:checkbox', row).val(['yes']);
		}
	}
}

function add_matching_ui(rule_id, add_matching, prefix, matching) {
	// add matching ui
	var matching_id = rules_newId();
	var matching_ui = jQuery('<div/>');
	add_matching.before(matching_ui);
	
	// fill matching ui
	var name_prefix = prefix + '[matchings][' + matching_id + ']';
	matching_ui.append('<input type="text" name="' + name_prefix +'[property]"/>');
	matching_ui.append('<select name="' + name_prefix +'[operator]"><option value="equals">==</option><option value="not_equals">!=</option><option value="starts_with">starts with</option><option value="regex">regex</option></select>');
	matching_ui.append('<input type="text" name="' + name_prefix +'[value]"/>');
	matching_ui.append('<a href="#" class="remove-matching">[x]</a>');
	
	jQuery('.remove-matching', matching_ui).click(function(){ matching_ui.remove(); return false; });
	
	// fill matching values
	if (matching != null) {
		jQuery('input:first', matching_ui).val(matching.property);
		jQuery('select', matching_ui).val(matching.operator);
		jQuery('input:last', matching_ui).val(matching.value);
	}
}

function add_action_ui(rule_id, add_action, prefix, action) {
	// add action ui
	var action_id = rules_newId();
	var action_ui = jQuery('<div/>');
	add_action.before(action_ui);
	
	// fill action ui
	var name_prefix = prefix + '[actions][' + action_id + ']';
	action_ui.append('<input type="text" name="' + name_prefix +'[property]"/>');
	action_ui.append(' = ');
	action_ui.append('<input type="text" name="' + name_prefix +'[value]"/>');
	action_ui.append('<a href="#" class="remove-action">[x]</a>');
	
	jQuery('.remove-action', action_ui).click(function(){ action_ui.remove(); return false; });
	
	// fil action values
	if (action != null) {
		jQuery('input:first', action_ui).val(action.property);
		jQuery('input:last', action_ui).val(action.value);
	}
}

function init_rules(ctx, prefix, rules) {
	// initial ui
	ctx.append('<table class="table"><tr><th>&nbsp;</th><th>Matching</th><th>Action</th><th>Stop</th></tr></table>');
	ctx.append('<div><a href="#" class="add-rule">add rule</a></div><br/>');
		
	jQuery('.add-rule', ctx).click(function(){
		add_rule_ui(ctx, prefix, null);				
		return false;
	});
	
	// load existing rules
	if (rules != null) {
		jQuery(rules).each(function(_, rule){
			add_rule_ui(ctx, prefix, rule);
		});
	}
}


