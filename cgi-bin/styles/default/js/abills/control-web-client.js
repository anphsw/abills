
/*
  Control-web for Client side
  Purpose of this code for ABillS:
    1 Increasing and decreasing number of buttons in table header by resize and not
*/

var mybody = document.body;

const dropdownTemplate = jQuery(
  `<div class="btn-group" style="display: none;">
      <button class="btn btn-default btn-xs dropdown-toggle" aria-expanded="false" data-toggle="dropdown">
        <span class="caret"></span>
      </button>
      <div class="dropdown-menu dropdown-menu-right"></div>
   </div>`
  );

let abillsBtnGroup = document?.getElementById('abillsBtnGroup');
let abillsDropdownGroup = (function () {
                            const element = abillsBtnGroup?.children[abillsBtnGroup?.children?.length - 1];
                            if(element?.classList[0] === 'btn-group') {
                              return jQuery(element);
                            } else {
                              return jQuery(abillsBtnGroup)
                                        .append(dropdownTemplate)
                                        .children("div:last-child");
                            }
                          })();

let abillsDropdownToggle = abillsDropdownGroup?.children()[0];
let abillsDropdown = abillsDropdownGroup?.children()[1];

var myflag = 2;

/* 1 */
function calculateBtnGroup() {
  /* cf width for typical btn, maybe calculate dynamically by content, but so hard */
  const calculatedButtonWidth = 160;

  const parentWidth = abillsBtnGroup.parentElement.clientWidth;
  const maybeWidth = (abillsBtnGroup.children.length - 1) * calculatedButtonWidth;

  /* inserting items to dropdown list from btn-group */
  if (parentWidth < maybeWidth) {
    let needToAdd = parseInt((maybeWidth - parentWidth) / calculatedButtonWidth);

    if (needToAdd != 0) {
      [...abillsBtnGroup.children].reverse().forEach(element => {
        if (element.classList[0] != 'btn-group') {
          if (needToAdd) {
            --needToAdd;
            if (element.classList.contains('active')) {
              element.className = 'dropdown-item active';
            } else {
              element.className = 'dropdown-item';
            }

            abillsDropdown.prepend(element);
          }
        }
      });
      if (abillsDropdown.children.length) {
        abillsDropdownGroup.show();
      }
    }
  }  /* inserting items to btn-group from dropdown list */
  else if (parentWidth > maybeWidth) {
    let needToAdd = parseInt((parentWidth - maybeWidth) / calculatedButtonWidth);

    if (needToAdd != 0) {
      [...abillsDropdown.children].forEach(element => {
        if (needToAdd) {
          --needToAdd;
          if(element.classList.contains('active')) {
            element.className = 'btn btn-default btn-xs active';
          } else {
            element.className = 'btn btn-default btn-xs';
          }
          abillsDropdownGroup.before(element);
        }
      });
      const itemsLength = abillsDropdown.children.length;
      if (needToAdd >= itemsLength) {
        abillsDropdownGroup.hide();
      }
    }
  }

  if (myflag) {
    --myflag;
    calculateBtnGroup();
  }
}

if (abillsBtnGroup) {
  calculateBtnGroup();
  window.addEventListener('resize', calculateBtnGroup, false);
}
