<hr>

<div class='form-group row' style='%EXT_SEL_STYLE%'>
  <label
      class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-TERRITORIAL-UNITS'>%TERRITORIAL_UNITS_LABEL%:</label>
  <div class='col-sm-9 col-md-8'>
    %TERRITORIAL_UNITS_SEL%
  </div>
</div>

%ADDRESS_TERRITORIAL_UNITS_SUBSELECT%

<hr>

<script>
  if (typeof UniversalNestedSelector === 'undefined') {
    const script = document.createElement('script');
    script.src = '/styles/default/js/universal-nested-selector.js';
    script.onload = () => {
      initTerritorialUnitsSelector();
    };
    document.head.appendChild(script);
  } else {
    initTerritorialUnitsSelector();
  }

  function initTerritorialUnitsSelector() {
    new UniversalNestedSelector({
      apiEndpoint: '/api.cgi/districts/territorial_units',
      selectName: 'TERRITORIAL_UNITS_SEL',
      identifierField: '%TERRITORIAL_UNITS_IDENTIFIER%',
      selectedField: '%TERRITORIAL_UNITS_SELECTED%',
      idField: '%TERRITORIAL_UNITS_IDENTIFIER%',
      containerClass: 'territorial-units-subselect',
      customEventPrefix: 'territorial-unit',
      optionTemplate: (item) => `${item.name}${item.code ? ' [' + item.code + ']' : ''}`,
      apiParams: {
        parentIdParam: 'PARENT_ID',
        parentNameParam: 'CODE',
        idParam: 'ID',
        pageRowsParam: 'PAGE_ROWS',
        extraParams: {NAME: '_SHOW'}
      }
    });
  }
</script>