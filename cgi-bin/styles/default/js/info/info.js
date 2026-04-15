/**
 * Created by Anykey on 12.11.2015.
 *
 * TODO : move to separate files
 *
 */

if (typeof info_script_loaded === 'undefined') {

  var info_script_loaded = true;

  function renewContent(context, callback) {
    var $this = $(context);
    var $refreshIcon = $this.find('.fa');

    var type = $this.attr('data-object_type');
    var id = $this.attr('data-object_id');
    var areaToRefresh = $this.attr('data-renews');
    var source_func = $this.attr('data-source');

    if (!(type && id && areaToRefresh && source_func)) {
      $refreshIcon.removeClass('btn-success');
      $refreshIcon.addClass('btn-danger');
      return false;
    }

    $refreshIcon.addClass('fa-pulse');

    var $areaToRefresh = $('' + areaToRefresh);

    var params = {
      OBJ_TYPE: type,
      OBJ_ID: id,
      get_index: source_func,
      header: 2,
      AJAX: 1
    };

    $.get('/admin/index.cgi', params, function (data) {
      $areaToRefresh.html(data);
      $refreshIcon.removeClass('fa-pulse');

      Events.emit('info_document_renewed', true);

      if (callback) {
        callback();
      }

      blocks_pagination();
      var main_page = document.getElementById("page1");
      if (main_page) {
        main_page.classList.add("paginator_active");
        main_page.click();
      }
    });
  }

  //Comments code
  var $commentsWrapper = $('#commentsWrapper');
  if ($commentsWrapper) {

    var $commentModal = $('#info_comments_modal');

    //Modal HTML parts
    var $commentsBody = $commentModal.find('#info_comments_body');
    var $commentsRefreshBtn = $('#info_comments_refresh');
    var $commentsForm = $commentModal.find('#form_add_comments');
    var $commentsModalTitle = $commentModal.find('#info_comments_modal_title');

    //Inputs
    var $commentsTextarea = $commentsForm.find('#COMMENTS_TEXT');
    var $commentsType = $('#OBJECT_TYPE');
    var $commentsId = $('#OBJECT_ID');
    var $commentsAddIndex = $('#ADD_INDEX');


    var $commentsBlock = $('#commentsBlock');

    Events.on('info_something_changed', function (data) {
      console.log(data);
      renewContent($commentsRefreshBtn, bindDelBtns);
      renewContent($commentsRefreshBtn, bindEditBtns);
      //renewDOM();
    });

    $commentsRefreshBtn.on('click', function () {
      Events.emit('info_something_changed', 'comments');
    });

    //bind events
    $commentsForm.on('submit', function (e) {
      e.preventDefault();
      submitCommentForm();
    });

    $commentModal.on('shown.bs.modal', function () {
      $commentsTextarea.focus();
    });

    jQuery('.del-attachment').on('click', function () {
      let comment = jQuery(this).parent();
      let id = comment.data('id');

      aModal.clear()
        .setId('ModalDelLocation')
        .setBody(`<h4>${_DELETE}</h4>`)
        .addButton(_NO, 'districtModalCancelButton', 'default')
        .addButton(_YES, 'districtModalButton', 'primary')
        .show(setUpDelModal);
      function setUpDelModal() {
        jQuery('#districtModalCancelButton').on('click', function () {
          aModal.hide();
        })

        jQuery('#districtModalButton').on('click', function () {
          fetch(`?header=2&get_index=info_document_del&DEL_ATTACHMENT_ID=${id}`)
            .then(response => {
              if (!response.ok) throw response;

              return response;
            })
            .then(function (response) {
              return response.json();
            })
            .then(result => {
              if (result.ok) comment.parent().remove();
              aModal.hide();
            })
            .catch(err => {
              console.log(err);
              aModal.hide();
            });
        })
      }
    });

    bindDelBtns();
    bindAttachBtns();
    bindEditBtns();
    bindAddBtn();

    function bindAttachBtns() {
      $(document).on('click', '.commentAttachBtn', function () {
        let id = jQuery(this).data('id');
        jQuery('#INFO_COMMENT_ID').val(id);

        jQuery('#UPLOAD_FILE').on('change', function (e) {
          jQuery('form[name="info_attachment"]').submit();
        });

        jQuery('#UPLOAD_FILE').click();
      });
    }

    function renewDOM() {
      $commentModal = $('#info_comments_modal');

      //Modal HTML parts
      $commentsBody = $commentModal.find('#info_comments_body');
      $commentsForm = $commentModal.find('#form_add_comments');
      $commentsModalTitle = $commentModal.find('#info_comments_modal_title');

      //Inputs
      $commentsTextarea = $commentsForm.find('#COMMENTS_TEXT');
      $commentsType = $('#OBJECT_TYPE');
      $commentsId = $('#OBJECT_ID');
      $commentsAddIndex = $('#ADD_INDEX');

      $commentsWrapper = $('#commentsWrapper');
      $commentsBlock = $('#commentsBlock');
    }

    function bindDelBtns() {
      $(document).on('click', '.commentDeleteBtn', function (e) {
        e.preventDefault();
        var $commentDiv = $(this).parent().parent().parent();

        var $icon = $(this).find('.fa');
        $icon.removeClass('fa-trash ');
        $icon.addClass('fa fa-spinner fa-pulse');

        var text = $commentDiv.find(".text").text().trim().substring(0, 100);
        var uid = $commentsId.val() || '';
        var url = $(this).data('url');

        var params = $.param({
          UID: uid,
          COMMENTS: text,
        });

        $.getJSON(url, params, function (data) {
          if (data.status == 0) {
            Events.emit('info_something_changed', 'comments');
            renewDOM();
          }
        });
      });
    }

    function bindEditBtns() {
      var $commentEditBtn = $('.commentEditBtn');
      $(document).on('click', '.commentEditBtn', function (e) {
        e.preventDefault();
        var $commentDiv = $(this).parent().parent().parent();
        var $text = $commentDiv.find(".text").text().trim();

        $commentDiv.find(".text").html("<textarea class='form-control'>" + $text + "</textarea>");

        var $icon = $(this).find('.fa');
        $icon.removeClass('fa-pencil-alt');
        $icon.addClass('fa-check');
        $(this).removeClass('commentEditBtn');
        $(this).addClass('commentEditSubmit');

        $('.commentEditSubmit').on('click', function () {

          var $icon = $(this).find('.fa');
          $icon.removeClass('fa-plus ');
          $icon.addClass('fa fa-spinner fa-pulse');

          var text = $(this).parent().parent().find("textarea").val();
          var type = $commentsType.val();
          var uid = $commentsId.val() || '';
          var id = $(this).data('id');

          var formData = new FormData();

          formData.append('get_index', 'info_edit');
          formData.append('COMMENTS', text);
          formData.append('OBJ_TYPE', type);
          formData.append('ID', id);
          formData.append('UID', uid);
          formData.append('COMMENTS_OLD', $text);
          formData.append('SAVE', 1);
          formData.append('EDIT', 1);
          formData.append('header', 2);
          formData.append('INFO_COMMENT_ID', id);

          for (let i = 0; i < pastedImages.length; i++) {
            if (pastedImages[i]) {
              formData.append('UPLOAD_FILE_' + i, pastedImages[i]);
            }
          }

          $.ajax({
            url: '/admin/index.cgi',
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            success: function(data){
              Events.emit('info_something_changed', 'comments');
              renewDOM();
              if (pastedImages.length > 0) {
                location.reload();
                return;
              }
            }
          });

          // test uploading
          // for (let pair of formData.entries()) {
          //   console.log(pair[0], pair[1]);
          // }

        });

      });
    }

    function bindAddBtn() {

      var $commentAddBtn = $('.commentAddBtn');
      $commentAddBtn.on('click', function (e) {
        $commentsBlock = $('#commentsBlock');

        var date = moment(new Date()).format('YYYY-MM-DD HH:MM:SS');

        $commentsBlock.prepend("<div>" +
          "<div class=\"timeline-item\">" +
          "  <span class=\"time\"><i class=\"far fa-clock\"></i>" + date + "</span>" +
          "  <h3 class=\"timeline-header text-left\">" + lang_admin + "</h3>" +
          "  <div class=\"timeline-body text-left text info_comment\"><textarea class='form-control'></textarea></div>" +
          "  <div class=\"image_paste_preview\"></div>" +
          "  <div class=\"timeline-footer text-right\">" +
          "<a class='commentAddSubmit m-1'>" +
          "<span class='fa fa-plus text-success'></span>" +
          "</a>" +
          "<a class='commentRemove m-1'>" +
          "<span class='fa fa-trash text-danger'></span>" +
          "</a>" +
          "  </div>" +
          "</div>" +
          "</div>");

        $commentsBlock.find("textarea").focus();

        $('.commentRemove').on('click', function () {
          Events.emit('info_something_changed', 'comments');
          renewDOM();
        });

        $('.commentAddSubmit').on('click', function () {

          var $icon = $(this).find('.fa');
          $icon.removeClass('fa-plus ');
          $icon.addClass('fa fa-spinner fa-pulse');

          var text = $(this).parent().parent().find("textarea").val();
          var type = $commentsType.val();
          var id = $commentsId.val();

          var formData = new FormData();
          formData.append('get_index', 'info_comment_add');
          formData.append('TEXT', text);
          formData.append('OBJ_TYPE', type);
          formData.append('OBJ_ID', id);
          formData.append('header', 2);
          for (let i = 0; i < pastedImages.length; i++) {
            if (pastedImages[i]) {
              formData.append('UPLOAD_FILE_' + i, pastedImages[i]);
            }
          }

          $.ajax({
            url: '/admin/index.cgi',
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            success: function(data){
              Events.emit('info_something_changed', 'comments');
              renewDOM();

              if (pastedImages.length > 0) {
                location.reload();
                return;
              }
            }
          });

        });

      });

    }

    function submitCommentForm() {
      var text = $commentsTextarea.val();
      var type = $commentsType.val();
      var id = $commentsId.val();

      if (text.length < 1) {
        aTooltip.setClass('danger').setText('<h2>' + _COMMENTS_PLEASE + '</h2>').show();
        return false;
      }

      var formData = new FormData();
      formData.append('get_index', 'info_comment_add');
      formData.append('TEXT', text);
      formData.append('OBJ_TYPE', type);
      formData.append('OBJ_ID', id);
      formData.append('header', 2);

      for (let i = 0; i < pastedImages.length; i++) {
        if (pastedImages[i]) {
          formData.append('UPLOAD_FILE', pastedImages[i]);
        }
      }

      $.ajax({
        url: '/admin/index.cgi',
        type: 'POST',
        data: formData,
        processData: false,
        contentType: false,
        success: function(data){
          Events.emit('info_something_changed', 'comments');
          renewDOM();
          if (pastedImages.length > 0) {
            location.reload();
            return;
          }
        }
      });

    }
  }
}

