class SubTariffs {
  constructor(options = {}) {
    this.tariffsForm = null;
    this.renderedSubTariffRows = new Map();
    this.subTariffDependencies = new Map();
    this.activatedMainTariffs = new Set();
    this.allActivatedTariffs = new Map();
    this.apiResponseCache = new Map();

    this.PERIODS = new Map([
      [0, "Day"],
      [1, "Month"],
      [2, "Quarter"],
      [3, "Six month"],
      [4, "Year"]
    ]);

    this.config = {
      formId: 'ABON_USER_TPS',
      checkboxName: 'IDS',
      subTariffsApiEndpoint: '/api.cgi/abon/tariffs?TP_NAME&MAIN_TP_ID=',
      tariffInfoUrl: '?get_index=abon_tariffs&full=1&ABON_ID=',
      requestTimeout: 5000,
      ...options
    };

    this.initializeAsync();
  }

  /**
   * Async initialization wrapper
   */
  async initializeAsync() {
    try {
      await this.initialize();
    } catch (error) {
      console.error('Async initialization failed:', error);
    }
  }

  /**
   * Initialize the component
   */
  async initialize() {
    try {
      this.tariffsForm = jQuery(`#${this.config.formId}`);

      if (!this.tariffsForm.length) {
        throw new Error(`Form with ID ${this.config.formId} not found`);
      }

      const userIdInput = this.tariffsForm.find(`[name='UID']`).first();
      this.config.userId = userIdInput.val();

      if (!this.config.userId) {
        console.warn('User ID not found in form');
      }

      this.config.changeTariffUrl = `?get_index=abon_user&full=1&UID=${this.config.userId}&chg=`;

      this.setupEventListeners();

      const apiResponseData = await this.fetchData(`/api.cgi/abon/users?UID=${this.config.userId}`);
      const userActivatedTariffs = Array.isArray(apiResponseData) ? apiResponseData : [];

      userActivatedTariffs.forEach(tariff => {
        this.allActivatedTariffs.set(tariff?.id, tariff);
      });

      await this.processInitiallyActiveTariffs();
    } catch (error) {
      console.error('Failed to initialize SubTariffs:', error);
      throw error;
    }
  }

  /**
   * Process tariffs that are already checked on page load
   */
  async processInitiallyActiveTariffs() {
    const checkedCheckboxes = jQuery(`[name='${this.config.checkboxName}']:checked`);

    if (checkedCheckboxes.length === 0) {
      return;
    }

    for (let i = 0; i < checkedCheckboxes.length; i++) {
      const checkbox = jQuery(checkedCheckboxes[i]);
      const tariffId = checkbox.val();

      if (!tariffId) {
        continue;
      }

      try {
        this.activatedMainTariffs.add(tariffId);

        await this.fetchSubTariffs(tariffId);
        this.handleSubTariffs(checkbox);
      } catch (error) {
        console.error(`Error processing initially active tariff ${tariffId}:`, error);
      }
    }
  }
  setupEventListeners() {
    const checkboxes = jQuery(`[name='${this.config.checkboxName}']`);

    if (!checkboxes.length) {
      console.warn(`No checkboxes found with name ${this.config.checkboxName}`);
      return;
    }

    checkboxes.off('change.subtariffs').on('change.subtariffs', this.handleTariffCheckbox.bind(this));
  }

  /**
   * Handle tariff checkbox change event
   * @param {Event} event - The change event
   */
  async handleTariffCheckbox(event) {
    const checkbox = jQuery(event.target);
    const tariffId = checkbox.val();

    if (!tariffId) {
      console.warn('No tariff ID found in checkbox');
      return;
    }

    try {
      await this.fetchSubTariffs(tariffId);
      this.handleSubTariffs(checkbox);
    } catch (error) {
      console.error(`Error handling tariff checkbox for ID ${tariffId}:`, error);
    }
  }

