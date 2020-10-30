<div class='form-group message' id='msgs_card_%ID%' user_id='%UID%' draggable='true' ondragstart="return dragStart(event)">
  <div class='box %STATUS_COLOR%' id='MSGS_%ID%'>
    <div class='box-head'>
      <h5 class='box-title'>
        <a href='$SELF_URL%USER_CARD%' style='word-wrap: break-word; padding-left: 10px;'>%USER%</a>
        &nbsp;%DATE%
      </h5>
      <h6 align='left' style='padding-left: 10px;'>_{PRIORITY}_:&nbsp;%PRIORITY_ID%</h6>
    </div>
    <div class='box-body'>
      <a href='$SELF_URL%MSGS_OPEN%' style='word-wrap: break-word;'>%SUBJECT%</a>
    </div>
  </div>
</div>