//Images code
{
  var $delBtns = $('.imgDelBtn');
  var pastedImages = [];

  $delBtns.on('click', function () {
    var $this = $(this);
    $this.addClass('fa-spin');
    deleteImage(this);
  });


  function deleteImage(context) {
    var $context = $(context);
    var img_id = $context.data('image_id');
    var url = '/admin/index.cgi?get_index=info_image_del&header=2&OBJ_ID=' + img_id;

    $.getJSON(url, function (data) {
      if (data.status == 0) {
        $context.parent().parent().fadeOut(1000);
        $context.removeClass('fa-pulse');
      }
    });
  }

  //AJAX UPLOAD FORM
  $(function () {
    var $ajax_modal = $('#info_ajax_upload_modal');
    var $ajax_form = $ajax_modal.find('#form_ajax_upload');
    var $ajax_body = $ajax_modal.find('#info_ajax_upload_modal_body');
    var ajax_clear_body = '';
    var $add_btn = $ajax_modal.find('#go');
    var add_btn_text = $add_btn.text();

    console.log('Ajax Form Upload logic defined');

    bindAjaxFormSubmit();

    function uploadForm(context) {
      var url = "/admin/index.cgi";

      $add_btn.html('<span class="fa fa-spinner fa-pulse"></span>');
      $add_btn.addClass('disabled');

      ajax_clear_body = $ajax_body.html();
      console.log('submit');
      $.ajax({
        url: url, // Url to which the request is send
        type: "POST",             // Type of request to be send, called as method
        data: new FormData(context), // Data sent to server, a set of key/value pairs (i.e. form fields and values)
        contentType: false,       // The content type used when sending data to the server.
        cache: false,             // To unable request pages to be cached
        processData: false,        // To send DOMDocument or non processed data file it is set to false
        success: function (data)   // A function to be called if request succeeds
        {
          $ajax_body.empty().html(data);

          Events.emit('info_something_changed', true);

          setTimeout(function () {
            $ajax_modal.modal('hide');
            $ajax_body.html(ajax_clear_body);
            $add_btn.text(add_btn_text);
            $add_btn.removeClass('disabled');
            $ajax_form = $ajax_modal.find('#form_ajax_upload');
            bindAjaxFormSubmit();
          }, 3000);
        }
      });
    }

    function bindAjaxFormSubmit() {
      $ajax_form.on('submit', function (e) {
        e.preventDefault();
        console.log('before');
        uploadForm(this);
      });
    }
  });

  //DOCUMENTS SECTION
  {
    var $documentsWrapper = $('#docWrapper');
    if ($documentsWrapper[0]) {
      console.log('docs');
      var $documentRefreshBtn = $documentsWrapper.find('#info_documents_refresh');
      var $documentRefreshIcon = $documentsWrapper.find('#info_documents_refresh>.fa.fa-sync');

      //Bind events

      $documentRefreshBtn.on('click', function (e) {
        e.preventDefault();
        renewContent(this);
      });

      Events.on('info_something_changed', function () {
        renewContent($documentRefreshBtn);
      });

    }
  }

  var div_num;
  var cnt = 5;

  // PAGINATION
  function blocks_pagination() {
    var numElements = document.querySelectorAll('.num');
    var count = numElements.length;
    var cnt_page = Math.ceil(count / cnt);

    var paginator = document.querySelector(".paginator");
    var page = "";
    for (var i = 0; i < cnt_page; i++) {
      page += "<span data-page=" + i * cnt + "  id=\"page" + (i + 1) + "\">" + (i + 1) + "</span>";
    }

    paginator.innerHTML = page;

    // show first items
    div_num = document.querySelectorAll(".num");
    for (var i = 0; i < div_num.length; i++) {
      if (i < cnt) {
        div_num[i].style.display = "block";
      }
    }
  }

  blocks_pagination();

  var main_page = document.getElementById("page1");
  if (main_page) {
    main_page.classList.add("paginator_active");
  }

  window.listing_pagination = function(event){
    var e = event || window.event;
    var target = e.target;
    var id = target.id;

    if (target.tagName.toLowerCase() != "span") return;

    var num_ = id.substr(4);
    var data_page = +target.dataset.page;
    main_page.classList.remove("paginator_active");
    main_page = document.getElementById(id);
    main_page.classList.add("paginator_active");

    var j = 0;
    for (var i = 0; i < div_num.length; i++) {
      var data_num = div_num[i].dataset.num;
      if (data_num <= data_page || data_num >= data_page)
        div_num[i].style.display = "none";

    }
    for (var i = data_page; i < div_num.length; i++) {
      if (j >= cnt) break;
      div_num[i].style.display = "block";
      j++;
    }
  }

  if (main_page) {
    main_page.click();
  }

}

