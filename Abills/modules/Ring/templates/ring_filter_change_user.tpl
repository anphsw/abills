<div class='card card-primary card-outline box-form container-md'>
  <div class='card-header with-border text-center'><h5></h5></div>
    <div class='card-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' id='ID' value='%ID%'/>
      <input type='hidden' name='UID' id='UID' value='%UID%'/>
      <input type='hidden' name='TIME_START' id='TIME_START' value='%TIME_START%'/>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{ADMIN}_</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='A_NAME' id='A_NAME' value='%A_NAME%' disabled="disabled">
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{TIME}_</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='TIME' id='TIME' value='%TIME%' disabled="disabled">
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-xs-4 col-md-4' for='PHONE'>_{PHONE}_</label>
        <div class='col-md-8'>
          <div class='d-flex bd-highlight'>
            %PHONE_SEL%
            <a href='%CALLTO_HREF%' class='btn input-group-button'>
              <i class='fa fa-phone'></i>
            </a>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{FIO}_</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='FIO' id='FIO' value='%FIO%' disabled="disabled">
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{STATUS}_</label>
        <div class='col-md-8'>
          %STATUS%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-8'>
           <textarea cols="10" style="resize: vertical" class='form-control' name='COMMENTS'
                     id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <form name='RING_CHANGE_USER' id='RING_CHANGE_USER' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='ID' value='%ID%'/>
        <button type='submit' class='btn btn-primary float-left'>_{FILTER}_</button>
      </form>
      %PRE_BUTTON% %NEXT_BUTTON%
      <input type='submit' class='btn btn-primary float-right' name='change' id='change' value=_{CHANGE}_ onClick='changeRingUser()'>
      <span id="tooltip" class='text-success' style="display: none;">_{CHANGED}_</span>
    </div>


</div>

<script>

  function changeRingUser() {

    let change = document.getElementById('change');
    let tooltip = document.getElementById('tooltip');
    let rect = change.getBoundingClientRect();

    let r_id = jQuery('#ID').val();
    let uid = jQuery('#UID').val();
    let status = jQuery('#STATUS').val();
    let comments = jQuery('#COMMENTS').val();
    let phone = jQuery('#PHONE').val();

    let timeStartSec = jQuery('#TIME_START').val();

    let timeExist = jQuery('#TIME').val();
    let timeParts = timeExist.split(":");
    let existHoursInSec = parseInt(timeParts[0]) * 3600;
    let existMinutesInSec = parseInt(timeParts[1]) * 60;
    let existSec = parseInt(timeParts[2]);
    let timeExistingSec = existHoursInSec + existMinutesInSec + existSec;

    let now = new Date();
    let milliseconds = now.getTime();
    let timeEndSec = Math.floor(milliseconds / 1000);

    let totalTimeSec = timeEndSec - timeStartSec + timeExistingSec;
    let totalHours = Math.floor(totalTimeSec / 3600);
    let totalMin = Math.floor((totalTimeSec % 3600) / 60);
    let totalSec = totalTimeSec % 60;

    let time = totalHours.toString().padStart(2, '0') + ":" + totalMin.toString().padStart(2, '0') + ":" + totalSec.toString().padStart(2, '0');

    fetch('$SELF_URL?get_index=ring_user_filters&full=1&change=1&STATUS='+status+'&TIME='+time+'&COMMENTS='+comments+'&ID='+r_id+'&UID='+uid+'&PHONE='+phone)
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response =>
        response.text()
      )
      .then(result => {
        tooltip.style.display = "block";
        location.reload();
      })
      .catch(err => {
        console.log(err);
      });

  }

</script>
