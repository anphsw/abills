/**
 * Created by Anykey on 09.09.2015.
 */

$(document).ready(function () {
  
  var SPINNER         = '<i class="fa fa-spinner fa-pulse"></i>';
  var MUTABLE_SELECTS = $('select[data-download-on-click=1]');
  
  window['address_forms_count'] = window['address_forms_count'] || 0;
  var count                     = ++window['address_forms_count'];
  if (count > 1) {
    console.warn('[ Address Search ] %d search forms on a page', count);
    //return false;
  }
  
  // Loading districts needs special behaviour to save previous value;
  function loadDistricts() {
    var elem_id = 'DISTRICT';
    
    var select = $('#' + elem_id);
    var label  = $('label[for=' + elem_id + ']');
    
    //append_spinner
    label.append(SPINNER);
    
    //AJAX get
    var params = 'qindex=30&address=1';
    $.get(SELF_URL, params, function (data) {
      select.html(data);
    })
        .done(function () {
          label.find('i.fa').remove();
        });
    
  }
  
  function loadList(elem_id, param, value) {
    var $select = $('#' + elem_id);
    var $label  = $('label[for=' + elem_id + ']');
    //append_spinner
    $label.append(SPINNER);
    
    //AJAX get
    var params = 'qindex=30&address=1&' + param + '=' + value;
    
    $.get(SELF_URL, params, function (data) {
      $select.empty().html(data);
      $select.prop('disabled', false);
      $select.trigger("chosen:updated");
    })
        .done(function () {
          $label.find('i.fa').remove();
        });
  }
  
  function loadNext(elem_id) {
    switch (elem_id) {
      case 'DISTRICT':
        //load streets
        loadList('STREET', 'DISTRICT_ID', getValue('DISTRICT'));
        break;
      case 'STREET':
        //load builds
        loadList('BUILD', 'STREET', getValue('STREET'));
        break;
    }
  }
  
  function clearNext(id) {
    
    switch (id) {
      case 'DISTRICT':
        //enable streets
        clearSelect('STREET');
        clearSelect('BUILD');
        break;
      case 'STREET':
        //enable builds
        clearSelect('BUILD');
        break;
    }
  }
  
  function getValue(elem_id) {
    return $('#' + elem_id + '_ID').val();
  }
  
  function getSelect(elem_id) {
    return $('#' + elem_id);
  }
  
  function clearSelect(elem_id) {
    getSelect(elem_id).val('')
        .chosen(CHOSEN_PARAMS)
        .prop('disabled', true)
        .trigger("chosen:updated");
    
    $('#' + elem_id + '_ID').val('');
    
    if (elem_id == 'BUILD') {
      $('#LOCATION_ID').val('');
    }
  }
  
  var district_input_div = $('#DISTRICT').next('div');
  var streets_input_div  = $('#STREET').next('div');
  
  //Register onClick handlers;
  MUTABLE_SELECTS.on('change', function () {
    //get value
    var $select = $(this);
    var value   = $select.val();
    
    //update hidden
    var id = $select.attr('id');
    $('#' + id + '_ID').val(value);
    
    if (id == 'BUILD') {
      $('#LOCATION_ID').val(value);
      events.emit('buildselected', value);
    }
    
    clearNext(id);
    loadNext(id);
  });
  
  district_input_div.on('click', function () {
    getSelect('DISTRICT').trigger("chosen:updated");
  });
  
  //Allow loading streets before districts
  streets_input_div.one('click', loadStreetsWithoutDistricts);
  function loadStreetsWithoutDistricts() {
    var value = getValue('DISTRICT');
    if (value === '') {
      loadList('STREET', 'DISTRICT_ID', '*');
    }
  }
  
  function checkFlatsForBuild() {
    var CHECK_FREE     = document['FLAT_CHECK_FREE'] || false;
    var CHECK_OCCUPIED = document['FLAT_CHECK_OCCUPIED'] || false;
    if (!(CHECK_FREE || CHECK_OCCUPIED)) return true;
  
    var $flat_input        = $('#ADDRESS_FLAT');
    var $flat_input_holder = $flat_input.parents('.form-group').first();
    var current_checker = null;
    
    var initialized = false;
    
    events.on('buildselected', function (build_id) {
  
      if (!build_id) return false;
      
      //Load all flats for build_id
      $.get(SELF_URL, 'qindex=30&address=1&LOCATION_ID=' + build_id, function (data) {
        
        try {
          var flats = JSON.parse(data);
          current_checker = new FlatInputChecker(initialized, $flat_input, $flat_input_holder, flats, CHECK_FREE, CHECK_OCCUPIED);
        }
        catch (JsonParseException) {
          (new ATooltip).displayError(JsonParseException);
          console.warn(JsonParseException);
        }
      });
    })
  }
  
  function FlatInputChecker(initialized, $flat_input, $flat_input_holder, flats, CHECK_FREE, CHECK_OCCUPIED) {
    
    // Starting check process
    $flat_input.on('input', check_input_value);
    
    // Dismissing check if new build selected
    events.on('buildselected', function(){
      $flat_input.off('input');
      $flat_input.popover('destroy');
    });
    
    function check_input_value() {
      var flat = this.value;
      if (typeof (flats[flat]) !== 'undefined') {
        show_occupied(flats[flat]);
      }
      else {
        hide_occupied();
      }
    }
    
    function show_occupied(user){
      CHECK_FREE ? $flat_input_holder.addClass('has-error') : '';
      CHECK_OCCUPIED ? $flat_input_holder.addClass('has-success') : '';
      
      var content = '<a href="?index=15&UID=' + user.uid + '" target="_blank">' + user.user_name + '</a>';
      if (!initialized) {
        $flat_input.popover({
          'content': content,
          'html'   : true
        });
        initialized = true;
      }
      else {
        $flat_input.attr('data-content', content).data('bs.popover').setContent();
      }
      
      $flat_input.popover('show');
    }
    
    function hide_occupied(){
      CHECK_FREE ? $flat_input_holder.removeClass('has-error') : '';
      CHECK_OCCUPIED ? $flat_input_holder.removeClass('has-success') : '';
      $flat_input.popover('hide');
    }
    
  }
  
  
  
  loadDistricts();
  checkFlatsForBuild();
  
});
