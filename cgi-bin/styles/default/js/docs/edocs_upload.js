'use strict';

jQuery(document).ready(() => {
  jQuery('.edocs_upload_button').on('click', async function() {
    let uploadBtn = jQuery(this);

    const res = await sendRequest(`/api.cgi/docs/edocs/documents/`,
      { invoiceId: jQuery(this).attr('value') }, 'POST');

    if (res?.errstr || res?.error) {
      displayJSONTooltip({MESSAGE: {caption: res?.errmsg || res?.errstr || res?.errno, message_type: 'err'}});
      return 1;
    }

    let extId = res?.extId || res?.ext_id;
    if (extId) {
      uploadBtn.children().removeClass('fa fa-cloud-upload-alt p-1').addClass('fa fa-file-signature p-1');
      uploadBtn.removeClass('edocs_upload_button');
      uploadBtn.on('click', function() {
        window.open(`?get_index=docs_esign_documents&full=1&EXT_ID=${extId}`);
      });
    }
  });
});
