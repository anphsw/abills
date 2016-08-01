/**
 * This is functions used both in client and admin interface
 * */

var confirmMsg = '';
var IPV4REGEXP = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$|^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$";

function checkval(url) {

  var val;
  var field = document.getElementById('pagevalue').value;
  if (field == '')
    return alert('#pagevalue value is empty');

  val = parseInt(field);

  if (isNaN(val))
    return alert('#pagevalue.value is not a number!');

  if (val != field)
    return alert('Error parsing #pagevalue.value');

  if (val <= 0)
    return alert('Value is less than zero');

  window.location = url + val;
}

function showHidePageJump() {
  if (document.getElementById('pageJumpWindow').style.display == 'block') {
    document.getElementById('pageJumpWindow').style.display = 'none';
  } else {
    document.getElementById('pageJumpWindow').style.display = 'block';
  }
}

/*Holds ctrl pressed*/
var ctrl = false;
function keyDown(e) {
  var CTRL = 17;
  var ENTER = 13;

  switch (e.keyCode) {
    case CTRL:
      ctrl = true;
      break;
    case ENTER:
      if (ctrl) {
        clickButton('go');
      } else {
        clickButton('save');
        if (getData) getData(); //modalSearch
      }
  }
}

function clickButton(id) {
  var btn = document.getElementById(id);
  if (btn)
    btn.click();
}

/**

 */
function keyUp(e) {
  if (e.keyCode == 17)
    ctrl = false;
}

/**
 * Displays an confirmation box beforme to submit a "DROP/DELETE/ALTER" query.
 * This function is called while clicking links
 *
 * @return  boolean  whether to run the query or not
 * @param theLink
 * @param Message
 * @param CustomMsg
 */
function confirmLink(theLink, Message, CustomMsg) {
  if (CustomMsg != undefined) {
    confirmMsg = CustomMsg;
  }
  //else {
  // 	confirmMsg = confirmMsg + ' :\n';
  // }

  var is_confirmed = confirm(confirmMsg + Message);
  if (is_confirmed) {
    theLink.href += '&is_js_confirmed=1';
  }

  return is_confirmed;
} // end of the 'confirmLink()' function


/**
 * Generate a new password, which may then be copied to the form
 * with suggestPasswordCopy().
 *
 *
 * @return  boolean  always true
 * @param input_pwchars
 * @param input_passwordlength
 */
function suggestPassword(input_pwchars, input_passwordlength) {
  var pwchars = "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ.,:";
  var passwordlength = 8;    // do we want that to be dynamic?  no, keep it simple :)
  var passwd = document.getElementById('generated_pw');

  if (input_pwchars != '') {
    pwchars = input_pwchars;
  }

  if (input_passwordlength != '') {
    passwordlength = input_passwordlength;
  }


  passwd.value = '';

  for (i = 0; i < passwordlength; i++) {
    passwd.value += pwchars.charAt(Math.floor(Math.random() * pwchars.length))
  }
  return passwd.value;
}

/**
 * Copy the generated password (or anything in the field) to the form
 *
 * @param   string   the form name
 *
 * @return  boolean  always true
 */
function suggestPasswordCopy() {
  document.getElementById('text_pma_pw').value = document.getElementById('generated_pw').value;
  document.getElementById('text_pma_pw2').value = document.getElementById('generated_pw').value;
  return true;
}

/**
 * Copy one input form to other
 *
 * @param   from, to   the form name
 *
 * @return  boolean  always true
 */
function CopyInputField(from, to) {
  document.getElementById(to).value = document.getElementById(from).value;
  return true;
}

/*
 * Disable button after click
 * @param obj, object text
 *
 * @return  boolean  always true
 */
function obj_disable(obj, text) {
  obj.disabled = !obj.disabled;

  if (text != '') obj.value = text;

  return true;
}

function getGlyphicon(iconName) {
  return "<span class='glyphicon glyphicon-" + iconName + "'></span>";
}

