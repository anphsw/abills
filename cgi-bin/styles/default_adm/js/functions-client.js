/**
 * Created by Anykey on 20.08.2015.
 *
 * Functions that are used in Uportal v5
 */

/**
 * Login logic
 */

var CLIENT_INTERFACE = 1;

/**
 * Set's predefined icons for menu items
 *
 * Just add new id and glyphicon to decorate new menu element
 */
function setIcons() {
  var $arr = [
    [$('#form_info'), 'glyphicon glyphicon-user'],
    [$('#form_payments'), 'glyphicon glyphicon-euro'],
    [$('#form_finance'), 'glyphicon glyphicon-euro'],
    [$('#dv_user_info'), 'glyphicon glyphicon-globe'],
    [$('#docs_invoices_list'), 'glyphicon glyphicon-briefcase'],
    [$('#msgs_user'), 'glyphicon glyphicon-comment'],
    [$('#cards_user_payment'), 'glyphicon glyphicon-credit-card'],
    [$('#logout'), 'glyphicon glyphicon-log-out'],
    [$('#voip_user_info'), 'glyphicon glyphicon-earphone'],
    [$('#ureports_user_info'), 'glyphicon glyphicon-file'],
    [$('#iptv_user_info'), 'glyphicon glyphicon-sound-dolby'],
    [$('#abon_client'), 'glyphicon glyphicon-list'],
    [$('#form_passwd'), 'glyphicon glyphicon-lock'],
    [$('#ipn_user_activate'), 'glyphicon glyphicon-road'],
    [$('#bonus_service_discount_client'), 'glyphicon glyphicon-tower'],
    [$('#bonus_user'), 'glyphicon glyphicon-tower'],
    [$('#mail_users_list'), 'glyphicon glyphicon-envelope'],
    [$('#poll_user'), 'glyphicon glyphicon-stats'],
    [$('#megogo_user_interface'), 'fa fa-maxcdn'],
    [$('#o_user'), 'glyphicon glyphicon-book'],
    [$('#sharing_user_main'), 'fa fa-share']
  ];

  $arr.forEach(function (entry) {
    insertIcon(entry[0], entry[1]);
  });
}

function set_referrer() {
  document.getElementById('REFERRER').value = location.href;
}

function showLoading() {
  var shadow = document.getElementById('shadow');
  var loading = document.getElementById('load');
  shadow.style.display = 'block';
  loading.style.display = 'block';
}
/**
 * AJAX loading of page content
 * @param url
 * @param obj
 */
function showContent(url, obj) {
  var path = url.split("?")[1];
  var fullURL = SELF_URL + '?' + path + '&prevent_get_request_caching=' + new Date().getMilliseconds();

  if (obj) {

    showList(obj);
    checkForInnerList(obj);

    //Because of maps and charts scripts, this page can't be served more than one time
    if ($(obj).attr('id') === 'paysys_payment' || $(obj).attr('id') === 'o_user'){
      console.log(url);
      var params = url.match("qindex\=([0-9]*)\&.*sid\=(.*)");
      var index = params[1];
      var sid = params[2];

      url = "index.cgi?index=" + index + "&sid=" + sid;

      location.replace(url);

      return true;
    }

  }

  var $page = $('#page-content-wrapper');

  // TODO: Check why I used query on jObject
  $($page).fadeOut(200);

  $page.load(fullURL, function () {
    $($page).fadeIn(200);
    decorateTables();
    defineCommentModalLogic();
    f_tcalInit();
  }, 'text/html');
}

/**
 * Opening parent ierarchy of menu ul li elements
 * @param a
 */
function showList(a) {
  var $sidebar = $('#sidebar-wrapper');
  //close all
  $sidebar.find('ul').css('display', 'none');
  //deactivate current active
  $sidebar.find('.active').removeClass('active');

  //get li element
  var $elem = $(a).parent();
  //setActive
  $($elem).parents('.mainSubmenu').prev('li').addClass('active');
  $($elem).addClass('active');

  openParents($elem);

  setCookie('last_opened', findMainLiId($elem));

  function openParents($elem) {
    var $parent = $($elem).parent();
    if ($parent.is('ul')) {
      $parent.css('display', 'block');
      openParents($parent);
    }
  }

  //open child dropdown list
  var $childs = $($elem).next('ul');
  if ($childs.length > 0)
    $.each($childs, function (i, entry) {
      $(entry).css('display', 'block');
    })
}

/**
 * Returns id of first level menu li element
 * @param $elem
 * @returns {*}
 */
function findMainLiId($elem) {
  var parentLi = $($elem.parents('.mainSubmenu').prev('li'));
  if (parentLi.length == 0)
    return $elem.find('a').attr('id');
  else
    return parentLi.find('a').attr('id');
}


function checkForInnerList(listItem){

  var $item = $(listItem).parent();
  var shouldBeOpened = $('#wrapper').is('.toggled') && $item.next().is('ul');

  if (shouldBeOpened){
    toggleNavBar();
  }

}
/**
 * Inserts glyphicon for menu item
 * @param $li_element
 * @param icon
 */
