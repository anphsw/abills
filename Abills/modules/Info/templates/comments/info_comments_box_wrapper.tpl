<link href='/styles/default/css/info.css' rel='stylesheet'>

<div id='form_6' class='card for_sort'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{COMMENTS}_</h4>
    <div class='card-tools float-right'>
      %COMMENTS_CONTROLS%
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    <div id='commentsWrapper' class='row'>
      <div class='col-md-12'>
        <div class='col-md-12 timeline mb-0' id='commentsBlock'>
          %COMMENTS%
        </div>
      </div>
    </div>
  </div>
</div>

<script>
  var lang_edit = '_{EDIT}_';
  var lang_add = '_{ADD}_';
  var lang_comments = '_{COMMENTS}_';
  var lang_admin = '_{ADMIN}_';
</script>

<script src='/styles/default/js/info/info.js'></script>