function defineCommentModalLogic() {
  //Cache DOM
  var $modal = $('#comments_add');

  var $mHeader = $modal.find('#mHeader');
  var $mTitle = $modal.find('#mTitle');

  var $mInput = $modal.find('#mInput');
  var $mButton = $modal.find('#mButton');

  var $mForm = $modal.find('#mForm');

  //Focus input when showing modal
  $modal.on('shown.bs.modal', function () {
    $mInput.focus();
  });

  $('a[data-target="#comments_add"]').click(function () {
    var data_id = null;
    var xUID = null;

    if (typeof $(this).data('id') !== 'undefined') {
      data_id = $(this).data('id');
    }
    if (typeof $(this).data('id') !== 'undefined') {
      xUID = $(this).data('uix');
    }
    $mHeader.removeClass('alert-danger');
    $mHeader.addClass('alert-info');
    $mTitle.html(xUID);

    $mForm.on('submit', function (e) {
      e.preventDefault();

      var comments = $mInput.val();

      if (comments == '' || comments == null) {
        $mHeader.removeClass('alert-info');
        $mHeader.addClass('alert-danger');
        $mTitle.html(_COMMENTS_PLEASE + '!');
      }
      else {
        var url = data_id + '&COMMENTS=' + comments;
        window.location.replace(url);
        $modal.modal('hide');
      }
    });
  });
}
/**
 * Main function to get user location. By default tries to set values to #location_x and #location_y inputs.
 * successCallback is called with [x,y] as an argument.
 *
 * @param successCallback function with 1 argument [x, y]
 * @param errorCallback
 * @param notInForm - if true, not trying to find #location_x and #location_y inputs !NOT CALLING SUCCESS CALLBACK
 *
 * Anykey
 */
function getLocation(successCallback, errorCallback, notInForm) {

  function success(position) {
    var x = position.coords.latitude;
    var y = position.coords.longitude;

    if (!notInForm) {
      $('#location_x').val(position.coords.latitude);
      $('#location_y').val(position.coords.longitude);
    } else {
      return [x, y];
    }

    if (successCallback) {
      successCallback([x, y]);
    }
  }

  function error() {
    if (errorCallback) {
      errorCallback();
    }
  }

  var options = {
    enableHighAccuracy: true,
    timeout: 120000,
    maximumAge: 0
  };

  navigator.geolocation.getCurrentPosition(success, error, options);
}

var aColorPalette = new AColorPalette();
function AColorPalette() {
  var self = this;
  this.counter = 0;

  this.array = [
    '#F44336', // Red
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FFEB3B', // Yellow

    '#00BCD4', // Cyan
    '#CDDC39', // Lime
    '#9C27B0', // Purple
    '#009688', // Teal

    '#8BC34A', // Light Green
    '#607D8B', // Blue Grey
    '#9E9E9E', // Grey
    '#FF9800', // Orange

    '#795548', // Brown
    '#3F51B5', // Indigo
    '#FFC107', // Amber
    '#673AB7', // Deep Purple

    '#FF5722', // Deep Orange
    '#E91E63', // Pink
    '#03A9F4' // Light Blue
  ];

  this.getNextColorHex = function () {
    checkCounter();
    return this.array[this.counter++];
  };

  this.getCurrentColorHex = function () {
    return this.array[this.counter - 1];
  };

  this.getNextColorRGB = function () {
    return this.convertHexToRGB(this.getNextColorHex());
  };

  this.getNextColorRGBA = function (opacity) {
    return this.convertHexToRGBA(this.getNextColorHex(), opacity);
  };

  this.convertHexToRGB = function (hex) {
    var numbersHex = hex.substring(1); //removing '#'

    var rHex = numbersHex.substring(0, 2);
    var gHex = numbersHex.substring(2, 4);
    var bHex = numbersHex.substring(4, 6);

    var r = parseInt(rHex, 16);
    var g = parseInt(gHex, 16);
    var b = parseInt(bHex, 16);

    return 'rgb(' + r + ', ' + g + ', ' + b + ')';
  };

  this.convertHexToRGBA = function (hex, opacity) {
    var numbersHex = hex.substring(1); //removing '#'

    var rHex = numbersHex.substring(0, 2);
    var gHex = numbersHex.substring(2, 4);
    var bHex = numbersHex.substring(4, 6);

    var r = parseInt(rHex, 16);
    var g = parseInt(gHex, 16);
    var b = parseInt(bHex, 16);

    return 'rgba(' + r + ', ' + g + ', ' + b + ', ' + opacity + ')';
  };

  this.getColorsCount = function () {
    return this.array.length - 1;
  };

  this.getColorHex = function (index) {
    return this.array[index];
  };

  this.getColorRGB = function (index) {
    return this.convertHexToRGB(this.array[index]);
  };

  this.getColorRGBA = function (index, opacity) {
    return this.convertHexToRGBA(this.array[index], opacity);
  };

  function checkCounter() {
    if (self.counter == self.array.length - 1) self.counter = 0;
  }
}

