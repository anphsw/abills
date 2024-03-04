<div>
  <div class='card-header' style='display: none'>
    <h5 class='card-title'>_{PORTAL_ATTACHMENTS}_</h5>
  </div>
  <div class='mb-4'>
    <div class='drop-zone'>
      <span class='drop-soze__prompt'>
        _{DROP_FILE_OR_CLICK_TO_UPLOAD}_
      </span>
      <input class='drop-zone__input' name='file' id='file' type='file' onchange='uploadFile()' />
    </div>
  </div>
  <div class='col'>
    %ATTACHMENT_LIST%
  </div>
</div>

<script>
  function uploadFile() {
    const formDat = new FormData();
    const inputFile = document.getElementById('file').files[0];
    if (!inputFile.type.startsWith('image/')) {
      return;
    }
    formDat.append('file', inputFile);
    var settings = {
      'url': '/api.cgi/portal/attachment/',
      'method': 'POST',
      'timeout': 0,
      'processData': false,
      'mimeType': 'multipart/form-data',
      'contentType': false,
      'data': formDat
    };

    jQuery.ajax(settings).done(function(response) {
      const res = JSON.parse(response);
      onFileUploadSuccess(res);
    });

  };

  function onFileUploadSuccess(res) {
    const src = res?.attachments[0]?.src;

    const portalEditor = document.querySelector('.CodeMirror')?.CodeMirror;

    if (!portalEditor || !src) {
      jQuery('#CurrentOpenedModal').modal('hide');
      location.reload(true);
      return;
    }

    const img = jQuery('<img></img>').prop('src', src).prop('alt', 'Portal').prop('style', 'max-width: 100%');

    let picture = img.prop('outerHTML');

    let value = portalEditor.getValue();
    value = value + picture + '\n';

    portalEditor.setValue(value);
    jQuery('#CurrentOpenedModal').modal('hide');
  }

  document.querySelectorAll('.drop-zone__input').forEach((inputElement) => {
    const dropZoneElement = inputElement.closest('.drop-zone');

    dropZoneElement.addEventListener('click', (e) => {
      inputElement.click();
    });

    inputElement.addEventListener('change', (e) => {
      if (inputElement.files.length) {
        updateThumbnail(dropZoneElement, inputElement.files[0]);
      }
    });

    dropZoneElement.addEventListener('dragover', (e) => {
      e.preventDefault();
      dropZoneElement.classList.add('drop-zone--over');
    });

    ['dragleave', 'dragend'].forEach((type) => {
      dropZoneElement.addEventListener(type, (e) => {
        dropZoneElement.classList.remove('drop-zone--over');
      });
    });

    dropZoneElement.addEventListener('drop', (e) => {
      e.preventDefault();

      if (e.dataTransfer.files.length) {
        inputElement.files = e.dataTransfer.files;
        updateThumbnail(dropZoneElement, e.dataTransfer.files[0]);
      }

      dropZoneElement.classList.remove('drop-zone--over');
    });
  });


  function updateThumbnail(dropZoneElement, file) {
    let thumbnailElement = dropZoneElement.querySelector('.drop-zone__thumb');

    // First time - remove the prompt
    if (dropZoneElement.querySelector('.drop-zone__prompt')) {
      dropZoneElement.querySelector('.drop-zone__prompt').remove();
    }

    // First time - there is no thumbnail element, so lets create it
    if (!thumbnailElement) {
      thumbnailElement = document.createElement('div');
      thumbnailElement.classList.add('drop-zone__thumb');
      dropZoneElement.appendChild(thumbnailElement);
    }

    thumbnailElement.dataset.label = file.name;

    // Show thumbnail for image files
    if (file.type.startsWith('image/')) {
      const reader = new FileReader();

      reader.readAsDataURL(file);
      reader.onload = () => {
        thumbnailElement.style.backgroundImage = `url('${reader.result}')`;
      };
    } else {
      thumbnailElement.style.backgroundImage = null;
    }
  }

</script>
<style>
  .drop-zone {
    max-width: 100%;
    height: 200px;
    padding: 25px;
    display: flex;
    align-items: center;
    justify-content: center;
    text-align: center;
    font-family: 'Quicksand', sans-serif;
    font-weight: 500;
    font-size: 20px;
    cursor: pointer;
    color: #cccccc;
    border: 4px dashed #009578;
    border-radius: 10px;
  }

  .drop-zone--over {
    border-style: solid;
  }

  .drop-zone__input {
    display: none;
  }

  .drop-zone__thumb {
    width: 100%;
    height: 100%;
    border-radius: 10px;
    overflow: hidden;
    background-color: #cccccc;
    background-size: cover;
    position: relative;
  }

  .drop-zone__thumb::after {
    content: attr(data-label);
    position: absolute;
    bottom: 0;
    left: 0;
    width: 100%;
    padding: 5px 0;
    color: #ffffff;
    background: rgba(0, 0, 0, 0.75);
    font-size: 14px;
    text-align: center;
  }
</style>