%MENU%



<form action=$SELF_URL method=post class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value='$FORM{chg}'>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=TP_IDS value='%TP_IDS%'>
<input type=hidden name='step' value='$FORM{step}'>

<fieldset>

  %SUBSCRIBE_FORM%


  <div class='panel panel-default panel-form'>
<div class='panel-body'>

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
  <label class='control-label col-md-3' for='CID'>CID (Modem) (_{DELISMITER}_ ;):</label>
  <div class='col-md-9'>
      <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'> %SEND_MESSAGE%
    </div>
   </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='DISABLE'>VoD:</label>
  <div class='col-md-9'>
    <input id='VOD' name='VOD' value='1' %VOD%  type='checkbox'>
  </div>
   </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='DVCRYPT_ID'>DvCrypt ID:</label>
  <div class='col-md-9'>
      <input id='DVCRYPT_ID' name='DVCRYPT_ID' value='%DVCRYPT_ID%' placeholder='%DVCRYPT_ID%' class='form-control' type='text'>
  </div>
  </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_:</label>
  <div class='col-md-9' style='background: %STATUS_COLOR%;'>
    %STATUS_SEL%
  </div>
</div>

%IPTV_MODEMS%

<div class='form-group'>
  <label class='control-label col-md-3' for='IPTV_EXPIRE'>_{EXPIRE}_:</label>
  <div class='col-md-9'>
    <input id='IPTV_EXPIRE' name='IPTV_EXPIRE' value='%IPTV_EXPIRE%' placeholder='%IPTV_EXPIRE%' class='tcal form-control' type='text'>
  </div>
</div>
</div>
<div class='panel-footer text-center'>
  %BACK_BUTTON%
  <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
</div>
</div>

</fieldset>

</form>

