<div class='form-group message' id='msgs_card_%ID%' user_id='%UID%' draggable='true' ondragstart="return dragStart(event)">
  <div class='card card-outline %STATUS_COLOR%' id='MSGS_%ID%'>
    <div class='card-head'>
      <h4 class='card-title'>
        <a href='$SELF_URL%USER_CARD%' style='word-wrap: break-word; padding-left: 10px; padding-top: 50px;'>%USER%</a>
        &nbsp;%DATE%
      </h4>
      <h6 align='left' style='padding-left: 10px; padding-top: 50px;'>_{PRIORITY}_:&nbsp;%PRIORITY_ID%</h6>
    </div>
    <div class='card-body'>
      <a href='$SELF_URL%MSGS_OPEN%' style='word-wrap: break-word;'>%SUBJECT%</a>
    </div>
  </div>
</div>
