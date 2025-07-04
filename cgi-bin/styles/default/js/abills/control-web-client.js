
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

/* 5 */
function resultFormerFillCheckboxes() {
  var $ = jQuery;
  const checkboxParents = $('.abills-checkbox-parent');
  checkboxParents.children('input[type=checkbox][checked=checked]').parent().addClass('active');
  checkboxParents.click(function(event) {
    const _this = $(this);
    if (event.target.type !== 'checkbox') {
      const myCheckbox = _this.find('input[type=checkbox]');
      myCheckbox.click();
      const isChecked = myCheckbox.prop("checked");
      if(isChecked) {
        _this.addClass('active');
      } else {
        _this.removeClass('active');
      }
    }
  });

  const checkboxSelectAll = $('.abills-checkbox-select-all');

  checkboxSelectAll.each(function () {
    const selectAll = $(this);
    const groupContainer = selectAll.closest('.checkbox-group-container');
    const childCheckboxes = groupContainer.find('.abills-checkbox-parent input[type="checkbox"]');

    const allChecked = childCheckboxes.length > 0 && childCheckboxes.filter(':checked').length === childCheckboxes.length;
    selectAll.prop('checked', allChecked);
  });

  checkboxSelectAll.on('click', function () {
    const isChecked = $(this).prop('checked');

    const childCheckboxes = $(this)
      .closest('.checkbox-group-container')
      .find('.abills-checkbox-parent input[type="checkbox"]');

    childCheckboxes.prop('checked', isChecked);
  });
}

/* 6 */
function resultFormerCheckboxSearch() {
  var $ = jQuery;
  const checkboxParents = $('.abills-checkbox-parent');

  $('#resultFormSearch').on('input', function () {
    const searchValue = this.value.toLowerCase();
    if (searchValue) {
      checkboxParents.css('display', 'none');
      checkboxParents.filter(function () {
        return this.textContent.toLowerCase().includes(searchValue)
      }).css('display', 'block');
    } else {
      checkboxParents.removeAttr('style');
    }
  });

  $('.extra-fields-btn').on('click', function() {
    jQuery(this).toggleClass(['btn-primary', 'btn-outline-primary']);
    let extraFieldsBlockId = jQuery(this).data('id');
    jQuery(`#${extraFieldsBlockId}`).toggle('d-none');
  })
}

resultFormerFillCheckboxes();
resultFormerCheckboxSearch();