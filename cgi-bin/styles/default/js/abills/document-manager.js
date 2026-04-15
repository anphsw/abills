const MS_PER_DAY = 86400000;
const EXPIRE_WARN_DAYS = 90;

class DocumentManager {
  constructor(options) {
    this.container = jQuery(options.containerSelector || '#docs-card');

    this.apiUrl = options.apiUrl || '/api.cgi/users/documents/';
    this.uid = options.uid;

    this.docsList = [];
    this.docCache = {};
    this.activeDocId = null;

    this.DOC_TYPES = {
      1: {name: _PASSPORT, icon: 'fa-book', color: 'primary', hasExpire: false},
      2: {name: _ID_CARD, icon: 'fa-id-card', color: 'success', hasExpire: true},
      3: {name: _DRIVER_LICENSE, icon: 'fa-car', color: 'warning', hasExpire: true}
    };

    if (!this.container.length) {
      console.warn('DocumentManager: container not found');
      return;
    }

    if (!this.uid) {
      console.warn('DocumentManager: UID not found');
      return;
    }

    this.init();
  }

  async init() {
    this.buildTypeSelect();
    this.bindEvents();
    await this.loadDocsList();
  }

  async loadDocsList() {
    this.showLoader(true);
    try {
      const url = `${this.apiUrl}?DOC_TYPE&NUM&DATE&UID=${this.uid}`;
      const data = await sendRequest(url, {}, 'GET');

      if (data && !data.error && !data.errno) {
        this.docsList = (data.list || data || []).map(d => ({
          ...d,
          docType: d.docType ?? d.doc_type
        }));

        this.renderTable();

        if (this.docsList.length > 0) {
          await this.fetchAndLoadDoc(this.docsList[0].id);
        } else {
          this.showPanel('empty');
        }
      } else {
        this.showAlert('danger', data.error || data.errno || _ERROR_LOADING_LIST);
      }
    } catch (err) {
      console.log('Error loading documents list:', err);
      this.showAlert('danger', _CONNECTION_ERROR);
    } finally {
      this.showLoader(false);
    }
  }

  async fetchAndLoadDoc(docId) {
    if (this.docCache[docId]) {
      this.populateForm(this.docCache[docId]);
      return;
    }

    this.showLoader(true);
    try {
      const url = `${this.apiUrl}/${docId}`;
      const data = await sendRequest(url, {}, 'GET');

      if (data && !data.error && !data.errno) {
        this.docCache[docId] = data;
        this.populateForm(data);
      } else {
        this.showAlert('danger', data.error || data.errno || _ERROR_LOADING_DOCUMENT);
      }
    } catch (err) {
      console.log('Error loading document details:', err);
      this.showAlert('danger', _CONNECTION_ERROR);
    } finally {
      this.showLoader(false);
    }
  }

