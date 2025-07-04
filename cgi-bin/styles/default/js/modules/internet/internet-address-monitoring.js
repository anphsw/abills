class DistrictManager {
  constructor(options = {}) {
    this.onlineUsers = options.onlineUsers || {};
    this.offlineUsers = options.offlineUsers || {};
    this.districtTypes = options.districtTypes || {};

    this.filters = {
      showOnline: true,
      showOffline: true,
      showEmpty: true
    };

    this.cache = {
      districts: new Map(),
      streets: new Map(),
      builds: new Map(),
      hierarchy: new Map()
    };

    this.loadingStates = new Set();

    this.config = {
      maxElementsWarning: 5000,
      batchSize: 10,
      maxParallelRequests: 3,
      ...options.config
    };

    this.requestSemaphore = new Semaphore(this.config.maxParallelRequests);
  }

  async init() {
    this.bindEvents();
    await this.createDistrict();
  }

  bindEvents() {
    jQuery('#SHOW_ONLINE').on('change', (e) => {
      this.filters.showOnline = e.target.checked;
      this.applyFilters();
    });

    jQuery('#SHOW_OFFLINE').on('change', (e) => {
      this.filters.showOffline = e.target.checked;
      this.applyFilters();
    });

    jQuery('#SHOW_EMPTY').on('change', (e) => {
      this.filters.showEmpty = e.target.checked;
      this.applyFilters();
    });

    jQuery('#OPEN_ALL').on('click', () => {
      this.toggleAllCards(true);
    });

    jQuery('#CLOSE_ALL').on('click', () => {
      this.toggleAllCards(false);
    });

    jQuery(document).on('click', '[data-card-widget="collapse"]', (e) => {
      const button = jQuery(e.currentTarget);
      const card = button.closest('.card');
      this.handleCardToggle(card, button);
    });
  }

  handleCardToggle(card, button) {
    const cardBody = card.find('.card-body').first();
    const icon = button.find('i').first();
    const isCollapsed = card.hasClass('collapsed-card');

    if (isCollapsed) {
      card.removeClass('collapsed-card');
      icon.removeClass('fa-plus').addClass('fa-minus');
      cardBody.slideDown(300);
    } else {
      card.addClass('collapsed-card');
      icon.removeClass('fa-minus').addClass('fa-plus');
      cardBody.slideUp(300);
    }
  }

  async loadAndRenderProgressively(parentId, container, level = 0) {
    try {
      const districts = await this.fetchDistricts(parentId);

      if (districts.length === 0) {
        await this.loadAndRenderStreets(parentId, container, level);
        return;
      }

      const districtCards = districts.map(district => {
        const districtCard = this.createAndRenderDistrictSync(district, container, level);
        return { district, districtCard };
      });

      await this.loadDistrictChildrenInBatches(districtCards, level + 1);

    } catch (error) {
      console.error('Error in progressive loading:', error);
      this.showError(container, _INTERNET_DATA_LOADING_ERROR);
    }
  }

  createAndRenderDistrictSync(district, container, level) {
    const districtName = this.getDistrictName(district);
    const districtCard = this.createCard(districtName);
    districtCard.data('district-id', district.id);
    districtCard.data('level', level);

    container.append(districtCard);

    const districtCardBody = districtCard.find('.card-body').first();
    this.showMiniLoading(districtCardBody);

    return districtCard;
  }

  async loadDistrictChildrenInBatches(districtCards, level) {
    for (let i = 0; i < districtCards.length; i += this.config.batchSize) {
      const batch = districtCards.slice(i, i + this.config.batchSize);

      const batchPromises = batch.map(({ district, districtCard }) =>
        this.loadDistrictChildrenAsync(district.id, districtCard, level)
      );

      await Promise.all(batchPromises);
    }
  }

  async loadDistrictChildrenAsync(districtId, districtCard, level) {
    try {
      const districtCardBody = districtCard.find('.card-body').first();

      const childDistricts = await this.fetchDistricts(districtId);

      if (childDistricts.length === 0) {
        await this.loadAndRenderStreets(districtId, districtCardBody, level);
      } else {
        districtCardBody.empty();
        await this.loadAndRenderProgressively(districtId, districtCardBody, level);
      }

      await this.updateDistrictStats(districtCard, districtId);

    } catch (error) {
      console.error('Error loading district children:', error);
      const districtCardBody = districtCard.find('.card-body').first();
      this.showError(districtCardBody, _INTERNET_DATA_LOADING_ERROR);
    }
  }

  async loadAndRenderStreets(districtId, container, level) {
    try {
      const streets = await this.fetchStreets(districtId);

      if (streets.length === 0) {
        this.showEmpty(container, _INTERNET_NO_STREETS_IN_THIS_AREA);
        return;
      }

      container.empty();

      const streetCards = streets.map(street => {
        const streetCard = this.createCard(street.streetName);
        streetCard.data('street-id', street.id);
        streetCard.data('level', level);

        container.append(streetCard);

        const streetCardBody = streetCard.find('.card-body').first();
        const buttonsBlock = jQuery('<div>', { class: 'button-block' });
        streetCardBody.append(buttonsBlock);

        this.showMiniLoading(buttonsBlock);

        return { street, streetCard, buttonsBlock };
      });

      await this.loadStreetBuildsInBatches(streetCards);

    } catch (error) {
      console.error('Error loading streets:', error);
      this.showError(container, _INTERNET_DATA_LOADING_ERROR);
    }
  }

  async loadStreetBuildsInBatches(streetCards) {
    for (let i = 0; i < streetCards.length; i += this.config.batchSize) {
      const batch = streetCards.slice(i, i + this.config.batchSize);

      const batchPromises = batch.map(({ street, streetCard, buttonsBlock }) =>
        this.loadStreetBuildsAsync(street, streetCard, buttonsBlock)
      );

      await Promise.all(batchPromises);
    }
  }

  async loadStreetBuildsAsync(street, streetCard, buttonsBlock) {
    try {
      const builds = await this.fetchBuilds(street.id);

      buttonsBlock.empty();

      if (builds.length === 0) {
        this.showEmpty(buttonsBlock, _INTERNET_NO_BUILDINGS_ON_THIS_STREET);
        return;
      }

      this.renderBuilds(builds, buttonsBlock);

      const streetStats = this.calculateBuildsStats(builds);
      this.updateStreetTitle(streetCard, streetStats);

    } catch (error) {
      console.error('Error loading builds for street:', street.id, error);
      this.showError(buttonsBlock, _INTERNET_DATA_LOADING_ERROR);
    }
  }

  async updateDistrictStats(districtCard, districtId) {
    try {
      const districtTitle = districtCard.find('.card-title').first();
      const originalTitle = districtTitle.text().split(' (')[0];

      let districtChildren = districtCard.find('.card-body').first().children('.card').length || 0;
      districtTitle.html(`${originalTitle} (${districtChildren})`);

    } catch (error) {
      console.error('Error updating district stats:', error);
    }
  }

  showMiniLoading(container) {
    const loadingHtml = `
      <div class='text-center text-muted p-2'>
        <span class='fa fa-spinner fa-spin'></span>
        <small class='ml-2'>${_LOADING}...</small>
      </div>
    `;
    container.html(loadingHtml);
  }

  updateStreetTitle(streetCard, stats) {
    const streetTitle = streetCard.find('.card-title').first();
    const originalTitle = streetTitle.text().split(' (')[0];

    const statsHtml = [
      jQuery('<span>', {
        class: 'text-muted',
        html: stats.total
      }).prop('outerHTML'),
      jQuery('<span>', {
        class: 'text-success',
        html: stats.totalOnline
      }).prop('outerHTML'),
      jQuery('<span>', {
        class: 'text-danger',
        html: stats.totalOffline
      }).prop('outerHTML')
    ].join(' / ');

    streetTitle.html(`${originalTitle} (${statsHtml})`);
  }

  calculateBuildStats(build) {
    let onlineUsers = 0;
    let offlineUsers = 0;
    const tooltipContainer = jQuery('<div></div>');

    if (this.onlineUsers[build.id]) {
      Object.entries(this.onlineUsers[build.id]).forEach(([, user]) => {
        const userSpan = jQuery('<div>', {
          class: 'text-success',
          html: `${this.escapeHtml(user.fio)} - (UID: ${user.uid})`
        });
        tooltipContainer.append(userSpan);
        onlineUsers++;
      });
    }

    if (this.offlineUsers[build.id]) {
      Object.entries(this.offlineUsers[build.id]).forEach(([, user]) => {
        const userSpan = jQuery('<div>', {
          class: 'text-danger',
          html: `${this.escapeHtml(user.fio)} - (UID: ${user.uid})`
        });
        tooltipContainer.append(userSpan);
        offlineUsers++;
      });
    }

    return {
      onlineUsers,
      offlineUsers,
      tooltipHtml: tooltipContainer.html(),
      isEmpty: onlineUsers === 0 && offlineUsers === 0
    };
  }

  calculateBuildsStats(builds) {
    let totalOnline = 0;
    let totalOffline = 0;
    let totalEmpty = 0;

    builds.forEach(build => {
      const buildStats = this.calculateBuildStats(build);
      totalOnline += buildStats.onlineUsers;
      totalOffline += buildStats.offlineUsers;
      if (buildStats.isEmpty) {
        totalEmpty++;
      }
    });

    return {
      totalOnline,
      totalOffline,
      totalEmpty,
      total: builds.length
    };
  }

  renderBuilds(builds, container) {
    const fragment = document.createDocumentFragment();

    builds.forEach(build => {
      const buildStats = this.calculateBuildStats(build);
      const buildButton = this.createBuildButton(build, buildStats);

      buildButton.addClass(this.getBuildFilterClasses(buildStats));

      // Додаємо до фрагменту замість прямого додавання в DOM
      fragment.appendChild(buildButton[0]);

      this.renderTooltip(buildButton, buildStats.tooltipHtml, 'bottom');
    });

    container[0].appendChild(fragment);
  }

  createBuildButton(build, stats) {
    const buttonType = this.getBuildButtonType(stats);

    return jQuery('<a>', {
      id: `BUILD_BTN_${build.id}`,
      class: `btn btn-lg btn-build m-1 ${buttonType}`,
      href: `?index=7&type=11&search=1&search_form=1&LOCATION_ID=${build.id}&BUILDS=99`,
      html: this.escapeHtml(build.number),
      'data-tooltip': stats.tooltipHtml,
      'data-tooltip-position': 'bottom'
    });
  }

  getBuildButtonType(stats) {
    if (stats.isEmpty) return 'btn-default';
    return stats.offlineUsers > stats.onlineUsers ? 'btn-danger' : 'btn-success';
  }

  getBuildFilterClasses(stats) {
    const classes = [];

    if (stats.onlineUsers > 0) classes.push('has-online');
    if (stats.offlineUsers > 0) classes.push('has-offline');
    if (stats.isEmpty) classes.push('is-empty');

    return classes.join(' ');
  }

  getDistrictName(district) {
    const typeName = this.districtTypes[district.typeName] || district.typeName || _DISTRICT;
    return `${typeName} ${district.name}`;
  }

  createCard(titleText, stats = null) {
    const card = jQuery('<div>', {
      class: 'card card-big-form container collapsed-card'
    });

    const cardHeader = jQuery('<div>', {
      class: 'card-header-custom with-border'
    });

    let titleHtml = this.escapeHtml(titleText);
    if (stats && stats.total > 0) {
      const statsHtml = [
        jQuery('<span>', {
          class: 'text-muted',
          html: stats.total
        }).prop('outerHTML'),
        jQuery('<span>', {
          class: 'text-success',
          html: stats.online
        }).prop('outerHTML'),
        jQuery('<span>', {
          class: 'text-danger',
          html: stats.offline
        }).prop('outerHTML')
      ].join(' / ');

      titleHtml += ` (${statsHtml})`;
    }

    const cardTitle = jQuery('<h4>', {
      class: 'card-title',
      html: titleHtml
    });

    const cardTools = jQuery('<div>', {
      class: 'card-tools float-right'
    });

    const collapseButton = jQuery('<button>', {
      type: 'button',
      class: 'btn btn-tool',
      'data-card-widget': 'collapse'
    }).append(
      jQuery('<i>', { class: 'fa fa-plus' })
    );

    const cardBody = jQuery('<div>', {
      class: 'card-body',
      css: { display: 'none' }
    });

    cardTools.append(collapseButton);
    cardHeader.append(cardTitle, cardTools);
    card.append(cardHeader, cardBody);

    return card;
  }

  showLoading(container) {
    const loadingHtml = `
      <div id='status-loading-content'>
        <div class='text-center'>
          <span class='fa fa-spinner fa-spin fa-2x'></span>
          <div class='mt-2'>${_LOADING}...</div>
        </div>
      </div>
    `;
    container.html(loadingHtml);
  }

  showError(container, message) {
    const errorHtml = `
      <div class='alert alert-danger' role='alert'>
        <i class='fa fa-exclamation-triangle'></i>
        ${this.escapeHtml(message)}
      </div>
    `;
    container.html(errorHtml);
  }

  showEmpty(container, message) {
    const emptyHtml = `
      <div class='alert alert-info' role='alert'>
        <i class='fa fa-info-circle'></i>
        ${this.escapeHtml(message)}
      </div>
    `;
    container.html(emptyHtml);
  }

  applyFilters() {
    requestAnimationFrame(() => {
      const builds = jQuery('.btn-build');

      builds.each((index, element) => {
        const build = jQuery(element);
        const shouldShow = this.shouldShowBuild(build);

        if (shouldShow) {
          build.show();
        } else {
          build.hide();
        }
      });

      this.hideEmptyStreets();
    });
  }

  shouldShowBuild(build) {
    const hasOnline = build.hasClass('has-online');
    const hasOffline = build.hasClass('has-offline');
    const isEmpty = build.hasClass('is-empty');

    if (hasOnline && !this.filters.showOnline) return false;
    if (hasOffline && !this.filters.showOffline) return false;
    if (isEmpty && !this.filters.showEmpty) return false;

    return true;
  }

  hideEmptyStreets() {
    jQuery('.card[data-street-id]').each((index, element) => {
      const streetCard = jQuery(element);
      const visibleBuilds = streetCard.find('.btn-build:visible');

      if (visibleBuilds.length === 0) {
        streetCard.hide();
      } else {
        streetCard.show();
      }
    });
  }

  toggleAllCards(expand) {
    const cards = jQuery('.card');

    cards.each((index, element) => {
      const card = jQuery(element);
      const button = card.find('[data-card-widget="collapse"]').first();
      const isCollapsed = card.hasClass('collapsed-card');

      if (expand && isCollapsed) {
        button.click();
      } else if (!expand && !isCollapsed) {
        button.click();
      }
    });
  }

  async fetchDistricts(parentId) {
    const cacheKey = `districts_${parentId}`;

    if (this.cache.districts.has(cacheKey)) {
      return this.cache.districts.get(cacheKey);
    }

    return this.requestSemaphore.acquire(async () => {
      try {
        const response = await sendRequest(
          `/api.cgi/districts?PARENT_ID=${parentId}&TYPE_NAME&PAGE_ROWS=1000000&SORT=name`,
          {},
          'GET'
        );
        const result = Array.isArray(response) ? response : [];
        this.cache.districts.set(cacheKey, result);
        return result;
      } catch (error) {
        console.error('Error fetching districts:', error);
        return [];
      }
    });
  }

  async fetchStreets(districtId) {
    const cacheKey = `streets_${districtId}`;

    if (this.cache.streets.has(cacheKey)) {
      return this.cache.streets.get(cacheKey);
    }

    return this.requestSemaphore.acquire(async () => {
      try {
        const response = await sendRequest(
          `/api.cgi/streets?DISTRICT_ID=${districtId}&DISTRICT_NAME=_SHOW`,
          {},
          'GET'
        );
        const result = Array.isArray(response) ? response : [];
        this.cache.streets.set(cacheKey, result);
        return result;
      } catch (error) {
        console.error('Error fetching streets:', error);
        return [];
      }
    });
  }

  async fetchBuilds(streetId) {
    const cacheKey = `builds_${streetId}`;

    if (this.cache.builds.has(cacheKey)) {
      return this.cache.builds.get(cacheKey);
    }

    return this.requestSemaphore.acquire(async () => {
      try {
        const response = await sendRequest(
          `/api.cgi/builds?STREET_ID=${streetId}`,
          {},
          'GET'
        );
        const result = Array.isArray(response) ? response : [];
        this.cache.builds.set(cacheKey, result);
        return result;
      } catch (error) {
        console.error('Error fetching builds:', error);
        return [];
      }
    });
  }

  async createDistrict(parentId = 0, container = null) {
    if (!container) {
      container = jQuery('#DISTRICT_PANELS');
    }

    try {
      const initialCheck = await this.fetchDistricts(parentId);

      if (initialCheck.length > this.config.maxElementsWarning) {

      }

      container.empty();

      await this.loadAndRenderProgressively(parentId, container);

      this.applyFilters();
      jQuery('#status-loading-content').addClass('d-none');

    } catch (error) {
      console.error('Error creating district:', error);
      this.showError(container, _INTERNET_DATA_LOADING_ERROR);
    }
  }

  renderTooltip(element, content, position) {
    if (typeof renderTooltip === 'function') {
      renderTooltip(element, content, position);
    } else {
      element.attr('title', content);
    }
  }

  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  setOnlineUsers(onlineUsers) {
    this.onlineUsers = onlineUsers;
  }

  setOfflineUsers(offlineUsers) {
    this.offlineUsers = offlineUsers;
  }

  setDistrictTypes(districtTypes) {
    this.districtTypes = districtTypes;
  }

  async updateData(newData = {}) {
    if (newData.onlineUsers) this.setOnlineUsers(newData.onlineUsers);
    if (newData.offlineUsers) this.setOfflineUsers(newData.offlineUsers);
    if (newData.districtTypes) this.setDistrictTypes(newData.districtTypes);

    this.cache.districts.clear();
    this.cache.streets.clear();
    this.cache.builds.clear();
    this.cache.hierarchy.clear();

    await this.createDistrict();
  }
}

class Semaphore {
  constructor(maxConcurrent) {
    this.maxConcurrent = maxConcurrent;
    this.current = 0;
    this.queue = [];
  }

  async acquire(fn) {
    return new Promise((resolve, reject) => {
      this.queue.push({ fn, resolve, reject });
      this.process();
    });
  }

  process() {
    if (this.current >= this.maxConcurrent || this.queue.length === 0) {
      return;
    }

    this.current++;
    const { fn, resolve, reject } = this.queue.shift();

    fn()
      .then(resolve)
      .catch(reject)
      .finally(() => {
        this.current--;
        this.process();
      });
  }
}