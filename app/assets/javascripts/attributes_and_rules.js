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
    html += applications_select('custom_attribute_value[]');
    if (show_accept_when_not_specified_option) html += ' &nbsp; ' + accept_when_not_specified_checkbox(true);
    html += ' &nbsp; ' + remove_custom_attribute_link();
    li_value.html(html);
    break;
  case 'suggested_channel':
    var html = ' = ';
    html += channels_select('custom_attribute_value[]');
    if (show_accept_when_not_specified_option) html += ' &nbsp; ' + accept_when_not_specified_checkbox();
    html += ' &nbsp; ' + remove_custom_attribute_link();
    li_value.html(html);
    break;
  case 'explicit_channel':
    var html = ' = ';
    html += channels_select('custom_attribute_value[]');
    if (show_accept_when_not_specified_option) html += ' &nbsp; ' + accept_when_not_specified_checkbox();
    html += ' &nbsp; ' + remove_custom_attribute_link();
    li_value.html(html);
    break;
  case 'country':
    get_countries({
      success: function(countries) {
        var html = ' = ';
        html += countries_select(countries, 'custom_attribute_value[]');
        if (show_accept_when_not_specified_option) html += ' &nbsp; ' + accept_when_not_specified_checkbox(true);
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
        if (show_accept_when_not_specified_option) html += ' &nbsp; ' + accept_when_not_specified_checkbox(true);
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
    if (show_accept_when_not_specified_option) html += ' &nbsp; ' + accept_when_not_specified_checkbox();
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
      li_value2.html(carriers_select(carriers, 'custom_attribute_value[]'));
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
    error: map.error
  });
}

function get_carriers(country_id, map) {
  $.ajax({
    type: "GET",
    url: '/api/carriers.json?country_id=' + country_id,
    dataType: 'json',
    success: map.success,
    error: map.error
  });
}

function get_carrier(carrier_id, map) {
  $.ajax({
    type: "GET",
    url: '/api/carriers/' + carrier_id + '.json',
    dataType: 'json',
    success: map.success,
    error: map.error
  });
}

function applications_select(name) {
  return custom_select(applications, 'Select an application...', name);
}

function channels_select(name) {
  return custom_select(channels, 'Select a channel...', name);
}

