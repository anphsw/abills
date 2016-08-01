/**
 * This array is used to remember mark status of rows in browse mode
 */
var marked_row = [];

var modalsSearchArray = [];

var ADMIN_INTERFACE = 1;

/**
 * enables highlight and marking of rows in data tables
 *
 */
function PMA_markRowsInit() {
  // for every table row ...
  var rows = document.getElementsByTagName('tr');
  for (var i = 0; i < rows.length; i++) {
    // ... with the class 'odd' or 'even' ...
    if ('odd' != rows[i].className.substr(0, 3) && 'even' != rows[i].className.substr(0, 4)) {
      continue;
    }
    // ... add event listeners ...
    // ... to highlight the row on mouseover ...
    if (navigator.appName == 'Microsoft Internet Explorer') {
      // but only for IE, other browsers are handled by :hover in css
      rows[i].onmouseover = function () {
        this.className += ' hover';
      };
      rows[i].onmouseout = function () {
        this.className = this.className.replace(' hover', '');
      }
    }
    // Do not set click events if not wanted
    if (rows[i].className.search(/noclick/) != -1) {
      continue;
    }
    // ... and to mark the row on click ...
    rows[i].onmousedown = function (event) {
      var unique_id;
      var checkbox;
      var table;

      // Somehow IE8 has this not set
      if (!event) var event = window.event;

      checkbox = this.getElementsByTagName('input')[0];
      if (checkbox && checkbox.type == 'checkbox') {
        unique_id = checkbox.name + checkbox.value;
      } else if (this.id.length > 0) {
        unique_id = this.id;
      } else {
        return;
      }

      if (typeof(marked_row[unique_id]) == 'undefined' || !marked_row[unique_id]) {
        marked_row[unique_id] = true;
      } else {
        marked_row[unique_id] = false;
      }

      if (marked_row[unique_id]) {
        this.className += ' marked';
      } else {
        this.className = this.className.replace(' marked', '');
      }

      if (checkbox && checkbox.disabled == false) {
        checkbox.checked = marked_row[unique_id];
        if (typeof(event) == 'object') {
          table = this.parentNode;
          i = 0;
          while (table.tagName.toLowerCase() != 'table' && i < 20) {
            i++;
            table = table.parentNode;
          }

          if (event.shiftKey == true && table.lastClicked != undefined) {
            if (event.preventDefault) {
              event.preventDefault();
            } else {
              event.returnValue = false;
            }
            i = table.lastClicked;

            if (i < this.rowIndex) {
              i++;
            } else {
              i--;
            }

            while (i != this.rowIndex) {
              table.rows[i].onmousedown();
              if (i < this.rowIndex) {
                i++;
              } else {
                i--;
              }
            }
          }

          table.lastClicked = this.rowIndex;
        }
      }
    };

    // ... and disable label ...
    var labeltag = rows[i].getElementsByTagName('label')[0];
    if (labeltag) {
      labeltag.onclick = function () {
        return false;
      }
    }
    // .. and checkbox clicks
    var checkbox = rows[i].getElementsByTagName('input')[0];
    if (checkbox) {
      checkbox.onclick = function () {
        // opera does not recognize return false;
        this.checked = !this.checked;
      }
    }
  }
}
window.onload = PMA_markRowsInit;


//hide tables onclick test
$(document).ready(function () {
  $('.tableHideShowImg').click(function () {
    //console.log($(this).parents().eq(1).next());
    $(this).parents().eq(1).next().slideToggle(0);
    $(this).parents().eq(1).next().next().slideToggle(0);

    console.log($(this).attr('src'));
    if ($(this).attr('src').match(/.*dropup\.png$/)) {
      $(this).attr('src', '/img/dropdown.png');
    } else {
      $(this).attr('src', '/img/dropup.png');
    }

  });
  $('.js_cols_name').click(function () {

    var prevPopupWindow = $(this).parents().eq(1).prev().children().children('div#open_popup_block_middle');
    //console.log();
    prevPopupWindow.css({
      'overflow-y': 'scroll',
      'margin-top': -((prevPopupWindow.height()) / 2),
      'margin-left': -((prevPopupWindow.width()) / 2)
    }).slideToggle(0);


    $('#close_popup_window').click(function () {

      $(this).parent().hide();
    });
  });

  $('#hold_up_window, input[name=\"hold_up_window\"]').click(function (e) {
    e.preventDefault();
    var prevPopupWindow = $(this).closest('table').next('div#open_popup_block_middle');
    var close = prevPopupWindow.children('a#close_popup_window');

    console.log(close);
    prevPopupWindow.css({
      'margin-top': -((prevPopupWindow.height()) / 2),
      'margin-left': -((prevPopupWindow.width()) / 2)
    }).slideToggle(0);

    close.click(function () {
      $(this).parent().hide();
    });

  });


});


