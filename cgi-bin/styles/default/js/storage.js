function selectArticles(self, empty_sel = false, required = false) {
  let empty_search = empty_sel ? "&EMPTY_SEL=1" : "";
  let required_type = required ? '&REQUIRED=1' : '';

  jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_main&SHOW_SELECT=1&ARTICLE_TYPE_ID=' +
    jQuery(self).val() + empty_search + required_type, function (result) {
    jQuery("div.ARTICLES_S").empty();
    jQuery("div.ARTICLES_S").html(result);
    initChosen();
  });
}

$(function () {

  var initAddBuildMenu = function () {

    jQuery('a.BUTTON-ENABLE-ADD').click(function (e) {
      e.preventDefault();
      jQuery('.addInvoiceMenu').hide();
      jQuery('.changeInvoiceMenu').show();
      jQuery('#INVOICE_ID').attr('disabled', 'disabled');
    });
    jQuery('a.BUTTON-ENABLE-SEL').click(function (e) {
      e.preventDefault();
      jQuery('#INVOICE_ID').removeAttr('disabled');
      jQuery('.addInvoiceMenu').show();
      jQuery('.changeInvoiceMenu').hide();
    });
  };

  initAddBuildMenu();


  jQuery('#SELL_PRICE,#COUNT').on('input', function () {
    if (jQuery('#SUM').attr('readonly') || jQuery('#COUNT').attr('readonly')) return;

    let count = parseInt(jQuery('#COUNT').val(), 10);
    let sellPrice = parseFloat(jQuery('#SELL_PRICE').val().replace(',', '.'));

    if (!isNaN(count) && count > 0 && !isNaN(sellPrice) && sellPrice > 0) {
      jQuery('#SUM').val((count * sellPrice));
    } else {
      jQuery('#SUM').val('');
    }
  });

  $(function() {
    $('[data-storage-invoice-select2-ajax]').each(function() {
      var $select = $(this);
      var ajaxUrl = $select.data('ajax-url');

      $select.select2({
        ajax: {
          url: ajaxUrl,
          dataType: 'json',
          delay: 250,
          data: function(params) {
            return {
              INVOICE_NUMBER: params.term ? `*${params.term}*` : '',
              INVOICE_DATE: params.term ? `*${params.term}*` : '',
              ID: params.term ? `*${params.term}*` : '',
              _MULTI_HIT: 1,
              PAGE_ROWS: 50,
              SORT: 'id',
              DESC: 'DESC'
            };
          },
          processResults: function(data, params) {
            let results = [];
            if (!data.list || !data.total) return { results: results };
            jQuery.each(data.list, function (i, val) {
              results.push({
                id: val.id,
                text: val.id + ' ' + (val?.invoiceNumber || val?.invoice_number || '') + ' : ' + val?.date
              });
            });

            return {
              results: results,
            };
          },
          cache: true
        },
        minimumInputLength: 0,
        placeholder: '',
        allowClear: true,
        width: '100%'
      });
    });
  });

});