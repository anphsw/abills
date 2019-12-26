function selectArticles(empty_sel) {
  console.log("Changed");
  empty_search = "";
  if(empty_sel == 1){
    empty_search = "&EMPTY_SEL=" + empty_sel;
  }
  jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_main&SHOW_SELECT=1&ARTICLE_TYPE_ID=' + jQuery('#ARTICLE_TYPE_ID').val() + empty_search, function (result) {
    jQuery("div.ARTICLES_S").empty();
    jQuery("div.ARTICLES_S").html(result);
    initChosen();
    console.log(result);
  });

  console.log("Ending");
};





$(function () {

  var initAddBuildMenu = function () {

    jQuery('a.BUTTON-ENABLE-ADD').click(function (e) {
      e.preventDefault();
      jQuery('.addInvoiceMenu').hide();
      jQuery('.changeInvoiceMenu').show();
    });
    jQuery('a.BUTTON-ENABLE-SEL').click(function (e) {
      e.preventDefault();
      jQuery('.addInvoiceMenu').show();
      jQuery('.changeInvoiceMenu').hide();
    });
  };

  initAddBuildMenu();

});