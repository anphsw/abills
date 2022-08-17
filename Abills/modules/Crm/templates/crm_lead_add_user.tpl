<script>
  jQuery(function () {
    jQuery('#add_uid').on('click', function () {

      var login = jQuery('#UID_HIDDEN').val();

      if (login != '') {
        jQuery.get('?qindex=$index&header=2&LEAD_ID=$FORM{LEAD_ID}&add_uid=' + jQuery('#UID_HIDDEN').val(), function (data) {
          location.reload();
        });
      } else {
        alert('_{USER_NOT_EXIST}_');
      }
    });
  });
</script>

<input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
<div class='form-group row'>
  <div class='col-md-12'>
    <div class='input-group'>
      <div class='input-group-prepend'>
        %USER_SEARCH%
      </div>
      <input type='text' form='unexistent' class='form-control' name='LOGIN' value='%USER_LOGIN%' id='LOGIN'
             readonly='readonly'/>
      <div class='input-group-append'>
        <button type='button' class='btn btn-primary fa fa-plus' id='add_uid' data-tooltip='_{MATCH_USER}_'></button>
      </div>
    </div>
  </div>
</div>
