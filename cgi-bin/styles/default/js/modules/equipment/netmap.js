document.addEventListener('DOMContentLoaded', async () => {
  const equipmentControlPanel = new EquipmentControlPanel();

  const cy = window.cy = cytoscape({
    container: document.getElementById('cy'),
    style: [
      {
        selector: 'node',
        style: {
          'content': 'data(label)',
          'shape': 'roundrectangle',
          'background-image': e => getTypeImage(e.data().type),
          'background-color': e => getStateColor(e.data().state),
          'background-width': '70%',
          'background-height': '70%',
          'width': '70',
          'height': '70'
        }
      },
      {
        selector: 'edge',
        style: {
          'content': 'data(label)',
          'curve-style': 'bezier',
          'target-arrow-shape': 'triangle'
        }
      }
    ],
    elements: {
      nodes,
      edges
    },
    wheelSensitivity: 0.2,
    layout: {name: 'preset'}
  });

  const nodesWithoutPosition = cy.nodes().filter(n => !n.position() || (n.position().x === 0 && n.position().y === 0));

  cy.layout({
    name: 'cose-bilkent',
    eles: nodesWithoutPosition,
    randomize: true,
    tilingPaddingVertical: 20,
    tilingPaddingHorizontal: 30,
    fit: false
  }).run();

  cy.one('layoutstop', () => {
    cy.fit();
  });
  const makeTippy = (node, text) => {
    return tippy(node.popperRef(), {
      content: () => {
        const div = document.createElement('div');
        div.className = 'tippy';
        div.innerHTML = text;
        return div;
      },
      arrow: true,
      placement: 'bottom',
      hideOnClick: false,
      sticky: true,
      flip: false
    });
  };

  if (nodes.length <= 50) {
    nodes.forEach(node => {
      const n = cy.getElementById(node.data.id);
      const tippy = makeTippy(n, node.data.ip);
      tippy.show();
    });
  }

  cy.on('zoom', () => {
    document.querySelectorAll('.tippy').forEach(tippy => {
      tippy.style.width = `${cy.nodes()[0].width() * cy.zoom()}px`;
      tippy.style.fontSize = `${cy.zoom()}vh`;
    });
  });

  cy.on('tap', evt => {
    if (evt.originalEvent.target.tagName === 'BUTTON') return;
    document.querySelectorAll('.info-table').forEach(table => table.style.display = 'none');
    tooltipInstances.forEach(tippy => {
      if (tippy) {
        tippy.destroy();
        tippy = undefined;
      }
    });
  });

  cy.on('dragfree', 'node', (event) => {
    const node = event.target;
    let position = node.position();
    let nasId = node.data().nasId;

    if (!nasId || !position) return;

    sendRequest(`/api.cgi/equipment/nas/netmap/positions/`, {
      positions: [{ nasId: nasId, coordx: position.x, coordy: position.y }]
    }, 'POST')
      .then((data) => {
      })
      .finally(() => {});
  });
  cy.on('tap', 'node', evt => {
    if (evt.originalEvent.target.tagName === 'BUTTON') return;

    const node = evt.target;
    document.querySelector('.info-table').style.display = 'block';
    jQuery('.info-table').html(createNodeInfoCard(node.data()));

    if (nodes.length > 50) {
      tooltipInstances.forEach(tippy => {
        if (tippy) {
          tippy.destroy();
          const index = tooltipInstances.indexOf(tippy);
          if (index !== -1) tooltipInstances.splice(tippy, 1);
        }
      });
      renderChildTooltips(node, makeTippy);
      document.querySelectorAll('.tippy').forEach(tippy => {
        tippy.style.width = `${node.width() * cy.zoom()}px`;
        tippy.style.fontSize = `${cy.zoom()}vh`;
      });
    }
  });

  document.getElementById('layout').addEventListener('click', function () {
    let layout = cy.layout({
      name: 'cose-bilkent',
      animate: 'end',
      animationEasing: 'ease-out',
      animationDuration: 1000,
      randomize: true,
      tilingPaddingVertical: 50,
      tilingPaddingHorizontal: 150,
      fit: true,
      padding: 30,
      nodeOverlap: 10,
      idealEdgeLength: 150,
      edgeElasticity: 0.1,
    });

    layout.one('layoutstop', function () {
      let positions = cy.nodes().map(node => ({
        coordx: node.position('x'),
        coordy: node.position('y'),
        nasId: node.data('nasId')
      }));

      sendRequest(`/api.cgi/equipment/nas/netmap/positions/`, {positions: positions}, 'POST');
    });

    layout.run();
  });

  const time = (window.performance.timing.domContentLoadedEventStart - window.performance.timing.connectEnd) / 1000;
  document.querySelector('.time-count').textContent = `${_TIME}: ${time}`;
});

