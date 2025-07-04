/**
 * Handles messages search functionality with improved modularity and error handling
 */
class MessagesSearch {
  /**
   * Constructor for MessagesSearch
   * @param {Object} options - Configuration options for the search functionality
   */
  constructor(options = {}) {
    this.$searchContainer = null;
    this.$searchInput = null;
    this.$searchBtn = null;
    this.$tableRows = null;
    this.$resultsTable = null;
    this.$tablePagination = null;

    this.titles = null;
    this.statuses = {};

    this.config = {
      minSearchLength: 3,
      requestTimeout: 5000,
      searchEndpoint: '/api.cgi/msgs/search/',
      defaultSearchParams: {
        message: '_SHOW',
        replyText: '_SHOW',
        state: '_SHOW',
        chapterName: '_SHOW',
        date: '_SHOW',
        responsible: '_SHOW',
        subject: '_SHOW',
        desc: 'DESC'
      },
      hiddenColumns: ['chapter'],
      messageUrl: '?get_index=msgs_admin&full=1&chg=',
      ...options
    };

    this.handleSearchButtonPress = this.handleSearchButtonPress.bind(this);
  }

  /**
   * Set the search container element
   * @param {jQuery|HTMLElement} element - Search container element
   */
  setSearchContainer(element) {
    this.$searchContainer = jQuery(element);
  }

  /**
   * Convert object keys to camelCase
   * @param {Object|Array} obj - Object or array to convert
   * @returns {Object|Array} Converted object or array
   */
  convertKeysToCamelCase(obj) {
    if (Array.isArray(obj)) {
      return obj.map(this.convertKeysToCamelCase);
    }

    if (obj !== null && typeof obj === 'object') {
      return Object.fromEntries(
        Object.entries(obj).map(([key, value]) => [
          this.toCamelCase(key),
          this.convertKeysToCamelCase(value)
        ])
      );
    }

    return obj;
  }

  /**
   * Convert snake_case to camelCase
   * @param {string} str - String to convert
   * @returns {string} Converted string
   */
  toCamelCase(str) {
    return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
  }

  /**
   * Set table titles with camelCase conversion
   * @param {Object} titles - Titles object
   */
  setTableTitles(titles) {
    this.titles = this.convertKeysToCamelCase(titles);
  }

