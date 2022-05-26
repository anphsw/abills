
/*
  Purpose of this code for ABillS:
    1 Increasing and decreasing number of buttons in table header by resize and not
    2 Closing right sidebar if user clicked in overlay
*/

var mybody = document.body;

let rightSidebarButton = document.getElementById('right_menu_btn');
let rightSidebar = document.getElementsByClassName('control-sidebar')[0];

let abillsBtnGroup = document?.getElementById('abillsBtnGroup');
let abillsDropdown = abillsBtnGroup?.children[7];
let abillsDropdownToggle = abillsBtnGroup?.children[6];

var myflag = 2;

/* 1 */
function calculateBtnGroup() {
  let chCf = 142; /* cf width for typical btn, maybe calculate dynamically by content, but so hard */

  let parentWidth = abillsBtnGroup.parentElement.clientWidth;
  let maybeWidth = (abillsBtnGroup.children.length - 1) * chCf;

  /* inserting items to dropdown list from btn-group */
  if (parentWidth < maybeWidth) {
    let needToAdd = parseInt((maybeWidth - parentWidth) / chCf);

    if(needToAdd != 0) {
      [...abillsBtnGroup.children].reverse().forEach(element => {
        if(element.classList[0] != 'dropdown-menu') {
          if(element.classList[3] != 'dropdown-toggle') {
            if(needToAdd) {
              --needToAdd;
              if(element.classList.contains('active')) {
                element.className = 'dropdown-item active';
              } else {
                element.className = 'dropdown-item';
              }
              abillsDropdown.insertAdjacentElement('afterBegin', element);
            }
          }
        }
      });
    }
  }  /* inserting items to btn-group from dropdown list */
  else if (parentWidth > maybeWidth) {
    let needToAdd = parseInt((parentWidth - maybeWidth) / chCf);

    if (needToAdd != 0) {
      [...abillsDropdown.children].forEach(element => {
        if(needToAdd) {
          --needToAdd;
          if(element.classList.contains('active')) {
            element.className = 'btn btn-default btn-xs active';
          } else {
            element.className = 'btn btn-default btn-xs';
          }
          abillsDropdownToggle.insertAdjacentElement('beforeBegin', element);
        }
      });

    }
  }

  if (!abillsDropdown.children.length) {
    abillsDropdownToggle.style.cssText = 'display: none;';
  } else {
    abillsDropdownToggle.style.cssText = 'display: inline-block;';
  }

  if (myflag) {
    --myflag;
    calculateBtnGroup();
  }
}

window.addEventListener('resize', controlRightMenu, false);
if(abillsBtnGroup) {
  if(abillsDropdown?.classList.contains('dropdown-menu')) {
    calculateBtnGroup();
    window.addEventListener('resize', calculateBtnGroup, false);
    rightSidebar.addEventListener('transitionend', calculateBtnGroup, false);
  }
}


/* 2 */
jQuery(() => {
  jQuery('#sidebar-overlay').on('click', () => {
    jQuery('body').removeClass('control-sidebar-slide-open')
  })
})