  /**
   * Handle sub tariffs display logic
   * @param {jQuery} checkbox - The checkbox element
   */
  handleSubTariffs(checkbox) {
    const tariffId = checkbox.val();
    const isChecked = checkbox.prop('checked');
    const tableRow = checkbox.closest('tr');

    if (!tableRow.length) {
      console.error('Table row not found for checkbox');
      return;
    }

    this.updateActivatedTariffs(tariffId, isChecked);

    const subTariffs = this.apiResponseCache.get(tariffId) || [];

    if (subTariffs.length === 0) {
      return;
    }

    subTariffs.forEach(subTariff => this.processSubTariff(subTariff, tariffId, isChecked, tableRow));
  }

  /**
   * Update the set of activated main tariffs
   * @param {string} tariffId - Tariff plan ID
   * @param {boolean} isChecked - Whether checkbox is checked
   */
  updateActivatedTariffs(tariffId, isChecked) {
    if (isChecked) {
      this.activatedMainTariffs.add(tariffId);
    } else {
      this.activatedMainTariffs.delete(tariffId);
    }
  }

  /**
   * Process individual sub tariff
   * @param {Object} subTariff - Sub tariff object
   * @param {string} parentTariffId - Parent tariff ID
   * @param {boolean} isParentChecked - Whether parent is checked
   * @param {jQuery} parentRowElement - Parent table row
   */
  processSubTariff(subTariff, parentTariffId, isParentChecked, parentRowElement) {
    const { id } = subTariff;

    if (!isParentChecked) {
      this.handleSubTariffRemoval(id, parentTariffId);
      return;
    }

    this.handleSubTariffAddition(subTariff, parentTariffId, parentRowElement);
  }

  /**
   * Handle sub tariff removal logic
   * @param {string} subTariffId - Sub tariff ID
   * @param {string} parentTariffId - Parent tariff ID
   */
  handleSubTariffRemoval(subTariffId, parentTariffId) {
    const requiredParentTariffs = this.subTariffDependencies.get(subTariffId) || [];
    const hasAnyActiveParent = requiredParentTariffs.some(tariffId => this.activatedMainTariffs.has(tariffId));

    if (!hasAnyActiveParent && this.renderedSubTariffRows.has(subTariffId)) {
      this.renderedSubTariffRows.get(subTariffId).detach();
    }
  }

  /**
   * Handle sub tariff addition logic
   * @param {Object} subTariff - Sub tariff object
   * @param {string} parentTariffId - Parent tariff ID
   * @param {jQuery} parentRowElement - Parent table row
   */
  handleSubTariffAddition(subTariff, parentTariffId, parentRowElement) {
    const { id } = subTariff;

    if (!this.subTariffDependencies.has(id)) {
      this.subTariffDependencies.set(id, []);
    }

    const requiredParentTariffs = this.subTariffDependencies.get(id);
    if (!requiredParentTariffs.includes(parentTariffId)) {
      requiredParentTariffs.push(parentTariffId);
    }

    if (this.renderedSubTariffRows.has(id)) {
      parentRowElement.after(this.renderedSubTariffRows.get(id));
      return;
    }

    const newRowElement = this.createSubTariffRow(subTariff, parentRowElement);
    this.renderedSubTariffRows.set(id, newRowElement);
    parentRowElement.after(newRowElement);

    if (typeof initDatepickers === 'function') {
      initDatepickers();
    }
  }

