<div class='card card-secondary'>
  <div class='card-header with-border text-center'>
    <h3 class="card-title">_{ADD_FRIEND}_</h3>
  </div>
  <form name='ADD_FRIEND' id='form_ADD_FRIEND' method='post' class='form form-horizontal'>
    <div class='card-body'>
      <input type='hidden' name='index' value='$index'/>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4" for='FIO'>_{FIO}_</label>
        <div class="col-sm-8 col-md-8">
          <input type='text' class='form-control' name='FIO' value='%FIO%' id='FIO'/>
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4" for='PHONE'>_{PHONE}_</label>
        <div class="col-sm-8 col-md-8">
          <input type='text' class='form-control' name='PHONE' value='%PHONE%' id='PHONE'/>
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4" for='ADDRESS'>_{ADDRESS}_</label>
        <div class="col-sm-8 col-md-8">
          <textarea cols="10" class='form-control' name='ADDRESS' id='ADDRESS'>%ADDRESS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      %ACTION%
    </div>
  </form>
</div>

