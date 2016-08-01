/**
 * Created by Anykey on 02.09.2015.
 */

/*Holds ctrl pressed*/
var ctrl = false;

var CTRL  = 17;
var ENTER = 13;

/**
 holds ctrl released
 */
function keyUp(e) {
  if (e.keyCode == CTRL)
    ctrl = false;
}

function keyDown(e) {
  switch (e.keyCode) {
    case CTRL:
      ctrl = true;
      break;
    
    case ENTER:
      if (ctrl) {
        clickButton('go');
      }
      else {
        clickButton('save');
        clickButton('search'); //modal-search
      }
  }
}

function clickButton(id) {
  var btn = document.getElementById(id);
  if (btn !== null) btn.click();
}


$(document).ready(function () {
  //set keyboard listener
  var $body = $('body');
  
  $body.on('keydown', function (event) {
    keyDown(event);
  });
  
  $body.on('keyup', function (event) {
    keyUp(event)
  });
});