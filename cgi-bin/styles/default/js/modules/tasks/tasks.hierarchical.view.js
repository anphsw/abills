let task_id = jQuery('#TASK_ID').val();
var chart = null;
let dragNode;
let dropNode;
let dragStartX;
let dragStartY;
let isDragStarting = false;
const addFakeRootNode = jQuery('#ADD_FAKE_ROOT_NODE').val();
const fakeRootNodeId = addFakeRootNode ? 'fake-root' : '';

sendRequest(`/api.cgi/tasks/?PARENT_ID&SUBTASKS_OF=${task_id}&PAGE_ROWS=65500`, {}, 'GET').then((data) => {
  data = data.list;
  data.forEach(item => {
    if (item.id == task_id) item.parentId = '';
    if (!item.parentId) item.parentId = '';
  });

  if (addFakeRootNode) {
    const fakeRoot = {
      id: fakeRootNodeId,
      parentId: null,
      name: '',
      descr: '',
      _expanded: true,
      expanded: true,
      fakeNode: true
    };

    data.unshift(fakeRoot);

    data.forEach(item => {
      if (item.parentId === '') {
        item.parentId = fakeRootNodeId;
      }
    });
  }

  chart = new d3.OrgChart()
    .nodeWidth((d) => 280)
    .initialZoom(0.7)
    .nodeHeight((d) => 140)
    .childrenMargin((d) => 50)
    .compactMarginBetween((d) => 25)
    .compactMarginPair((d) => 50)

    .siblingsMargin((d) => 25)
    .neighbourMargin((a, b) => 20)
    .nodeContent(function (d, i, arr, state) {
      return generateContentWithButton(d);
    })
    .container('.chart-container')
    .nodeEnter(function (node) {
      d3.select(this).call(
        d3
          .drag()
          .on('start', function (d, node) {
            onDragStart(this, d, node);
          })
          .on('drag', function (dragEvent, node) {
            onDrag(this, dragEvent);
          })
          .on('end', function (d) {
            onDragEnd(this, d);
          })
      );
    })
    .data(data)
    .render()
    .expandAll()
    .fit();

});

function addChildNode(parentId, event) {
  event.preventDefault();
  let confirmModal = new AModal();
  confirmModal
    .setBody(getNewNodeForm())
    .addButton(_CANCEL, 'confirmModalCancelBtn', 'default')
    .addButton(_ADD, 'confirmModalConfirmBtn', 'success')
    .show(function () {
      jQuery('#TASK_TYPE').select2({width: '100%'});
      jQuery('#RESPONSIBLE').select2({width: '100%'});
      jQuery('#CONTROL_DATE').datepicker({
        autoclose: true,
        format: 'yyyy-mm-dd',
        startDate: new Date(),
        todayHighlight: true,
        clearBtn: true,
        forceParse: false
      }).on('show', cancelEvent).on('hide', cancelEvent);
      jQuery('#confirmModalConfirmBtn').on('click', function () {

        sendRequest(`/api.cgi/tasks/`, {
          parentId: parentId,
          name: jQuery('#TASK_NAME').val(),
          descr: jQuery('#TASK_DESCR').val(),
          task_type: jQuery('#TASK_TYPE').val(),
          responsible: jQuery('#RESPONSIBLE').val(),
          control_date: jQuery('#CONTROL_DATE').val()
        }, 'POST')
          .then(data => {
            if (!data.insertId) {
              confirmModal.hide();
              return;
            }

            chart.addNode({
              id: data.insertId,
              parentId: parentId,
              name: jQuery('#TASK_NAME').val(),
              descr:  jQuery('#TASK_DESCR').val(),
              _expanded: true,
              expanded: true
            });
            confirmModal.hide();
          })
          .catch(err => {
            console.log(err);
            confirmModal.hide();
          });
      });

      jQuery('#confirmModalCancelBtn').on('click', function () {
        confirmModal.hide();
      });
    });
}

