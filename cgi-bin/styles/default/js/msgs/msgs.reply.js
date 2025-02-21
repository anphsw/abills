jQuery(function () {
  jQuery('#btn-bold').on('click', function() {
    const textarea = document.getElementById('REPLY_TEXT') || document.getElementById('MESSAGE');

    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;

    if (start !== end) {
      const beforeSelection = textarea.value.substring(0, start);
      const selectedText = textarea.value.substring(start, end);
      const afterSelection = textarea.value.substring(end);

      textarea.value = beforeSelection + "*" + selectedText + "*" + afterSelection;
    } else {
      textarea.value += '**';

      const newCursorPosition = textarea.value.length - 1;
      textarea.setSelectionRange(newCursorPosition, newCursorPosition);
    }
    textarea.focus();
  });

  function wrapSelectionWithTags(textarea, openingTag, closingTag) {
    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;

    if (start !== end) {
      const beforeSelection = textarea.value.substring(0, start);
      const selectedText = textarea.value.substring(start, end);
      const afterSelection = textarea.value.substring(end);

      textarea.value = beforeSelection + openingTag + selectedText + closingTag + afterSelection;

      const newCursorPosition = start + openingTag.length + selectedText.length + closingTag.length;
      textarea.setSelectionRange(newCursorPosition, newCursorPosition);
    } else {
      textarea.value += openingTag + closingTag;

      const newCursorPosition = textarea.value.length - closingTag.length;
      textarea.setSelectionRange(newCursorPosition, newCursorPosition);
    }

    textarea.focus();
  }

  jQuery('#btn-spoiler').on('click', function() {
    const textarea = document.getElementById('REPLY_TEXT') || document.getElementById('MESSAGE');
    wrapSelectionWithTags(textarea, '[HIDDEN]', '[/HIDDEN]');
  });

  jQuery('#btn-code').on('click', function() {
    const textarea = document.getElementById('REPLY_TEXT') || document.getElementById('MESSAGE');
    wrapSelectionWithTags(textarea, '[CODE]', '[/CODE]');
  });


  jQuery('.spoiler').on('click', function () {
    const spoilerText = jQuery(this).find('.spoiler-text');

    if (!spoilerText.hasClass('visible')) {
      spoilerText.addClass('visible');
      jQuery(this).addClass('active');
    }
  });
});