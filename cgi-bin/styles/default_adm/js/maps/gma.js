/**
 * Created by Anykey on 02.06.2016.
 */

var build = {
  city         : "Коломия",
  coordx       : "0.00000000000000",
  coordy       : "0.00000000000000",
  country      : "804",
  district_id  : "1",
  district_name: "Main District",
  full_address : "Коломия, Main District, Моцарта, 1",
  id           : "2",
  number       : "1",
  postalCode   : "78200",
  street_id    : "2",
  street_name  : "Моцарта"
};

var result = {
  add_index   : "199",
  message     : "Нема результатів",
  requested_id: "2",
  set_class   : "danger",
  status      : "2"
};


$(function () {
  "use strict";
  
  var single_coord_index = window['single_coord_index'];
  var builds_to_process  = window['builds_for_auto_coords'];
  var builds_count       = builds_to_process.length;
  
  var build_with_id = {};
  $.each(builds_to_process, function (i, build) {
    build_with_id[build.id] = build;
  });
  
  
  var ATableModifier = (function () {
    
    var position_of = {
      ID     : 0,
      ADDRESS: 1,
      STATUS : 2,
      BUTTON : 4
    };
    
    var $table = $('#GMA_TABLE_ID_');
    
    var table_row_for_id = {};
    
    function updateIndex() {
      table_row_for_id = {};
      
      $table.find('tr').map(function (index, entry) {
        var $entry = $(entry);
        var id     = $entry.find('td').first().text();
        
        table_row_for_id[id] = $entry;
      });
      
      ABuildProcessor.setInputsLocked(false);
    }
    
    function reloadTable(districts_are_not_real) {
      ABuildProcessor.setInputsLocked(true);
      
      var params = $.param({
        index                 : INDEX,
        DISTRICTS_ARE_NOT_REAL: districts_are_not_real ? 1 : 0
      });
      
      $table.load(SELF_URL + ' #GMA_TABLE_ID_', params, updateIndex);
    }
    
    function setClass(id, new_class) {
      
    }
    
    function handleStatus(status, result) {
      // Set class
      var id = result.requested_id;
      
      table_row_for_id[id].attr('class', 'text-' + result.set_class);
      
      var $status_td = $(table_row_for_id[id].children('td')[position_of.STATUS]);
      $status_td.text(result.message);
      
    }
    
    return {
      reloadTable : reloadTable,
      updateIndex : updateIndex,
      setClass    : setClass,
      handleStatus: handleStatus
    }
    
  })();
  
  
  var ABuildProcessor = (function () {
    
    var $exec_btn         = $('#GMA_EXECUTE_BTN');
    var $country_code_inp = $('#COUNTRY_CODE_id');
    var $districts_chb    = $('#DISTRICTS_ARE_NO_REAL');
    var country           = '';
    
    $districts_chb.on('change', function () {
      ATableModifier.reloadTable($districts_chb.prop('checked'));
    });
    
    $exec_btn.on('click', function () {
      setInputsLocked(true);
      var country = $country_code_inp.val();
      startExecution();
    });
    
    function startExecution() {
      AProgressBar.set(0);
      requestCoordsFor(0);
    }
    
    function requestCoordsFor(index_of_build) {
      
      var build = builds_to_process[index_of_build];
      
      console.log(build);
      
      if (index_of_build >= builds_to_process.length) {
        setInputsLocked(false);
        return true;
      }
      
      
      var districts_are_not_real = $districts_chb.prop('checked');
      
      var district_name = (districts_are_not_real) ? '' : ( build.district_name + ", ");
      
      var requested_addr = build.city + ', '
          + district_name
          + build.street_name + ', '
          + build.number;
      
      var params = $.param({
        qindex         : single_coord_index,
        header         : 2,
        //json : 1,
        REQUEST_ADDRESS: requested_addr,
        BUILD_ID       : build.id
      });
      
      $.getJSON(SELF_URL, params, function (responce) {
        AProgressBar.update(1, responce.status);
        
        ATableModifier.handleStatus(responce.status, responce);
        
        if (responce.status < 500) {
          requestCoordsFor(index_of_build + 1);
        }
        else {
          AProgressBar.setMax();
          AProgressBar.setClass('progress-bar-danger');
        }
        
      })
    }
    
    function setInputsLocked(boolean) {
      if (boolean) {
        $exec_btn.addClass('disabled');
        $districts_chb.attr('disabled', true);
      }
      else {
        $exec_btn.removeClass('disabled');
        $districts_chb.attr('disabled', false);
      }
    }
    
    
    return {
      setInputsLocked: setInputsLocked
    }
  })();
  
  ATableModifier.updateIndex();
  
  var AProgressBar = (function () {
    
    var max_value     = builds_count;
    var $progress_bar = $('#progress_status');
    var progress      = 0;
    var current_class = 'progress-bar-success';
    
    function update(value, status) {
      // Overall progress
      progress += value;
      setWidth(progress);
    }
    
    function set(value) {
      progress = value;
      setWidth(progress);
    }
    
    function setClass(new_class) {
      $progress_bar.removeClass(current_class);
      $progress_bar.addClass(new_class);
    }
    
    function setMax() {
      set(max_value);
    }
    
    function setWidth(progress) {
      var new_width     = progress / max_value * 100;
      var new_width_int = Math.round(new_width);
      $progress_bar.attr('style', 'width : ' + new_width_int + '%');
    }
    
    return {
      setClass: setClass,
      setMax  : setMax,
      update  : update,
      set     : set
    }
    
  })();
  
  
});