%MAPS%

<script>
  jQuery(document).ready(function () {
    if (!map) return;

    const interval = parseInt('%ONLINE_USERS_UPDATE_INTERVAL%', 10) || 300;
    let isProcessing = false;
    let isFirstLoad = true;

    const showSpinner = () => {
      const mapWrapper = document.getElementById('map-wrapper');
      if (!mapWrapper || document.getElementById('map-spinner-overlay')) return;

      const overlay = document.createElement('div');
      overlay.id = 'map-spinner-overlay';
      overlay.style.position = 'absolute';
      overlay.style.top = 0;
      overlay.style.left = 0;
      overlay.style.width = '100%';
      overlay.style.height = '100%';
      overlay.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
      overlay.style.zIndex = 1000;
      overlay.style.display = 'flex';
      overlay.style.flexDirection = 'column';
      overlay.style.alignItems = 'center';
      overlay.style.justifyContent = 'center';
      overlay.style.color = 'white';
      overlay.style.textAlign = 'center';

      const spinner = document.createElement('div');
      spinner.className = 'spinner-border text-light';
      spinner.style.width = '3rem';
      spinner.style.height = '3rem';
      spinner.setAttribute('role', 'status');
      spinner.innerHTML = '<span class="visually-hidden"></span>';

      const loadingText = document.createElement('div');
      loadingText.style.marginTop = '1rem';
      loadingText.textContent = '_{LOADING_DATA_ONTO_THE_MAP}_';

      overlay.appendChild(spinner);
      overlay.appendChild(loadingText);

      mapWrapper.style.position = 'relative';
      mapWrapper.appendChild(overlay);
    };

    const hideSpinner = () => {
      const overlay = document.getElementById('map-spinner-overlay');
      if (overlay) overlay.remove();
    };

    const clearCustomElements = () => {
      FORM?.CUSTOM_ELEMENTS?.MARKER?.clearLayers();
      FORM?.CUSTOM_ELEMENTS?.POLYGON?.clearLayers();
    };

    const processBuilds = (list) => {
      return list.reduce((builds, build) => {
        if (!Array.isArray(build?.coords) || build.coords.length < 1) return builds;

        const buildId = build?.buildId || build?.build_id;
        const info = tableInfo(build?.users);
        const isOnline = build?.isOnline;

        builds[buildId] = build.coords.length > 1
          ? {
            POLYGON: {
              ID: buildId,
              OBJECT_ID: buildId,
              POINTS: build.coords,
              COLOR: isOnline ? 'green' : 'grey',
              INFO: info.html(),
              DISABLE_EDIT: 1
            },
            ID: buildId
          }
          : {
            MARKER: {
              ID: buildId,
              OBJECT_ID: buildId,
              COORDX: build.coords[0][0],
              COORDY: build.coords[0][1],
              TYPE: isOnline ? 'build_green' : 'build_grey',
              INFO: info.html(),
              DISABLE_EDIT: 1
            },
            ID: buildId
          };

        return builds;
      }, {});
    };

    const updateData = async () => {
      if (isProcessing) return;
      isProcessing = true;

      try {
        if (isFirstLoad) showSpinner();

        FORM['HIDE_EDIT_BUTTONS'] = 1;

        const data = await sendRequest(`/api.cgi/maps/online`, {}, 'GET');
        if (!Array.isArray(data?.list)) return;

        clearCustomElements();

        FORM['OBJECT_TO_SHOW'] = processBuilds(data.list);
        ObjectsConfiguration.showCustomObjects();
      } catch (error) {
        console.error(error);
      } finally {
        if (isFirstLoad) {
          hideSpinner();
          isFirstLoad = false;
        }
        isProcessing = false;
      }
    };

    updateData();
    setInterval(updateData, interval * 1000);
  });


  function tableInfo(users) {

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

    tableRow.append(onlineCell, loginCell, depositCell, fioCell);
    tableBody.append(tableRow);
    users.forEach(user => {
      let userRow = jQuery('<tr></tr>');
      let onlineIcon = jQuery(`<span title="_{ONLINE}_" class="${user.online ? 'far fa-check-circle text-green' : ''}"></span>`);
      let loginLink = jQuery(`<a title="${user.uid}" href="%SELF_URL%?get_index=form_users&amp;header=1&amp;full=1&amp;UID=${user.uid}">${user.uid}</a>`);
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
</script>