<form name='PAYSYS_GROUP_SETTINGS' id='form_PAYSYS_GROUP_SETTINGS' method='post'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='SYSTEM_ID' id='SYSTEM_ID' value='%SYSTEM_ID%'>
  <input type='hidden' name='MERCHANT_ID' id='MERCHANT_ID' value='%MERCHANT_ID%'>
  <input type='hidden' name='PAYSYSTEM_ID' id='PAYSYSTEM_ID' value='%PAYSYSTEM_ID%'>

  <div class='card big-box card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ADD}_ _{_MERCHANT}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group %HIDE_SELECT%'>
        <label class=' col-md-12 col-sm-12'>_{PAY_SYSTEM}_</label>
        <div class='col-md-12 col-sm-12'>
          %PAYSYS_SELECT%
        </div>
      </div>

      <div id='paysys_connect_system_body'>
        <div class='form-group' id='ACCOUNT_KEYS_SELECT'>
          <label class=' col-md-12 col-sm-12' id='KEY_NAME'></label>
          <div class='col-md-12 col-sm-12'>
            %ACCOUNT_KEYS_SELECT%
          </div>
        </div>
      </div>

      <div id='paysys_connect_system_body'>
        <div class='form-group' id='PAYMENT_METHOD_SELECT'>
          <label class=' col-md-12 col-sm-12' id='PAYMENT_METHOD_LABEL'></label>
          <div class='col-md-12 col-sm-12'>
            %PAYMENT_METHOD_SELECT%
          </div>
        </div>
      </div>

      <div class='form-group %HIDE_DOMAIN_SEL%'>
        <label class=' col-md-12 col-sm-12'>_{DOMAIN}_</label>
        <div class='col-md-12 col-sm-12'>
          %DOMAIN_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class=' col-sm-12 col-md-12' for='MERCHANT_NAME'>_{MERCHANT_NAME2}_:</label>
        <div class='col-sm-12 col-md-12'>
          <input type='text' class='form-control' id='MERCHANT_NAME' name='MERCHANT_NAME' value='%MERCHANT_NAME%'
                 required>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='%BTN_NAME%' value='%BTN_VALUE%' id='BTN_ADD'>
    </div>
  </div>
