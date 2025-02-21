<script src='/styles/default/js/cytoscape.min.js'></script>
<!-- FIXME: popper should have loaded from bootstrap bundle,
            but cytoscape-popper ignores this. -->
<script src='/styles/default/js/popper.min.js'></script>
<script src='/styles/default/js/cytoscape-popper.js'></script>

<script src='/styles/default/js/layout-base.js'></script>
<script src='/styles/default/js/cose-base.min.js'></script>
<script src='/styles/default/js/cytoscape-cola.min.js'></script>

<script src='/styles/default/js/tippy.all.min.js'></script>
<link rel='stylesheet' href='/styles/default/css/tippy.css'/>
<link rel='stylesheet' href='/styles/default/css/modules/equipment/equipment.netmap.css'/>

<div class='row text-left'>
  <div id='scheme_controls' class='card bg-light p-2 m-2 mt-0 w-100'>

    <div class='d-flex bd-highlight'>
      <div class='bd-highlight'>
        <div class='btn-group' role='toolbar'>

          <div class='btn-group'>
            <button type='button' class='btn btn-default dropdown-toggle' data-toggle='dropdown' aria-haspopup='true'
                    aria-expanded='false'>
              <span class='text-success'><i class='fa fa-plus'></i></span>
              <span class='caret'></span>
            </button>
            <ul class='dropdown-menu plus-options' aria-labelledby='dLabel'></ul>
          </div>
          <div class='btn-group'>
            <button id='fit' onclick='cy.fit()' type='button' role='button' class='btn btn-default'>
              _{EQUIPMENT_SCALE_TO_CONTENT}_
            </button>
          </div>
          <div class='btn-group'>
            <button id='layout' type='button' role='button' class='btn btn-default'>
              _{EQUIPMENT_ALIGN}_
            </button>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>
<div id='cy' class='border'>
  <div class='info-table'>
    <table class='table'>
    </table>
  </div>

</div>
<div class='counters-wrap'>
  <div class='node-count'>_{COUNT}_:</div>
  <div class='time-count'>_{TIME}_:</div>
</div>

<div class='d-none' id='EQUIPMENT_ADD_FORM'>
  %EQUIPMENT_ADD_FORM%
</div>

<script>
  var nasList = JSON.parse('%DATA%');
  var types = JSON.parse('%TYPES%');
  var nodes = [];
  var edges = [];
  var nodes_count = 0;
  var tooltipInstances = [];

  var _NO = '_{NO}_' || 'No';
  var _TIME = '_{TIME}_' || 'Time';
  var _MODEL = '_{MODEL}_' || 'Model';
  var _TYPE = '_{TYPE}_' || 'Type';
  var _EQUIPMENT = '_{EQUIPMENT}_' || 'Equipment';
  var _GO = '_{GO}_' || 'Go';
  var _PORT = '_{PORT}_' || 'Port';
  var _COMMENTS = '_{COMMENTS}_' || 'Comments';
  var _CHANGE = '_{CHANGE}_' || 'Change';
  var _EQUIPMENT_ADD_NEW_EQUIPMENT = '_{EQUIPMENT_ADD_NEW_EQUIPMENT}_' || 'Add new equipment';
  var _EQUIPMENT_ADD_PORT_BINDING = '_{EQUIPMENT_ADD_PORT_BINDING}_' || 'Add port binding';

  const EQUIPMENT_ADD_FORM = document.getElementById('EQUIPMENT_ADD_FORM');
  EQUIPMENT_ADD_FORM.remove();
  EQUIPMENT_ADD_FORM.classList.remove('d-none')

  jQuery.each(nasList.nodes, function (k, v) {
    nodes.push({
      data: {
        id: 'n' + k,
        label: v.data.label,
        ip: v.data.ip,
        state: v.data.state,
        type: v.data.type_id,
        model: v.data.model,
        vendor: v.data.vendor,
        port: v.data.port,
        online: v.data.online || 0,
        nasId: v.data?.nas_id
      },
      position: v.data.position
    });
    nodes_count += 1;
  });
  jQuery('.node-count').text('_{COUNT}_: ' + nodes_count);
  jQuery.each(nasList.edges, function (k, v) {
    edges.push({
      data: {
        id: v.source + ' -> ' + v.target,
        source: 'n' + v.source,
        target: 'n' + v.target,
        label: v.name
      }
    });
  });
</script>
<script src='/styles/default/js/modules/equipment/netmap.js'></script>