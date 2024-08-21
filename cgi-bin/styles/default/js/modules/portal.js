/**
 * Created by Anykey on 17.03.2017.
 * Improved by fr0staman on 27.02.2023
 */

var textarea_id = 'news-text';
var unallowedTags = ['svg', 'meta', 'link', 'head', 'header', 'script', 'style', 'img'];
var allowedAttr = ['href', 'src', 'alt'];

function resizeIframe(iframe) {
  const minHeight = 300;
  const bodyHeight = iframe.contentWindow.document.body.scrollHeight + 15;
  iframe.height = (bodyHeight < minHeight ? minHeight : bodyHeight) + "px"
}

function is_html(string) {
  return /<\/?[a-z][\s\S]*>/i.test(string);
}

function fillPreview(cm, e) {
  if (e) {
    cancelEvent(e);
  }
  var previewFrame = document.getElementById('preview');
  var preview      = previewFrame.contentDocument || previewFrame.contentWindow.document;
  
  preview.open();
  
  preview.write(
    '<!DOCTYPE html><html><head>' +
    '<link href="/styles/default/css/adminlte.min.css" rel="stylesheet">' +
    '<link href="/styles/default/css/style.css" rel="stylesheet">' +
    '</head><body>' +
    '<div class=\'container my-3\' id=\'preview_container\'>' +
    '</div></body></html>'
  );

  preview.addEventListener('DOMContentLoaded', function (event) {
    var text = document.querySelector('.CodeMirror').CodeMirror.getValue();
    var replaced_html = text;

    const isRealHtml = is_html(replaced_html);
    if (!isRealHtml) {
      replaced_html = replaced_html.replace(/\n|\r\n/gm, '<br/>');
    }
    preview.getElementById('preview_container').innerHTML = replaced_html;
  });
  
  preview.close();
}

function wrap_text(tag, text) {
  if (tag === 'a') {
    text = text || "TEXT";
    return `<a href="YOUR_URL">${text}</a>`;
  }
  return `<${tag}>${text}</${tag}>`;
}

function cleanHtml(text) {
  var theDiv = jQuery('<div>');
  theDiv.html(text);
  theDiv.find("*").filter(
    function() {
      const thisTag = this.tagName.toLowerCase()
      if (unallowedTags.includes(thisTag)) {
        this.remove();
      }
      return true;
    }
  ).each(function() {
    var attributes = jQuery.map(this.attributes, function(item) {
      return item.name;
    });

    // now use jQuery to remove the attributes
    var element = jQuery(this);
    jQuery.each(attributes, function(i, item) {
      if (allowedAttr.indexOf(item) == -1) {
        element.removeAttr(item);
      }
    });

  });
  const result = theDiv.html();
  return result;
}

function onPaste(cm, change) {
  if (change.origin === 'paste') {
    const copyMode = jQuery('input[name="COPY_MODE"]:checked').val();
    if (copyMode === 'PLAIN') {
      return;
    }
    if (!event || !event?.clipboardData) {
      return;
    }
    var cb = event.clipboardData;

    if (cb.types.indexOf("text/html") != -1) {        // contains html
      var pastedContent = cb.getData("text/html")
    } else if(cb.types.indexOf("text/html") != -1) { // contains text
      var pastedContent = cb.getData("text/html")
    } else {
      var pastedContent = cb.getData(cb.types[0])    // get whatever it has
    }

    let textContent;
    if (copyMode === 'FULL') {
      textContent = pastedContent;
    } else if (copyMode === 'CLEAN') {
      textContent = cleanHtml(pastedContent);
    }
    const splittedContent = textContent.split('\n');
    change.update(null, null, splittedContent);
  }
};

function setupResendButtons() {
  jQuery('[data-method-id]').on('click', function() {
    const thisButton = jQuery(this);
    const methodId = thisButton.data('method-id');
    const articleId = jQuery('[name="id"]').prop('value');
    const [checkbox] = jQuery('[method-id="' + methodId + '"]');
    const type = checkbox.name.substring(NEWSLETTER_CHECKBOX_PREFIX.length)
    const newsletterDatetimeInput = jQuery('[name="' + type + '_START_DATETIME' + '"]');
    const datetime = newsletterDatetimeInput.val();

    thisButton.prop('disabled', 'disabled');
    const loadingLabel = thisButton.data('label-on-loading');

    thisButton.html(loadingLabel);
    _apiCreateNewsletter(methodId, articleId, datetime)
      .then(res => {
        if (!res.ok) {
          throw res;
        }
        return res.json()
      })
      .then(res => {
        const successLabel = thisButton.data('label-on-success');
        thisButton.html(successLabel);
        thisButton.removeClass('btn-success').addClass('btn-info');
      })
      .catch(err => {
        const errorLabel = thisButton.data('label-on-error');
        thisButton.html(errorLabel);
        thisButton.removeClass('btn-success').addClass('btn-danger');
      });

  })
}

function _apiCreateNewsletter(sendMethod, portalArticleId, startDatetime) {
  const body = {
    portalArticleId,
    sendMethod,
    startDatetime
  };

  return fetch("/api.cgi/portal/newsletter", {
    method: "POST",
    body: JSON.stringify(body)
  })
}

const NEWSLETTER_CHECKBOX_PREFIX = 'NEWSLETTER_';

function _fillDatetimeOnClick(e) {
  const type = e.target.name.substring(NEWSLETTER_CHECKBOX_PREFIX.length);
  const newsletterDatetimeInput = jQuery('[name="' + type + '_START_DATETIME' + '"]');
  const dateInput = jQuery('[name="date"]');

  if (!newsletterDatetimeInput.val()) {
    const dateOnly = new Date(dateInput.val() || new Date());
    dateOnly.setHours(12, 0, 0);
    const formattedDate = formatDate(dateOnly, 'yyyy-mm-dd hh:ii:ss')
    newsletterDatetimeInput.val(formattedDate);
  }
}

jQuery(function () {
  var portalEditor = document.querySelector('.CodeMirror').CodeMirror;

  function create_tag_wrap_handler(tag_name) {
    return function (e) {
      cancelEvent(e);
      var selected_text = portalEditor.getSelection();
      var wrapped_text = wrap_text(tag_name, selected_text);
      portalEditor.replaceSelection(wrapped_text);
    }
  }

  // Initialize all controls
  jQuery('div#editor-controls').find('button').each(function (i, btn) {
    var j_btn = jQuery(btn);
    var tag   = j_btn.data('tag');
    
    if (!tag) return;
    
    j_btn.on('click', create_tag_wrap_handler(tag));
  });

  jQuery('#portal_reindent_button').on('click', function() {
    const editorContent = portalEditor.getValue();
    const editorContentFormatted = html_beautify(editorContent, { indent_size: 2 });
    portalEditor.setValue(editorContentFormatted);
    portalEditor.refresh();
  });

  jQuery('[name^="'+ NEWSLETTER_CHECKBOX_PREFIX + '"]').on('click', _fillDatetimeOnClick);

  fillPreview();
  portalEditor.on('beforeChange', onPaste);
  portalEditor.on('change', fillPreview);
  setupResendButtons();
});
