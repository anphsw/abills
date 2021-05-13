<form action=$SELF_URL method=post enctype=multipart/form-data>

<input type='hidden' name='index'  value=$index>
<input type='hidden' name='ACTION' value='%ACTION%'>
<input type='hidden' name='ID'   value='%ID%'>
  
<div class='card card-primary card-outline box-form form-horizontal'>
  
<div class='card-header with-border text-center'>_{TYPE}_</div>

<div class='card-body'>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{NAME}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='NAME' value='%NAME%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{ICON}_</label>
    <div class='col-md-9'><input type='file' name=UPLOAD_FILE></div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='COMMENT'>%COMMENT%</textarea>
    </div>
  </div>
</div>

<div class='card-footer'>
   <button class='btn btn-primary' type='submit'>%BTN%</button>
</div>

</div>

</form>