const renderChildTooltips = (parentNode, createTooltip, visited = new Set()) => {
  const nodeId = parentNode.id();

  if (visited.has(nodeId)) return;
  visited.add(nodeId);

  const currentNode = cy.getElementById(nodeId);
  const tooltip = createTooltip(currentNode, currentNode.data().ip);
  tooltipInstances.push(tooltip);
  tooltip.show();

  cy.edges(`[source = '${nodeId}']:visible`)
    .forEach(edge => renderChildTooltips(edge.target(), createTooltip, visited));
};

const createNodeInfoCard = nodeData => {
  const {id, label = id, ip = '0.0.0.0', state, type, vendor, model, port, online, nasId} = nodeData;
  const statusClass = getNodeStatusClass(state);

  const cardContainer = document.createElement('div');
  cardContainer.classList.add('node-container', 'cursor-pointer', 'pl-1', 'pt-1');

  const sideBar = document.createElement('div');
  sideBar.classList.add('node-sidebar', statusClass);
  cardContainer.appendChild(sideBar);

  const contentWrapper = document.createElement('div');
  contentWrapper.classList.add('node-content-wrapper');

  const header = document.createElement('div');
  header.classList.add('node-header');

  const title = document.createElement('span');
  title.classList.add('node-title', 'mb-2');
  title.innerText = label;

  const statusBadge = document.createElement('span');
  statusBadge.classList.add('node-status-badge', statusClass);

  const img = document.createElement('img');
  img.src = getTypeImage(type);
  img.classList.add('node-icon');
  statusBadge.appendChild(img);

  header.appendChild(title);
  header.appendChild(statusBadge);
  contentWrapper.appendChild(header);

  contentWrapper.appendChild(createElementWithIcon(ip, 'fa-network-wired'));
  contentWrapper.appendChild(createElementWithIcon(`${vendor} ${model}`, 'fa-server', 'mt-1'));
  if (port) contentWrapper.appendChild(createElementWithIcon(port, 'fa-ethernet', 'mt-1'));
  if (online) contentWrapper.appendChild(createElementWithIcon(online, 'fa-users', 'mt-1'));

  cardContainer.appendChild(contentWrapper);

  const button = document.createElement('button');
  button.textContent = _GO;
  button.classList.add('btn', 'btn-light', 'flex-fill', 'w-100', 'node-btn');
  button.addEventListener('click', (event) => {
    event.preventDefault();
    window.open(`?get_index=equipment_info&full=1&NAS_ID=${nasId}`, '_blank');
  });

  const buttonContainer = document.createElement('div');
  buttonContainer.append(button);

  const portContainer = document.createElement('div');
  portContainer.classList.add('port-container', 'text-center');
  const spinner = document.createElement('div');
  spinner.classList.add('fa', 'fa-spinner', 'fa-pulse');
  portContainer.appendChild(spinner);

  cardContainer.appendChild(portContainer);
  cardContainer.appendChild(buttonContainer);

  jQuery(cardContainer).on('mouseenter', function () {
    cy.userPanningEnabled(false);
    cy.userZoomingEnabled(false);
  });

  jQuery(cardContainer).on('mouseleave', function () {
    cy.userPanningEnabled(true);
    cy.userZoomingEnabled(true);
  });

  sendRequest(`/api.cgi/equipment/nas/${nasId}/ports/?UPLINK&PAGE_ROWS=1000&PORT_COMMENTS&VLAN`, {}, 'GET')
    .then(data => {
      if (data?.total < 1) return;
      if (!Array.isArray(data?.list)) return;

      let ports = [];
      data?.list.forEach(item => {
        let uplinkBtn = '';
        if (item?.uplink > 0) {
          uplinkBtn = jQuery(`<a title='${nasList?.nodes[item.uplink]?.data?.label}'>${item.uplink}</a>`);
          uplinkBtn.attr('href', `?get_index=equipment_info&full=1&NAS_ID=${item.uplink}`);
          uplinkBtn.addClass('btn btn-user btn-secondary');
        }
        else {
          uplinkBtn = jQuery(`<button title='${_CHANGE}'>${_CHANGE}</button>`);
          uplinkBtn.addClass('btn btn-default');
          uplinkBtn.on('click', function () {
            createPortModal(item.id, item.port, nasId);
          });
        }
        ports.push([item?.port, item?.portComments, uplinkBtn, item?.vlan || '']);
      });

      let table = createTable([_PORT, _COMMENTS, 'UPLINK', 'Native VLAN'], ports,
        'table table-striped table-hover table-condensed nas-ports-table');
      spinner.remove();
      jQuery(portContainer).append(table);
    })
    .catch(err => {
      console.log(err)
    })
    .finally(() => {
      spinner.remove();
    })

  return cardContainer;
};

