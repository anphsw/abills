<form method='post'>
<input type='hidden' name='index' value='$index' />

<div class='panel panel-primary form-horizontal'>
<div class='panel-heading'>_{DOWNLOAD_CHANNELS}_</div>
<div class='panel-body'>
%TABLE%

<div class='form-group'>
  <label class='col-md-3 control-label text-center required'>_{NAME}_ _{FILE}_</label>
  <div class='col-md-9'>
    <div class='input-group'>
    <input type='text' class='form-control' required name='FILENAME' value='%FILENAME%' placeholder='Channels IPTV'>
    <span class='input-group-addon'>.m3u</span>
    </div>
    <!-- <input type='text' class='form-control' name='FILENAME' value='%FILENAME%'> -->
  </div>

</div>
</div>
<div class='panel-footer'><button type='submit' class='btn btn-primary'>_{EXPORT}_</button></div>
</div>

</form>