function defineResetInputLogic() {
  $('input[type=reset]').on('click', updateChosen);
}

/**
 * Returns string that is desired length long.
 * placeholder is appended to a start of string
 *
 * @param string
 * @param desiredLength
 * @param placeholder symbol to prepend to string. Default is "0"
 * @returns {string}
 */
function ensureLength(string, desiredLength, placeholder) {
  //assert string is a string;
  string += "";

  placeholder = placeholder || "0";
  
  while (string.length < desiredLength) {
    string = placeholder.concat(string);
  }

  return string;
}

function fixCheckBoxSendValue() {
  $('form').on('submit', function () {
    var $checkboxes = $(this).find('input[type="checkbox"]').filter('[data-return="1"]');

    if ($checkboxes.length > 0) {
      $.each($checkboxes, function (i, checkbox) {
        var $checkbox = $(checkbox);
        if (!$checkbox.prop('checked')) {

          var newCheckbox = document.createElement('input');
          newCheckbox.type = 'hidden';
          newCheckbox.name = $checkbox.attr('name');
          newCheckbox.value = 0;

          $checkbox.parent().append(newCheckbox);
        }
      });
    }

  });
}

function renewChosenValue($select, value) {
  var $options = $select.children('option');

  var $option = null;
  $.each($options, function (i, e) {
    if (e.value == value) {
      $option = e;
    }
  });

  if ($option) {
    $select.val(value);
    updateChosen();
  }
}

function updateChosen() {
  setTimeout(function () {
    $('select').trigger('chosen:updated');
  }, 100);

}

function defineCheckPatternLogic() {
  'use strict';
  var $patternedInputs = $('input[check_for_pattern]');
  
  $patternedInputs.on('input', function () {
    var $this = $(this);
    var value = this.value;
  
    var pattern = new RegExp($this.attr('check_for_pattern'));
  
    if (!pattern.test(value)) {
      $this.parents('.form-group').addClass('has-error');
    }
    else {
      $this.parents('.form-group').removeClass('has-error');
    }
  
  });
  
  function disableAllLinked(i, e) {
    
    function disableSingleLinked(i, e) {
      var $e = $(e);
      $e.prop('disabled', true);
    }
    
    function enableSingleLinked(i, e) {
      var $e = $(e);
      $e.prop('disabled', false);
    }
    
    var $this = $(e);
    var value = $this.val();
    var linked_Id = $this.attr('input-disables');
    var $linked;

    // if few IDs specified
    if (linked_Id.indexOf(',') != -1) {
      $linked = [];
      var ids = linked_Id.split(',');
      $.each(ids, function (i, id) {
        $linked.push($('#' + id));
      });

      if (
          ($this.is('input[type=checkbox]') && !($this.prop('checked')))
          ||
          (!$this.is('input[type=checkbox]') && ( value !== '' ))
      ) {
        $.each($linked, disableSingleLinked)
      }
      else {
        $.each($linked, enableSingleLinked);
      }
    } // If single input specified
    else {
      $linked = $('#' + linked_Id);
      if (
          ($this.is('input[type=checkbox]') && !($this.prop('checked')))
          ||
          (!$this.is('input[type=checkbox]') && ( value !== '' ))
      ) {
        disableSingleLinked(null, $linked);
      }
      else {
        enableSingleLinked(null, $linked);
      }
    }
  }
  
  var $linkedInputs = $('input[input-disables]');
  
  if ($linkedInputs.length > 0) {
    $.each($linkedInputs, function (i, e) {
      var $this = $(e);
    
      var event_name = 'input';
      
      if ($this.is('input[type="checkbox"]')) {
        event_name = 'change'
      }
      
      $this.on(event_name, function () {
        disableAllLinked(null, this);
      });
    
    
      disableAllLinked(null, e)
    });
  }
}

