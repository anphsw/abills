function initMultifileUploadZone(id, name_, max_files_, dropZoneId) {
  const CONFIG = {
    name: name_ || 'FILE_UPLOAD',
    maxFiles: max_files_ || 2
  };

  const elements = {
    fileZone: jQuery('#' + id),
    dropZone: jQuery('#' + dropZoneId),
    mainInput: null,
    counterInput: null
  };

  let fileCounter = 0;

  function initializeElements() {
    elements.mainInput = elements.fileZone.find('input[name="' + CONFIG.name + '"]');
    elements.counterInput = jQuery('<input/>', {
      name: CONFIG.name + '_UPLOADS_COUNT',
      type: 'hidden'
    });
    elements.fileZone.append(elements.counterInput);
  }

  function updateInputs() {
    const inputs = elements.fileZone.find('input[type="file"]');
    const filledInputs = [];
    const emptyInputs = [];

    inputs.each(function() {
      const input = jQuery(this);
      if (input.prop('files').length > 0) {
        filledInputs.push(input);
      } else {
        emptyInputs.push(input);
      }
    });

    emptyInputs.forEach(input => input.parent().remove());

    fileCounter = 0;
    filledInputs.forEach(input => {
      fileCounter++;
      const inputName = fileCounter === 1 ? CONFIG.name : CONFIG.name + '_' + (fileCounter - 1);
      input.attr('name', inputName).data('number', fileCounter - 1);
    });

    elements.counterInput.val(fileCounter);

    if (fileCounter < CONFIG.maxFiles) {
      createNewInput();
    }
  }

  function createNewInput() {
    const newInput = jQuery('<input/>', {
      type: 'file',
      name: CONFIG.name
    });

    newInput.data('number', -1);
    newInput.on('change', handleInputChange);

    const formGroup = jQuery('<div/>', { class: 'form-group m-1' });
    formGroup.append(newInput);
    elements.fileZone.append(formGroup);

    return newInput;
  }

  function handleInputChange() {
    if (this.files.length > 0) {
      updateInputs();
    }
  }

  function createThumbnail(file, inputElement) {
    const reader = new FileReader();
    reader.readAsDataURL(file);

    reader.onload = function(event) {
      const container = createThumbnailContainer(event.target.result, inputElement);
      elements.dropZone.parent().append(container);
    };
  }

  function createThumbnailContainer(imageSrc, inputElement) {
    const container = document.createElement('div');
    container.style.cssText = 'display: inline-block; margin: 5px; padding: 5px; border: 1px solid #ddd; border-radius: 4px; background: #f9f9f9; position: relative;';

    const img = new Image();
    img.src = imageSrc;
    img.style.cssText = 'height: 100px; display: block;';

    const deleteBtn = createDeleteButton(inputElement, container);

    container.appendChild(img);
    container.appendChild(deleteBtn);

    return container;
  }

  function createDeleteButton(inputElement, container) {
    const deleteBtn = document.createElement('button');
    deleteBtn.textContent = '✕';
    deleteBtn.style.cssText = 'position: absolute; top: 2px; right: 2px; background: #ff4444; color: white; border: none; border-radius: 50%; width: 20px; height: 20px; cursor: pointer; font-size: 12px;';

    deleteBtn.addEventListener('click', function(e) {
      e.preventDefault();
      handleFileDelete(inputElement, container);
    });

    return deleteBtn;
  }

  function handleFileDelete(inputElement, container) {
    // Очищаємо input
    inputElement.val('');
    inputElement.prop('files', null);

    container.remove();

    updateInputs();
  }

  function createFileListItem(fileName) {
    const listItem = document.createElement('li');
    listItem.textContent = fileName;
    elements.dropZone.parent().append(listItem);
  }

  function findEmptyInput() {
    return elements.fileZone.find('input[type="file"]').filter(function() {
      return this.files.length === 0;
    }).first();
  }

  function handleFiles(files) {
    for (let i = 0; i < files.length && fileCounter < CONFIG.maxFiles; i++) {
      const file = files[i];
      let emptyInput = findEmptyInput();

      if (emptyInput.length === 0) {
        emptyInput = createNewInput();
      }

      emptyInput[0].files = files;

      if (file.type.indexOf('image/') >= 0) {
        createThumbnail(file, emptyInput);
      } else {
        createFileListItem(file.name);
      }
    }

    updateInputs();
  }

  function initializeDragAndDrop() {
    if (elements.dropZone.length === 0) return;

    elements.dropZone.on('drop', function(e) {
      elements.dropZone.css('border', '');
      e.preventDefault();
      e.stopPropagation();

      const files = e.originalEvent.dataTransfer.files;
      handleFiles(files);
    });

    elements.dropZone.on('dragover', function(e) {
      elements.dropZone.css('border', 'medium solid #0000FF');
      e.preventDefault();
      e.stopPropagation();
    });

    elements.dropZone.on('dragleave', function(e) {
      elements.dropZone.css('border', '');
    });

    elements.dropZone.on('paste', function(e) {
      const clipboard = e.originalEvent.clipboardData;
      if (clipboard && clipboard.files && clipboard.files.length > 0 && fileCounter < CONFIG.maxFiles) {
        e.preventDefault();
        handleFiles(clipboard.files);
      }
    });
  }

  function initialize() {
    initializeElements();

    elements.mainInput.on('change', handleInputChange);

    initializeDragAndDrop();

    if (elements.fileZone.find('input[type="file"]').length === 0) {
      createNewInput();
    }
  }

  initialize();
}