jQuery(document).ready(function () {
  let buttonId = 'layer_40';

  setInterval(function (){
    if (jQuery(`#${buttonId}`).hasClass('btn_not_active')) return;

    sendRequest(`/api.cgi/maps/online`, {}, 'GET')
      .then(data => {
        if (!Array.isArray(data)) return;

        if (AllLayers[buttonId]) AllLayers[buttonId].clearLayers();

        let builds = {};
        data.forEach(build => {
          let [info, tableBody] = tableInfo(build, builds[build.buildId]);
          let type = builds[build.buildId] && builds[build.buildId]['MARKER'] ? builds[build.buildId]['MARKER']['TYPE'] : '';
          type = type === 'build_green' ? 'build_green' : build.online ? 'build_green' : 'build_grey';

          builds[build.buildId] = {
            MARKER: {
              ID: build.buildId,
              OBJECT_ID: build.buildId,
              COORDX: build.coordx,
              COORDY: build.coordy,
              TYPE: type,
              INFO: info.html(),
              DISABLE_EDIT: 1
            },
            TABLE_BODY: tableBody,
            TABLE: info,
            ID: build.buildId
          }
        });

        ObjectsConfiguration.showObject({ id: '40' }, Object.values(builds))
      });
  }, MAP_ONLINE_UPDATE * 1000);

  function tableInfo(user, build = {}) {
    if (build.TABLE && build.TABLE_BODY) {
      let userRow = jQuery('<tr></tr>');
      let onlineIcon = jQuery(`<span title="${_ONLINE}" class="${user.online ? 'far fa-check-circle text-green' : ''}"></span>`);
      let loginLink = jQuery(`<a title="${user.uid}" href="%SELF_URL%?get_index=form_users&amp;header=1&amp;full=1&amp;UID=${user.uid}">${user.uid}</a>`);
      userRow.append(jQuery('<td></td>').append(onlineIcon), jQuery('<td></td>').append(loginLink),
        jQuery(`<td>${user.deposit}</td>`), jQuery(`<td>${user.fio}</td>`));

      build.TABLE_BODY.append(userRow);
      return [build.TABLE, build.TABLE_BODY];
    }

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
    let userRow = jQuery('<tr></tr>');
    let onlineIcon = jQuery(`<span title="${_ONLINE}" class="${user.online ? 'far fa-check-circle text-green' : ''}"></span>`);
    let loginLink = jQuery(`<a title="${user.uid}" href="%SELF_URL%?get_index=form_users&amp;header=1&amp;full=1&amp;UID=${user.uid}">${user.uid}</a>`);

    tableRow.append(onlineCell, loginCell, depositCell, fioCell);
    userRow.append(jQuery('<td></td>').append(onlineIcon), jQuery('<td></td>').append(loginLink),
      jQuery(`<td>${user.deposit}</td>`), jQuery(`<td>${user.fio}</td>`));

    tableBody.append(tableRow, userRow);

    table.append(tableBody);

    cardHeader.append(cardTitle, cardTools);

    tableWrapper.append(table);

    card.append(cardHeader, tableWrapper);

    return [jQuery('<div>').append(card), tableBody];
  }
});