function defineIpInputLogic() {
  var $ipInputs = $('.ip-input');
  
  $ipInputs.attr('check_for_pattern', IPV4REGEXP);
  defineCheckPatternLogic();
}

function isValidIp(ip) {
  //RegExp test for valid ipv4 and ipv6
  var ipRegularExpression = new RegExp(IPV4REGEXP);
  return ipRegularExpression.test(ip);
}


function isValidIpv4(ip) {
  if (ip.indexOf('.') != -1) {
    var octets = ip.split('.');

    if (octets.length != 4) return false;

    var result = true;
    $.each(octets, function (index, octet) {
      if (octet < 0 && octet > 255) result = false;
    });
    return result;

  } else {
    return false;
  }
}

/** Log levels */
var LEVEL_INFO = 1;
var LEVEL_WARNING = 2;
var LEVEL_ERROR = 3;
var LEVEL_DEBUG = 4;

/** Global log_level treshold */
var LOG_LEVEL = LEVEL_INFO;

function _log(level, module, string) {
  var caller_name = '';
  if (level <= LOG_LEVEL) {
    if (arguments.callee.caller) {
      caller_name = arguments.callee.caller.name || 'anonymous';
    }
    console.log(caller_name + " : [ " + module + " ]" + ' : ' + JSON.stringify(string));
  }
}

/**
 *
 * @param $object
 * @param info
 * @param position one of: left, top, botom, right
 */
function renderTooltip($object, info, position) {

  if (typeof position === 'undefined') position = 'right';

  $object.attr('data-content', info);
  $object.attr('data-html', true);
  $object.attr('data-toggle', 'popover');
  $object.attr('data-trigger', 'hover');
  $object.attr('data-placement', position);
  $object.attr('data-container', 'body');
  $object.popover();

}

function defineTooltipLogic() {

  var $hasTooltip = $('[data-tooltip]');

  for (var i = 0; i < $hasTooltip.length; i++) {
    var $obj = $($hasTooltip[i]);
    console.log($obj);
    renderTooltip($obj, $obj.attr('data-tooltip'), $obj.attr('data-tooltip-position'));
  }

  return true;
}

// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
function debounce(func, wait, immediate) {
  var timeout;
  return function () {
    var context = this, args = arguments;
    var later = function () {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
}

// Allow callback to run at most 1 time per $limit ms
function throttle (callback, limit) {
  var wait = false;                  // Initially, we're not waiting
  return function () {               // We return a throttled function
    if (!wait) {                   // If we're not waiting
      callback.call();           // Execute users function
      wait = true;               // Prevent future invocations
      setTimeout(function () {   // After a period of time
        wait = false;          // And allow future invocations
      }, limit);
    }
  }
}

function defineStickyNavsLogic() {
  var $sticky = $('.sticky');
  var $body =  $('body');
  var $page = $('#page-content-wrapper');

  var bodyColor = $body.css('background-color');

  if (bodyColor === 'rgba(0, 0, 0, 0)' || bodyColor === 'rgb(255, 255, 255)') {
    bodyColor = 'white';
  }

  var mainPanel = $('nav.navbar.navbar-inverse.navbar-fixed-top');
  var mainPanelHeight = mainPanel.height();

  var pageWidth = $page.width();
  $body.on('resize', function(){
    'use strict';
    pageWidth = $page.width();
  });

  function stick($element, offsetTop) {
  
    if (!$element.hasClass('fixed') && window.screen.availHeight > 10 * offsetTop) {
      $element.addClass("fixed text-center");
      var backCol = $element.css('background-color');
      $element.data('old-background', $element.css('background-color'));

      if (backCol === 'rgba(0, 0, 0, 0)' || backCol === 'transparent') {
        backCol = bodyColor;
      }

      $element.css({
        position: 'fixed',
        top: mainPanelHeight + offsetTop,
        'background-color': backCol,
        'z-index': 200,
        border: '1px solid silver',
        width: pageWidth
        //'margin-left' : 'auto',
        //'margin-right' : 'auto'
      });
    }
  }

  function unStick($element) {
    if ($element.hasClass('fixed')) {
      $element.removeClass("fixed");
      $element.css(
        {
          position: 'relative',
          top: '',
          'background-color': $element.data('old-background'),
          'z-index': 100,
          'border': '',
          width: ''
        }
      );
    }
  }


  function checkToStick($element, position, offsetTop) {
    var wrapper = $(document);

    wrapper.on('scroll', function(event) {

      var pageYOffset = window.pageYOffset;

      if (pageYOffset == 0) {
        unStick($element);
      }
      else {

        throttle(function () {
          var shouldBeSticked = (pageYOffset != 0)
              && (pageYOffset + offsetTop + mainPanelHeight + $element.outerHeight() > position);

          shouldBeSticked ? stick($element, offsetTop) : unStick($element);
        }, 100)();

      }

    });

    return $element.outerHeight();
  }

  var sum = 0;
  $.each($sticky, function (i, element) {
    var $element = $(element);
    //here checkToStick() returns height of $element, so every next element knows its relative position
    sum += checkToStick($element, $element.offset().top, sum);
  });
}

function defineTreeMenuLogic() {

  var $trees = $('.tree li:has(ul)');

  if ($trees.length == 0) return true;

  $trees.addClass('parent_li').find(' > span').attr('title', 'Collapse this branch');

  //expand first level
  $('.nav.nav-list.main').find('ul.tree').first().toggle();

  //expand next level on click
  $('label.tree-toggler').on('click', function () {
    toggleBranch(this)
  });

  function toggleBranch(context) {
    $(context).parent().children('ul.tree').toggle(300);
  }

}

function defineNavbarFormLogic(){
  'use strict';
  var $navbarForms = $('form.navbar-form:not(.no-live-select)');
  $.each($navbarForms, function(i, form){
    var $form = $(form);

    $.each($form.find('select'), function (j, select){
      $(select).on('change', function(){
        $form.submit();
      });
    });

  });
}

function defineAutoSubmitSelect(){
  var $autoSubmitted = $('select[data-auto-submit]');
  
  if ($autoSubmitted.length > 0){
    $autoSubmitted.on('change', function(){
      var $this = $(this);
      var params = $this.attr('data-auto-submit');
      
      if (params === 'form'){
        $this.closest('form').submit();
        return true;
      }
      else {
        var name = $this.attr('name');
        var value = $this.val();
        location.replace('?'+ params + '&' + name + '=' + value);
      }
    })
  }
  
}

//document ready
$(function () {

  // Main comment modal initialization
  defineCommentModalLogic();

  // Because of Chosen.js we need custom logic for resetting form
  defineResetInputLogic();

  // Checking ip-inputs for IPV4 regexp
  defineIpInputLogic();

  // Checking inputs for defined regexpressions
  defineCheckPatternLogic();

  // Sticky panels that are fixed on top
  defineStickyNavsLogic();

  // Recursive HTML trees
  defineTreeMenuLogic();

  // Find and initialize all tooltips
  defineTooltipLogic();

  // Auto sending navbar form
  defineNavbarFormLogic();

  // Returning 0 for unchecked chekboxes
  fixCheckBoxSendValue();
  
  //Make autosubmittable selects work
  defineAutoSubmitSelect();

});
