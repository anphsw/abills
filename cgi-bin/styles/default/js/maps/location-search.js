function feelAllCoords() {
  let searchBtns = jQuery('.search-btn');

  searchBtns.each(function () {
    if (jQuery(this).hasClass('disabled'))
      return;

    jQuery(this).click();
  });
}

function findLocation(build_id) {
  sendRequest(`/api.cgi/builds/?ID=${build_id}&STREET_SECOND_NAME`, {}, 'GET')
    .then(data => {
      if (!Array.isArray(data) || data.length === 0) return;

      const { id, number, streetName, street_name, districtName,
        district_name, streetSecondName, street_second_name } = data[0];
      if (!id) return;

      const streetUrl = `street=${number}+${streetName || street_name}`;
      const streetSecondNameUrl = streetSecondName || street_second_name ? `street=${number}+${streetSecondName || street_second_name}` : undefined;
      const cityUrl = `&city=${districtName || district_name}`;

      searchBuildLocation(build_id, number, streetUrl, cityUrl, streetSecondNameUrl);
    });
}

function searchBuildLocation(buildId, number, streetUrl, cityUrl,  streetSecondNameUrl = undefined) {
  let url = `https://nominatim.openstreetmap.org/search?${streetUrl}${cityUrl}&format=json&polygon_geojson=1`;
  const spanElementId = `number_${buildId}`;
  Spinner.on(spanElementId);

  sendFetch(url, function () {
    Spinner.off(spanElementId, NOT_FOUND, 'btn-danger');
  }, function (data) {
    let result = resultProcessing(data, spanElementId, buildId, number);
    if (result === -1 && streetSecondNameUrl !== undefined) {
      searchBuildLocation(buildId, number, streetSecondNameUrl, cityUrl);
    }
  });
}

function resultProcessing(data, spanElementId, buildId, number) {
  if (data.length === 0) {
    Spinner.off(spanElementId, NOT_FOUND, 'btn-danger');
    return -1;
  }

  let buildings = [];
  data.forEach(function (element) {
    if (element.class !== 'building')
      return;

    buildings.push(element.geojson.coordinates[0]);
  });

  if (buildings.length === 0) {
    Spinner.off(spanElementId, NOT_FOUND, 'btn-danger');
    return -1;
  }

  if (buildings.length !== 1) {
    buildings = [];
    data.forEach(function (element) {
      if (element.class !== 'building')
        return;

      let names = element.display_name.split(',');
      if (names[0] !== number)
        return;

      buildings.push(element.geojson.coordinates[0]);
    });

    if (buildings.length === 0) {
      Spinner.off(spanElementId, NOT_FOUND, 'btn-danger');
      return -1;
    }

    if (buildings.length !== 1) {
      Spinner.off(spanElementId, SEVERAL_RESULTS, 'btn-warning');
      return;
    }
  }

  Spinner.off(spanElementId, SUCCESS, 'btn-success');
  updateBuildCoords(buildings[0], buildId);
}

let Spinner = {
  spinner: '<div class="fa fa-spinner fa-pulse"><span class="sr-only">Loading...</span></div>',
  on: function (spanElementId) {
    const spanElement = jQuery('#' + spanElementId);
    const btnElement = jQuery('#button_' + spanElementId);

    spanElement.html(Spinner.spinner);

    btnElement.attr('aria-disabled', 'true');
    btnElement.addClass('disabled');
  },
  off: function (spanElementId, status, color) {
    const spanElement = jQuery('#' + spanElementId);
    let contraryClass = color === 'btn-success' ? 'btn-danger' : 'btn-success';

    spanElement.html(status);
    spanElement.removeClass('btn-default');
    spanElement.removeClass(contraryClass);
    spanElement.addClass(color);
  },
};

function sendFetch(url, err_callback, success_callback) {
  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw response
      }
      return response;
    })
    .then(function (response) {
      try {
        return response.json();
      } catch (e) {
        if (err_callback)
          err_callback();

        alert("Error: " + e);
      }
    })
    .then(result => {
      if (success_callback)
        success_callback(result);
    })
    .catch(err => {
      if (err_callback)
        err_callback();

      alert(err);
    });
}

function updateBuildCoords(coords, buildId) {
  let url = registerBuildPolygon(buildId);
  let latLngArray = [];
  coords.forEach(function (element) {
    latLngArray.push(element[1] + ":" + element[0]);
  });

  url += '&coords=' + latLngArray.join(',');
  addBuildAjax(url, JSON.stringify(coords));
}

let registerBuildPolygon = function (buildId) {
  return 'get_index=maps_main&header=2&add=1&LAYER_ID=12'
    + '&update_build=1'
    + '&LOCATION_ID=' + buildId
    + '&change=1';
};

function addBuildAjax(link, data, err_callback, success_callback) {
  jQuery.ajax({
    url: '/admin/index.cgi?',
    type: 'POST',
    data: link,
    contentType: false,
    cache: false,
    processData: false,
    success: function () {
      if (success_callback) {
        success_callback();
      }
    },
    fail: function (error) {
      if (err_callback) {
        err_callback();
      }
    },
    complete: function () {
    }
  });
}