const createPortModal = (portId, port, nasId) => {
  let confirmModal = new AModal();
  confirmModal
    .setHeader(_EQUIPMENT_ADD_PORT_BINDING)
    .setBody(_createPortModalBody(port, nasId))
    .addButton(_NO, 'confirmModalCancelBtn', 'default')
    .addButton(_CHANGE, 'changePortUplink', 'primary')
    .show(function () {
      jQuery('#UPLINK').select2()

      let form = jQuery('form#change-port-info');
      form.on('submit', function(e) {
        e.preventDefault();
        let uplink = jQuery('#UPLINK').val();

        jQuery('#changePortUplink').remove();
        sendRequest(`/api.cgi/equipment/nas/${nasId}/ports/${portId}`, {uplink: uplink, vlan: jQuery('#VLAN').val()}, 'PUT')
          .then((data) => {
            if (data?.affected > 0) {
              cy.add([
                { group: 'edges', data: { id: 'edge1', source: `n${uplink}`, target: `n${nasId}`, label: port, id: `${uplink} -> ${nasId}` } }
              ]);

              confirmModal.hide();
              jQuery('.node-container').remove();
            }
            else {
              confirmModal.hide();
            }
          })
          .finally(() => {
            confirmModal.hide();
          })
      });

      jQuery('#changePortUplink').on('click', function () {
        form.submit();
      });

      jQuery('#confirmModalCancelBtn').on('click', function () {
        confirmModal.hide();
      });
    });
}

