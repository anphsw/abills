<form action=$SELF_URL name='storage_filter_installation' method=POST>
  <input type=hidden name=index value=$index>
  <input type=hidden name=search value=1>

  <fieldset>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'><h4 class='box-title'>_{SEARCH}_</h4></div>
      <div class='box-body form form-horizontal'>

        <div class='form-group'>
          <label class='col-md-3 control-label' for='LOGIN'>_{USER}_</label>
          <div class='col-md-9'>
            <input type=text name='LOGIN' class='form-control' value='%LOGIN%' id='LOGIN' />
          </div>
        </div>

        <!--<div class='form-group'>-->
          <!--<label class='col-md-3 control-label'>_{ADMIN}_</label>-->
          <!--<div class='col-md-9'>%AID%</div>-->
        <!--</div>-->

        <div class='form-group'>
          <label class='col-md-3 control-label'>_{INSTALLED}_</label>
          <div class='col-md-9'>%INSTALLED_AID%</div>
        </div>

        <div class='form-group'>
          <label class='col-md-3 control-label'>_{RESPOSIBLE}_ _{FOR_INSTALLATION}_</label>
          <div class='col-md-9'>
            %INSTALLED_AID_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='col-md-3 control-label' for='ARTICLE_SEARCH_id'>_{ARTICLE}_</label>
          <div class='col-md-9'>
            <select name='STORAGE_ARTICLE_ID' id='ARTICLE_SEARCH_id' class='form-control normal-width'>
              <option value='' %SEARCH_STORAGE_ARTICLE_EMPTY_STATE%>_{LIVE_SEARCH}_</option>
              <option value='%SEARCH_STORAGE_ARTICLE_ID%' %SEARCH_STORAGE_ARTICLE_STATE%>%SEARCH_STORAGE_ARTICLE_NAME%</option>
            </select>
          </div>
        </div>

        <div class='form-group'>
          <label class='col-md-3 control-label' for='ARTICLE_SEARCH_id'>SN</label>
          <div class='col-md-9'>
            <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
          </div>
        </div>

        <div class='form-group'>
          <label class='col-md-3 control-label'>_{STATUS}_</label>
          <div class='col-md-9'>
            %STATUS%
          </div>
        </div>

        <hr>

        <div class='form-group'>
          <label class='col-md-12 text-center text-bold '>_{DATE}_: </label>
          <div class='col-md-1'>
            <input type='checkbox' class='form-control-static' data-input-enables='DATE'/>
          </div>
          <div class='col-md-11'>%DATE_SELECT%</div>
        </div>

        <hr>

        %ADDRESS_FORM%
      </div>
      <div class='box-footer'>
        <input class='btn btn-primary' type=submit name=show_installation value='_{SHOW}_'>
      </div>
    </div>
  </fieldset>
</form>

<script>
//  jQuery.getScript('/styles/default_adm/js/ajax-chosen.jquery.min.js', function () {
//    jQuery('select#ARTICLE_SEARCH_id').ajaxChosen({
//          jsonTermKey: 'quick_search',
//          type       : 'GET',
//          url        : '/admin/index.cgi',
//          dataType   : 'json',
//          data       : {
//            qindex           : '$index',
//            header           : 2,
//            show_installation: 1,
//            search_type      : 1
//          }
//        },
//        function (data) {
//          var results = [];
//          console.log(data);
//
//          if (data) {
//            jQuery.each(data, function (i, val) {
//              results.push({
//                value: val.id,
//                text : val.type_name + ' : ' + val.name
//              });
//            });
//          }
//
//          return results;
//        });
//  });

jQuery(document).ready(function() {

  jQuery('select#ARTICLE_SEARCH_id').select2({
    ajax: {
      url        : '/admin/index.cgi',
      dataType   : "json",
      type       : "POST",
      quietMillis: 50,
      data: function(term) {
        return {
          quick_search: term.term,
          qindex: '$index',
          header: 2,
          show_installation: 1,
          search_type: 1
        }
    },
    processResults : function(data) {
      var results = [];
          console.log(data);

          if (data) {
            jQuery.each(data, function (i, val) {
              results.push({
                id: val.id,
                text : val.type_name + ' : ' + val.name
              });
            });
          }

          return {results: results};
    }
      // Additional AJAX parameters go here; see the end of this chapter for the full code of this example
    }
  });
});
</script>