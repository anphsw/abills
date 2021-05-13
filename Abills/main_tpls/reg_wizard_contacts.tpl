<input type='hidden' name='ALL_CONTACT_TYPES' value='%ALL_CONTACT_TYPES%'>
<input type='hidden' name='phone' id='phone' value='$FORM{phone}'>
<input type='hidden' name='email' id='email' value='$FORM{email}'>
<input type='hidden' name='LEAD_ID' value='$FORM{LEAD_ID}'>
<input type='hidden' name='PHONE_NUMBER' id='PHONE_NUMBER' value='$FORM{PHONE_NUMBER}'>

<div class='card card-primary card-outline'>
  <div class='card-header with-border'><h3 class='card-title'>_{CONTACTS}_</h3>
    <div class='card-tools pull-right'>
      <button type='button' class='btn btn-box-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body rpw'>
      <div class='col-md-12 col-xs-12'>
        <div id='additional_fields_container'></div>
        <div class='col-md-2 col-xs-2 offset-md-10'>
          <a title="_{ADD}_ _{CONTACTS}_" class='btn btn-sm btn-secondary' id='add_field'>
            <span class='fa fa-plus'></span>
          </a>
        </div>
    </div>


    <!-- Invisible element for clone-->
    <div class='form-group d-none row' id='blank_element'>
      <label class='control-label col-md-2 col-xs-12 '>_{TYPE}_:</label>
      <div id="select_type_contact_1" class='col-md-3 col-xs-12 ' style="margin: 0 0 8px 0 ">

      </div>
      <label class='control-label col-md-2 col-xs-12'>_{VALUE}_:</label>
      <div class=' col-md-3 col-xs-10'>
        <input class='form-control  ct_input' name="CONTACT_TYPE_2" type='text' disabled
              onchange="validation(jQuery(this))">
      </div>
      <div class='col-md-2 col-xs-2'>
        <a title='_{REMOVE}_' class='btn btn-sm btn-secondary  del_btn' >
          <span class='fa fa-minus'></span>
        </a>
      </div>
    </div>
  </div>
</div>

<script type='text/javascript'>
  jQuery(function () {
    var typeSelect = "%TYPE_SELECT%";
    var i = 1;
    var defs = '%DEFAULT_CONTACT_TYPES%';
    var array = defs.split(',');
    jQuery(array).each(function(n,t) {
      createAddressElement(t);
    });

    jQuery('#add_field').click(function () {
      createAddressElement();
    });

    jQuery('.del_btn').click(function () {
      this.closest('.form-group').remove();
      checkContactInputColors();
    });

    function createAddressElement(type) {
      type = type || 2;
      var oldI = i;
      jQuery('#blank_element').clone(true)
        .attr('id', 'field' + i)
        .removeClass('d-none')
        .appendTo('#additional_fields_container');
      jQuery('#field' + i).find('.ct_input').removeAttr('disabled').attr('name', 'CONTACT_TYPE_' + type);
      i++;

      jQuery('#blank_element').children('#select_type_contact_' + oldI).attr('id', 'select_type_contact_' + i);
      var typeSelectNew = typeSelect.replace(/TYPES_CONTACTS_/g, "TYPES_CONTACTS_" + oldI);
      jQuery('#select_type_contact_' + oldI).html(typeSelectNew);
      jQuery("#TYPES_CONTACTS_" + oldI).val(type);
      initChosen();
    }
    setLeadInfo();
  });

  function setLeadInfo() {
    var phone = jQuery('#phone').val();
    var email = jQuery('#email').val();

    jQuery('input[name="CONTACT_TYPE_2"]').val(phone);
    jQuery('input[name="CONTACT_TYPE_9"]').val(email);

    var require_phone = jQuery('#PHONE_NUMBER').val();
    if (require_phone == 'PHONE_NUMBER') {
      jQuery('input[name="CONTACT_TYPE_2"]').attr('required', true);
    }
  }

  function changeContactType(contactType) {
    var selectChanged = jQuery('#' + contactType.name);
    var selectedType = selectChanged.val();
    var parentId = selectChanged.parent().parent().parent().attr('id');
    jQuery('#' + parentId).find('.ct_input').attr('name', 'CONTACT_TYPE_' + selectedType);
  };

  function validation(data) {
    var name = data.attr('name');
    var patt = /\d/g;
    var resultType = name.match(patt);

    if (resultType == 2 && next_disable === 1) {
      var phone = data.val();
      changeClassAndColor(data, 2, phone);
    }
    else if (resultType == 9 && next_disable === 1) {
      var email = data.val();
      changeClassAndColor(data, 9, email);
    }
    else if (resultType == 1 && next_disable === 1) {
      var cellPhone = data.val();
      changeClassAndColor(data, 1, cellPhone);
    }
  };

  function validateEmail(email) {
    var re = /^%EMAIL_FORMAT%/;
    return re.test(email);
  };

  function validatePhone(phone) {
    var re = /%PHONE_FORMAT%/;
    return re.test(phone);
  };

  function validateCellPhone(cellPhone) {
    var re = /%CELL_PHONE_FORMAT%/;
    return re.test(cellPhone);
  };

  function changeClassAndColor(obj, type, value) {
    var myfunc;
    if (type == 1) {
      myfunc = validateCellPhone(value)
    }
    else if (type == 2) {
      myfunc = validatePhone(value)
    }
    else if (type == 9) {
      myfunc = validateEmail(value)
    }
    if (value != '') {
      if (myfunc) {
        obj.css('border-color', 'green');
        obj.addClass('contact_valid');
        obj.removeClass('contact_wrong');
        checkContactInputColors();
      }
      else {
        obj.css('border-color', 'red');
        obj.addClass('contact_wrong');
        obj.removeClass('contact_valid');
        checkContactInputColors();
      }
    }
    else {
      obj.css('border-color', '');
      obj.removeClass('contact_valid');
      obj.removeClass('contact_wrong');
      checkContactInputColors();
    }
  }

  function checkContactInputColors() {
    var redExist = 0;
    jQuery("#additional_fields_container :input.ct_input").each(function () {
      var input = jQuery(this);
      if (jQuery(this).hasClass('contact_wrong')) {
        redExist = 1;
        return false;
      }
    });
    if (redExist == 1 || next_disable === 2) {
      jQuery('input[name=next]').attr('disabled', 'disabled');
    }
    else {
      jQuery('input[name=next]').removeAttr('disabled', 'disabled');
    }
  }

  function validate_after_login() {
    jQuery("#additional_fields_container :input.ct_input").each(function () {
      validation(jQuery(this));
    });
  }

</script>