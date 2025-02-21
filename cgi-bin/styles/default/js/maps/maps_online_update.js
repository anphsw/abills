jQuery(document).ready(function () {

  const interval = parseInt(MAP_ONLINE_UPDATE, 10) || 30;
  let isProcessing = false;

  const processBuilds = (list) => {
    return list.reduce((builds, build) => {
      if (!Array.isArray(build?.coords) || build.coords.length < 1) return builds;

      const buildId = build?.buildId || build?.build_id;
      const info = tableInfo(build?.users);
      const isOnline = build?.isOnline;

      builds[buildId] = {
        MARKER: {
          ID: buildId,
          OBJECT_ID: buildId,
          COORDX: build.coords.length > 1 ? calculateAverageCoordinates(build.coords)[0] : build.coords[0][0],
          COORDY: build.coords.length > 1 ? calculateAverageCoordinates(build.coords)[1] : build.coords[0][1],
          TYPE: isOnline ? 'build_green' : 'build_grey',
          INFO: info.html(),
          DISABLE_EDIT: 1
        },
        ID: buildId
      };

      return builds;
    }, {});
  };

  const calculateAverageCoordinates = (coords) => {
    const sum = coords.reduce((acc, coord) => {
      acc[0] += coord[0];
      acc[1] += coord[1];
      return acc;
    }, [0, 0]);

    const length = coords.length;
    return [sum[0] / length, sum[1] / length];
  };

  const updateData = async () => {
    if (isProcessing) return;
    if (!jQuery(`#layer_40`).length || jQuery(`#layer_40`).hasClass('btn_not_active')) return;
    isProcessing = true;

    sendRequest(`/api.cgi/maps/online`, {}, 'GET')
      .then(data => {
        if (!Array.isArray(data?.list)) return;

        let builds = processBuilds(data?.list);

        if (AllLayers['layer_40']) AllLayers['layer_40'].clearLayers();
        ObjectsConfiguration.showObject({ id: '40' }, Object.values(builds));
      })
      .finally(() => {
        isProcessing = false;
      });
  };

  function tableInfo(users) {

    let card = jQuery('<div class="card card-primary card-outline"></div>');
    let cardHeader = jQuery('<div class="card-header d-flex flex-nowrap justify-content-between"></div>');
    let cardTitle = jQuery(`<div class="card-title"><h4 class="card-title table-caption">${_USERS}</h4></div>`);
    let cardTools = jQuery('<div class="card-tools"></div>');
    let tableWrapper = jQuery('<div class="" id="p_"></div>');
    let table = jQuery('<table class="table table-condensed table-hover table-bordered" id="_"></table>');
    let tableBody = jQuery('<tbody></tbody>');
    let tableRow = jQuery('<tr></tr>');
    let onlineCell = jQuery(`<td><b>${_ONLINE}</b></td>`);
    let loginCell = jQuery(`<td><b>${_LOGIN}</b></td>`);
    let depositCell = jQuery(`<td><b>${_DEPOSIT}</b></td>`);
    let fioCell = jQuery(`<td><b>${_FIO}</b></td>`);

    tableRow.append(onlineCell, loginCell, depositCell, fioCell);
    tableBody.append(tableRow);
    users.forEach(user => {
      let userRow = jQuery('<tr></tr>');
      let onlineIcon = jQuery(`<span title="${_ONLINE}" class="${user.online ? 'far fa-check-circle text-green' : ''}"></span>`);
      let loginLink = jQuery(`<a title="${user.uid}" href="?get_index=form_users&amp;header=1&amp;full=1&amp;UID=${user.uid}">${user.uid}</a>`);
      userRow.append(jQuery('<td></td>').append(onlineIcon), jQuery('<td></td>').append(loginLink),
        jQuery(`<td>${user.deposit}</td>`), jQuery(`<td>${user.fio}</td>`));
      tableBody.append(userRow)
    })

    table.append(tableBody);

    cardHeader.append(cardTitle, cardTools);

    tableWrapper.append(table);

    card.append(cardHeader, tableWrapper);

    return jQuery('<div>').append(card);
  }

  setInterval(updateData, interval * 1000);
});