// ===== IMAGE PASTE / DROP PREVIEW =====

var pastedImages = [];

function renderPreview(file, index, container) {

  var reader = new FileReader();

  reader.onload = function(e) {
    var wrapper = $('<div class="image_paste_item" style="position:relative;margin:5px;">');
    var img = $('<img>', {
      src: e.target.result,
      css:{
        maxWidth:'180px',
        border:'1px solid #ccc',
        borderRadius:'4px'
      }
    });
    var del = $('<span>',{
      html:'&times;',
      css:{
        position:'absolute',
        top:'2px',
        right:'6px',
        cursor:'pointer',
        color:'red',
        fontSize:'21px',
        fontWeight:'bold',
        fontFamily:'FontAwesome'
      }
    });
    del.on('click', function(){
      pastedImages[index] = null;
      wrapper.remove();
    });

    wrapper.append(img).append(del);
    container.append(wrapper);
  };

  reader.readAsDataURL(file);
}

function addImage(file, container){
  var index = pastedImages.length;
  pastedImages.push(file);
  renderPreview(file, index, container);
}

// ===== CTRL+V =====
$(document).on('paste','.info_comment',function(e){
  var container = $(this).closest('.timeline-item').find('.image_paste_preview');
  var items = (e.originalEvent.clipboardData || e.clipboardData).items;

  for (var i=0;i<items.length;i++){
    if(items[i].type.indexOf('image') !== -1){
      var file = items[i].getAsFile();
      addImage(file, container);
    }
  }
});

// ===== DRAG & DROP =====
$(document).on('dragover','.info_comment',function(e){
  e.preventDefault();
});

$(document).on('drop','.info_comment',function(e){
  e.preventDefault();
  var container = $(this).closest('.timeline-item').find('.image_paste_preview');
  var files = e.originalEvent.dataTransfer.files;

  for(var i=0;i<files.length;i++){
    if(files[i].type.indexOf('image') !== -1){
      addImage(files[i], container);
    }
  }
});