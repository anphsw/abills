/**
 * Handles tariff calculations based on user speed settings
 */
class TariffCalculator {
  constructor() {
    this.tariffsGradients = {};
    this.currentTpId = 0;
    this.userReduction = 0;
    this.tariffReduction = false;
    this.personalTpStartValue = 0;

    this.SELECTORS = {
      userId: () => jQuery('[name="UID"]').val(),
      internetId: () => jQuery('[name="ID"]').val(),
      tpSelector: 'select#TP_ID',
      speedInput: '#SPEED',
      personalTp: '#PERSONAL_TP'
    };

    this.SIZE_UNITS = {
      'b': 1024,
      'kb': 1,
      'mb': 1 / 1024,
      'gb': 1 / (1024 ** 2),
      'tb': 1 / (1024 ** 3)
    };

    this.handleSpeedChange = this.handleSpeedChange.bind(this);
    this.handleTariffChange = this.handleTariffChange.bind(this);

    this.$speedInput = null;
    this.$personalTp = null;
    this.$tpSelector = null;
  }

  /**
   * Performs API requests with error handling and timeouts
   * @param {string} url - Request URL
   * @param {Object} params - Request parameters
   * @param {string} method - HTTP method
   * @param {number} timeout - Timeout in ms
   * @returns {Promise} - Promise with response
   */
  async fetchData(url, params = {}, method = 'GET', timeout = 5000) {
    try {
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Request timeout')), timeout)
      );

      const fetchPromise = sendRequest(url, params, method);
      return await Promise.race([fetchPromise, timeoutPromise]);
    } catch (error) {
      console.error(`Error fetching data from ${url}:`, error);
      throw error;
    }
  }

  /**
   * Converts size between different units
   * @param {string} valueWithUnit - Value with unit
   * @param {string} targetUnit - Target unit
   * @returns {number|null} - Converted value or null
   */
  convertSize(valueWithUnit, targetUnit) {
    if (!valueWithUnit || !targetUnit) return null;

    targetUnit = targetUnit.toLowerCase();
    const match = String(valueWithUnit).match(/^(\d+(?:\.\d+)?)([a-zA-Z]+)$/);
    if (!match) return null;

    const value = parseFloat(match[1]);
    const sourceUnit = match[2].toLowerCase();

    if (!(sourceUnit in this.SIZE_UNITS) || !(targetUnit in this.SIZE_UNITS)) return null;

    const valueInKilobits = value / this.SIZE_UNITS[sourceUnit];
    return Math.round(valueInKilobits * this.SIZE_UNITS[targetUnit]);
  }

  /**
   * Loads and caches tariff gradients
   * @param {number} tpId - Tariff plan ID
   * @returns {Promise<Array>} - Promise with gradients
   */
  async fetchTariffGradient(tpId) {
    if (!tpId) return [];

    if (this.tariffsGradients[tpId]) {
      return this.tariffsGradients[tpId];
    }

    try {
      const data = await this.fetchData(`/api.cgi/internet/tariff/${tpId}`);

      if (!data || !data.gradients || !Array.isArray(data.gradients)) {
        this.tariffsGradients[tpId] = [];
        return [];
      }

      this.tariffReduction = !!data.reductionFee;
      this.tariffsGradients[tpId] = data.gradients.sort((a, b) => a.startValue - b.startValue);
      return this.tariffsGradients[tpId];
    } catch (error) {
      this.tariffsGradients[tpId] = [];
      return [];
    }
  }

  /**
   * Calculates price based on speed and gradients
   * @param {number} speed - Speed value
   * @returns {number|null} - Calculated price or null
   */
  calculatePrice(speed) {
    if (!this.currentTpId ||
      !this.tariffsGradients[this.currentTpId] ||
      !this.tariffsGradients[this.currentTpId].length) {
      return null;
    }

    const gradients = this.tariffsGradients[this.currentTpId];
    const minStartValue = gradients[0].startValue;
    const maxStartValue = gradients[gradients.length - 1].startValue;

    if (speed < minStartValue) {
      return null;
    }

    if (speed >= maxStartValue) {
      return this.applyReduction(
        gradients[gradients.length - 1].price * this.convertSize(`${speed}kb`, 'mb')
      );
    }

    const selectedGradient = gradients
      .filter(g => g.startValue <= speed)
      .reduce((max, g) => (!max || g.startValue > max.startValue ? g : max), null);

    if (!selectedGradient) return null;

    const price = selectedGradient.price * this.convertSize(`${speed}kb`, 'mb');
    return this.applyReduction(price);
  }

  /**
   * Applies reduction to price
   * @param {number} price - Initial price
   * @returns {number} - Price with reduction
   */
  applyReduction(price) {
    if (price <= 0 || !this.tariffReduction || !this.userReduction) {
      return price;
    }

    return +(price - (price * this.userReduction / 100)).toFixed(2);
  }

  /**
   * Speed change handler
   */
  handleSpeedChange() {
    let speed = this.$speedInput.val() || '0';

    const match = String(speed).match(/^(\d+)([a-zA-Z]*)$/);
    if (!match) return;

    if (match[2]) {
      const convertedSpeed = this.convertSize(speed, 'kb');
      if (convertedSpeed) {
        speed = convertedSpeed;
        this.$speedInput.val(speed);
      } else {
        speed = parseInt(speed, 10) || 0;
      }
    } else {
      speed = parseInt(speed, 10) || 0;
    }

    const price = this.calculatePrice(speed);
    this.$personalTp.val(price !== null ? price : this.personalTpStartValue || '');
  }

  /**
   * Tariff plan change handler
   */
  handleTariffChange() {
    const tpId = this.$tpSelector.val();
    this.currentTpId = tpId;

    this.fetchTariffGradient(tpId).then(() => {
      this.handleSpeedChange();
    });
  }

  /**
   * Loads user data
   * @returns {Promise} - Promise that resolves after loading data
   */
  async loadUserData() {
    try {
      const userId = this.SELECTORS.userId();
      if (!userId) return;

      const data = await this.fetchData(`/api.cgi/users/${userId}`);
      this.userReduction = data?.reduction || 0;
    } catch (error) {
      this.userReduction = 0;
    }
  }

  /**
   * Loads initial user tariff
   * @returns {Promise} - Promise that resolves after loading data
   */
  async loadInitialTariff() {
    try {
      const userId = this.SELECTORS.userId();
      const internetId = this.SELECTORS.internetId();
      if (!userId || !internetId) return;

      const data = await this.fetchData(`/api.cgi/users/${userId}/internet/${internetId}`);
      if (data && data.tpId) {
        this.currentTpId = data.tpId;
        await this.fetchTariffGradient(data.tpId);
      }
    } catch (error) {
      console.error(error);
    }
  }

  /**
   * Initializes cached DOM elements
   */
  initDomElements() {
    this.$speedInput = jQuery(this.SELECTORS.speedInput);
    this.$personalTp = jQuery(this.SELECTORS.personalTp);
    this.$tpSelector = jQuery(this.SELECTORS.tpSelector);

    this.personalTpStartValue = this.$personalTp.val();
  }

  /**
   * Sets up event listeners
   */
  setupEventListeners() {
    this.$speedInput.on('input', this.handleSpeedChange);

    if (this.$tpSelector.length > 0) {
      this.$tpSelector.on('change', this.handleTariffChange);
    }
  }

  /**
   * Initializes the tariff calculator
   * @returns {Promise} - Promise that resolves after initialization
   */
  async init() {
    this.initDomElements();

    await this.loadUserData();

    if (this.$tpSelector.length < 1) {
      await this.loadInitialTariff();
    } else {
      this.currentTpId = this.$tpSelector.val();
      await this.fetchTariffGradient(this.currentTpId);
    }

    this.setupEventListeners();

    this.handleSpeedChange();

    console.log('TariffCalculator initialized successfully');
  }
}