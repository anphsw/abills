<style>
  body {font-family: Arial, Helvetica, sans-serif;}
  
  .attachment_responsive {
    border-radius: 5px;
    cursor: pointer;
    transition: 0.3s;
  }
  
  .attachment_responsive:hover {opacity: 0.7;}
  
  .modal-img {
    display: none;
    position: fixed;
    z-index: 99999;
    padding-top: 100px;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    overflow: auto;
    background-color: rgb(0,0,0);
    background-color: rgba(0,0,0,0.9);
  }
  
  .modal-content-img {
    margin: auto;
    display: block;
    max-width: 90%;
  }

  .modal-content-img {  
    -webkit-animation-name: zoom;
    -webkit-animation-duration: 0.6s;
    animation-name: zoom;
    animation-duration: 0.6s;
  }
  
  @-webkit-keyframes zoom {
    from {-webkit-transform:scale(0)} 
    to {-webkit-transform:scale(1)}
  }
  
  @keyframes zoom {
    from {transform:scale(0)} 
    to {transform:scale(1)}
  }

  .closeImageResize {
    position: absolute;
    top: 15px;
    right: 35px;
    color: #f1f1f1;
    font-size: 40px;
    font-weight: bold;
    transition: 0.3s;
  }
  
  .closeImageResize:hover,
  .closeImageResize:focus {
    color: #bbb;
    text-decoration: none;
    cursor: pointer;
  }

  @media only screen and (max-width: 700px){
    .modal-content-img {
      width: 100%;
    }
  }
</style>

<input type='hidden' name='MAIN_INNER_MESSAGE' value='%MAIN_INNER_MSG%'/>
<input type='hidden' name='SUBJECT' value='%SUBJECT%' size=50/>
<a name='reply' class='anchor'></a>

<div class='box box-theme'>
  <div class='box-header with-border'>
    <h5 class='box-title'>_{REPLY}_</h5>
  </div>
  <div class='box-body form form-horizontal'>

    <div class='form-group'>
      <textarea id='REPLY_TEXT' name='REPLY_TEXT' data-action='drop-zone' class='form-control' rows=10 style='width:90%; margin-left:auto;margin-right:auto'>%QUOTING%%REPLY_TEXT%</textarea>
    </div>
    <div class='form-group'>
      <label class='col-md-12'>%ATTACHMENT%</label>
    </div>

    <div class='form-group'>

      <div class='col-md-6'>
        <label class='col-md-3 control-label'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATE_SEL%
        </div>
      </div>

      <div class='col-md-6'>
        <div class='checkbox'>
          <label>
            <input type='checkbox' name=REPLY_INNER_MSG value=1 %INNER_MSG% style=/>
            <strong>_{PRIVATE}_</strong>
          </label>
        </div>
      </div>

    </div>


    <div class='box box-theme collapsed-box'>
      <div class='box-header with-border'><h3 class='box-title'>_{EXTRA}_</h3>
        <div class='box-tools pull-right'>
          <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{ATTACHMENT}_:</label>
          <div class='col-md-9'>
            <div class='input-group'>
              <div id='file_upload_holder' style='border : 1px solid #d2d6de'>
                <input name='FILE_UPLOAD' type='file' data-number='0' class='fixed'>
              </div>
              <span class='input-group-addon'><a
                  href='$SELF_URL?UID=$FORM{UID}&index=$index&PHOTO=$FORM{chg}&webcam=1'
                  class='glyphicon glyphicon-camera'></a></span>
            </div>
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3'>_{TEMPLATES}_ (_{SURVEY}_):</label>

          <div class='col-md-9'>
            %SURVEY_SEL%
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{CHANGE}_ _{CHAPTERS}_:</label>

          <div class='col-md-9'>
            %CHAPTERS_SEL%
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label text-left'>_{RUN_TIME}_:</label>

          <div class='col-md-9'>

            <div class='input-group'>
              <span class='input-group-addon'><a class='glyphicon glyphicon-time'></a></span>

              <input class='form-control' id='RUN_TIME' type='text' name='RUN_TIME' %RUN_TIME_STATUS%>

              <span id='func_btn' run_status='1' class='input-group-addon'>
              <a id='func_icon' class='glyphicon glyphicon-play'></a></span>
              <span id='func_rst' class='input-group-addon'><a class='glyphicon glyphicon-refresh'></a></span>

            </div>
          </div>
        </div>
      </div>
    </div>
  </div>


  <div class='box-footer'>
    <input type='hidden' name='sid' value='$sid'/>
    <input type='submit' class='btn btn-primary' name='%ACTION%' value='  %LNG_ACTION%  ' id='go' title='Ctrl+C'/>
  </div>
</div>

<div id="myModalImg" class="modal-img">
  <span class="closeImageResize">&times;</span>
  <img class="modal-content-img" id="img_resize">
  <div id="caption"></div>
  <br/>
  <a id='download_btn' class="btn btn-success btn-large">_{DOWNLOAD}_</a>
  <br/><br/>
</div>

<script src="/styles/default_adm/js/msgs_reply_timer.js"></script>
<script>

  var saveStr = '_{SAVE}_';
  var cancelStr = '_{CANCEL}_';
  var replyId = 0;

  var modal = document.getElementById("myModalImg");
  var modalImg = document.getElementById("img_resize");
  var captionText = document.getElementById("caption");

  var downloadBtn = jQuery('#download_btn');
  var span = jQuery(".closeImageResize");

  jQuery(".attachment_responsive").on('click', function(event) {
    modal.style.display = "block";
    modalImg.src = this.src;
    downloadBtn.attr('href',this.src);
  });

  span.on('click', function(event) {
    modal.style.display = "none";
  });

  jQuery('#myModalImg').on('click', function(event) {
    modal.style.display = "none";
  });

  document.addEventListener('keydown', function(event) {
    const key = event.key;
    if (key === "Escape") {
      modal.style.display = "none";
    }
  });

  // Fixing select on bottom of the page
  jQuery(function () {
    var status_select = jQuery('select#STATE');
    var wrapper       = jQuery('div.content-wrapper');

    if (status_select.chosen) {
      status_select.on('chosen:showing_dropdown', function () {
        setTimeout(function () {
          wrapper.scrollTop(wrapper.height());
        }, 100);
      });
    }
  });

  // Multi upload logic
  jQuery(function () {
    var MAX_FILES_COUNT = 3;
    initMultifileUploadZone('file_upload_holder', 'FILE_UPLOAD', MAX_FILES_COUNT);
  });

  jQuery(function () {
    var survey_select = jQuery('select#SURVEY_ID');
    survey_select.on('change', function(){
      var select_value = this.value;
      if(select_value){
        jQuery.ajax({
          url: '$SELF_URL?get_index=msgs_admin&header=2&ajax=1&SURVEY_ID=' +  select_value + '',
          success: function(result){
            if(result) {
              jQuery( "[name='REPLY_TEXT']" ).val(result);
            }
          }
        });
      }
      else{
        jQuery( "[name='REPLY_TEXT']" ).val("");
      }
    });

  });
</script>
<script src="/styles/default_adm/js/draganddropfile.js"></script>