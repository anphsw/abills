<div class=noprint id=form_msg_add>

  <form action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='MsgSendForm' id='MsgSendForm'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='sid' value='$sid'/>
    <input type='hidden' name='ID' value='%ID%'/>

    <div class='card card-primary card-outline'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{MESSAGE}_</h4>
      </div>
      <div class='card-body form form-horizontal'>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{SUBJECT}_:</label>
          <div class='col-md-8'>
            <input type='text' name='SUBJECT' value='%SUBJECT%' size='50' class='form-control' required/>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{CHAPTERS}_:</label>
          <div class='col-md-8'>
            %CHAPTER_SEL%
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{MESSAGE}_:</label>
          <div class='col-md-8'>
            <textarea name='MESSAGE' data-action='drop-zone' cols='70' rows='9' class='form-control'
                      required>%MESSAGE%</textarea>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{STATE}_:</label>
          <div class='col-md-8'>
            %STATE_SEL%
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{PRIORITY}_:</label>
          <div class='col-md-8'>
            %PRIORITY_SEL%
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right'>_{ATTACHMENT}_:</label>

          <div class='col-md-8' id='file_upload_holder'>
            <div class='form-group row'>
              <input name='FILE_UPLOAD' type='file' data-number='0'>
            </div>
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <input type='submit' name='send' value='_{SEND}_' title='Ctrl+C' id='go' class='btn btn-primary'>
      </div>
    </div>
  </form>
</div>
<script>
  jQuery('form#MsgSendForm').on('submit', function () {
    jQuery('#go').on('click', function (click_event) {
      cancelEvent(click_event);
      return false;
    });
    return true;
  });

  // Multi upload logic
  jQuery(function () {
    var MAX_FILES_COUNT = 3;
    initMultifileUploadZone('file_upload_holder', 'FILE_UPLOAD', MAX_FILES_COUNT);
  }());
</script>

<script src='/styles/default_adm/js/draganddropfile.js'></script>