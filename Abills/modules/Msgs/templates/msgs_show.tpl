<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='UID' value='$FORM{UID}'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='PARENT' value='%PARENT%'/>
  <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
  <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>

  <div class='row' style='word-wrap: break-word;'>
    <div class='col-md-9 mt-2' id='reply_wrapper'>
      <div class='card card-outline %MAIN_PANEL_COLOR%'>
        <div class='card-header with-border'>
          <div class='row'>
            <div class='col-md-12'>
              <div class='card-title'>
                <span class='badge badge-primary'>%ID%</span>
                %SUBJECT% %CHANGE_SUBJECT_BUTTON%
              </div>
              <div class='card-tools pull-right'>
                %RATING_ICONS% %PARENT_MSG% %INNER_MSG_TAG%
              </div>
            </div>
          </div>
        </div>
        <div class='card-body text-left'>
          <div class='row'>
            <div class='col-md-3'><strong>_{STATUS}_:</strong></div>
            <div class='col-md-3'>%STATE_NAME%</div>
            <div class='col-md-3'><strong>_{PRIORITY}_:</strong></div>
            <div class='col-md-3'>%PRIORITY_TEXT%</div>
          </div>
          <div class='row'>
            <div class='col-md-3'><strong>_{CREATED}_:</strong></div>
            <div class='col-md-3'>%DATE%</div>
            <div class='col-md-3'><strong>_{CHAPTER}_:</strong></div>
            <div class='col-md-3'>%CHAPTER_NAME%</div>
          </div>
          <div class='row' style='display: %MSG_TAGS_DISPLAY_STATUS%'>
            <div class='col-md-12'>%MSG_TAGS%</div>
          </div>
          %PROGRESSBAR%
        </div>
      </div>

      <div class='card card-primary'>
        <div class='card-header with-border'>
          <h5 class='card-title'>%LOGIN% _{ADDED}_: %DATE%</h5>
        </div>
        <div class='card-body text-left'>
          %MESSAGE%
        </div>
        <div class='card-footer'>
          %RUN_TIME% %ATTACHMENT%
          <div class='pull-right'>%QUOTING% %DELETE% %EDIT%</div>
        </div>
      </div>

      %REPLY%
      %REPLY_FORM%
<!--      %ADDRESS_SET%-->
      %WORKPLANNING%
    </div>
    <div class='col-md-3 mt-2' id='ext_wrapper'>
      %EXT_INFO%
    </div>
  </div>
</form>

<script>
  var saveStr = '_{SAVE}_';
  var cancelStr = '_{CANCEL}_';
  var replyId = 0;
  var editedStr = '_{CHANGED}_';

  function save_reply(element) {
    var replyText = jQuery('.reply-edit').val();
    var date = new Date();
    var dateStr = date.toISOString().slice(0, 10) + ' ' + date.toTimeString().slice(0, 9) + "(%ADMIN_LOGIN%)";
    replyText = replyText + "\n\n\n" + editedStr + ": " + dateStr;
    var replyHtml = replyText.replace(/\</g, "&lt")
      .replace(/\>/g, "&gt")
      .replace(/\n/g, "<br />");

    jQuery(element).parent().html(replyHtml);

    console.log(jQuery.post('$SELF_URL', 'header=2&get_index=_msgs_edit_reply&edit_reply=' + replyId + '&replyText=' + replyText));
  }

  function edit_reply(element) {
    if (replyId == 0) {
      replyId = jQuery(element).attr('reply_id');
      var replyElement = jQuery(element).closest(".card").find(".card-body");
      var oldReplyHtml = replyElement[0].innerHTML;
      var oldReply = replyElement[0].innerText;
      replyElement.html("")
        .append("<textarea class='form-control reply-edit' rows='10' style='width:100%; margin-left:auto;margin-right:auto'>" + oldReply + "</textarea>")
        .append("<button type='button' class='btn btn-default btn-xs reply-save group-btn'>" + saveStr + "</button>")
        .append("<button type='button' class='btn btn-default btn-xs reply-cancel group-btn'>" + cancelStr + "</button>");
      replyElement.children().first().focus();

      jQuery(".reply-save").click(function (event) {
        event.preventDefault();
        save_reply(this);
        jQuery(".quoting-reply-btn").attr('disabled', false);
        replyId = 0;
      });

      jQuery(".reply-cancel").click(function (event) {
        event.preventDefault();
        jQuery(this).parent().html(oldReplyHtml);
        jQuery(".quoting-reply-btn").attr('disabled', false);
        replyId = 0;
      });
    }
  }

  function quoting_reply(element) {
    var replyField = jQuery('#REPLY_TEXT');

    var replyElement = jQuery(element).closest(".card").find(".card-body");
    var oldReplyHtml = replyElement[0].innerHTML;
    var oldReply = replyElement[0].innerText;

    oldReply = oldReply.replace(/^/g, '> ');
    oldReply = oldReply.replace(/\n/g, '\n> ');

    replyField.val(oldReply);
  }

  jQuery(function () {
    jQuery(".reply-edit-btn").click(function (event) {
      event.preventDefault();
      jQuery(".quoting-reply-btn").attr('disabled', true);
      edit_reply(this);
    });

    jQuery(".quoting-reply-btn").click(function (event) {
      event.preventDefault();
      quoting_reply(this);
    });

    jQuery(".reply-body").each(function () {
      let oldText = jQuery(this).html();
      jQuery(this).html(decodeURI(oldText.replaceAll('\\%', '\%')));
    })
  });
</script>