function getNewNodeForm(attr = {}) {
  const formContainer = jQuery('<div></div>');

  const taskTypeGroup = jQuery('<div>', {class: 'form-group row'});
  taskTypeGroup.append(
    jQuery('<label>', {
      class: 'col-md-4 col-form-label text-md-right required',
      for: 'TASK_TYPE',
      text: `${_TASK_TYPE}:`
    })
  );
  const taskTypeDiv = jQuery('<div>', {class: 'col-md-8'});
  const taskTypeSelect = jQuery('<select>', {
    name: 'TASK_TYPE',
    required: 'required',
    id: 'TASK_TYPE',
    class: 'form-control',
    value: (attr.taskType || '')
  });

  Object.keys(TASK_TYPES).forEach(type => {
    taskTypeSelect.append(new Option(TASK_TYPES[type], type))
  });
  taskTypeDiv.append(taskTypeSelect);
  taskTypeGroup.append(taskTypeDiv);
  formContainer.append(taskTypeGroup);

  const taskNameGroup = jQuery('<div>', {class: 'form-group row'});
  taskNameGroup.append(
    jQuery('<label>', {
      class: 'col-md-4 col-form-label text-md-right required',
      for: 'TASK_NAME',
      text: `${_TASK_NAME}:`
    })
  );
  const taskNameDiv = jQuery('<div>', {class: 'col-md-8'});
  const taskNameInput = jQuery('<input>', {
    class: 'form-control',
    name: 'NAME',
    id: 'TASK_NAME',
    required: ''
  });
  taskNameDiv.append(taskNameInput);
  taskNameGroup.append(taskNameDiv);
  formContainer.append(taskNameGroup);

  const taskDescrGroup = jQuery('<div>', {class: 'form-group row'});
  taskDescrGroup.append(
    jQuery('<label>', {
      class: 'col-md-4 col-form-label text-md-right required',
      for: 'TASK_DESCR',
      text: `${_TASK_DESCRIBE}:`
    })
  );
  const taskDescrDiv = jQuery('<div>', {class: 'col-md-8'});
  const taskDescrTextarea = jQuery('<textarea>', {
    class: 'form-control',
    rows: '5',
    name: 'DESCR',
    id: 'TASK_DESCR'
  });
  taskDescrDiv.append(taskDescrTextarea);
  taskDescrGroup.append(taskDescrDiv);
  formContainer.append(taskDescrGroup);

  const responsibleGroup = jQuery('<div>', {class: 'form-group row'});
  responsibleGroup.append(
    jQuery('<label>', {
      class: 'col-md-4 col-form-label text-md-right required',
      for: 'RESPONSIBLE',
      text: `${_RESPONSIBLE}:`
    })
  );
  const responsibleDiv = jQuery('<div>', {class: 'col-md-8'});
  const responsibleSelect = jQuery('<select>', {
    name: 'RESPONSIBLE',
    required: 'required',
    id: 'RESPONSIBLE',
    class: 'form-control'
  });
  Object.keys(ADMINS_HASH).forEach(aid => {
    responsibleSelect.append(new Option(ADMINS_HASH[aid], aid))
  });
  responsibleDiv.append(responsibleSelect);
  responsibleGroup.append(responsibleDiv);
  formContainer.append(responsibleGroup);

  const controlDateGroup = jQuery('<div>', {class: 'form-group row'});
  controlDateGroup.append(
    jQuery('<label>', {
      class: 'col-md-4 col-form-label text-md-right',
      for: 'CONTROL_DATE',
      text: `${_DUE_DATE}:`
    })
  );
  const controlDateDiv = jQuery('<div>', {class: 'col-md-8'});
  const controlDateInput = jQuery('<input>', {
    type: 'text',
    class: 'datepicker form-control',
    value: '2024-11-21',
    name: 'CONTROL_DATE',
    id: 'CONTROL_DATE'
  });
  controlDateDiv.append(controlDateInput);
  controlDateGroup.append(controlDateDiv);
  formContainer.append(controlDateGroup);

  return formContainer.html();
}

function onDragStart(element, dragEvent, node) {
  if (addFakeRootNode && node.id === fakeRootNodeId) {
    dragNode = null;
    return;
  }

  dragNode = node;
  const width = dragEvent.subject.width;
  const half = width / 2;
  const x = dragEvent.x - half;
  dragStartX = x;
  dragStartY = parseFloat(dragEvent.y);
  isDragStarting = true;

  d3.select(element).classed('dragging', true);
}

function onDrag(element, dragEvent) {
  if (!dragNode) {
    return;
  }

  const state = chart.getChartState();
  const g = d3.select(element);

  if (isDragStarting) {
    isDragStarting = false;
    document
      .querySelector('.chart-container')
      .classList.add('dragging-active');

    g.raise();

    const descendants = dragEvent.subject.descendants();
    const linksToRemove = [...(descendants || []), dragEvent.subject];
    const nodesToRemove = descendants.filter(
      (x) => x.data.id != dragEvent.subject.id
    );

    state['linksWrapper']
      .selectAll('path.link')
      .data(linksToRemove, (d) => state.nodeId(d))
      .remove();

    if (nodesToRemove) {
      state['nodesWrapper']
        .selectAll('g.node')
        .data(nodesToRemove, (d) => state.nodeId(d))
        .remove();
    }
  }

  dropNode = null;
  const cP = {
    width: dragEvent.subject.width,
    height: dragEvent.subject.height,
    left: dragEvent.x,
    right: dragEvent.x + dragEvent.subject.width,
    top: dragEvent.y,
    bottom: dragEvent.y + dragEvent.subject.height,
    midX: dragEvent.x + dragEvent.subject.width / 2,
    midY: dragEvent.y + dragEvent.subject.height / 2,
  };

  const allNodes = d3.selectAll('g.node:not(.dragging)');
  allNodes.select('rect').attr('fill', 'none');

  allNodes
    .filter(function (d2, i) {
      const cPInner = {
        left: d2.x,
        right: d2.x + d2.width,
        top: d2.y,
        bottom: d2.y + d2.height,
      };

      if (
        cP.midX > cPInner.left &&
        cP.midX < cPInner.right &&
        cP.midY > cPInner.top &&
        cP.midY < cPInner.bottom
      ) {
        dropNode = d2;
        return d2;
      }
    })
    .select('rect')

  dragStartX += parseFloat(dragEvent.dx);
  dragStartY += parseFloat(dragEvent.dy);
  g.attr('transform', 'translate(' + dragStartX + ',' + dragStartY + ')');
}

