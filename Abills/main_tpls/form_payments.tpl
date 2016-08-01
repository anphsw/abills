<script language='JavaScript' type='text/javascript'>
<!--
function postthread(param) {
       param = document.getElementById(param);
//       var id = setTimeout(param.disabled=true,10);
    param.value = '_{IN_PROGRESS}_...';
       param.style.backgroundColor='#dddddd';
}
-->
</script>

<form class='form-horizontal' action='$SELF_URL' method='post' id='user_form' name='user_form' role='form' onsubmit=\"postthread('submitbutton');\">
<input type=hidden name=index value='$index'>
<input type=hidden name=subf value='$FORM{subf}'>
<input type=hidden name=OP_SID value='%OP_SID%'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=step value='$FORM{step}'>

<fieldset>
<div class='panel panel-primary panel-form'>
<div class='panel-heading text-center'><h4>_{PAYMENTS}_</h4></div>
<div class='panel-body'>



<div class='form-group'>
    <label class='control-label col-md-3 required' for='SUM'>_{SUM}_:</label>
  <div class='col-md-4'>
      <input id='SUM' name='SUM' value='$FORM{SUM}' required placeholder='$FORM{SUM}' class='form-control' type='text'>
   </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='DESCRIBE'>_{DESCRIBE}_:</label>
  <div class='col-md-9'>
    <input id='DESCRIBE' type='text' name='DESCRIBE' value='%DESCRIBE%' class='form-control'>
  </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='INNER_DESCRIBE'>_{INNER}_:</label>
  <div class='col-md-9'>
     <input id='INNER_DESCRIBE' type='text' name='INNER_DESCRIBE' value='%INNER_DESCRIBE%' class='form-control'>
  </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='PAYMENT_METHOD'>_{PAYMENT_METHOD}_:</label>
  <div class='col-md-9'>
    %SEL_METHOD%
  </div>
</div>
<!-- <div class='form-group'>
    <label class='control-label col-md-3' for='CASHBOX'>_{CASHBOX}_:</label>
    <div class='col-md-9'>
        %CASHBOX_SELECT%
     </div>
</div> -->

%ER_FORM%

<div class='form-group'>
  <label class='control-label col-md-3' for='EXT_ID'>EXT ID:</label>
  <div class='col-md-9'>
    <input id='EXT_ID' type='text' name='EXT_ID' value='%EXT_ID%' class='form-control'>
  </div>
</div>

%DATE_FORM%

%EXT_DATA_FORM%

%DOCS_INVOICE_RECEIPT_ELEMENT%
</div>
<div class='panel-footer'>
    %BACK_BUTTON% <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>

</div>
</div>






</fieldset>
</form>

