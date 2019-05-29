<div class='col-md-3'>
  <div class='box box-primary'>
    <div class='box-header with-border'>
      <h3 class='profile-username text-center'>
        %FIO%
        <button type="button" id='addTag' data-toggle="modal" data-target="#leadTags"
                class="btn btn-primary btn-sm glyphicon glyphicon-tags" style="display: %TAGS_BUTTON%"></button>
      </h3>

      <div class="col-md-12">
        %TAGS%
      </div>

      <p class='text-muted text-center'>%COMPANY%</p>
    </div>
    <div class='box-body '>

      <strong><i class='glyphicon glyphicon-earphone'></i> _{PHONE}_</strong>
      <p class='muted'>%PHONE%</p>
      <hr>
      <strong><i class='glyphicon glyphicon-envelope'></i> E-Mail</strong>
      <p class='muted'>%EMAIL%</p>
      <hr>
      <strong><i class='fa fa-address-card'></i> _{ADDRESS}_</strong>
      <p class='muted'>%CITY%, %ADDRESS%</p>
      <hr>
      <strong><i class='fa fa-arrow-down'></i> _{SOURCE}_</strong>
      <p class='muted'>%SOURCE%</p>
      <hr>
      <strong><i class='glyphicon glyphicon-calendar'></i> _{DATE}_ _{REGISTRATION}_</strong>
      <p class='muted'>%DATE%</p>
      <hr>
      <strong><i class='glyphicon glyphicon-envelope'></i> _{USER}_</strong>
      <p class='muted'>%USER_BUTTON% %DELETE_USER_BUTTON%</p>
      <hr>
      <hr>
      <div class='' data-tooltip='_{COMMENTS}_'><textarea class='form-control' rows=5 readonly="">%COMMENTS%</textarea>
      </div>
      <div class='box-footer'>
        %CHANGE_BUTTON%
        %BUTTON_TO_LEAD_INFO%
        %CONVERT_DATA_BUTTON%
      </div>
    </div>
  </div>
</div>