/**

 */
// function comments_add(theLink, Message, CustomMsg) {
//   var comments = prompt(Message, '');
//
//   if (comments == '' || comments == null) {
//     alert('Enter comments');
//   }
// }

function defineHighlightRow() {
  $('tr').on('click', function () {
    var $this = $(this);

    if (!$this.parents('table').hasClass('no-highlight')) {

      //Get a color for bg-info class
      var $color = $('.bg-success').css('background-color');

      //We need to know if it's been already colored
      var trigger = ($this.css('background-color') == $color);

      //operate only on second click
      var second_click = $this.prop('highlighted') == true;
      switch (second_click) {
        case true:
          switch (trigger) {
            case true: //if it was colored
              $this.css('background-color', $(this).prop('color_before')); //drop custom color
              $this.prop('highlighted', false);
              break;
            default:  //if not
              $this.css('background-color', $color);    //set custom color
              break;
          }
          break;
        default:
          $(this).prop('highlighted', true);
          $(this).prop('color_before', $this.css('background-color'));
      }

    }
  });
}


function defineMainSearchLiveLogic() {
  'use strict';
  var $universal_search = $('.UNIVERSAL_SEARCH');
  if ($universal_search.length == 0){
    return true;
  }
  
  var $universal_search_form = $('#UNIVERSAL_SEARCH_FORM');
  var $type_select = $universal_search_form.find('#type');
  
  $.getScript('/styles/default_adm/js/mustache.min.js', function () {
    $.getScript('/styles/default_adm/js/jquery.marcopolo.min.js', function () {
      var login_uid_row_template = '<div class="row">'
          + '<span class="pull-left">{{fio}}</span>'
          + '<span class="pull-right"><strong>{{login}} ( {{uid}} )</strong></span>'
          + '</div>';
      var address_phone_row_template = '<div class="row">'
          + '<span class="mp_address pull-left"><strong>{{address_full}}</strong>&nbsp;</span>'
          + '<span class="mp_phone pull-right"><i class="text-muted">{{phone}}</i></span>'
          + '</div>';
  
      Mustache.parse(login_uid_row_template);
      Mustache.parse(address_phone_row_template);
  
      try {
    
        $universal_search.marcoPolo({
      
          data: function () {
            return {
              qindex        : 7,
              header        : 1,
              search        : 1,
              type          : $type_select.val() || 10,
              json          : 1,
              SKIP_FULL_INFO: 1,
              EXPORT_CONTENT: "USERS_LIST"
            }
          },
      
          formatData: function (data) {
            return data.DATA_1;
          },
      
          submitOnEnter: true,
          highlight    : false,
  
          selectable : ':not(.disabled)',
          
          formatItem: function (data, $item) {
            
            // Disable selecting if not universal search type;
            if ($type_select.val() !== '10' ){
              $item.addClass('disabled');
              $item.addClass('bg-warning');
            }
            else {
              $item.addClass('bg-info');
            }
            
            var result = Mustache.render(login_uid_row_template, data);
            if (data.address_full && data.phone){
              result += Mustache.render(address_phone_row_template, data);
            }
            return result;
          },
      
          minChars: 3,
      
          onSelect: function (data, $item) {
            location.replace('?index=15&UID=' + data.uid);
          },
      
          param: 'LOGIN',
      
          required: false
        });
      }
      catch (Error){
        console.log(Error.message);
      }
    });
  });
  
 
  //Higlighted style
  var highlighted_style_block = ''
      + '<style> ol.mp_list li.mp_highlighted {' +
      ' background-color:' + $('.bg-success').css('background-color')
      +'}</style>';
  
  $('head').append(highlighted_style_block);
}


$(document).ready(function () {
  
  //Highlight row
  defineHighlightRow();
  
  //Live universal search
  defineMainSearchLiveLogic();
  
});


var currColor = 0;
var colorArray = [
  'rgba(200, 0  , 0  ',
  'rgba(0  , 200, 0',
  'rgba(0  , 0  , 200 ',
  'rgba(255, 200, 0 ',
  'rgba(255, 0  , 200',
  'rgba(200, 255, 0',
  'rgba(200, 0  , 255 ',
  'rgba(255, 0  , 0  ',
  'rgba(150 , 100 , 255',
  'rgba(52 , 184 , 156'
];

function nextColor(opacity) {
  if (currColor == colorArray.length - 2) currColor = 0;
  return colorArray[currColor++] + ',' + opacity + ')';
}