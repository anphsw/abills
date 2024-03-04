<div class='card card-primary card-outline card-form'>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-form-label col-md-4' for='PROJECT_ID'>_{PROJECT}_:</label>
      <div class='col-md-8'>
        %PROJECT_SEL%
      </div>
    </div>
  </div>
</div>

<script>
  jQuery(document).ready(function(){
    jQuery('#PROJECT_ID').change(function(){
      var project_id = jQuery('#PROJECT_ID').val();
      var link = 'index.cgi?index=%INDEX%&PROJECT_ID=' + project_id;
      window.location.assign(link);
    });
  });
</script>