  /**
   * Set message statuses with color parsing
   * @param {Object} statuses - Statuses object
   */
  setMessageStatuses(statuses) {
    this.statuses = Object.entries(statuses).reduce((acc, [key, value]) => {
      const match = value.match(/(.+):(#\w{6})$/);

      acc[key] = match
        ? jQuery("<span>").text(match[1].trim()).css("color", match[2])
        : jQuery("<span>").text(value);

      return acc;
    }, {});
  }

  /**
   * Fetch data with timeout and error handling
   * @param {string} url - Request URL
   * @param {Object} params - Request parameters
   * @param {string} method - HTTP method
   * @param {number} timeout - Timeout in ms
   * @returns {Promise} - Promise with response
   */
  async fetchData(
    url,
    params = {},
    method = 'GET',
    timeout = this.config.requestTimeout
  ) {
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
   * Creates a table from an array of objects with text highlighting capability
   * @param {Array} list - Array of objects to display
   * @param {string} highlightText - Text to highlight
   * @param {string|Array} highlightColumns - Column name(s) for highlighting (default 'subject')
   * @param {Object} options - Additional settings
   * @returns {jQuery} jQuery table object
   */
  createTableFromList(list, highlightText = '', highlightColumns = 'subject', options = {}) {
    const defaults = {
      tableClass: 'table table-striped table-hover table-sm',
      maxCellWidth: '350px',
      maxCellHeight: '150px',
      highlightColor: '#fff3cd',
      responsive: true,
      maxContentLength: 10000,
      customRenderers: {},
      hiddenColumns: [],
      columnOrder: [],
      total: list.length
    };

    const settings = { ...defaults, ...options };

    if (!Array.isArray(list) || list.length === 0) {
      return jQuery('<div class="table-responsive pl-2 pr-2">')
        .append(jQuery(`<div class="alert alert-warning">${_NO_MATCHES_FOUND}</div>`));
    }

    const escapeHtml = (unsafe) => {
      if (typeof unsafe !== 'string') {
        return String(unsafe);
      }
      return unsafe
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    };

    const sanitizeContent = (content) => {
      if (content === null || content === undefined) {
        return '';
      }

      const stringContent = String(content);
      const { maxContentLength } = settings;

      return stringContent.length > maxContentLength
        ? `${stringContent.substring(0, maxContentLength)}...(truncated)`
        : stringContent;
    };

    const highlightTextInContent = (content, textToHighlight) => {
      if (!content || !textToHighlight || textToHighlight.trim() === '') {
        return escapeHtml(content);
      }

      try {
        const escapedContent = escapeHtml(content);
        const safeSearchText = textToHighlight.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const regex = new RegExp(safeSearchText, 'gi');

        return escapedContent.replace(
          regex,
          match => `<mark class="bg-warning text-dark font-weight-bold">${match}</mark>`
        );
      } catch (e) {
        console.error('Error highlighting text:', e);
        return escapeHtml(content);
      }
    };

    const allColumns = list.length > 0 ? Object.keys(list[0]) : [];

    let visibleColumns = allColumns.filter(col => !settings.hiddenColumns.includes(col));

    if (Array.isArray(settings.columnOrder) && settings.columnOrder.length > 0) {
      const orderedColumns = settings.columnOrder.filter(col => visibleColumns.includes(col));

      const remainingColumns = visibleColumns
        .filter(col => !orderedColumns.includes(col))
        .sort((a, b) => a.localeCompare(b));

      visibleColumns = [...orderedColumns, ...remainingColumns];
    } else {
      visibleColumns.sort((a, b) => a.localeCompare(b));
    }

    const validateColumns = (cols) => {
      if (!cols) return [];
      const colArray = Array.isArray(cols) ? cols : [cols];
      return colArray.filter(col => visibleColumns.includes(col));
    };

    const columnsToHighlight = validateColumns(highlightColumns);

    const shouldHighlight = Boolean(highlightText && highlightText.trim());

    const thead = jQuery('<thead>').append(
      jQuery('<tr>').append(
        visibleColumns.map(col => {
          const columnTitle = this.titles && this.titles[col] ? this.titles[col] : col;
          return jQuery('<th scope="col">').text(sanitizeContent(columnTitle));
        })
      )
    );

    const tbody = jQuery('<tbody>').append(
      list.map((item, rowIndex) => {
        if (!item || typeof item !== 'object') {
          return jQuery('<tr>').append(
            jQuery(`<td colspan="${visibleColumns.length}">`).text('Invalid row data')
          );
        }

        return jQuery('<tr>').append(
          visibleColumns.map(col => {
            const cellContent = item[col] ?? '';
            const td = jQuery('<td>');

            if (typeof cellContent === 'string' && cellContent.length > 80) {
              td.css({
                'max-width': settings.maxCellWidth,
                'max-height': settings.maxCellHeight,
                'overflow': 'auto',
                'white-space': 'pre-wrap',
                'word-break': 'break-word',
                'position': 'relative'
              }).addClass('text-cell');
            }

            const hasCustomRenderer = settings.customRenderers[col] &&
              typeof settings.customRenderers[col] === 'function';
            const needsHighlighting = shouldHighlight && columnsToHighlight.includes(col);

            if (hasCustomRenderer) {
              const rendererOptions = needsHighlighting
                ? { highlightText, highlightTextFunc: highlightTextInContent }
                : {};

              const renderedContent = settings.customRenderers[col](
                cellContent,
                item,
                rowIndex,
                rendererOptions
              );

              return td.html(renderedContent);
            }
            else if (needsHighlighting) {
              return td.html(highlightTextInContent(cellContent, highlightText));
            }
            else {
              return td.text(sanitizeContent(cellContent));
            }
          })
        );
      })
    );

    const table = jQuery('<table>', {
      class: settings.tableClass,
      'data-rows': list.length
    }).append(thead, tbody);

    return settings.responsive
      ? jQuery('<div class="table-responsive">')
        .append(jQuery(`<div class='alert alert-success mr-2 ml-2'>${_MATCHES_FOUND}: ${settings?.total}</div>`))
        .append(table)
      : table;
  }

  /**
   * Handle search button press event
   */
  handleSearchButtonPress() {
    const searchText = this.$searchInput.val() || '';

    if (this.$searchBtn.hasClass('disabled')) return;

    if (searchText.length < this.config.minSearchLength) {
      this.$tableRows.removeClass('d-none');
      if (this.$resultsTable) this.$resultsTable.remove();
      return;
    }

    this.$searchBtn.addClass('disabled');

    this.loadFoundMessages()
      .then(status => {
        if (status) {
          this.$tableRows.addClass('d-none')
        }
        else {
          this.$tableRows.removeClass('d-none')
        }
      })
      .catch(error => {
        console.error('Search failed:', error);
      })
      .finally(() => this.$searchBtn.removeClass('disabled'));
  }

  /**
   * Load and display found messages
   */
  async loadFoundMessages() {
    try {
      const searchText = this.$searchInput.val();

      const params = {
        searchText,
        ...this.config.defaultSearchParams,
      };
      const data = await this.fetchData(this.config.searchEndpoint, params, 'POST');

      if (this.$resultsTable) this.$resultsTable.remove();

      this.$resultsTable = this.createTableFromList(
        data?.list || [],
        searchText,
        ['subject', 'message', 'replyText'],
        {
          hiddenColumns: this.config.hiddenColumns,
          columnOrder: ['id', 'subject', 'message', 'replyText'],
          customRenderers: {
            state: (value) =>
              this.statuses[value]?.clone() || value,
            subject: (value, rowData, _, rendererOptions) =>
              jQuery('<a>')
                .attr('href', `${this.config.messageUrl}${rowData?.id}`)
                .html(rendererOptions.highlightTextFunc(value, rendererOptions.highlightText))
          },
          total: data?.total
        }
      );

      if (this.$resultsTable !== null) {
        this.$tableRows.before(this.$resultsTable);
      }

      return data?.total > 0;
    } catch (error) {
      console.error('Error loading messages:', error);
    }

    return false;
  }

  /**
   * Initialize DOM elements
   */
  initDomElements() {
    this.$tablePagination = this.$searchContainer.find('.pagination').first();
    this.hasPagination = this.$tablePagination.length > 0;

    this.$searchElement = this.createSearchElement();

    this.$searchContainer
      .removeClass('col-md-6')
      .addClass('col-md-12')
      .append(this.$searchElement);

    this.$tableRows = jQuery(`#${this.config?.tableId || 'MSGS_LIST_'}`);
  }

  /**
   * Set up event listeners
   */
  setupEventListeners() {
    this.$searchBtn.on('click', this.handleSearchButtonPress);
  }

  /**
   * Create search element with input and button
   * @returns {jQuery} Search element
   */
  createSearchElement() {
    this.$searchBtn = jQuery('<button>', {
      type: 'submit',
      id: 'search-btn',
      class: 'btn btn-default'
    });

    this.$searchInput = jQuery('<input>', {
      type: 'text',
      class: 'form-control',
      placeholder: `${_SEARCH}...`,
      autocomplete: 'off',
    });

    return jQuery('<div>', { class: 'row' }).append(
      jQuery('<div>', {
        class: `${this.hasPagination ? 'col-md-6' : 'col-md-12'}`
      }).append(
        jQuery('<div>', { class: 'input-group input-group-sm mr-3' }).append(
          this.$searchInput,
          jQuery('<div>', { class: 'input-group-append d-block' }).append(
            this.$searchBtn.append(
              jQuery('<i>', { class: 'fa fa-search' })
            )
          )
        )
      ),
      this.hasPagination
        ? jQuery('<div>', { class: 'col-md-6'}).append(this.$tablePagination)
        : jQuery()
    );
  }

  /**
   * Initialize the message search functionality
   * @returns {Promise} Initialization promise
   */
  async init() {
    try {
      this.initDomElements();
      this.setupEventListeners();
      console.log('MessageSearch initialized successfully');
    } catch (error) {
      console.error('MessageSearch initialization failed:', error);
    }
  }
}