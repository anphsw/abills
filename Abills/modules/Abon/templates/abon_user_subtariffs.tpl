<script src='/styles/default/js/modules/abon/abon-subtariffs.js'></script>
<script>
  const subTariffs = new SubTariffs({
    formId: 'ABON_USER_TPS',
    requestTimeout: 10000
  });

  var periods = {};

  try {
    periods = JSON.parse('%PERIODS%');

    subTariffs.setPeriods(periods);
  } catch (err) {
    console.log('JSON parse error');
    console.log(err);
  }
</script>