function custom_select(objects, title, name) {
  var html = '';
  html += '<select name="' + name + '">';
  html += '<option value="">' + title + '</option>';
  for(var i = 0; i < objects.length; i++) {
    html += '<option>' + objects[i] + '</option>';
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

function carriers_select(carriers, name) {
  var html = '';
  html += '<select name="' + name + '">';
  html += '<option value="">Select a carrier...</option>';
  for(var i = 0; i < carriers.length; i++) {
    html += '<option value="' + carriers[i].guid + '">' + carriers[i].name + '</option>';
  }
  html += '</select>';
  return html;
}

function accept_when_not_specified_checkbox(checked) {
  var html = '';
  html += '<input type="hidden" name="custom_attribute_optional[]" value="0"/>';
  html += '<input type="checkbox" name="custom_attribute_optional[]" value="1"';
  if (checked) html += ' checked="checked"';
  html += '/> Accept when not specified';
  return html;
}

// ======= rules engine ui ===========

var rules_nextId = 0;
function rules_newId() { rules_nextId++; return rules_nextId; }

function add_rule_ui(ctx, prefix, rule, excluded_matchings, excluded_actions) {
  var table = jQuery('table', ctx);

  var rule_id = rules_newId();
  var rule_prefix = prefix + '[' + rule_id + ']'

  var row = jQuery('<tr><td><a href="#" class="remove-rule">[x]</a></td><td><a href="#" class="add-matching">add condition</a></td><td><a href="#" class="add-action">add action</a></td><td><input type="checkbox" name="' + rule_prefix +'[stop]" value="yes"></td></tr>');
  table.append(row);
  var add_matching = jQuery('.add-matching', row);
  var add_action = jQuery('.add-action', row);

  jQuery('.remove-rule', row).click(function(){ row.remove(); return false; });
  add_matching.click(function(){ add_matching_ui(rule_id, add_matching, rule_prefix, null, excluded_matchings); return false; });
  add_action.click(function(){ add_action_ui(rule_id, add_action, rule_prefix, null, excluded_actions); return false; });

  if (rule != null) {
    // load existing matchings
    if (rule.matchings) {
      jQuery(rule.matchings).each(function(_, matching){
        add_matching_ui(rule_id, add_matching, rule_prefix, matching, excluded_matchings);
      });
    }
    // load existing actions
    if (rule.actions) {
      jQuery(rule.actions).each(function(_, action){
        add_action_ui(rule_id, add_action, rule_prefix, action, excluded_actions);
      });
    }
    // load stop value
    if (rule.stop) {
      jQuery('input:checkbox', row).val(['yes']);
    }
  }
}

function add_matching_ui(rule_id, add_matching, prefix, matching, excluded_matchings) {
  // add matching ui
  var matching_id = rules_newId();
  var matching_ui = jQuery('<div/>');
  add_matching.before(matching_ui);

  // fill matching ui
  var matchings = [];
  var all_matchings = ['application', 'body', 'country', 'carrier', 'from', 'subject', 'subject_and_body', 'to', 'other'];
  if (excluded_matchings) {
    if (excluded_matchings['include']) {
      excluded_matchings = excluded_matchings['include'];
      for(var i in all_matchings) {
        if (excluded_matchings.indexOf(all_matchings[i]) >= 0) {
          matchings.push(all_matchings[i]);
        }
      }
    } else {
      excluded_matchings = excluded_matchings['exclude'];
      for(var i in all_matchings) {
        if (excluded_matchings.indexOf(all_matchings[i]) < 0) {
          matchings.push(all_matchings[i]);
        }
      }
    }
  } else {
    matchings = all_matchings;
  }

  var name_prefix = prefix + '[matchings][' + matching_id + ']';
  var matching_ui_str = '';
  matching_ui_str += '<span class="property"><select name="' + name_prefix +'[property]">';
  matching_ui_str += property_combo_string(matchings);
  matching_ui_str += '</select></span>';

  matching_ui.append(matching_ui_str);
  matching_ui.append('<select class="operator" name="' + name_prefix +'[operator]"><option value="equals">equals</option><option value="not_equals">not equals</option><option value="starts_with">starts with</option><option value="regex">regex</option></select>');
  matching_ui.append('<span class="value"><input type="text" name="' + name_prefix +'[value]"/></span>');
  matching_ui.append('<a href="#" class="remove-matching">[x]</a>');

  jQuery('.remove-matching', matching_ui).click(function(){ matching_ui.remove(); return false; });

  var property = jQuery('select:first', matching_ui);
  var propertyDiv = jQuery('.property', matching_ui);
  var valueDiv = jQuery('.value', matching_ui);
  var operatorSelect = jQuery('.operator', matching_ui);

  init_properties(name_prefix, property, propertyDiv, valueDiv, operatorSelect);
  if (matching != null) {
    init_existing_property(matching, name_prefix, property, propertyDiv, valueDiv, operatorSelect);
  }
}

function add_action_ui(rule_id, add_action, prefix, action, excluded_actions) {
  // add action ui
  var action_id = rules_newId();
  var action_ui = jQuery('<div/>');
  add_action.before(action_ui);

  // fill action ui
  var actions = [];
  var all_actions = ['application', 'body', 'cost', 'country', 'carrier', 'from', 'subject', 'to', 'cancel', 'other'];
  if (excluded_actions) {
    if (excluded_actions['include']) {
      excluded_actions = excluded_actions['include'];
      for(var i in all_actions) {
        if (excluded_actions.indexOf(all_actions[i]) >= 0) {
          actions.push(all_actions[i]);
        }
      }
    } else {
      excluded_actions = excluded_actions['exclude'];
      for(var i in all_actions) {
        if (excluded_actions.indexOf(all_actions[i]) < 0) {
          actions.push(all_actions[i]);
        }
      }
    }
  } else {
    actions = all_actions;
  }

  var name_prefix = prefix + '[actions][' + action_id + ']';
  var action_ui_str = '';
  action_ui_str += '<span class="property"><select name="' + name_prefix +'[property]">';
  action_ui_str += property_combo_string(actions);
  action_ui_str += '</span>';

  action_ui.append(action_ui_str);
  action_ui.append('<span class="value_container">');
  action_ui.append('<span class="operator"> = </span>');
  action_ui.append('<span class="value"><input type="text" name="' + name_prefix +'[value]"/></span>');
  action_ui.append('<a href="#" class="remove-action">[x]</a>');
  action_ui.append('</span>');

  jQuery('.remove-action', action_ui).click(function(){ action_ui.remove(); return false; });

  var property = jQuery('select:first', action_ui);
  var propertyDiv = jQuery('.property', action_ui);
  var operatorDiv = jQuery('.operator', action_ui);
  var valueDiv = jQuery('.value', action_ui);

  init_properties(name_prefix, property, propertyDiv, valueDiv, operatorDiv);
  if (action != null) {
    init_existing_property(action, name_prefix, property, propertyDiv, valueDiv, operatorDiv);
  }
}

function init_rules(ctx, prefix, rules, excluded_matchings, excluded_actions) {
  // initial ui
  ctx.append('<table class="table"><tr><th>&nbsp;</th><th>Condition</th><th>Action</th><th>Stop</th></tr></table>');
  ctx.append('<div><a href="#" class="add-rule">add rule</a></div><br/>');

  jQuery('.add-rule', ctx).click(function(){
    add_rule_ui(ctx, prefix, null, excluded_matchings, excluded_actions);
    return false;
  });

  // load existing rules
  if (rules != null) {
    jQuery(rules).each(function(_, rule){
      add_rule_ui(ctx, prefix, rule, excluded_matchings, excluded_actions);
    });
  }
}

function init_properties(name_prefix, property, propertyDiv, valueDiv, operatorSelect) {
  var propertyChangedFunction = function(property) {
    var val = property.val();
    switch(val) {
      case 'application':
        init_property_application(name_prefix, valueDiv, operatorSelect);
        break;
      case 'country':
        init_property_country(name_prefix, valueDiv, operatorSelect);
        break;
      case 'carrier':
        init_property_carrier(name_prefix, valueDiv, operatorSelect);
        break;
      case 'other':
        init_property_other(name_prefix, propertyDiv, valueDiv, operatorSelect);
        break;
      case 'cancel':
        operatorSelect.hide();
        valueDiv.val('true');
        valueDiv.hide();
        break;
      default:
        init_property_field(name_prefix, propertyDiv, valueDiv, operatorSelect);
        break;
    }
    if (val != 'cancel') {
      operatorSelect.show();
      valueDiv.show();
    }
  };
  property.change(function() { propertyChangedFunction(jQuery(this))});
  propertyChangedFunction(property);
}

function init_property_application(name_prefix, valueDiv, operatorSelect, existing) {
  if (operatorSelect && operatorSelect.get()[0].tagName == 'SELECT') {
    operatorSelect.html(op_equals_not_equals());
    if (existing) operatorSelect.val(existing.operator);
  }
  valueDiv.html(applications_select(name_prefix + '[value]'));
  if (existing) {
    jQuery('select', valueDiv).val(existing.value);
  }
}

function init_property_country(name_prefix, valueDiv, operatorSelect, existing) {
  if (operatorSelect && operatorSelect.get()[0].tagName == 'SELECT') {
    operatorSelect.html(op_equals_not_equals());
    if (existing) operatorSelect.val(existing.operator);
  }
  get_countries({
    success: function(countries) {
      valueDiv.html(countries_select(countries, name_prefix + '[value]'));
      if (existing) {
        jQuery('select', valueDiv).val(existing.value);
      }
    },
    error: function() {
      alert('An error happened while retreiving countries :-(');
    }
  });
}

function init_property_carrier(name_prefix, valueDiv, operatorSelect, existing) {
  if (operatorSelect && operatorSelect.get()[0].tagName == 'SELECT') {
    operatorSelect.html(op_equals_not_equals());
    if (existing) operatorSelect.val(existing.operator);
  }
  get_countries({
    success: function(countries) {
      valueDiv.html(countries_select(countries, 'dummy'));
      var countriesSelect = jQuery('select:first', valueDiv);
      var countriesSelectChange = function() {
        var countryId = countriesSelect.val();
        if (countryId) {
          get_carriers(countriesSelect.val(), {
            success: function(carriers) {
              var selects = jQuery('select', valueDiv);
              if (selects.length == 2) {
                jQuery('select:last', valueDiv).remove();
              }
              valueDiv.append(carriers_select(carriers, name_prefix + '[value]'));
              if (existing) {
                jQuery('select', valueDiv).val(existing.value);
              }
            },
            error: function() {
              alert('An error happened while retreiving carriers :-(');
            }
          });
        } else {
          jQuery('select:last', valueDiv).remove();
        }
      };

      countriesSelect.change(function() { countriesSelectChange() });
      if (existing) {
        get_carrier(existing.value, {
          success: function(carrier) {
            countriesSelect.val(carrier.country_iso2);
            countriesSelectChange(countriesSelect);
          },
          error: function() {
            alert('An error happened while retreiving a carrier :-(');
          }
        });
      }
    },
    error: function() {
      alert('An error happened while retreiving countries :-(');
    }
  });
}

function init_property_other(name_prefix, propertyDiv, valueDiv, operatorSelect, existing) {
  propertyDiv.html('<input type="text" name="' + name_prefix +'[property]"/>');
  if (operatorSelect && operatorSelect.get()[0].tagName == 'SELECT') {
    operatorSelect.html(op_all());
  }
  valueDiv.html('<input type="text" name="' + name_prefix +'[value]"/>');

  if (existing) {
    jQuery('input', propertyDiv).val(existing.property);
    jQuery('input', valueDiv).val(existing.value);
    if (operatorSelect && operatorSelect.get()[0].tagName == 'SELECT') {
      operatorSelect.val(existing.operator);
    }
  }
}

function init_property_field(name_prefix, propertyDiv, valueDiv, operatorSelect, existing) {
  if (operatorSelect && operatorSelect.get()[0].tagName == 'SELECT') {
    operatorSelect.html(op_all());
  }
  valueDiv.html('<input type="text" name="' + name_prefix +'[value]"/>');

  if (existing) {
    jQuery('input', propertyDiv).val(existing.property);
    jQuery('input', valueDiv).val(existing.value);
    if (operatorSelect && operatorSelect.get()[0].tagName == 'SELECT') {
      operatorSelect.val(existing.operator);
    }
  }
}

function init_existing_property(existing, name_prefix, property, propertyDiv, valueDiv, operatorSelect) {
  property.val(existing.property);
  switch(existing.property) {
  case 'application':
    init_property_application(name_prefix, valueDiv, operatorSelect, existing);
    break;
  case 'country':
    init_property_country(name_prefix, valueDiv, operatorSelect, existing);
    break;
  case 'carrier':
    init_property_carrier(name_prefix, valueDiv, operatorSelect, existing);
    break;
  case 'from':
  case 'to':
  case 'subject':
  case 'body':
  case 'subject_and_body':
  case 'cost':
    init_property_field(name_prefix, propertyDiv, valueDiv, operatorSelect, existing);
    break;
  case 'cancel':
    operatorSelect.hide();
    valueDiv.val('true');
    valueDiv.hide();
    break;
  default:
    init_property_other(name_prefix, propertyDiv, valueDiv, operatorSelect, existing);
    break;
  }
}

function op_equals_not_equals() {
  return '<option value="equals">is</option><option value="not_equals">is not</option>';
}

function op_all() {
  return '<option value="equals">is</option><option value="not_equals">is not</option><option value="starts_with">starts with</option><option value="regex">regex</option>';
}

function property_combo_string(actions) {
  str = '';
  for(var i = 0; i < actions.length; i++) {
    switch(actions[i]) {
      case 'application':
        str += '<option value="application">Application</option>';
        break;
      case 'body':
        str += '<option value="body">Body</option>';
        break;
      case 'cost':
        str += '<option value="cost">Cost</option>';
        break;
      case 'country':
        str += '<option value="country">Country</option>';
        break;
      case 'carrier':
        str += '<option value="carrier">Carrier</option>';
        break;
      case 'from':
        str += '<option value="from">From</option>';
        break;
      case 'subject':
        str += '<option value="subject">Subject</option>';
        break;
      case 'subject_and_body':
        str += '<option value="subject_and_body">Subject and Body</option>';
        break;
      case 'to':
        str += '<option value="to">To</option>';
        break;
      case 'cancel':
        str += '<option value="cancel">Cancel the message</option>';
        break;
      case 'other':
        str += '<option value="other">Other...</option></select>';
        break;
    }
  }
  return str;
}
