<form action=$SELF_URL method=post class='form-horizontal' ID='IPTV_USER' >
<input type=hidden name=index value=$index>
<input type=hidden name=ID value='$FORM{chg}'>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=TP_IDS value='%TP_IDS%'>
<input type=hidden name='step' value='$FORM{step}'>
<fieldset>

<div class='col-md-12'>
<!-- service start  // col-sm-height-->
<div class='col-md-6 col-sm-height'>

<div class='panel panel-default'>
<div class='panel-body col-sm-height'>

%EXTRA_SCREANS%

<label class='control-label col-md-12' for='DEVICE'>_{SUBSCRIBE}_ OLLTV</label>

<div class='form-group'>
  <label class='control-label col-md-3' for='BUNDLE_TYPE'>_{ACTIVATE}_</label>
  <div class='col-md-8'>
    %BUNDLE_TYPE_SEL%
  </div>
  <div class='col-md-1'>
    %BUNDLE_DEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='START_DATE'>_{START}_</label>
  <div class='col-md-3'>
    %start_date%
  </div>

  <label class='control-label col-md-3' for='END_DATE'>_{END}_</label>
  <div class='col-md-3'>
    %expiration_date%
  </div>
</div>

<!--  -->

  <div class='form-group'>
  <label class='control-label col-md-3' for='TP_NUM'>_{TARIF_PLAN}_:</label>
  <div class='col-md-9'>
      %TP_NUM%
      %TP_NAME%
      %CHANGE_TP_BUTTON%
    </div>
   </div>

  <div class='form-group'>
  <label class='control-label col-md-3' for='FILTER_ID'>Filter-ID:</label>
  <div class='col-md-9'>
      <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%' class='form-control' type='text'>
    </div>
  </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='PIN'>PIN:</label>
  <div class='col-md-9'>
      <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_:</label>
  <div class='col-md-9' style='background: %STATUS_COLOR%;'>
    %STATUS_SEL%
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='OLLTV_USER_ID'>ID:</label>
  <label class='control-label col-md-5' for='OLLTV_USER_ID'>%OLLTV_USER_ID%</label>

<!--   <label class='control-label col-md-3' for='UNSUBSCRIBE'>_{UNSUBSCRIBE}_</label>
  <div class='col-md-1'>
        <input id='UNSUBSCRIBE' name='UNSUBSCRIBE' value='1' type='checkbox'>
  </div>
-->

  <label class='control-label col-md-3' for='DELETE'>_{DEL}_</label>
  <div class='col-md-1'>
     <input id='DELETE' name='DELETE' value='1' type='checkbox'>
  </div>
</div>

<div class='form-group'>
  %REGISTRATION_INFO% %REGISTRATION_INFO_PDF%
</div>
<div>
%BOUGHT_SUBSRIBES%
</div>
</div></div>

</div>
<!-- service end -->


<!-- device start -->
<div class='col-md-6 col-sm-height'>

%FORM_DEVICE%

</div>
<!-- device end -->


<!-- personal info -->


</div>

<div class='col-md-12'>

<!-- device start -->
<div class='col-md-6'>

<div class='panel panel-default'>
<div class='panel-body '>

  <div class='form-group'>
  <label class='control-label col-md-3 required' for='EMAIL'>E-mail:</label>
  <div class='col-md-9'>
      <input id='EMAIL' name='EMAIL' required value='%EMAIL%' placeholder='%EMAIL%' class='form-control' type='text'>
    </div>
  </div>

  <div class='form-group'>
  <label class='control-label col-md-3' for='GENDER'>_{GENDER}_:</label>
  <div class='col-md-9'>
    %GENDER_SEL%
    </div>
  </div>

  <div class='form-group'>
  <label class='control-label col-md-3' for='CITY'>_{CITY}_:</label>
  <div class='col-md-4'>
      <input id='CITY' name='CITY' value='%CITY%' placeholder='%CITY%' class='form-control' type='text'>
    </div>

  <label class='control-label col-md-2' for='ZIP'>_{ZIP}_:</label>
  <div class='col-md-3'>
      <input id='ZIP' name='ZIP' value='%ZIP%' placeholder='%ZIP%' class='form-control' type='text'>
  </div>
  </div>

  <div class='form-group'>
  <label class='control-label col-md-3' for='FIO'>_{FIO}_:</label>
  <div class='col-md-5'>
      <input id='FIO' name='FIO' value='%FIO%' placeholder='%FIO%' class='form-control' type='text'>
    </div>
    <div class='col-md-4'>
      <input id='FIO2' name='FIO2' value='%FIO2%' placeholder='%FIO2%' class='form-control' type='text'>
    </div>
  </div>

  <div class='form-group'>
  <label class='control-label col-md-3' for='BIRTH_DATE'>_{BIRTH_DATE}_:</label>
  <div class='col-md-3'>
      <input id='BIRTH_DATE' name='BIRTH_DATE' value='%BIRTH_DATE%' placeholder='%BIRTH_DATE%' class='form-control tcal' type='text'>
    </div>

  <label class='control-label col-md-4' for='SEND_NEWS'>_{SEND_NEWS}_:</label>
  <div class='col-md-2'>
      <input id='SEND_NEWS' name='SEND_NEWS' value=1 %SEND_NEWS% type='checkbox'>
    </div>
  </div>

  %PARENT_CONTROL%

</div>

</div>

</div>


<div class='col-sm-offset-2 col-sm-8'>
 	%BACK_BUTTON%
  <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
</div>

</fieldset>
</form>