function onDragEnd(element, dragEvent) {
  document
    .querySelector('.chart-container')
    .classList.remove('dragging-active');

  if (!dragNode) {
    return;
  }

  d3.select(element).classed('dragging', false);

  if (!dropNode) {
    chart.render();
    return;
  }

  if (dragEvent.subject.parent.id === dropNode.id) {
    dropNode = null;
    chart.render();
    return;
  }

  d3.select(element).remove();
  
  const data = chart.getChartState().data;
  const node = data?.find((x) => x.id == dragEvent.subject.id);
  let oldParentId = node.parentId;

  if (addFakeRootNode && dropNode.id === fakeRootNodeId) {
    chart.render();
    return;
  }
  node.parentId = dropNode.id;

  dropNode = null;
  dragNode = null;
  chart.render();

  sendRequest(`/api.cgi/tasks/${node.id}/`, {
    parentId: node.parentId
  }, 'PUT')
    .then(data => {
      if(data.errno) {
        console.log(data)
        node.parentId = oldParentId;
        chart.render();
      }
    })
    .catch(err => {
      console.log(err)
      node.parentId = oldParentId;
      chart.render();
    });
}


function generateContentWithButton(d) {
  if (addFakeRootNode && d.id === fakeRootNodeId) {
    return generateHeaderNodeContent(d);
  }

  const content = generateContent(d);
  return `
    <div class="node-content" style="position: relative;">
      ${content}
      <div class="button-container">
          <button class="node-btn add-button" onclick="addChildNode(${d.id}, event)" onmousedown="event.stopPropagation();">+</button>
        <button class="node-btn remove-button" onclick="removeChildNode(${d.id}, event)" onmousedown="event.stopPropagation();">−</button>
      </div>
    </div>
        
    <div style="position: absolute; bottom: 0; left: 6px; width: 98%;" class="node-btn" onmousedown="event.stopPropagation();">
      <div style="border-top: 1px solid #E4E2E9;" class="mt-2"></div>
      <div class="d-flex">
        <button class="btn btn-light flex-fill h-100 node-btn" style="border-right: 1px solid #E4E2E9;" 
                onclick="editNode(${d.id}, event)" onmousedown="event.stopPropagation();">
          <span class="fa fa-pencil-alt mr-1"></span>${_EDIT}
        </button>
        <button class="btn btn-light flex-fill h-100 node-btn" 
                onclick="viewNode(${d.id}, event)" onmousedown="event.stopPropagation();">
          <span class="fa fa-eye mr-1"></span>${_GO}
        </button>
      </div>
    </div>`;
}

function generateHeaderNodeContent(d) {
  let color = getStateColor(d.data.state);

  return ` 
  
  <div style="background-color:#ffffff; margin-top:-1px; margin-left:-1px; width:${d.width}px; height:${d.height}px; border-radius:10px; border: 1px solid #E4E2E9; position: relative;">
    <div style="position: absolute; top: 0; left: -1px; width: 7px; height: 100%; background-color: ${color}; border-top-left-radius: 10px; border-bottom-left-radius: 10px;"></div>
    <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
      <span class="h5 mb-0 text-truncate" style="color: black; text-align: center;">${_TASKS_GENERAL_REPORT}</span>
    </div>
  </div>`;
}

function generateContent(d) {
  let color = getStateColor(d.data.state);
  let status = getStatusName(d.data.state);

  return ` 
  <div style="background-color:#ffffff; margin-top:-1px; margin-left:-1px; width:${d.width}px; height:${d.height}px; border-radius:10px; border: 1px solid #E4E2E9; position: relative;">
    <div style="position: absolute; top: 0; left: -1px; width: 7px; height: 100%; background-color: ${color}; border-top-left-radius: 10px; border-bottom-left-radius: 10px;"></div>

    <div style="position: relative;">
      <div class='p-3'>
        <div class="d-flex justify-content-between align-items-center">
          <span class="h6 mb-0 text-left flex-grow-1 text-truncate" style='color: black'>${d.data.name}</span>
          <span class="btn rounded-pill btn-xs pl-2 pr-2 flex-shrink-0" style="background-color:${color}; color: white;">${status}</span>
        </div>
        <div class="text-muted text-left mt-2" style="display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden;">
          ${d.data.descr}
        </div>
      </div>
    </div>
  </div>`;
}