function insertIcon($li_element, icon) {
  //$($li_element).removeAttr('href');

  var text = $li_element.text();
  $li_element.html('<i class="' + icon + '"></i><span>' + text + '</span>');
  $li_element.attr('iconed', true);
}



/**
 * Reads value at key 'last_opened' in local storage and if defined, highlights defined li item in main menu
 * Cookie is 1 day alive
 */
function openLastActive() {
  var last = getCookie('last_opened', '');
  $('#' + last).parent('li').addClass('active');
}

/**
 * Set's icon for a main li elements that are not defined if setIcons() inner array
 * @param $arr
 */
function operateNotDefined($arr) {
  $.each($arr, function (index, entry) {
    insertIcon($(entry), 'glyphicon glyphicon-chevron-right');
  });
}

/**
 * Makes a bootstrapped <div class="table"> tables look like striped
 */
function stripeTablePanels() {
  //Make striped rows
  var $obj = $('div.table .row');
  var color = $('.well').css('background-color');

  for (var i = 0; i <= $obj.length; i += 2) {
    $($obj[i]).css('background-color', color);
  }
}

/**
 * For user cabinet v4 templates, where using tables this script makes next:
 *   * adds classes 'table' 'table striped'
 *   * wraps tables in "< div class='panel panel-default'> < /div>"
 * @param $table
 */
function decorateTable($table) {
  $($table).addClass('table table-striped');
  wrap($($table), 'panel panel-default');
  $($table).parent().css('margin-bottom', '0');
}

/**
 * For v4 templates (tabled).
 * Find all .table inside .panel.
 * For each found element, if its not < table> remove padding, else remove vertical padding.
 */
function decoratePanelTable() {
  var $elem = $('.panel').find('.table');

  if ($elem.length)
    $.each($elem, function (i, entry) {
      //switch ($elem.is('table')) {
      //    case true:
      //        //$(entry).parent().css('padding', '0');
      //        break;
      //    default :
      $(entry).parent().css('padding-top', '0');
      $(entry).parent().css('padding-bottom', '0');
      //        break;
      //}
    });
  $elem.parent().css('margin-bottom', '0');
}


/**
 * Main function to decorate Tables and Panels
 */
function decorateTables() {
  decoratePanelTable();
  stripeTablePanels();
}

function decorateMenu() {

  var $menu = $('#sidebar-wrapper');

  if ($menu && !$menu.attr('decorated') === true) {

    $menu.find('>ul>li').next('ul').addClass('mainSubmenu');

    var leftcolor = $('#primary').css('background-color');
    $($menu).find('>ul>li').attr('style', 'border-left: 10px solid ' + leftcolor);


    //Icon second level menu
    var $inner = $menu.find('>ul>ul>li>a');
    $.each($inner, function (i, entry) {
      insertIcon($(entry), 'glyphicon glyphicon-chevron-right');
    });

    //set Icons for first level menu
    setIcons();

    //icon items without predefined icon
    var $arr = $menu.find('>ul>li>a').not('[iconed=true]');

    //operateNotDefined($arr);

    setLogoutLogic();

    $menu.attr('decorated', true);

    openLastActive();
  }

}


function setLogoutLogic() {
  var $logout = $('#logout');
  if ($logout.length > 0) {
    $($logout).removeAttr('onclick');

    $logout.on('click', function () {
      logout();
    });
  }
}

function logout() {
  window.location.replace(SELF_URL + '?index=1000');
}
//
///**
// * Message user/admin replies decorating
// */
//function decorateMessages() {
//  $('.panel.even').addClass('panel-info');
//  $('.panel.odd').addClass('panel-success');
//}

function addDefaultTemplate() {
  $('#themes-list').find('ul').prepend('<li onclick="setDefaultTemplate()">Default</li>');
}


function setDefaultTemplate() {
  Cookies.remove('theme');
  window.location.reload();
}

function changeTheme(obj) {
  var path = $(obj).attr('data-path');
  setCookie('theme', path);
  window.location.reload();
}

function getTheme() {
  var path = getCookie('theme', '');
  if (path != '') {
    var stylesheet = '<link href=\'/' + path + '\' rel=\'stylesheet\'>';
    $('head').append(stylesheet);
  }

  if (path.indexOf('Material') != -1) {
    $(function () {
      var lis = $('#sidebar-wrapper').find('>ul>li');
      var elems = lis.find('a');

      //make top buttons white
      $('.menu-toggle>a').css({"color": "white"});

      //make menu text visible
      elems.css({"color": "white"});

      //make text black on hover
      elems.hover(function () {
          $(this).css({"color": "black"});
        }, function () {
          $(this).css({"color": "white"});
        }
      );

      //remove left color
      lis.css({"border-left": ""});


    });
  }
}


$(document).ready(function () {
  /**
   * Menu style and logic
   */
  decorateMenu();
  addDefaultTemplate();

  // fade on page loaded
  $('#page-content-wrapper').fadeIn(200);

  //make styled tables
  decorateTables();
});