function _createPortModalBody(port, nasId) {
  let form = jQuery('<form></form>').attr('id', 'change-port-info');

  let portInput = jQuery('<input/>').attr('name', 'PORT').attr('value', port).addClass('form-control').attr('readonly', 1);
  let portInputContainer = jQuery('<div></div>').addClass('col-md-8').append(portInput);
  let portLabel = jQuery('<label></label>').addClass('col-md-4 col-form-label text-md-right').text(`${_PORT}:`);
  let portFormGroup = jQuery('<div></div>').addClass('form-group row').append(portLabel).append(portInputContainer);

  let selectList = jQuery('<select></select>', {width: '100%', id: 'UPLINK', name: 'UPLINK'});
  Object.keys(nasList.nodes).forEach(value => {
    if (nasId == value) return;
    let option = jQuery('<option></option>', {value: value, text: nasList.nodes[value]?.data?.label});
    selectList.append(option);
  });
  let uplinkInputContainer = jQuery('<div></div>').addClass('col-md-8').append(selectList);
  let uplinkLabel = jQuery('<label></label>').addClass('col-md-4 col-form-label text-md-right').text(`UPLINK:`);
  let uplinkFormGroup = jQuery('<div></div>').addClass('form-group row').append(uplinkLabel).append(uplinkInputContainer);

  let vlanInput = jQuery('<input/>').attr('name', 'VLAN').attr('id', 'VLAN').addClass('form-control');
  let vlanInputContainer = jQuery('<div></div>').addClass('col-md-8').append(vlanInput);
  let vlanLabel = jQuery('<label></label>').addClass('col-md-4 col-form-label text-md-right').text('VLAN:');
  let vlanFormGroup = jQuery('<div></div>').addClass('form-group row').append(vlanLabel).append(vlanInputContainer);

  form.append(portFormGroup).append(uplinkFormGroup).append(vlanFormGroup);
  return form.prop('outerHTML');
}

const createElementWithIcon = (description, iconClass, containerClass = '') => {
  const container = document.createElement('div');
  if (containerClass) container.classList.add(containerClass);

  const icon = document.createElement('i');
  icon.classList.add('fa', iconClass, 'mr-2', 'text-muted');
  container.appendChild(icon);

  const textNode = document.createTextNode(description);
  container.appendChild(textNode);

  return container;
};

const getTypeImage = type => {
  const images = new Map([
    [2, '/img/netmap/wifi.svg'],
    [3, '/img/netmap/router.svg'],
    [4, '/img/netmap/pon.svg'],
    [0, '/img/netmap/user.svg'],
  ]);
  return images.get(type) || '/img/netmap/switch.svg';
};

const getNodeStatusClass = state => {
  const classes = new Map([
    [0, 'bg-success'],
    [1, 'bg-danger'],
    [2, 'bg-secondary'],
    [3, 'bg-primary'],
    [4, 'bg-warning'],
  ]);
  return classes.get(state) || 'bg-success';
};

const getStateColor = state => {
  const colors = new Map([
    [0, 'rgb(0,175,0)'],
    [1, 'rgb(200,0,0)'],
    [2, 'rgb(0,0,200)'],
    [3, 'rgb(0,0,200)'],
    [4, 'rgb(255, 162, 40)'],
  ]);
  return colors.get(state) || 'rgb(255, 162, 40)';
};

class EquipmentControlPanel {
  constructor() {
    this.controlPanelContainer = document.querySelector('#scheme_controls');
    this.additionMenu = this.controlPanelContainer.querySelector('ul.dropdown-menu.plus-options');
    this.initializeOptionsList(this.additionMenu, this.additionOptions);
  }

  initializeOptionsList(menuContainer, options) {
    Object.entries(options).forEach(([optionName, handler]) => {
      const menuItem = document.createElement('li');
      menuItem.classList.add('dropdown-item', 'pl-0', 'pr-0');

      const optionButton = document.createElement('a');
      optionButton.classList.add('btn', 'w-100', 'pt-0', 'pb-0', 'text-left');
      optionButton.textContent = optionName;
      optionButton.addEventListener('click', handler.bind(this));

      menuItem.appendChild(optionButton);
      menuContainer.appendChild(menuItem);
    });
  }