function getStateColor(state) {
  switch (state) {
    case 0:
      return '#17a2b8';
    case 1:
      return '#28a745';
    case 2:
      return '#dc3545';
    default:
      return '#17a2b8';
  }
}

function getStatusName(state) {
  if (!state) return _TASK_IN_WORK;
  if (state === 1) return _TASKS_COMPLETED;
  if (state === 2) return _TASKS_NOT_COMPLETED

  return _UNKNOWN;
}

function removeChildNode(id, event) {
  event.preventDefault();
  let confirmDelModal = new AModal();
  confirmDelModal
    .setHeader(`${_DEL} #${id}`)
    .setBody(`<h4 class="modal-title"><div id="confirmModalContent">${_CONFIRM_DEL}</div></h4>`)
    .addButton(_NO, 'confirmDelModalCancelBtn', 'default')
    .addButton(_YES, 'confirmDelModalConfirmBtn', 'success')
    .show(function () {
      jQuery('#confirmDelModalConfirmBtn').on('click', function () {
        sendRequest(`/api.cgi/tasks/${id}/`, {}, 'DELETE')
          .then(data => {
            chart.removeNode(id);
          })
          .catch(err => {
            console.log(err);
          });
        confirmDelModal.hide();
      });

      jQuery('#confirmDelModalCancelBtn').on('click', function () {
        confirmDelModal.hide();
      });
    });
}

function editNode(nodeId, event) {
  event.preventDefault();
  let changeModal = new AModal();
  changeModal
    .setBody(getNewNodeForm())
    .addButton(_CANCEL, 'changeTaskCancelBtn', 'default')
    .addButton(_CHANGE, 'changeTaskBtn', 'success')
    .show(function () {

      jQuery('#changeTaskBtn').attr('disabled', true);

      jQuery('#TASK_TYPE').select2({width: '100%'});
      jQuery('#RESPONSIBLE').select2({width: '100%'});
      jQuery('#CONTROL_DATE').datepicker({
        autoclose: true,
        format: 'yyyy-mm-dd',
        startDate: new Date(),
        todayHighlight: true,
        clearBtn: true,
        forceParse: false
      }).on('show', cancelEvent).on('hide', cancelEvent);

      let task = {};
      sendRequest(`/api.cgi/tasks/${nodeId}/`, {}, 'GET')
        .then(data => {
          if (data.id) {
            task = data;
            jQuery('#TASK_TYPE').val(task?.taskType);
            jQuery('#TASK_TYPE').select2().trigger('change');
            jQuery('#RESPONSIBLE').val(task?.responsible);
            jQuery('#RESPONSIBLE').select2().trigger('change');
            jQuery('#CONTROL_DATE').val(task?.controlDate);
            jQuery('#TASK_NAME').val(task?.name)
            jQuery('#TASK_DESCR').val(task?.descr)
            jQuery('#changeTaskBtn').attr('disabled', false);
          }
          else {
            changeModal.hide();
          }
        })
        .catch(err => {
          console.log(err);
        });

      jQuery('#changeTaskBtn').on('click', function () {

        sendRequest(`/api.cgi/tasks/${nodeId}/`, {
          name: jQuery('#TASK_NAME').val(),
          descr: jQuery('#TASK_DESCR').val(),
          task_type: jQuery('#TASK_TYPE').val(),
          responsible: jQuery('#RESPONSIBLE').val(),
          control_date: jQuery('#CONTROL_DATE').val()
        }, 'PUT')
          .then(data => {
            if (data.errno) {
              changeModal.hide();
              return;
            }

            const attrs = chart.getChartState();
            const node = attrs.allNodes.filter(({ data }) => attrs.nodeId(data) == nodeId)[0];
            if (node) {
              node.data.name = jQuery('#TASK_NAME').val();
              node.data.descr = jQuery('#TASK_DESCR').val();
              chart.render();
            }
            changeModal.hide();
          })
          .catch(err => {
            console.log(err);
            changeModal.hide();
          });
      });

      jQuery('#changeTaskCancelBtn').on('click', function () {
        changeModal.hide();
      });
    });
}

function viewNode(nodeId, event) {
  event.preventDefault();
  window.open(`?get_index=task_web_add&full=1&chg_task=${nodeId}`, '_blank');
}