  async saveDoc(event) {
    event.preventDefault();

    const docId = this.container.find('#doc-id').val();
    const typeId = this.container.find('#doc-type-select').val();
    const cfg = this.DOC_TYPES[typeId] || {};
    const num = jQuery.trim(this.container.find('#doc-num').val());

    const btnSave = this.container.find('#btn-doc-save');
    btnSave.prop('disabled', true).html(`<i class="fa fa-spinner fa-spin mr-1"></i>${_SAVING}…`);

    const fd = new FormData();
    fd.append('uid', this.uid);
    fd.append('docType', typeId);
    fd.append('num', num);
    fd.append('date', this.container.find('#doc-date').val());
    fd.append('expire', cfg.hasExpire ? this.container.find('#doc-expire').val() : '');
    fd.append('issuedBy', this.container.find('#doc-issued-by').val());
    if (docId) fd.append('docId', docId);

    try {
      const resp = await sendRequest(
        docId ? `${this.apiUrl}/${docId}` : this.apiUrl,
        fd,
        docId ? 'PUT' : 'POST'
      );

      if (resp && !resp.error && !resp.errno) {
        const updatedData = {
          id: docId || resp.insertId || resp.insert_id,
          docType: parseInt(typeId),
          num: num,
          date: this.container.find('#doc-date').val(),
          expire: cfg.hasExpire ? this.container.find('#doc-expire').val() : null,
          issuedBy: this.container.find('#doc-issued-by').val()
        };

        this.docCache[updatedData.id] = updatedData;

        if (docId) {
          const listItem = this.docsList.find(d => d.id == docId);
          if (listItem) {
            listItem.docType = typeId;
            listItem.num = num;
          }
        } else {
          this.docsList.push({id: updatedData.id, docType: typeId, num: num});
          this.activeDocId = updatedData.id;
          this.container.find('#doc-id').val(updatedData.id);
          this.container.find('#doc-type-select').prop('disabled', true);
          btnSave.text(_CHANGE);
        }

        this.renderTable();
        this.showAlert('success', _CHANGED);
      } else {
        let errorText = _ERROR;

        if (resp.errmsg) {
          errorText = resp.errmsg.trim().replace(/\n/g, '<br>');
        } else if (resp.errors && Array.isArray(resp.errors)) {
          errorText = resp.errors.map(e => `<b>${e.param}</b>: ${e.errstr}`).join('<br>');
        } else if (resp.errstr || resp.error) {
          errorText = resp.errstr || resp.error;
        } else if (resp.errno) {
          errorText = `${_ERROR} #${resp.errno}`;
        }

        this.showAlert('danger', errorText);
      }
    } catch (err) {
      console.log('Error saving document:', err);
      this.showAlert('danger', err?.errmsg ? err.errmsg.trim().replace(/\n/g, '<br>') : _ERROR);
    } finally {
      btnSave.prop('disabled', false).text(_CHANGE);
    }
  }

  showAlert(type, msg) {
    const alertEl = this.container.find('#doc-alert');
    alertEl.attr('class', `alert alert-${type} py-1 px-2 mb-3 small`).html(msg).show();
    setTimeout(() => alertEl.fadeOut(), 5000);
  }

  deleteDoc(docId, event) {
    if (event) event.preventDefault();

    const confirmDelModal = new AModal();
    confirmDelModal
      .setHeader(`${_DELETING_DOCUMENT} #${docId}`)
      .setBody(`<h4 class="modal-title"><div id="confirmModalContent">${_CONFIRM_DELETE_DOCUMENT}</div></h4>`)
      .addButton(_NO, 'confirmDelModalCancelBtn', 'default')
      .addButton(_YES, 'confirmDelModalConfirmBtn', 'danger')
      .show(() => {

        jQuery('#confirmDelModalConfirmBtn').one('click', async () => {
          confirmDelModal.hide();
          this.showLoader(true);

          try {
            const resp = await sendRequest(`${this.apiUrl}/${docId}`, {}, 'DELETE');

            if (resp && !resp.error && !resp.errno) {
              this.docsList = this.docsList.filter(d => d.id != docId);
              delete this.docCache[docId];

              if (this.activeDocId == docId) {
                this.activeDocId = null;
                this.showPanel('empty');
              }
              this.renderTable();
              this.showAlert('success', _DOCUMENT_DELETED);
            } else {
              this.showAlert('danger', resp.error || resp.errno || _ERROR);
            }
          } catch (err) {
            console.log('Error deleting document:', err);
            this.showAlert('danger', _ERROR);
          } finally {
            this.showLoader(false);
          }
        });

        jQuery('#confirmDelModalCancelBtn').one('click', () => {
          confirmDelModal.hide();
        });
      });
  }

  renderTable() {
    const tbody = this.container.find('#docs-table-body');
    tbody.empty();

    if (this.docsList.length === 0) {
      tbody.append(`<tr><td colspan="4" class="text-center text-muted small py-2">${_NO_DOCUMENTS}</td></tr>`);
      return;
    }

    jQuery.each(this.docsList, (i, docItem) => {
      const cfg = this.DOC_TYPES[docItem.docType] || {name: '?'};
      const activeClass = (docItem.id == this.activeDocId) ? 'table-active' : '';

      const actionButtons = `
        <a href="#" class="btn-edit-doc"   data-id="${docItem.id}" title="${_CHANGE}">
          <span class="fa fa-pencil-alt text-primary p-1"></span>
        </a>
        <a href="#" class="btn-delete-doc" data-id="${docItem.id}" title="${_DELETE}">
          <span class="fa fa-times text-danger p-1"></span>
        </a>
      `;

      const tr = jQuery('<tr>')
        .addClass(activeClass)
        .append(jQuery('<td>').addClass('pl-3 align-middle').text(cfg.name))
        .append(jQuery('<td>').addClass('align-middle').text(docItem.num || '—'))
        .append(jQuery('<td>').text(docItem.date || ''))
        .append(jQuery('<td>').addClass('text-center pr-3 align-middle').html(actionButtons));

      tbody.append(tr);
    });
  }