  initializeEquipmentAddForm() {
    let typeSelect = jQuery('<select></select>', {width: '100%', id: 'TYPE_ID', name: 'TYPE_ID', required: 'required'});
    Object.keys(types).forEach(typeId => {
      let option = jQuery('<option></option>', {value: typeId, text: types[typeId]?.NAME});
      typeSelect.append(option);
    });

    let typeFormGroup = jQuery('<div></div>', {class: 'form-group row'});
    let typeLabel = jQuery('<label></label>', {class: 'col-md-4 col-form-label text-md-right required'});
    typeLabel.text(`${_TYPE}:`);
    let typeSelectContainer = jQuery('<div></div>', {class: 'col-md-8'});
    typeSelectContainer.append(typeSelect);

    typeFormGroup.append(typeLabel);
    typeFormGroup.append(typeSelectContainer);

    let modelsSelect = jQuery('<select></select>', {width: '100%', id: 'MODEL_ID', name: 'MODEL_ID'});

    let modelsFormGroup = jQuery('<div></div>', {class: 'form-group row'});
    let modelsLabel = jQuery('<label></label>', {class: 'col-md-4 col-form-label text-md-right'});
    modelsLabel.text(`${_MODEL}:`);
    let modelsSelectContainer = jQuery('<div></div>', {class: 'col-md-8'});
    modelsSelectContainer.append(modelsSelect);

    modelsFormGroup.append(modelsLabel);
    modelsFormGroup.append(modelsSelectContainer);
    jQuery('#NAS_NAME').parent().parent().after(modelsFormGroup);
    jQuery('#NAS_NAME').parent().parent().after(typeFormGroup);

    typeSelect.on('change', function () {
      let typeId = jQuery(this).val();
      modelsSelect.find('option').remove();

      if (!typeId) return;

      let models = types[typeId]?.MODELS;
      if (!models) return;

      models.forEach(model => {
        let option = jQuery('<option></option>', {value: model?.ID, text: model?.NAME});
        modelsSelect.append(option);
      });
    });
    typeSelect.select2().trigger('change');
    modelsSelect.select2();
  }

  handleAddEquipment() {
    let self = this;
    let confirmModal = new AModal();
    confirmModal
      .setHeader(_EQUIPMENT_ADD_NEW_EQUIPMENT)
      .setBody(EQUIPMENT_ADD_FORM.innerHTML)
      .setSize('lg')
      .addButton(_NO, 'confirmModalCancelBtn', 'default')
      // .addButton('_{YES}_', 'confirmModalConfirmBtn', 'success')
      .show(function () {

        let form = jQuery('form#FORM_NAS');
        let submit_btn = form.find(`button[type='submit']`);

        self.initializeEquipmentAddForm();
        form.on('submit', function (e) {
          e.preventDefault();
          let formData = form.serializeArray().reduce(function (json, {name, value}) {
            json[name] = value;
            return json;
          }, {});
          formData['NAS_TYPE'] = 'other';

          submit_btn.prop('disabled', true);

          sendRequest(`/api.cgi/equipment/nas/`, formData, 'POST')
            .then((data) => {

              if (!data.insertId) {
                aModal.hide();
                return;
              }

              sendRequest(`/api.cgi/equipment/nas/${data.insertId}/details/`, formData, 'POST')
                .then((info) => {
                  if (info.affected) {
                    let newNode = {
                      data: {
                        id: `n${data.insertId}`,
                        nasId: data.insertId,
                        label: formData?.NAS_NAME,
                        ip: formData?.IP,
                        state: formData?.NAS_DISABLE || 0,
                        type: formData?.TYPE_ID,
                        model: '',
                        vendor: jQuery('#MODEL_ID').find(':selected').text(),
                        online: 0
                      }
                    };
                    cy.add(newNode);
                    nodes.push(newNode);
                  }
                })
                .catch((error) => {
                  console.log(error);
                })
                .finally(() => {
                  aModal.hide();
                })
            })
            .catch((error) => {
              console.log(error);
              aModal.hide();
              // location.reload()
            });
        });
        jQuery('#confirmModalCancelBtn').on('click', function () {
          confirmModal.hide();
        });
      });
  }

  additionOptions = {
    [_EQUIPMENT]: this.handleAddEquipment,
  };
}
