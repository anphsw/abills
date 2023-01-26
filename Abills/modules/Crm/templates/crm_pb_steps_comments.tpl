<ul class='nav nav-pills mb-3 btn-group w-100' id='pills-tab' role='tablist'>
  %PILLS%
</ul>


<div class='tab-content'>
  %TIMELINE%
</div>

<script>
  jQuery(`[name='ACTION_ID']`).on('change', actionPanel);

  function actionPanel() {
    let action_id = jQuery(this).val();
    let parent = jQuery(this).parent().parent().parent();
    let plan_date = parent.find(`[name='PLANNED_DATE']`).parent().parent();
    let priority = parent.find(`[name='PRIORITY']`).parent().parent().parent();

    if (action_id) {
      plan_date.show();
      priority.show();
      return;
    }

    plan_date.hide();
    priority.hide();
  }
</script>
