/**
 * Created by Anykey on 17.08.2015.
 */

var MENU_AUTO_HIDDEN_WIDTH = 992;
var menuHidden = (Cookies.get('menuHidden') !== 'false');
//console.log('menuhidden: ' + menuHidden);
/* Nav bar */
function toggleNavBar() {
    $('#wrapper').toggleClass('toggled');
    Cookies.set('menuHidden', !menuHidden);
    menuHidden = !menuHidden;
}

function showhideMenu (){
    if ( $(window).width() >= MENU_AUTO_HIDDEN_WIDTH && !menuHidden) {
      $('#wrapper').addClass('toggled');
    }
    else if ($(window).width() < MENU_AUTO_HIDDEN_WIDTH && menuHidden){
      $('#wrapper').addClass('toggled');
    }
}
function hideshowMenu (){
    if ($(window).width() < MENU_AUTO_HIDDEN_WIDTH && menuHidden && $('#wrapper').is('.toggled') ){
      $('#wrapper').toggleClass('toggled');
      Cookies.set('menuHidden', !menuHidden);
      menuHidden = !menuHidden;
    }
    else if ($(window).width() < MENU_AUTO_HIDDEN_WIDTH && menuHidden && !$('#wrapper').is('.toggled') ) {
        Cookies.set('menuHidden', !menuHidden);
        menuHidden = !menuHidden;
    }
}