</form>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
    var acc_keys = JSON.parse('%ACCOUNT_KEYS%');
  } catch (err) {
    console.log('JSON parse error.');
  }

  var KEY_NAME = '';
  var SHOW_SELECT = 0;

  var defaultSelectedValue = jQuery('#MODULE').serialize();
  jQuery('#ACCOUNT_KEYS_SELECT').hide();
  jQuery('#PAYMENT_METHOD_SELECT').hide();

  acc_keys.map(acc_key => {
    jQuery('#KEYS').append(new Option(acc_key, acc_key))
  });

  function rebuild_form(type) {
    jQuery('.appended_field').remove();
    let keys = Object.keys(arr[type]['CONF']) || {};
    let sorted = keys.sort();
    let systemID = arr[type]['SYSTEM_ID'] || 0;
    let checkBoxes = arr[type]['CHECKBOX_FIELDS'] || [];
    let selectFields = arr[type]['SELECT_FIELDS'] || {};
    let splitRules = arr[type]['SPLIT_RULES'] || ['MERCHANT_ID','PERCENT'];
    jQuery('#SYSTEM_ID').attr('value', systemID);

    jQuery('#ACCOUNT_KEYS_SELECT').show();
    jQuery('#PAYMENT_METHOD_SELECT').show();

    for (let i = 0; i < sorted.length; i++) {
      let val = arr[type]['CONF'][sorted[i]];
      let param = sorted[i];
      param = param.replace(/(_NAME_)/, '_' + type.toUpperCase() + '_');

      if (param.includes('ACCOUNT_KEY')) {
        SHOW_SELECT = 1;
        KEY_NAME = param;
        jQuery('#KEY_NAME').text(param);
        if (val) {
          jQuery('#KEYS').val(val).change();
        } else {
          jQuery('#KEYS').val('UID').change();
        }
      } else if (param.includes('PAYMENT_METHOD')) {
        jQuery('#PAYMENT_METHOD_LABEL').empty();
        jQuery('#PAYMENT_METHOD_LABEL').append(param);
        jQuery('#PAYMENT_METHOD').attr('name', param);
        if (val) {
          jQuery('#PAYMENT_METHOD').val(val).change();
        } else {
          jQuery('#PAYMENT_METHOD').val(' ').change();
        }
      } else if (param.includes('SPLIT_RULES')) {
        const merchant_rules = (val || '').split(';').map(item => {
          const values = item.split(':');
          return Object.fromEntries(splitRules.map((rule, index) => [rule, Number(values[index] || 0)]));
        });

        let formContainer = jQuery('#paysys_connect_system_body');

        let hiddenInput = jQuery('<input>').attr({
          type: 'hidden',
          name: param,
          id: param
        });
        formContainer.append(hiddenInput);

        let label = jQuery("<label for=''></label>").text(param).addClass('col-md-12 col-sm-12');
        formContainer.append(label);

        let addButton = jQuery('<div></div>').addClass('text-right');
        // need to separate elements because is adding a div around the button and the span and Boostrap dies
        let button = jQuery("<button type='button'></button>").addClass('btn btn-sm btn-success mb-3');
        button.append(jQuery('<span></span>').addClass('fa fa-plus'));
        addButton.append(button);

        let splitRulesLocales = {
          MERCHANT_ID: 'ID _{_MERCHANT}_',
          PERCENT: '_{PERCENT}_',
        }

        sendRequest(`/api.cgi/paysys/merchants?paysysId=${arr[type]['ID']}&LIST2HASH=id,merchant_name`, {}, 'GET')
          .then(merchants => {
            function addFieldPair(obj = {}) {
              let container = jQuery('<div></div>').addClass('field-pair');

              splitRules.forEach(key => {
                if (key.includes('MERCHANT_ID')) {
                  let element = jQuery('<div></div>').addClass('form-group appended_field');
                  element.append(jQuery('<label></label>').text(splitRulesLocales[key]).addClass('col-md-12 col-sm-12 text-muted'));
                  let selectList = jQuery('<select></select>', {id: obj[key], name: key, class: 'split-rules'});
                  let inputGroup = jQuery('<div></div>', {class: 'input-group-append select2-append'}).append(selectList);
                  let selectDiv = jQuery('<div></div>', {class: 'select'}).append(inputGroup);
                  let flexFill = jQuery('<div></div>', {class: 'flex-fill bd-highlight overflow-hidden select2-border'})
                    .append(selectDiv);
                  let dFlex = jQuery('<div></div>', {class: 'col-md-12 col-sm-12'}).append(flexFill);
                  element.append(dFlex);

                  selectList.append(jQuery(`<option></option>`, {value: '', text: ''}));
                  Object.entries(merchants).forEach(([id, name]) => {
                    selectList.append(jQuery(`<option></option>`, {
                      id: `${id}_${obj[key]}`,
                      text: name,
                      value: id,
                      ...((id == obj[key]) ? { selected: "" } : {})
                    }));
                  })

                  selectList.select2({width: '100%', allowClear: true, placeholder: ''});

                  container.append(element);
                }
                else {
                  let element = jQuery('<div></div>').addClass('form-group appended_field');
                  element.append(jQuery('<label></label>').text(splitRulesLocales[key]).addClass('col-md-12 col-sm-12 text-muted'));
                  element.append(jQuery('<div></div>').addClass('col-md-12 col-sm-12').append(
                    jQuery("<input>").attr({
                      name: key,
                      value: obj[key] || '',
                      type: 'text'
                    }).addClass('form-control split-rules')
                  ));
                  container.append(element);
                }
              });

              formContainer.append(container);
              formContainer.append('<hr>');

              formContainer.append(addButton);
              updateHiddenInput();
            }

            merchant_rules.forEach(obj => addFieldPair(obj));

            addButton.click(function () {
              addFieldPair();
            });

            formContainer.append(addButton);

            function serializeInputs() {
              let values = [];
              let totalPercent = 0;

              formContainer.find('input[name="PERCENT"]').removeClass('is-invalid');
              formContainer.find('.percent-error').remove();

              formContainer.find('.field-pair').each(function () {
                let pairValues = [];
                splitRules.forEach(key => {
                  let inputValue = jQuery(this).find(`[name="${key}"]`).val() || 0;
                  pairValues.push(inputValue);

                  if (key === 'PERCENT') {
                    totalPercent += parseFloat(inputValue) || 0;
                  }
                });
                values.push(pairValues.join(':'));
              });

              if (totalPercent > 100) {
                makeNegativePercent();
              }

              return values.join(';');
            }

            function updateHiddenInput() {
              let serializedValue = serializeInputs();
              hiddenInput.val(serializedValue);
            }

            formContainer.on('input', 'input.split-rules', updateHiddenInput);
            formContainer.on('change', 'select.split-rules', updateHiddenInput);

            jQuery('form').on('submit', function (e) {
              let totalPercent = 0;

              formContainer.find('input[name="PERCENT"]').each(function () {
                totalPercent += parseFloat(jQuery(this).val()) || 0;
              });

              if (totalPercent !== 100 && totalPercent !== 0) {
                e.preventDefault();
                makeNegativePercent();
              }
            });

            function makeNegativePercent() {
              formContainer.find('input[name="PERCENT"]').addClass('is-invalid');

              if (formContainer.find('.percent-error').length === 0) {
                let errorMessage = jQuery('<div></div>')
                  .addClass('percent-error text-danger mt-2')
                  .text('_{ERR_PERCENT_VALUE}_');

                formContainer.find('.field-pair').last().after(errorMessage);
              }
            }
          });
      } else if (selectFields[param]) {
        let element = jQuery('<div></div>').addClass('form-group appended_field');
        element.append(jQuery("<label for='" + (param || '') + "'></label>").text(param).addClass('col-md-12 col-sm-12'));

        let selectList = jQuery('<select></select>', {id: param, name: param});
        let inputGroup = jQuery('<div></div>', {class: 'input-group-append select2-append'}).append(selectList);
        let selectDiv = jQuery('<div></div>', {class: 'select'}).append(inputGroup);
        let flexFill = jQuery('<div></div>', {class: 'flex-fill bd-highlight overflow-hidden select2-border'})
          .append(selectDiv);
        let dFlex = jQuery('<div></div>', {class: 'col-md-12 col-sm-12'}).append(flexFill);
        element.append(dFlex);

        selectList.append(jQuery(`<option></option>`, {value: '', text: ''}));
        jQuery.each(selectFields[param], (idx, value) => {
          selectList.append(jQuery(`<option></option>`, {
            value,
            text: value,
            ...((val === value) ? { selected: "" } : {})
          }));
        })

        selectList.select2({width: '100%', allowClear: true, placeholder: ''});

        jQuery('#paysys_connect_system_body').append(element);
      } else if (checkBoxes.includes(param)) {
        const checked = (val === '1') ? 'checked' : '';
        let element = jQuery('<div></div>').addClass('form-group appended_field');
        element.append(jQuery("<label for=''></label>").text(param).addClass('col-md-12 col-sm-12'));
        element.append(jQuery("<div style='display: flex; justify-content: center;'></div>").addClass('col-md-12 col-sm-12').append(
          jQuery(`<input ${checked} style='height: 20px; width:20px' type='checkbox' name='${param || ""}' id='${param || ""}' value='1' data-return='1' data-checked='1'>`)));

        jQuery('#paysys_connect_system_body').append(element);
      } else {
        let element = jQuery('<div></div>').addClass('form-group appended_field');
        element.append(jQuery("<label for='" + (param || '') + "'></label>").text(param).addClass('col-md-12 col-sm-12'));
        element.append(jQuery("<div></div>").addClass('col-md-12 col-sm-12').append(
          jQuery("<input name='" + (param || '') + "' id='" + (param || '') + "' value='" + (val || '') + "'>").addClass('form-control')));

        jQuery('#paysys_connect_system_body').append(element);
      }

      if (i + 1 === sorted.length && SHOW_SELECT === 0) {
        jQuery('#ACCOUNT_KEYS_SELECT').hide();
      } else if (i + 1 === sorted.length && SHOW_SELECT === 1) {
        SHOW_SELECT = 0;
      }
    }

    // generateTooltips(type);
  }

  jQuery('#BTN_ADD').on('click', () => {
    if (!(jQuery('#' + KEY_NAME).length) && jQuery('#ACCOUNT_KEYS_SELECT:visible').length !== 0) {
      let element = jQuery('<div></div>').addClass('form-group appended_field hidden');
      element.append(jQuery("<label for=''></label>").text(KEY_NAME).addClass('col-md-12 col-sm-12'));
      element.append(jQuery("<div></div>").addClass('col-md-12 col-sm-12').append(
        jQuery("<input name='" + KEY_NAME + "' id='selected_value' value='" + (jQuery('#KEYS').find(':selected').text() || '') + "'>").addClass('form-control')));

      jQuery('#paysys_connect_system_body').append(element);
    } else if (jQuery('#ACCOUNT_KEYS_SELECT:visible').length === 0) {
      jQuery('#selected_value').remove();
    }
  });

  jQuery(() => {
    if (jQuery('#MODULE').val()) {
      rebuild_form(jQuery('#MODULE').val());
    }

    jQuery('#MODULE').on('change', () => {
      rebuild_form(jQuery('#MODULE').val());
    });
  });

  var PORTAL_COMMENT_DESC = '_{PORTAL_COMMENT_DESC}_';
  var PORTAL_COMMISSION_DESC = '_{PORTAL_COMMISSION_DESC}_';

  function generateTooltips (type) {
    const docsUrl = arr[type]['DOCS'] || '';
    let url = '';

    const urlType = /pageId/.test(docsUrl);
    const match = docsUrl.match(/[a-zA-Z0-9_\\-\\+]+\$/);
    if (match.length < 1) return 1;

    if (urlType) {
      url = `http://abills.net.ua/wiki/rest/api/content/${match}?expand=body.storage`
    } else {
      url = `http://abills.net.ua/wiki/rest/api/content/search?cql=space=AB AND title=${match}&expand=body.storage`;
    }

    fetch(url)
      .then(async response => {
        if (!response.ok) throw response;

        const content = await response.json();
        const body = urlType ? content?.body?.storage?.value : content?.results[0]?.body?.storage?.value;

        const tooltipsInfo = body.match(/(?<=<td[^>]*>)(.*?)(?=<\/td)/gm);

        if (tooltipsInfo.length < 1) return 1;

        tooltipsInfo.map((val, index) => {
          if (val.includes('PAYSYS_')) {
            const value = val.replace(/<[^>]*>/gm, '');
            const tooltipValue = tooltipsInfo[index + 1].replace(/<[^>]*>/gm, '');
            jQuery(`input[name*=${value}]`).attr('title', tooltipValue)
              .hover(() => {
                jQuery().tooltip()
              });
          }
        });
      })
      .catch(e => console.warn(e));

    jQuery("input[name*='PORTAL_DESCRIPTION']").attr('title', PORTAL_COMMENT_DESC)
      .hover(() => {
        jQuery().tooltip()
      });

    jQuery("input[name*='PORTAL_COMMISSION']").attr('title', PORTAL_COMMISSION_DESC)
      .hover(() => {
        jQuery().tooltip()
      });
  }
</script>
