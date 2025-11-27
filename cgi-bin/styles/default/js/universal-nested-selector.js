class UniversalNestedSelector {
  constructor(config = {}) {
    this.config = {
      apiEndpoint: config.apiEndpoint || '/api.cgi/districts/territorial_units',
      pageRows: config.pageRows || 1000000,

      selectName: config.selectName || 'NESTED_UNITS_SEL',
      identifierField: config.identifierField || 'NESTED_UNITS_IDENTIFIER',
      selectedField: config.selectedField || 'NESTED_UNITS_SELECTED',
      idField: config.idField || 'NESTED_UNITS_ID',
      multipleField: config.multipleField || null,

      eventId: config.eventId || null,
      customEventPrefix: config.customEventPrefix || 'nested-select',

      containerClass: config.containerClass || 'nested-units-subselect',
      selectClass: config.selectClass || 'mt-1',
      defaultOptionText: config.defaultOptionText || '--',
      optionTemplate: config.optionTemplate || ((item) => `${item.name}`),
      labelTemplate: config.labelTemplate || null,

      infoButton: {
        enabled: config.infoButton?.enabled || false,
        baseUrl: config.infoButton?.baseUrl || '?get_index=form_districts&full=1&chg=0',
        icon: config.infoButton?.icon || 'fa fa-list-alt p-1',
        urlPattern: config.infoButton?.urlPattern || /chg=\d+/,
        ...config.infoButton
      },

      multipleSelection: {
        enabled: config.multipleSelection?.enabled || false,
        fieldPrefix: config.multipleSelection?.fieldPrefix || 'MULTIPLE',
        checkboxClass: config.multipleSelection?.checkboxClass || 'form-control-static m-2',
        ...config.multipleSelection
      },

      grouping: {
        enabled: config.grouping?.enabled || false,
        groupByField: config.grouping?.groupByField || 'parentId',
        groupNameField: config.grouping?.groupNameField || 'parentName',
        groupLabelTemplate: config.grouping?.groupLabelTemplate || ((name) => `== ${name} ==`),
        ...config.grouping
      },

      typeLabels: {
        enabled: config.typeLabels?.enabled || false,
        typesData: config.typeLabels?.typesData || {},
        typeIdField: config.typeLabels?.typeIdField || 'typeId',
        separator: config.typeLabels?.separator || '/',
        suffix: config.typeLabels?.suffix || ':',
        ...config.typeLabels
      },

      debounceDelay: config.debounceDelay || 300,
      enableCache: config.enableCache !== false,

      dataMapping: {
        id: config.dataMapping?.id || 'id',
        name: config.dataMapping?.name || 'name',
        code: config.dataMapping?.code || 'code',
        parentId: config.dataMapping?.parentId || ['parentId', 'parent_id'],
        typeId: config.dataMapping?.typeId || ['typeId', 'type_id'],
        parentName: config.dataMapping?.parentName || ['parentName', 'parent_name'],
        ...config.dataMapping
      },

      apiParams: {
        parentIdParam: 'PARENT_ID',
        idParam: 'ID',
        pageRowsParam: 'PAGE_ROWS',
        parentNameParam: 'PARENT_NAME',
        typeIdParam: 'TYPE_ID',
        ...config.apiParams
      },

      ...config
    };

    this.nestedUnitsId = jQuery(`[name='${this.config.idField}']`).val() || 0;
    this.loadingRequests = new Map();
    this.cache = this.config.enableCache ? new Map() : null;

    this.init();
  }

  init() {
    this.setupHiddenInput();
    this.attachEventListeners();
  }

  setupHiddenInput() {
    const identifierInput = jQuery(`[name='${this.config.identifierField}']`);
    const firstSelect = jQuery(`[name='${this.config.selectName}']`).first();

    if (identifierInput.length < 1 && firstSelect.length > 0) {
      const form = firstSelect.closest('form');
      if (form.length === 0 || identifierInput.closest('form')[0] !== form[0]) {
        firstSelect.append(jQuery('<input/>', {
          type: 'hidden',
          name: this.config.identifierField,
          value: this.config.selectedField
        }));
      }
    }
  }

  attachEventListeners() {
    jQuery(document).off(`change.nested-selector-${this.config.selectName}`)
      .on(`change.nested-selector-${this.config.selectName}`,
        `[name='${this.config.selectName}']`,
        (e) => {
          const target = jQuery(e.target);

          this.handleSelectChange(e.target).then(r => {
            target.attr('data-nested-initialized', true);
          });
        });
  }

  async handleSelectChange(selectElement) {
    const $select = jQuery(selectElement);
    const container = this.getContainer($select);
    const selectedValue = this.processSelectedValue($select.val());
    const streetId = $select.data('street-id');

    this.removeChildSelects($select);

    this.updateHiddenInput(selectedValue);

    this.updateInfoButton(container, selectedValue);

    if (!selectedValue) {
      this.handleEmptySelection(selectElement);
      return;
    }

    try {
      const childData = await this.loadChildUnits(selectedValue);

      this.dispatchSelectionEvent($select, selectedValue);

      if (childData && childData.length > 0) {
        this.createChildSelect(childData, container, selectedValue, streetId);
      }
    } catch (error) {
      this.handleError('Failed to load nested units', error);
    }
  }

  getContainer(selectElement) {
    let container = selectElement.closest('.form-group, .row, .field-container');

    if (container.length === 0) {
      let current = selectElement.parent();
      for (let i = 0; i < 5; i++) {
        current = current.parent();
        if (current.length === 0) break;
      }
      container = current;
    }

    return container.length > 0 ? container : selectElement.closest('div');
  }

  processSelectedValue(value) {
    if (Array.isArray(value)) {
      const filtered = value.filter(v => v);
      return filtered.length > 0 ? filtered.join(';') : '';
    }
    return value || '';
  }

  updateHiddenInput(value) {
    jQuery(`[name='${this.config.identifierField}']`).val(value);
  }

  updateInfoButton(container, selectedValue) {
    if (!this.config.infoButton.enabled || !selectedValue) return;

    const infoBtn = container.find('.bd-highlight > .input-group-append > a.input-group-button').first();

    if (infoBtn.length > 0 && !selectedValue.includes(';')) {
      const currentUrl = infoBtn.attr('href');
      const newUrl = currentUrl.replace(this.config.infoButton.urlPattern, `chg=${selectedValue}`);
      infoBtn.attr('href', newUrl);
    }
  }

  handleEmptySelection(currentSelectElement) {
    const $currentSelect = jQuery(currentSelectElement);
    const lastActiveSelect = jQuery(`[name='${this.config.selectName}']:has(option:selected)`)
      .not(`#${$currentSelect.attr('id')}`)
      .last();

    const previousValue = lastActiveSelect.val() || '';
    this.updateHiddenInput(previousValue);
  }

  dispatchSelectionEvent($select, value) {
    if (this.config.eventId) {
      const eventName = `${this.config.customEventPrefix}-change-${this.config.eventId}`;
      this.dispatchCustomEvent(eventName, {
        district: jQuery($select[0]),
        select: jQuery($select[0]),
        value: value
      });
    }
  }

  removeChildSelects(currentSelect) {
    let container = this.getContainer(currentSelect);
    // console.log('removeChildSelects', container)

    container.nextAll(`.${this.config.containerClass}`).remove();
  }

  async loadChildUnits(parentId) {
    if (this.loadingRequests.has(parentId)) {
      this.loadingRequests.get(parentId).abort();
    }

    if (this.cache) {
      const cacheKey = `parent_${parentId}`;
      if (this.cache.has(cacheKey)) {
        return this.cache.get(cacheKey);
      }
    }

    const controller = new AbortController();
    this.loadingRequests.set(parentId, controller);

    try {
      const url = this.buildApiUrl(parentId);
      const response = await fetch(url, {
        method: 'GET',
        mode: 'cors',
        cache: 'no-cache',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        redirect: 'follow',
        referrerPolicy: 'no-referrer',
        signal: controller.signal
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();

      if (!Array.isArray(data)) {
        throw new Error('Invalid response format: expected array');
      }

      if (this.cache) {
        const cacheKey = `parent_${parentId}`;
        this.cache.set(cacheKey, data);
      }

      return data;
    } finally {
      this.loadingRequests.delete(parentId);
    }
  }

  buildApiUrl(parentId) {
    const params = new URLSearchParams();
    params.set(this.config.apiParams.parentIdParam, parentId);

    if (this.config.apiParams.parentNameParam) {
      params.set(this.config.apiParams.parentNameParam, '_SHOW');
    }

    params.set(this.config.apiParams.idParam, `!${this.nestedUnitsId}`);
    params.set(this.config.apiParams.pageRowsParam, this.config.pageRows);

    if (this.config.apiParams.typeIdParam) {
      params.set(this.config.apiParams.typeIdParam, '');
    }

    if (this.config.apiParams.extraParams && typeof this.config.apiParams.extraParams === 'object') {
      for (const [key, value] of Object.entries(this.config.apiParams.extraParams)) {
        params.set(key, value);
      }
    }

    return `${this.config.apiEndpoint}?${params.toString()}`;
  }

  createChildSelect(data, container, parentId, streetId = null) {
    const selectId = `${this.config.selectName.replace('_SEL', '')}_${Date.now()}`;
    const normalizedData = this.validateAndNormalizeData(data);

    const selectStructure = this.buildComplexSelectStructure(selectId, normalizedData, streetId, parentId);

    const labelText = this.generateLabelText(normalizedData);

    const rowElement = this.buildCompleteRow(selectStructure, labelText);

    container.after(rowElement);

    this.initializeSelectLibraries(selectStructure.selectElement);

    this.focusAndOpenSelect(selectStructure.selectElement);

    this.dispatchCustomEvent(`${this.config.customEventPrefix}-created`, {
      parentId,
      selectId,
      data: normalizedData,
      element: selectStructure.selectElement[0]
    });
  }

  buildComplexSelectStructure(selectId, data, streetId, parentId) {
    const selectElement = jQuery('<select>', {
      class: this.config.selectClass,
      id: selectId,
      name: this.config.selectName,
      'data-street-id': streetId || undefined
    });

    selectElement.append(jQuery('<option>', {
      value: '',
      text: this.config.defaultOptionText
    }));

    this.addOptionsToSelect(selectElement, data);

    const inputGroup = jQuery('<div>', {
      class: 'input-group-append select2-append'
    }).append(selectElement);

    let flexFill;

    if (this.config.infoButton.enabled) {
      const selectDiv = jQuery('<div>', { class: 'select' }).append(inputGroup);
      flexFill = jQuery('<div>', {
        class: 'flex-fill bd-highlight overflow-hidden select2-border'
      }).append(selectDiv);
    } else {
      flexFill = jQuery('<div>', {
        class: 'flex-fill bd-highlight overflow-hidden select2-border'
      }).append(inputGroup);
    }

    const dFlex = jQuery('<div>', { class: 'd-flex bd-highlight' }).append(flexFill);

    if (this.config.infoButton.enabled) {
      this.addInfoButton(dFlex);
    }

    if (this.config.multipleSelection.enabled && this.config.multipleField) {
      this.addMultipleCheckbox(dFlex, parentId, selectId);
    }

    return {
      selectElement,
      container: dFlex
    };
  }

  addOptionsToSelect(selectElement, data) {
    if (this.config.grouping.enabled) {
      const groups = this.groupData(data);

      Object.entries(groups).forEach(([groupKey, groupData]) => {
        const groupName = groupData[0][this.config.grouping.groupNameField] || groupKey;
        const optgroup = jQuery('<optgroup>', {
          label: this.config.grouping.groupLabelTemplate(groupName)
        });

        groupData.forEach(item => {
          const optionText = typeof this.config.optionTemplate === 'function'
            ? this.config.optionTemplate(item)
            : `${item.name}`;

          const option = jQuery('<option>', {
            value: item.id,
            text: optionText
          });
          optgroup.append(option);
        });

        selectElement.append(optgroup);
      });
    } else {
      data.forEach(item => {
        const optionText = typeof this.config.optionTemplate === 'function'
          ? this.config.optionTemplate(item)
          : `${item.name}`;

        const option = jQuery('<option>', {
          value: item.id,
          text: optionText,
          'data-parent-id': item.parentId,
          'data-type-id': item.typeId
        });
        selectElement.append(option);
      });
    }
  }

  groupData(data) {
    const groups = {};
    const groupField = this.config.grouping.groupByField;

    data.forEach(item => {
      const groupKey = item[groupField] || 'ungrouped';
      if (!groups[groupKey]) {
        groups[groupKey] = [];
      }
      groups[groupKey].push(item);
    });

    return groups;
  }

  addInfoButton(dFlex) {
    const span = jQuery('<span>', { class: this.config.infoButton.icon });
    const a = jQuery('<a>', {
      class: 'btn input-group-button rounded-left-0',
      href: this.config.infoButton.baseUrl
    }).append(span);

    const groupAppend = jQuery('<div>', {
      class: 'input-group-append h-100'
    }).append(a);

    const db = jQuery('<div>', { class: 'bd-highlight' }).append(groupAppend);
    dFlex.append(db);
  }

  addMultipleCheckbox(dFlex, parentId, selectId) {
    const checkboxName = `${this.config.multipleField}_${parentId}`;
    const checkboxId = `${this.config.multipleField}_${selectId}`;

    const checkbox = jQuery('<input>', {
      type: 'checkbox',
      name: checkboxName,
      value: 1,
      class: this.config.multipleSelection.checkboxClass,
      id: checkboxId,
      'data-select-multiple': selectId
    });

    const checkboxGroup = jQuery('<div>', {
      class: 'input-group-text p-0 px-1 rounded-left-0'
    }).append(checkbox);

    const groupAppend = jQuery('<div>', {
      class: 'input-group-append h-100'
    }).append(checkboxGroup);

    const db = jQuery('<div>', { class: 'bd-highlight' }).append(groupAppend);
    dFlex.append(db);
  }

  generateLabelText(data) {
    if (typeof this.config.labelTemplate === 'function') {
      return this.config.labelTemplate(data);
    }

    if (this.config.typeLabels.enabled) {
      const types = [];
      const typesData = this.config.typeLabels.typesData;
      const typeIdField = this.config.typeLabels.typeIdField;

      data.forEach(item => {
        const typeId = item[typeIdField];
        if (typeId && typesData[typeId]) {
          const typeName = typesData[typeId];
          if (!types.includes(typeName)) {
            types.push(typeName);
          }
        }
      });

      let labelText = types.join(this.config.typeLabels.separator);
      if (labelText) {
        labelText += this.config.typeLabels.suffix;
      }
      return labelText;
    }

    return '';
  }

  buildCompleteRow(selectStructure, labelText) {
    const colBody = jQuery('<div>').append(selectStructure.container);
    const group = jQuery('<div>', { class: 'col-md-8' }).append(colBody);
    const label = jQuery('<label>', {
      class: 'col-sm-3 col-md-4 col-form-label text-md-right'
    }).text(labelText);

    return jQuery('<div>', {
      class: `form-group row ${this.config.containerClass}`
    }).append(label).append(group);
  }

  validateAndNormalizeData(data) {
    const mapping = this.config.dataMapping;

    return data
      .filter(item => item && this.getFieldValue(item, mapping.id) && this.getFieldValue(item, mapping.name))
      .map(item => {
        const parentId = item.parentId ?? item.parent_id;
        const parentName = item.parentName ?? item.parent_name;
        const typeId = item.typeId ?? item.type_id;

        item.parentId = item.parentId ?? parentId;
        item.parentName = item.parentName ?? parentName;
        item.typeId = item.typeId ?? typeId;

        return {
          id: this.getFieldValue(item, mapping.id),
          name: this.getFieldValue(item, mapping.name) || '',
          code: this.getFieldValue(item, mapping.code) || '',
          parentId: this.getFieldValue(item, mapping.parentId) || null,
          parentName: this.getFieldValue(item, mapping.parentName) || '',
          typeId: this.getFieldValue(item, mapping.typeId) || null
        };
      });
  }

  getFieldValue(item, fieldPath) {
    if (Array.isArray(fieldPath)) {
      for (const path of fieldPath) {
        const value = item[path];
        if (value !== undefined && value !== null) {
          return value;
        }
      }
      return null;
    }
    return item[fieldPath];
  }

  initializeSelectLibraries(selectElement) {
    if (typeof window.defineLinkedInputsLogic === 'function') {
      try {
        const group = selectElement.closest('.col-md-8');
        window.defineLinkedInputsLogic(group);
      } catch (e) {
        console.warn('Failed to initialize linked inputs logic:', e);
      }
    }

    if (typeof window.initChosen === 'function') {
      try {
        window.initChosen();
      } catch (e) {
        console.warn('Failed to initialize Chosen:', e);
      }
    }

    if (typeof selectElement.select2 === 'function') {
      try {
        selectElement.select2({
          width: '100%',
          allowClear: true,
          placeholder: ''
        });
      } catch (e) {
        console.warn('Failed to initialize Select2:', e);
      }
    }
  }

  focusAndOpenSelect(selectElement) {
    try {
      if (typeof selectElement.select2 === 'function') {
        setTimeout(() => {
          selectElement.focus().select2('open');
        }, 100);
      } else {
        selectElement.focus();
      }
    } catch (e) {
      console.warn('Failed to focus select:', e);
    }
  }

  handleError(message, error = null) {
    console.error('UniversalNestedSelector Error:', message, error);

    this.dispatchCustomEvent(`${this.config.customEventPrefix}-error`, {
      message,
      error: error?.message || 'Unknown error'
    });
  }

  dispatchCustomEvent(eventName, detail) {
    try {
      const event = new CustomEvent(eventName, {
        detail,
        bubbles: true,
        cancelable: true
      });
      document.dispatchEvent(event);
    } catch (e) {
      console.warn('Failed to dispatch custom event:', eventName, e);
    }
  }

  destroy() {
    this.loadingRequests.forEach(controller => {
      try {
        controller.abort();
      } catch (e) {
        console.warn('Failed to abort request:', e);
      }
    });
    this.loadingRequests.clear();

    jQuery(document).off(`change.nested-selector-${this.config.selectName}`);

    jQuery(`[name="${this.config.selectName}"]`).each((_, select) => {
      const $select = jQuery(select);
      if (typeof $select.select2 === 'function') {
        try {
          $select.select2('destroy');
        } catch (e) {
          console.warn('Failed to destroy select2:', e);
        }
      }
    });

    if (this.cache) {
      this.cache.clear();
    }

    console.log('UniversalNestedSelector destroyed');
  }
}