  populateForm(docData) {
    this.activeDocId = docData.id;
    const cfg = this.DOC_TYPES[docData.docType] || {name: '?', hasExpire: false};

    this.container.find('#doc-id, #doc-num, #doc-date, #doc-expire, #doc-issued-by').val('');
    this.container.find('#doc-id').val(docData.id);
    this.container.find('#doc-type-select').val(docData.docType).prop('disabled', true).trigger('change');
    this.container.find('#doc-num').val(docData.num || '');
    this.container.find('#doc-date').val(docData.date);
    this.container.find('#doc-expire').val(docData.expire);
    this.container.find('#doc-issued-by').val(docData.issuedBy || '');

    this.toggleExpireField(cfg.hasExpire, docData.expire);
    this.container.find('#btn-doc-save').text(_CHANGE);

    this.renderTable();
    this.showPanel('form');
  }

  bindEvents() {
    this.container.on('click', '#btn-add-doc', (e) => {
      e.preventDefault();
      this.activeDocId = null;
      this.container.find('#doc-id, #doc-num, #doc-date, #doc-expire, #doc-issued-by').val('');
      this.container.find('#doc-type-select').prop('disabled', false);
      this.container.find('#btn-doc-save').text(_ADD);
      this.applyTypeConfig();
      this.renderTable();
      this.showPanel('form');
    });

    this.container.on('change', '#doc-type-select', () => this.applyTypeConfig());

    this.container.find('#btn-doc-save').first().on('click', (e) => this.saveDoc(e));

    this.container.on('click', '.btn-edit-doc', (e) => {
      e.preventDefault();
      const docId = jQuery(e.currentTarget).data('id');
      if (docId) this.fetchAndLoadDoc(docId);
    });

    this.container.on('click', '.btn-delete-doc', (e) => {
      const docId = jQuery(e.currentTarget).data('id');
      if (docId) this.deleteDoc(docId, e);
    });
  }

  showPanel(panelName) {
    const panel = this.container.find('#docs-panel-' + panelName);
    if (!panel.length) {
      console.warn(`DocumentManager: panel "${panelName}" not found`);
      return;
    }
    this.container.find('#docs-panel-empty, #docs-panel-form').hide();
    panel.show();
  }

  showLoader(show) {
    this.container.find('#docs-loader').css('display', show ? 'flex' : 'none');
  }

  applyTypeConfig() {
    const typeId = this.container.find('#doc-type-select').val();
    const cfg = this.DOC_TYPES[typeId] || {hasExpire: false};
    this.toggleExpireField(cfg.hasExpire, null);
  }

  toggleExpireField(hasExpire, expireVal) {
    this.container.find('#field-expire').toggle(hasExpire);
    const ew = this.container.find('#expire-warn').hide();

    if (hasExpire && expireVal) {
      const dl = this.daysDiff(expireVal);
      if (dl === null) return;

      if (dl < 0) {
        ew.removeClass('text-warning').addClass('text-danger').text(_DOCUMENT_EXPIRED).show();
      } else if (dl < EXPIRE_WARN_DAYS) {
        ew.removeClass('text-danger').addClass('text-warning').text(`${_EXPIRES_IN} ${dl} ${_DAYS}`).show();
      }
    }
  }

  daysDiff(dateStr) {
    if (!dateStr || dateStr === '0000-00-00') return null;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return Math.floor((new Date(dateStr) - today) / MS_PER_DAY);
  }

  buildTypeSelect() {
    const typeSelectEl = this.container.find('#doc-type-select');
    if (!typeSelectEl.length) {
      console.warn('DocumentManager: #doc-type-select not found');
      return;
    }
    typeSelectEl.empty();
    jQuery.each(this.DOC_TYPES, (typeId, cfg) => {
      typeSelectEl.append(jQuery('<option>').val(typeId).text(cfg.name));
    });
  }
}