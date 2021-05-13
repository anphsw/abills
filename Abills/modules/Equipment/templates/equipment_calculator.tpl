<style>
  .buttons .btn {
    margin-top: 5px;
  }
</style>

<FORM action='$SELF_URL' METHOD='POST' class='form calculator-form'>
  <input type='hidden' name='index' value='$index'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h3 class="card-title"> _{CALCULATOR}_</h3>
    </div>
    <div class='card-body'>


      <div class='form-group'>
        <div class="row">
          <label class='control-label col-md-3 col-md-offset-1'>_{TYPE}_</label>

          <div class='col-md-7 control-element'>
            %TYPE%
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class="row">
          <label class='control-label col-md-3 col-md-offset-1'>_{CABLE_LENGTH}_</label>

          <div class='col-md-7 control-element'>
            %LENGTH%
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class="row">
          <label class='control-label col-md-3 col-md-offset-1'>_{CON_COUNT}_</label>

          <div class='col-md-7 control-element'>
            %COUNT%
          </div>
        </div>
      </div>

      <div id="add">

      </div>

      <div class="form-group answer h4">

      </div>

      <div class='form-group buttons'>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 5/95', 'coupler', 1, {'0.3': '_{PASS}_', '13': '_{BEND}_'})">_{COUPLER}_
          5/95
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 10/90', 'coupler', 1, {'0.5': '_{PASS}_', '10': '_{BEND}_'})">
          _{COUPLER}_ 10/90
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 15/85', 'coupler', 1, {'0.8': '_{PASS}_', '8.3': '_{BEND}_'})">
          _{COUPLER}_ 15/85
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 20/80', 'coupler', 1, {'1': '_{PASS}_', '7': '_{BEND}_'})">_{COUPLER}_
          20/80
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 25/75', 'coupler', 1, {'1.5': '_{PASS}_', '6.3': '_{BEND}_'})">
          _{COUPLER}_ 25/75
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 30/70', 'coupler', 1, {'0.7': '_{PASS}_', '5.4': '_{BEND}_'})">
          _{COUPLER}_ 30/70
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 35/65', 'coupler', 1, {'2': '_{PASS}_', '4.7': '_{BEND}_'})">_{COUPLER}_
          35/65
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 40/60', 'coupler', 1, {'2.2': '_{PASS}_', '4': '_{BEND}_'})">_{COUPLER}_
          40/60
        </button>
        <button type="button" class="btn btn-primary"
                onclick="generate_input('_{COUPLER}_ 45/55', 'coupler', 1, {'2.8': '_{PASS}_', '3.7': '_{BEND}_'})">
          _{COUPLER}_ 45/55
        </button>
      </div>
      <div class='form-group buttons'>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/2', 'divider', 2, '3.6')">
          _{DIVIDER}_ 1/2
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/3', 'divider', 2, '6.1')">
          _{DIVIDER}_ 1/3
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/4', 'divider', 2, '7.2')">
          _{DIVIDER}_ 1/4
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/6', 'divider', 2, '8.5')">
          _{DIVIDER}_ 1/6
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/8', 'divider', 2, '11.4')">
          _{DIVIDER}_ 1/8
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/10', 'divider', 2, '11.8')">
          _{DIVIDER}_ 1/10
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/12', 'divider', 2, '12.5')">
          _{DIVIDER}_ 1/12
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/16', 'divider', 2, '15')">
          _{DIVIDER}_ 1/16
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/24', 'divider', 2, '16.5')">
          _{DIVIDER}_ 1/24
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/32', 'divider', 2, '17.5')">
          _{DIVIDER}_ 1/32
        </button>
        <button type="button" class="btn btn-primary" onclick="generate_input('_{DIVIDER}_ 1/36', 'divider', 2, '20')">
          _{DIVIDER}_ 1/36
        </button>
      </div>
    </div>
    <div class='card-footer'>
      <button type="button" class="btn btn-primary calculate">_{CALCULATE}_</button>
    </div>

  </div>
</FORM>

<script>

  function generate_input(label, name, type, data) {
    var rund = Math.floor(Math.random() * (99999 - 999)) + 999,
      data_;
    if (type === 1) {
      data_ = JSON.stringify(data);
    } else if (type === 2) {
      data_ = data;
    }
    jQuery.ajax({
      url: '$SELF_URL',
      type: "POST",
      data: {
        generate_input: 1,
        LABEL: label,
        NAME: name + rund,
        header: 2,
        qindex: '$index',
        TYPE: type,
        DATA: data_
      },
      success: function (resp) {
        jQuery(add).append(resp);
        initChosen();
      }
    });
  }

  jQuery(document).on('click', '.del', function () {
    jQuery(this).parent().parent().parent().remove();
  });
  jQuery(document).on('click', '.calculate', function () {
    var form = jQuery('.calculator-form'),
      data = form.serializeArray();
    data.shift();
    data = objectifyForm(data);
    var result = parseFloat(data['TYPE']);
    jQuery.each(data, function (k, v) {
      result -= parseFloat(v);
    });

    result += parseFloat(data['TYPE']);
    result += parseFloat(data['LENGTH']);
    result += parseFloat(data['COUNT']);


    result = result - (parseFloat(data['LENGTH']) * 0.36) - (parseFloat(data['COUNT']) * 0.5)

    jQuery('.answer').html("_{SIGNAL}_: "+result.toFixed(2));

  });

  function objectifyForm(form) {
    var arr = {};
    for (var i = 0; i < form.length; i++) {
      arr[form[i]['name']] = form[i]['value'];
    }
    return arr;
  }

</script>