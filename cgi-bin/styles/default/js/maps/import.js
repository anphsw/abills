(function($) {
  'use strict';

  let importUI = null;
  let currentParser = null;
  let currentResult = null;
  let progressUI = null;

  const BILLING_MODELS = {
    'cable': {
      title: _MAPS_CABLE,
      icon: '<i class="fa fa-random"></i>',
      styleClass: 'active-cable',
      fields: [
        { key: 'name', label: _MAPS_NAME },
        { key: 'length', label: _MAPS_LENGTH },
        { key: 'type_id', label: _MAPS_TYPE },
        { key: 'coords', label: _MAPS_COORDINATES, type: 'geometry' }
      ]
    },
    'well': {
      title: _MAPS_WELL,
      icon: '<i class="fa fa-circle"></i>',
      styleClass: 'active-well',
      fields: [
        { key: 'name', label: _MAPS_NAME },
        { key: 'type_id', label: _MAPS_TYPE },
        { key: 'coords', label: _MAPS_COORDINATES, type: 'geometry' }
      ]
    }
  };

  class Helpers {
    static escapeHtml(text) {
      if (!text) return '';
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }
  }

  class StatHelper {
    static generateHtml(dataList) {
      const total = dataList.length;
      const cables = dataList.filter(i => i.type === 'cable').length;
      const wells = dataList.filter(i => i.type === 'well').length;

      return `
        <div class="text-left">
          <div class="alert alert-info">
            <strong>${_MAPS_STATISTICS}:</strong><br>
            ${_MAPS_TOTAL}: <strong>${total}</strong> ${_MAPS_ELEMENTS}<br>
            <i class="fa fa-random"></i> ${_MAPS_CABLES}: <strong>${cables}</strong><br>
            <i class="fa fa-circle"></i> ${_MAPS_WELLS}: <strong>${wells}</strong>
          </div>
        </div>
      `;
    }

    static generateResultHtml(result) {
      const alertClass = result.errors > 0 ? 'alert-warning' : 'alert-success';
      return `
        <div class="text-left">
          <div class="alert ${alertClass}">
            <strong>${_MAPS_RESULT}:</strong><br>
            ${_MAPS_TOTAL_PROCESSED}: <strong>${result.total}</strong><br>
            <i class="fa fa-check"></i> ${_MAPS_SUCCESSFULLY}: <strong>${result.success}</strong><br>
            <i class="text-danger fa fa-times"></i> ${_MAPS_ERRORS}: <strong>${result.errors}</strong>
          </div>
        </div>
      `;
    }
  }

  class ModalManager {
    static confirm(options) {
      return new Promise((resolve) => {
        const modalId = 'confirmModal_' + Date.now();
        const modal = new AModal();

        modal.clear()
          .setId(modalId)
          .setHeader(options.title || _MAPS_CONFIRMATION)
          .setBody(options.message || '')
          .addButton(options.cancelText || _MAPS_CANCEL, 'btnCancel_' + modalId, 'secondary', 'button')
          .addButton(options.confirmText || _MAPS_CONFIRM, 'btnConfirm_' + modalId, 'primary', 'button');

        modal.show();

        setTimeout(() => {
          $('#btnConfirm_' + modalId).on('click', function() {
            modal.hide();
            resolve(true);
          });

          $('#btnCancel_' + modalId).on('click', function() {
            modal.hide();
            resolve(false);
          });
        }, 100);
      });
    }

    static alert(options) {
      return new Promise((resolve) => {
        const modalId = 'alertModal_' + Date.now();
        const modal = new AModal();

        const iconMap = {
          success: '<i class="fa fa-check-circle"></i>',
          error: '<i class="fa fa-exclamation-triangle"></i>',
          warning: '<i class="fa fa-exclamation-circle"></i>',
          info: '<i class="fa fa-info-circle"></i>'
        };
        const icon = iconMap[options.type] || iconMap.info;
        const title = `${icon} ${options.title || _MAPS_MESSAGE}`;

        modal.clear()
          .setId(modalId)
          .setHeader(title)
          .setBody(options.message || '')
          .addButton(options.okText || 'OK', 'btnOk_' + modalId, 'primary', 'button');

        modal.show();

        setTimeout(() => {
          $('#btnOk_' + modalId).on('click', function() {
            modal.hide();
            resolve();
          });
        }, 100);
      });
    }

    static showTooltip(text, type = 'success', duration = 3000) {
      const tooltip = new ATooltip();
      tooltip.setText(text);
      tooltip.setClass(type);
      tooltip.setTimeout(duration);
      tooltip.show();
    }
  }

  class ImportUI {
    constructor(containerId) {
      this.container = jQuery('#' + containerId);
      this.layers = [];
      this.rawData = null;
    }

    render(parseResult) {
      this.layers = parseResult.layers;
      this.rawData = parseResult.rawData;
      this.container.empty();

      if (this.layers.length === 0) {
        this.container.html(`<div class="alert alert-warning">${_MAPS_LAYERS_NOT_FOUND}</div>`);
        return;
      }

      this.layers.forEach(layer => {
        this.container.append(this._createLayerCard(layer));
      });

      this._attachEvents();
      initSelect2();
    }

    _createLayerCard(layer) {
      const card = jQuery(`
        <div class="card mb-4 shadow-sm kmz-layer-card" data-layer-id="${layer.id}">
          <div class="card-header bg-white">
            <h5 class="mb-0">
              <i class="fa fa-folder-open-o"></i> <strong>${Helpers.escapeHtml(layer.name)}</strong>
              <small class="text-muted">(${layer.type}, ${layer.fields.length} ${_MAPS_FIELDS_GENITIVE})</small>
            </h5>
          </div>
          <div class="card-body">
            <div class="form-group row">
              <label class="col-sm-4 col-form-label font-weight-bold text-right">
                ${_MAPS_IMPORT_AS}:
              </label>
              <div class="col-sm-8">
                <select class="form-control billing-type-select">
                  <option value="">-- ${_MAPS_DO_NOT_IMPORT} --</option>
                </select>
              </div>
            </div>
            <div class="mapping-area" style="display:none;">
              <hr>
              <table class="table table-sm table-hover">
                <thead class="thead-light">
                  <tr>
                    <th width="35%">${_MAPS_SYSTEM_FIELD}</th>
                    <th width="5%" class="text-center"><i class="fa fa-arrow-right"></i></th>
                    <th width="60%">${_MAPS_FILE_FIELD}</th>
                  </tr>
                </thead>
                <tbody class="mapping-tbody"></tbody>
              </table>
            </div>
          </div>
        </div>
      `);

      const select = card.find('.billing-type-select');
      for (const [key, model] of Object.entries(BILLING_MODELS)) {
        select.append(`<option value="${key}">${model.title}</option>`);
      }
      return card;
    }

    _attachEvents() {
      const self = this;
      this.container.off('change').on('change', '.billing-type-select', function() {
        const select = jQuery(this);
        const card = select.closest('.card');
        const layerId = card.data('layer-id');
        const type = select.val();
        self._handleTypeChange(card, layerId, type);
      });
    }

    _handleTypeChange(card, layerId, type) {
      const mappingArea = card.find('.mapping-area');
      const tbody = card.find('.mapping-tbody');

      card.removeClass('active-cable active-well');
      tbody.empty();

      if (!type) {
        mappingArea.slideUp();
        return;
      }

      const model = BILLING_MODELS[type];
      const layer = this.layers.find(l => l.id === layerId);

      if (model.styleClass) card.addClass(model.styleClass);

      model.fields.forEach(field => {
        tbody.append(this._createMappingRow(field, layer));
      });

      mappingArea.slideDown();
      // initSelect2();
    }

    _createMappingRow(sysField, layer) {
      const tr = jQuery('<tr>');
      jQuery('<td>').addClass('align-middle font-weight-bold').text(sysField.label).appendTo(tr);
      jQuery('<td>').addClass('align-middle text-center text-muted').html('<i class="fa fa-arrow-right"></i>').appendTo(tr);

      const tdControl = jQuery('<td>');
      if (sysField.type === 'geometry') {
        tdControl.append(`<input type="text" class="form-control-plaintext text-muted" value="${_MAPS_AUTOMATICALLY} (${layer.type})" readonly>`);
      } else {
        const select = jQuery(`<select class="form-control field-select" data-sys-key="${sysField.key}"><option value="">-- ${_MAPS_SKIP} --</option></select>`);
        layer.fields.forEach(field => {
          const sample = layer.samples[field];
          const label = sample
            ? `${field} (${_MAPS_EXAMPLE_SHORT}: ${sample.substring(0, 30)}${sample.length > 30 ? '...' : ''})`
            : field;
          const isMatch = field.toLowerCase().includes(sysField.key.toLowerCase()) ||
            sysField.key.toLowerCase().includes(field.toLowerCase());
          select.append(`<option value="${field}" ${isMatch ? 'selected' : ''}>${label}</option>`);
        });
        tdControl.append(select);
      }
      tr.append(tdControl);
      return tr;
    }

    getConfiguration() {
      const config = [];
      this.container.find('.kmz-layer-card').each(function() {
        const card = jQuery(this);
        const type = card.find('.billing-type-select').val();
        if (type) {
          const mapping = {};
          card.find('.field-select').each(function() {
            const select = jQuery(this);
            if (select.val()) mapping[select.data('sys-key')] = select.val();
          });
          config.push({
            layerId: card.data('layer-id'),
            type: type,
            mapping: mapping
          });
        }
      });
      return config;
    }
  }

  class ProgressUI {
    constructor() {
      this.modal = null;
      this.modalId = 'progressModal_import';
      this.lastData = { processed: 0, total: 0, success: 0, errors: 0, currentBatch: 0, totalBatches: 0, logs: [] };
    }

    show() {
      $('#' + this.modalId).remove();

      const body = this._buildProgressHTML();
      this.modal = new AModal();
      this.modal.clear()
        .setId(this.modalId)
        .setSize('lg')
        .setHeader(`<i class="fa fa-spinner fa-spin"></i> ${_MAPS_IMPORTING_DATA}...`)
        .setBody(body)
        .addButton(_MAPS_STOP, 'btnCancelImport', 'danger', 'button')
        .show();

      setTimeout(() => $('#' + this.modalId).find('.close').hide(), 100);

      this.updateUI(this.lastData);
    }

    hideTemporary() {
      const $el = $('#' + this.modalId);
      if ($el.length) {
        $el.modal('hide');
      }
    }

    restore() {
      setTimeout(() => {
        this.show();
      }, 300);
    }

    close() {
      if (this.modal) this.modal.hide();
      $('#' + this.modalId).modal('hide');
      setTimeout(() => {
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
      }, 300);
    }

    update(data) {
      this.lastData = data;
      this.updateUI(data);
    }

    updateUI(data) {
      if (!data || !$('#' + this.modalId).length) return;

      const percent = data.total > 0 ? Math.round((data.processed / data.total) * 100) : 0;

      this._updateElement('progressBar', el => {
        el.style.width = percent + '%';
        el.textContent = percent + '%';
      });
      this._updateElement('statProcessed', el => el.textContent = data.processed);
      this._updateElement('statSuccess', el => el.textContent = data.success);
      this._updateElement('statErrors', el => el.textContent = data.errors);
      this._updateElement('currentItem', el => el.textContent = `${_MAPS_BATCH} ${data.currentBatch} ${_MAPS_FROM} ${data.totalBatches}`);
      this._updateLogs(data.logs);
    }

    _buildProgressHTML() {
      return `
        <div class="progress-container">
          <div class="progress" style="height: 25px; margin-bottom: 20px;">
            <div class="progress-bar progress-bar-striped progress-bar-animated" id="progressBar" role="progressbar" style="width: 0%; font-weight: bold;">0%</div>
          </div>
          <div class="row mb-3 text-center">
             <div class="col-4"><strong>${_MAPS_PROCESSED}:</strong> <span id="statProcessed">0</span></div>
             <div class="col-4 text-success"><i class="fa fa-check"></i> <span id="statSuccess">0</span></div>
             <div class="col-4 text-danger"><i class="fa fa-times"></i> <span id="statErrors">0</span></div>
          </div>
          <div id="currentItem" class="text-center mb-3 text-muted font-italic"></div>
          <div id="importLog" style="max-height: 200px; overflow-y: auto; background: #f8f9fa; padding: 10px; border: 1px solid #dee2e6; font-family: monospace; font-size: 11px;"></div>
        </div>
      `;
    }

    _updateElement(id, callback) {
      const el = $('#' + this.modalId).find('#' + id)[0];
      if (el) callback(el);
    }

    _updateLogs(logs) {
      const logEl = $('#' + this.modalId).find('#importLog')[0];
      if (!logEl) return;

      logEl.innerHTML = logs.map(log => {
        const color = { success: '#28a745', error: '#dc3545', info: '#6c757d' }[log.type] || '#6c757d';
        return `<div style="color: ${color};">[${log.time}] ${log.message}</div>`;
      }).join('');

      logEl.scrollTop = logEl.scrollHeight;
    }
  }

  class BatchImporter {
    constructor(data, batchSize) {
      this.data = data;
      this.batchSize = batchSize || 50;
      this.processed = 0;
      this.success = 0;
      this.errors = 0;
      this.cancelled = false;
      this.logs = [];
    }

    async import(onProgress) {
      const batches = [];
      for (let i = 0; i < this.data.length; i += this.batchSize) {
        batches.push(this.data.slice(i, i + this.batchSize));
      }

      for (let i = 0; i < batches.length; i++) {
        if (this.cancelled) break;
        await this._processBatch(batches[i], i + 1, batches.length, onProgress);
        await new Promise(r => setTimeout(r, 100));
      }

      return {
        total: this.data.length,
        processed: this.processed,
        success: this.success,
        errors: this.errors,
        logs: this.logs,
        cancelled: this.cancelled
      };
    }

    async _processBatch(batch, num, total, onProgress) {
      this._log(`${_MAPS_BATCH} ${num}/${total} (${batch.length} ${_MAPS_ELEMENTS})`);
      try {
        const response = await fetch('/api.cgi/maps/import', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ list: batch })
        });
        const result = await response.json();

        if (result.errno) {
          this._log(`${_MAPS_ERROR}: ${result.errstr}`, 'error');
          this.errors += batch.length;
        } else {
          this._log(`${_MAPS_SUCCESSFULLY}: ${batch.length}`, 'success');
          this.success += batch.length;
        }
      } catch (error) {
        this._log(`${_MAPS_ERROR}: ${error.message}`, 'error');
        this.errors += batch.length;
      }

      this.processed += batch.length;
      if (onProgress) {
        onProgress({
          total: this.data.length,
          processed: this.processed,
          success: this.success,
          errors: this.errors,
          currentBatch: num,
          totalBatches: total,
          logs: this.logs
        });
      }
    }

    _log(message, type = 'info') {
      this.logs.push({ time: new Date().toLocaleTimeString(), message, type });
    }

    cancel() { this.cancelled = true; }
  }

  class KmzParser {
    supports(filename) { return ['kmz', 'kml'].includes(filename.split('.').pop().toLowerCase()); }
    async parse(file) {
      const kmlText = await this._extractKml(file);
      const xmlDoc = new DOMParser().parseFromString(kmlText, 'application/xml');
      if (xmlDoc.querySelector('parsererror')) throw new Error(_MAPS_XML_STRUCTURE_ERROR);
      return { rawData: xmlDoc, layers: this._extractLayers(xmlDoc) };
    }
    async _extractKml(file) {
      if (file.name.toLowerCase().endsWith('.kmz')) {
        const zip = await JSZip.loadAsync(file);
        for (const f in zip.files) if (f.endsWith('.kml')) return await zip.files[f].async('text');
        throw new Error(_MAPS_KML_NOT_FOUND_ARCHIVE);
      }
      return await file.text();
    }
    _extractLayers(xmlDoc) {
      const layersMap = new Map();
      Array.from(xmlDoc.getElementsByTagName('Placemark')).forEach(pm => {
        const id = this._getLayerId(pm);
        if (!layersMap.has(id)) {
          layersMap.set(id, { id, name: id, type: this._getGeometryType(pm), fields: [], samples: {} });
        }
        this._collectFields(pm, layersMap.get(id));
      });
      return Array.from(layersMap.values());
    }
    _getLayerId(pm) {
      const schema = pm.querySelector('SchemaData');
      if (schema && schema.getAttribute('schemaUrl')) return schema.getAttribute('schemaUrl').replace('#', '');
      let parent = pm.parentElement;
      while (parent && parent.nodeName !== 'Document') {
        if (parent.nodeName === 'Folder') {
          const name = parent.querySelector(':scope > name');
          if (name) return name.textContent.trim();
        }
        parent = parent.parentElement;
      }
      return 'Layer_' + this._getGeometryType(pm);
    }
    _getGeometryType(pm) {
      if (pm.querySelector('LineString')) return 'LineString';
      if (pm.querySelector('Point')) return 'Point';
      if (pm.querySelector('Polygon')) return 'Polygon';
      return 'Unknown';
    }
    _collectFields(pm, layer) {
      const add = (k, v) => {
        if (!k || !v) return;
        if (!layer.fields.includes(k)) { layer.fields.push(k); layer.samples[k] = v; }
      };
      const name = pm.querySelector(':scope > name');
      if (name) add('name', name.textContent.trim());
      pm.querySelectorAll('ExtendedData > Data').forEach(d => add(d.getAttribute('name'), d.querySelector('value')?.textContent.trim()));
      pm.querySelectorAll('SchemaData > SimpleData').forEach(d => add(d.getAttribute('name'), d.textContent.trim()));
    }
    extractFeatures(xmlDoc, layerId, mapping) {
      const features = [];
      Array.from(xmlDoc.getElementsByTagName('Placemark')).forEach(pm => {
        if (this._getLayerId(pm) !== layerId) return;
        const geometry = this._extractGeometry(pm);
        if (!geometry) return;
        const attrs = {};
        const rawData = {};
        const name = pm.querySelector(':scope > name');
        if (name) rawData['name'] = name.textContent.trim();
        pm.querySelectorAll('ExtendedData > Data').forEach(d => rawData[d.getAttribute('name')] = d.querySelector('value')?.textContent.trim());
        pm.querySelectorAll('SchemaData > SimpleData').forEach(d => rawData[d.getAttribute('name')] = d.textContent.trim());
        for (const [sysKey, kmlKey] of Object.entries(mapping)) {
          if (rawData[kmlKey] !== undefined) attrs[sysKey] = rawData[kmlKey];
        }
        features.push({ geometry, attributes: attrs });
      });
      return features;
    }
    _extractGeometry(pm) {
      const ls = pm.querySelector('LineString coordinates');
      if (ls) return { type: 'polyline', coordinates: this._parseCoords(ls.textContent) };
      const pt = pm.querySelector('Point coordinates');
      if (pt) return { type: 'point', coordinates: this._parseCoords(pt.textContent)[0] };
      return null;
    }
    _parseCoords(text) {
      return text.trim().split(/\s+/).map(p => {
        const [lon, lat] = p.split(',').map(parseFloat);
        return [lat, lon];
      }).filter(c => !isNaN(c[0]));
    }
  }

  class ImportManager {
    static getParser(filename) {
      if (filename.endsWith('kmz') || filename.endsWith('kml')) return new KmzParser();
      return null;
    }
  }

  $(document).ready(function() {
    importUI = new ImportUI('mapping-container');

    $('#load').on('click', handleLoad);
    $('#btn-save').on('click', handleSave);
    $('#btn-preview').on('click', handlePreview);

    $(document).on('click', '#btnCancelImport', handleCancelImport);
  });

  async function handleLoad() {
    const fileInput = document.getElementById('loadFile');
    if (!fileInput.files.length) return ModalManager.showTooltip(_MAPS_CHOOSE_FILE, 'warning');

    const file = fileInput.files[0];
    currentParser = ImportManager.getParser(file.name);

    if (!currentParser) return ModalManager.alert({ type: 'error', message: _MAPS_FORMAT_NOT_SUPPORTED });

    try {
      $('#load').prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i>');
      currentResult = await currentParser.parse(file);

      if (currentResult.layers.length === 0) return ModalManager.showTooltip(_MAPS_LAYERS_NOT_FOUND, 'warning');

      importUI.render(currentResult);
      $('#footer-actions').slideDown();
      ModalManager.showTooltip(`${_MAPS_LOADED} ${currentResult.layers.length} ${_MAPS_LAYERS}`);

    } catch (e) {
      console.error(e);
      ModalManager.alert({ type: 'error', message: e.message });
    } finally {
      $('#load').prop('disabled', false).html(`<i class="fa fa-upload"></i> ${_MAPS_UPLOAD}`);
    }
  }

  async function handlePreview() {
    const config = importUI.getConfiguration();
    if (!config.length) return ModalManager.showTooltip(_MAPS_CONFIGURE_IMPORT, 'warning');

    const data = buildImportData(config);
    const preview = data.slice(0, 3);
    const statsHtml = StatHelper.generateHtml(data);

    ModalManager.alert({
      title: _MAPS_PREVIEW,
      message: `
        ${statsHtml}
        <p><strong>${_MAPS_DATA_EXAMPLE_FIRST_3}:</strong></p>
        <pre style="font-size:11px; max-height:300px; overflow:auto; background: #f8f9fa; padding: 10px;">${JSON.stringify(preview, null, 2)}</pre>
      `
    });
  }

  async function handleSave() {
    const config = importUI.getConfiguration();
    if (!config.length) return ModalManager.showTooltip(_MAPS_NOTHING_TO_IMPORT, 'warning');

    const data = buildImportData(config);
    const statsHtml = StatHelper.generateHtml(data);

    const confirmed = await ModalManager.confirm({
      title: _MAPS_IMPORT_CONFIRMATION,
      message: `${statsHtml}<p>${_MAPS_START_IMPORT_QUESTION}?</p>`,
      confirmText: _MAPS_START_IMPORT
    });

    if (confirmed) startImport(data);
  }

  async function handleCancelImport() {
    if (progressUI) progressUI.hideTemporary();

    await new Promise(r => setTimeout(r, 200));

    const confirmed = await ModalManager.confirm({
      title: _MAPS_PROCESS_STOP,
      message: _MAPS_STOP_CONFIRM_QUESTION,
      confirmText: _MAPS_YES_STOP,
      cancelText: _MAPS_CONTINUE,
    });

    if (confirmed) {
      if (window.currentImporter) window.currentImporter.cancel();
    } else {
      if (progressUI) progressUI.restore();
    }
  }
  function buildImportData(config) {
    const result = [];
    config.forEach(cfg => {
      const features = currentParser.extractFeatures(currentResult.rawData, cfg.layerId, cfg.mapping);
      features.forEach(f => {
        result.push({ type: cfg.type, geometry: f.geometry, ...f.attributes });
      });
    });
    return result;
  }

  async function startImport(data) {
    const batchSize = parseInt($('#batchSize').val()) || 50;
    progressUI = new ProgressUI();
    const importer = new BatchImporter(data, batchSize);

    window.currentImporter = importer;
    progressUI.show();

    try {
      const result = await importer.import(progress => progressUI.update(progress));

      progressUI.close();

      setTimeout(async () => {
        const statsHtml = StatHelper.generateResultHtml(result);
        const title = result.cancelled ? _MAPS_IMPORT_STOPPED : _MAPS_IMPORT_RESULT;
        const type = result.errors > 0 || result.cancelled ? 'warning' : 'success';

        await ModalManager.alert({
          type: type,
          title: title,
          message: statsHtml
        });

        location.reload();
      }, 300);

    } catch (e) {
      console.error(e);
      if (progressUI) progressUI.close();
      setTimeout(() => ModalManager.alert({ type: 'error', message: `${_MAPS_CRITICAL_ERROR}: ` + e.message }), 300);
    } finally {
      window.currentImporter = null;
    }
  }

})(jQuery);