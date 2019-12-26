<div class="col-md-8 col-md-offset-2">

  <form id="%ACTION%Form">
    <input type=hidden name=qindex value=%INDEX%>
    <input type=hidden name=header value='2'>
    <input type=hidden name=module value=%MODULE%>
    <input type=hidden name=action value=%ACTION%>

    <div class='box box-theme form-horizontal'>
      <div class='box-heading with-border'><h4 class='box-title'>%ACTION%</h4></div>

      <div class='box-body'>

        %INPUTS%

        <div class='box-footer'>
          <button id="%ACTION%Submit" type='button' class='btn btn-primary'>_{START_PAYSYS_TEST}_</button>
        </div>
      </div>
    </div>
  </form>
  <div class='box box-theme form-horizontal' id="%ACTION%Box" style="display: none">

    <div class='box-body' id="%ACTION%Results"></div>
  </div>

  <script>
    jQuery(function () {
      jQuery('#%ACTION%Submit').on('click', function () {
        var data = jQuery('#%ACTION%Form').serialize();

        jQuery.post("/admin/index.cgi", data, function (result) {
          jQuery('#%ACTION%Results').html(result);
          jQuery('#%ACTION%Box').show();
        });

      });

    });
  </script>

</div>