<div class='form-group row' style='%EXT_SEL_STYLE%'>
  <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-DISTRICT'>%DISTRICT_LABEL%:</label>
  <div class='col-sm-9 col-md-8'>
    %DISTRICT_SEL%
  </div>
</div>

%ADDRESS_DISTRICT_SUBSELECT%

<script>

  var districtTypesLang = {};

  try {
    districtTypesLang = JSON.parse('%DISTRICT_TYPES_LANG%');
  } catch (err) {
    console.log('JSON parse error');
    console.log(err);
  }
  var district_id = jQuery(`[name='ID']`).val() || 0;

  if (jQuery(`[name='%DISTRICT_IDENTIFIER%']`).length < 1) {
    jQuery(jQuery(`[name='DISTRICT_SEL']:not([change-set])`).first().append(jQuery('<input/>', {
      type: 'hidden',
      name: '%DISTRICT_IDENTIFIER%',
      value: '%DISTRICT_SELECTED%'
    })))
  }

  jQuery(`[name='DISTRICT_SEL']:not([change-set])`).on('change', loadDistrictChild).attr('change-set', 1);
  function loadDistrictChild() {
    let district_sel = jQuery(this);
    let infoPanel = false;

    let container = district_sel.parent().parent().parent().parent().parent();
    container = container.parent();

    let street_id = district_sel.data('street-id');
    let id = district_sel.val();
    if (Array.isArray(id)) {
      if (!id[0]) id.shift();
      id = !id.length ? '' : id.join(';');
    }

    if (id) {
      let infoBtn = container.find('.bd-highlight > .input-group-append > a.input-group-button').first();

      if (infoBtn.length > 0) {
        if (!id.includes(';')) {
          let url = infoBtn.attr('href');
          let newUrl = url.replace(/chg=\d+/, `chg=${id}`);
          infoBtn.attr('href', newUrl);
        }
        infoPanel = true;
      }
    }

    let districtPanel = district_sel.parent().parent().parent().parent();
    districtPanel = districtPanel.parent().parent();
    if (infoPanel) {
      districtPanel = districtPanel.parent()
      container = container.parent();
    }

    // districtPanel.nextAll('.mt-3').remove();
    districtPanel.nextAll('.district-subselect').remove();

    jQuery(`[name='%DISTRICT_IDENTIFIER%']`).val(id);

    if (!id) {
      let lastActiveSelect = jQuery(`[name='DISTRICT_SEL']:has(option:selected):not(#${district_sel.attr('id')})`).last();
      let prev_id = lastActiveSelect.val() || '';
      jQuery(`[name='%SELECT_NAME%']`).val(prev_id);
      jQuery(`[name='%DISTRICT_IDENTIFIER%']`).val(prev_id);

      let customEvent = new CustomEvent('district-change-%DISTRICT_EVENT_ID%', {detail: {district: lastActiveSelect}});
      document.dispatchEvent(customEvent);
      return;
    }

    fetch(`/api.cgi/districts?PARENT_ID=${id}&PARENT_NAME=_SHOW&ID=!${district_id}&PAGE_ROWS=1000000&TYPE_ID`, {
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
    })
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.json())
      .then(data => {
        let customEvent = new CustomEvent('district-change-%DISTRICT_EVENT_ID%', {detail: {district: district_sel}});
        document.dispatchEvent(customEvent);

        if (data.length < 1) return;
        createSelect(data, container, id, street_id, infoPanel);
      })
      .catch(e => {
        console.log(e);
      });
  }

  function createSelect(data, container, parent_id, street_id, info_panel = false) {
    let selectId = `DISTRICT_${Date.now()}`;
    let selectList = jQuery('<select></select>', {class: 'mt-1', id: selectId, name: 'DISTRICT_SEL', 'data-street-id': street_id});
    let inputGroup = jQuery('<div></div>', {class: 'input-group-append select2-append'}).append(selectList);
    let selectDiv = jQuery('<div></div>', {class: 'select'}).append(inputGroup);
    let flexFill = jQuery('<div></div>', {class: 'flex-fill bd-highlight overflow-hidden select2-border'})
      .append(info_panel ? selectDiv : inputGroup);
    let dFlex = jQuery('<div></div>', {class: 'd-flex bd-highlight'}).append(flexFill);

    if (info_panel) {
      let span = jQuery('<span></span>', {class: 'fa fa-list-alt p-1'});
      let a = jQuery('<a></a>', {class: 'btn input-group-button rounded-left-0'})
        .attr('href', '?get_index=form_districts&full=1&chg=0').append(span);
      let groupAppend = jQuery('<div></div>', {class: 'input-group-append h-100'}).append(a);
      let db = jQuery('<div></div>', {class: 'bd-highlight'}).append(groupAppend);
      dFlex.append(db);
    }

    if (jQuery(`[name='DISTRICT_MULTIPLE']`).length > 0) {
      let checkbox = jQuery('<input/>', {type: 'checkbox', name: `DISTRICT_MULTIPLE_${parent_id}`, value: 1,
        class: 'form-control-static m-2', id: `DISTRICT_MULTIPLE_${selectId}`, 'data-select-multiple': selectId})
      let checkboxGroup = jQuery('<div></div>', {class: 'input-group-text p-0 px-1 rounded-left-0'}).append(checkbox);
      let groupAppend = jQuery('<div></div>', {class: 'input-group-append h-100'}).append(checkboxGroup);
      let db = jQuery('<div></div>', {class: 'bd-highlight'}).append(groupAppend);
      dFlex.append(db);
    }

    let districtTypes = [];
    let optgroups = {};
    data.forEach(address => {
      const { parent_id, parent_name, type_id } = address;
      address.parentId = address.parentId ?? parent_id;
      address.parentName = address.parentName ?? parent_name;
      address.typeId = address.typeId ?? type_id;

      if (!optgroups[address.parentId]) {
        optgroups[address.parentId] = jQuery(`<optgroup label='== ${address.parentName} =='></optgroup>`);
      }

      if (address.typeId && districtTypesLang[address.typeId]) {
        if (!districtTypes.includes(districtTypesLang[address.typeId])) districtTypes.push(districtTypesLang[address.typeId]);
      }
      let option = jQuery('<option></option>', {value: address.id, text: address.name});
      optgroups[address.parentId].append(option);
    });

    let labelText = districtTypes.join('/');
    if (labelText) labelText += ':';
    // let group = jQuery('<div></div>', {class: 'col-md-8'}).append(dFlex);
    let colBody = jQuery('<div></div>').append(dFlex);
    let group = jQuery('<div></div>', {class: 'col-md-8'}).append(colBody);
    let label = jQuery('<label></label>', {class: 'col-sm-3 col-md-4 col-form-label text-md-right'}).text(labelText);
    let row = jQuery('<div></div>', {class: 'form-group row district-subselect'}).append(label).append(group);
    container.after(row);

    defineLinkedInputsLogic(group);
    let default_option = jQuery('<option></option>', {value: '', text: '--'});
    selectList.append(default_option);

    jQuery.each(optgroups, function(key, value) { selectList.append(value);});

    initChosen();
    selectList.select2({width: '100%', allowClear: true, placeholder: ''});
    selectList.on('change', loadDistrictChild).focus().select2('open');
  }
</script>