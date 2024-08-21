<div class='panel with-nav-tabs panel-default'>
  <nav class='abills-navbar navbar navbar-expand-sm navbar-light'>
    <a class='navbar-brand d-sm-none pl-3'>_{MENU}_</a>
    <button
      class='navbar-toggler'
      type='button'
      data-toggle='collapse'
      data-target='#navbarPanelContent'
      aria-controls='navbarPanelContent'
      aria-expanded='false'
      aria-label='_{INTERNET}_ _{MAP}_'
    >
      <span class='navbar-toggler-icon'></span>
    </button>
    <div id='navbarPanelContent' class='collapse navbar-collapse'>
      <ul class='nav nav-tabs navbar-nav'>
        <li class='nav-item'>
          <a class='nav-link %TAB1_ACTIVE% active' href='#tab1default' data-toggle='tab'>
            _{INTERNET}_
          </a>
        </li>
        <li class='nav-item'>
          <a class='nav-link %TAB2_ACTIVE%' href='#tab2default' data-toggle='tab'>
            _{MAP}_
          </a>
        </li>
      </ul>
    </div>
  </nav>
  <div class='panel-body'>
    <div class='tab-content'>
      <div class='active tab-pane %TAB1_ACTIVE%' id='tab1default'>
        <div class='form-group'>
          %FILTERS%
        </div>
        <div class='form-group'>
          %TABLE%
        </div>
      </div>

      <div class='tab-pane %TAB2_ACTIVE%' id='tab2default'>
        %MAPS%
      </div>
    </div>
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    jQuery(`[href='#tab2default']`).on('click', function() {
      setTimeout(function () {
        map.invalidateSize(true);
      }, 0);
    });

    if (typeof map !== 'undefined') {
      let interval = '%ONLINE_USERS_UPDATE_INTERVAL%' || 30;
      setInterval(function(){
        sendRequest(`/api.cgi/maps/online`, {}, 'GET')
          .then(data => {
            if (!Array.isArray(data)) return;
            if (FORM && FORM['CUSTOM_MARKERS']) FORM['CUSTOM_MARKERS'].clearLayers();

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

            FORM['OBJECT_TO_SHOW'] = builds;
            ObjectsConfiguration.showCustomObjects();
          });
      }, interval * 1000);
    }

    function tableInfo(user, build = {}) {
      if (build.TABLE && build.TABLE_BODY) {
        let userRow = jQuery('<tr></tr>');
        let onlineIcon = jQuery(`<span title="_{ONLINE}_" class="${user.online ? 'far fa-check-circle text-green' : ''}"></span>`);
        let loginLink = jQuery(`<a title="${user.uid}" href="%SELF_URL%?get_index=form_users&amp;header=1&amp;full=1&amp;UID=${user.uid}">${user.uid}</a>`);
        userRow.append(jQuery('<td></td>').append(onlineIcon), jQuery('<td></td>').append(loginLink),
          jQuery(`<td>${user.deposit}</td>`), jQuery(`<td>${user.fio}</td>`));

        build.TABLE_BODY.append(userRow);
        return [build.TABLE, build.TABLE_BODY];
      }

      let card = jQuery('<div class="card card-primary card-outline"></div>');
      let cardHeader = jQuery('<div class="card-header d-flex flex-nowrap justify-content-between"></div>');
      let cardTitle = jQuery('<div class="card-title"><h4 class="card-title table-caption">_{USERS}_</h4></div>');
      let cardTools = jQuery('<div class="card-tools"></div>');
      let tableWrapper = jQuery('<div class="" id="p_"></div>');
      let table = jQuery('<table class="table table-condensed table-hover table-bordered" id="_"></table>');
      let tableBody = jQuery('<tbody></tbody>');
      let tableRow = jQuery('<tr></tr>');
      let onlineCell = jQuery('<td><b>_{ONLINE}_</b></td>');
      let loginCell = jQuery('<td><b>_{LOGIN}_</b></td>');
      let depositCell = jQuery('<td><b>_{DEPOSIT}_</b></td>');
      let fioCell = jQuery('<td><b>_{FIO}_</b></td>');
      let userRow = jQuery('<tr></tr>');
      let onlineIcon = jQuery(`<span title="_{ONLINE}_" class="${user.online ? 'far fa-check-circle text-green' : ''}"></span>`);
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
</script>