  /**
   * Create a new sub tariff row
   * @param {Object} subTariff - Sub tariff object
   * @param {jQuery} templateRowElement - Template row to clone
   * @returns {jQuery} - New row element
   */
  createSubTariffRow(subTariff, templateRowElement) {
    const { id, tpName, price, period } = subTariff;
    const clonedRowElement = templateRowElement.clone();
    const activatedTariffInfo = this.allActivatedTariffs.has(id) ? this.allActivatedTariffs.get(id) : {};

    clonedRowElement.find('input[type="checkbox"]')
      .val(id)
      .prop('checked', this.allActivatedTariffs.has(id));

    const cellElements = clonedRowElement.find('td');
    cellElements.eq(1).text(id);
    cellElements.eq(5).text(price || '');
    cellElements.eq(6).text(this.PERIODS.get(period) || this.PERIODS.get(0));

    const linkElement = cellElements.eq(2).find('a');
    if (linkElement.length) {
      linkElement.text(tpName || '')
        .attr('href', `${this.config.tariffInfoUrl}${id}`)
        .attr('title', tpName || '');
    }

    cellElements.eq(9).text('');


    this.updateInputElements(clonedRowElement, id);
    const cell10 = cellElements.eq(10);

    if (this.allActivatedTariffs.has(id)) {
      cell10.text(activatedTariffInfo?.nextAbon);
      cellElements.eq(9).text(activatedTariffInfo?.date);
      cellElements.eq(8).find('input').val(activatedTariffInfo?.feesPeriod);
      cellElements.eq(7).find('input').val(activatedTariffInfo?.serviceCount);
      cellElements.eq(4).find('input').val(activatedTariffInfo?.comments);
      cellElements.eq(3).find('input').val(activatedTariffInfo?.personalDescription);
    }
    else {
      if (!cell10.find('input').length) {
        cell10.text('');
        const dateInput = jQuery(`<input type="text" name="DATE_${id}" value="0000-00-00" size="10" class="form-control datepicker" id="DATE_${id}" form="${this.config.formId}">`);
        cell10.append(dateInput);
      } else {
        const existingInput = cell10.find('input');
        existingInput.attr('name', `DATE_${id}`)
          .attr('id', `DATE_${id}`)
          .val('0000-00-00');
      }
    }

    cellElements.eq(11).text('');

    return clonedRowElement;
  }

  /**
   * Update input elements in cloned row
   * @param {jQuery} rowElement - The row element
   * @param {string} newTariffId - New ID to use
   */
  updateInputElements(rowElement, newTariffId) {
    rowElement.find('input[type="text"]').each(function() {
      const inputElement = jQuery(this);

      const oldName = inputElement.attr('name');
      if (oldName) {
        const newName = oldName.replace(/_\d+$/, `_${newTariffId}`);
        inputElement.attr('name', newName);
      }

      const oldId = inputElement.attr('id');
      if (oldId) {
        const newIdAttribute = oldId.replace(/_\d+$/, `_${newTariffId}`);
        inputElement.attr('id', newIdAttribute);
      }

      inputElement.val('');
    });
  }

  /**
   * Fetch data with error handling and timeout
   * @param {string} url - Request URL
   * @param {Object} params - Request parameters
   * @param {string} method - HTTP method
   * @param {number} timeout - Timeout in ms
   * @returns {Promise} - Promise with response
   */
  async fetchData(url, params = {}, method = 'GET', timeout = this.config.requestTimeout) {
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Request timeout')), timeout)
    );

    try {
      const fetchPromise = sendRequest(url, params, method);
      return await Promise.race([fetchPromise, timeoutPromise]);
    } catch (error) {
      console.error(`Error fetching data from ${url}:`, error);
      throw error;
    }
  }

  /**
   * Fetch and cache sub tariffs
   * @param {string} tariffId - Tariff plan ID
   * @returns {Promise<Array>} - Promise with sub tariffs
   */
  async fetchSubTariffs(tariffId) {
    if (!tariffId) {
      return [];
    }

    // Return cached data if available
    if (this.apiResponseCache.has(tariffId)) {
      return this.apiResponseCache.get(tariffId);
    }

    try {
      const apiResponseData = await this.fetchData(`${this.config.subTariffsApiEndpoint}${tariffId}`);

      const subTariffs = Array.isArray(apiResponseData) ? apiResponseData : [];
      this.apiResponseCache.set(tariffId, subTariffs);

      return subTariffs;
    } catch (error) {
      console.error(`Failed to fetch sub tariffs for ${tariffId}:`, error);
      this.apiResponseCache.set(tariffId, []);
      return [];
    }
  }

  /**
   * Set custom periods mapping
   * @param {Object|Map} periods - Periods mapping (object or Map)
   */
  setPeriods(periods) {
    if (!periods) {
      throw new Error('Periods parameter is required');
    }

    if (periods instanceof Map) {
      this.PERIODS = new Map(periods);
    } else if (typeof periods === 'object') {
      this.PERIODS = new Map(Object.entries(periods).map(([key, value]) => [parseInt(key), value]));
    } else {
      throw new Error('Periods must be an object or Map');
    }
  }
}