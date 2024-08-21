<link href='/styles/default/css/info.css' rel='stylesheet'>

<div id='form_6' class='card for_sort dataTables_wrapper card-primary card-outline'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{COMMENTS}_</h4>
    <div class='card-tools float-right'>
      %COMMENTS_CONTROLS%
      <button type='button' class='btn btn-tool text-right col-md-12' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body p-0'>
    <div class="paginator text-right p-1" onclick="listing_pagination(event)"></div>
    <div id='commentsWrapper' class='row'>
      <div class='col-md-12'>
        <div class='col-md-12 timeline mb-0' id='commentsBlock'>
          %COMMENTS%
        </div>
      </div>
    </div>
  </div>
</div>

<div id='myModalImg' class='modal-img'>
  <span class='closeImageResize'>&times;</span>
  <img class='modal-content-img' id='img_resize'>
  <div id='caption'></div>
  <br/><br/>
  <div class='text-center'>
    <a id='download_btn' class='btn btn-success btn-large text-center'>_{DOWNLOAD}_</a>
  </div>
  <br/><br/>
</div>

<script>
  var lang_edit = '_{EDIT}_';
  var lang_add = '_{ADD}_';
  var lang_comments = '_{COMMENTS}_';
  var lang_admin = '_{ADMIN}_';

  var modal = document.getElementById('myModalImg');
  var modalImg = document.getElementById('img_resize');
  var captionText = document.getElementById('caption');

  var downloadBtn = jQuery('#download_btn');
  var span = jQuery('.closeImageResize');

  jQuery('.attachment_responsive').on('click', function (event) {
    modal.style.display = 'block';
    modalImg.src = this.src;
    downloadBtn.attr('href', this.src);
  });

  span.on('click', function (event) {
    modal.style.display = 'none';
  });

  jQuery('#myModalImg').on('click', function (event) {
    modal.style.display = 'none';
  });

</script>

<script src='/styles/default/js/info/info.js'></script>

<style>
  .paginator {
    line-height: 150%;
  }
  .paginator_active {
    font-weight: bold;
  }
  .paginator > span {
    display: inline-block;
    margin-right: 10px;
    cursor: pointer;
  }
  .attachment_responsive {
    border-radius: 5px;
    cursor: pointer;
    transition: 0.3s;
  }
  .attachment_responsive:hover {
    opacity: 0.7;
  }
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
    background-color: rgb(0, 0, 0);
    background-color: rgba(0, 0, 0, 0.9);
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
    from {
      -webkit-transform: scale(0)
    }
    to {
      -webkit-transform: scale(1)
    }
  }
  @keyframes zoom {
    from {
      transform: scale(0)
    }
    to {
      transform: scale(1)
    }
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
  @media only screen and (max-width: 700px) {
    .modal-content-img {
      width: 100%;
    }
  }
</style>