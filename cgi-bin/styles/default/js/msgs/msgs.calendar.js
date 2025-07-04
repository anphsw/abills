class CalendarManager {
  constructor(options) {
    this.calendar = null;
    this.containerEl = document.getElementById('external-events');
    this.calendarEl = document.getElementById('calendar');
    this.isDroppedToExternal = false;

    this.allTasks = [];
    this.filteredTasks = [];
    this.availableAdmins = new Set();
    this.currentFilter = null;
    this.statuses = options?.statuses || {};

    this.currentPage = 0;
    this.pageSize = 25;
    this.totalTasks = 0;
    this.isLoading = false;
    this.locale = options?.locale || 'en';

    this.init();
  }

  init() {
    this.initExternalEvents();
    this.initDraggable();
    this.loadUnscheduledTasks();
    this.initCalendar();
    this.initFilterControls();
    this.initLoadMoreButton();
  }

  initFilterControls() {
    const self = this;
    jQuery('#admin-filter').on('change', function (e) {
      self.filterByAdmin(jQuery(this).val());
    });
  }

  initLoadMoreButton() {
    const self = this;
    document.getElementById('load-more-btn').addEventListener('click', function () {
      self.loadMoreTasks();
    });
  }

  updateAdminFilter() {
    const select = document.getElementById('admin-filter');
    if (!select) return;

    select.innerHTML = `<option value="">${_MSGS_ALL_ADMINS}</option>`;

    Array.from(this.availableAdmins).sort().forEach(function (admin) {
      const option = document.createElement('option');
      option.value = admin;
      option.textContent = admin;
      select.appendChild(option);
    });
  }

  filterByAdmin(adminLogin) {
    this.currentFilter = adminLogin;

    if (!adminLogin) {
      this.filteredTasks = [...this.allTasks];
    } else {
      this.filteredTasks = this.allTasks.filter(function (task) {
        const taskAdmin = task.resposibleAdminLogin || task.responsible;
        return taskAdmin === adminLogin;
      });
    }

    this.renderFilteredTasks();
  }

  renderFilteredTasks() {
    jQuery('#external-events .external-event').remove();
    const self = this;

    this.filteredTasks.forEach(function (task) {
      const element = self.createExternalEventElement(task);
      jQuery('#external-events').append(element);
    });

    this.initExternalEvents();
    this.updateLoadMoreButton();

    if (this.filteredTasks.length === 0 && this.totalTasks > 0) {
      this.showNoTasksMessage(true);
      this.showTasksInExternalEvents(false);
    } else {
      this.showNoTasksMessage(false);
      this.showTasksInExternalEvents(true);
    }
  }

  updateLoadMoreButton() {
    const loadMoreContainer = document.getElementById('load-more-container');
    const hasMoreTasks = this.allTasks.length < this.totalTasks;

    if (hasMoreTasks && (!this.currentFilter || this.filteredTasks.length > 0)) {
      loadMoreContainer.style.display = 'block';
    } else {
      loadMoreContainer.style.display = 'none';
    }
  }

  initExternalEvents(elements) {
    const elementsToProcess = elements || jQuery('#external-events div.external-event');

    elementsToProcess.each(function () {
      const eventObject = {
        title: jQuery.trim(jQuery(this).find('.task-item__title').text()),
        admin: jQuery(this).find('.task-item__admin').text(),
        duration: jQuery(this).find('.task-item__duration').text(),
        id: jQuery(this).data('task-id'),
        taskData: jQuery(this).data('task-data')
      };

      jQuery(this).data('eventObject', eventObject);
      jQuery(this).draggable({
        zIndex: 1070,
        revert: true,
        revertDuration: 0,
        scroll: false,
        containment: 'document'
      });
    });
  }

  initDraggable() {
    new FullCalendar.Draggable(this.containerEl, {
      itemSelector: '.external-event',
      eventData: function (eventEl) {
        const computedStyle = window.getComputedStyle(eventEl, null);
        const taskData = jQuery(eventEl).data('task-data') || {};
        const taskId = jQuery(eventEl).data('task-id');
        const titleText = jQuery(eventEl).find('.task-item__title').text() || eventEl.innerText;
        return {
          id: taskId,
          title: titleText,
          backgroundColor: computedStyle.getPropertyValue('background-color'),
          borderColor: computedStyle.getPropertyValue('background-color'),
          textColor: computedStyle.getPropertyValue('color'),
          extendedProps: {
            originalTaskId: taskId,
            taskData: taskData,
            aid: taskData.aid,
            chapterId: taskData.chapterId,
            responsible: taskData.responsible || taskData.resposible,
            resposibleAdminLogin: taskData.resposibleAdminLogin,
            stateId: taskData.stateId,
            uid: taskData.uid,
            duration: taskData.planInterval || 120,
            planTime: taskData.planTime || '00:00:00'
          }
        };
      }
    });
  }

  async loadUnscheduledTasks(page = 0) {
    if (this.isLoading) return;

    this.isLoading = true;
    this.showLoadingIndicator(true);

    if (page === 0) {
      this.showNoTasksMessage(false);
      this.showTasksInExternalEvents(false);
    }

    try {
      const pageRows = this.pageSize;
      const pgOffset = page * this.pageSize;

      const result = await sendRequest(
        '/api.cgi/msgs/list?PLAN_DATE=0000-00-00&PLAN_INTERVAL&RESPOSIBLE_ADMIN_LOGIN&PAGE_ROWS=' + pageRows + '&PG=' + pgOffset,
        {},
        'GET'
      );

      const newTasks = result?.list || [];
      this.totalTasks = result?.total || 0;

      if (page === 0) {
        this.allTasks = newTasks;
        this.availableAdmins.clear();
      } else {
        this.allTasks = this.allTasks.concat(newTasks);
      }

      const self = this;
      newTasks.forEach(function (message) {
        const adminLogin = message?.resposibleAdminLogin || message?.responsible;
        if (adminLogin && adminLogin !== _NO_RESPONSIBLE && adminLogin.trim() !== '') {
          self.availableAdmins.add(adminLogin);
        }
      });

      this.updateAdminFilter();

      this.filterByAdmin(this.currentFilter);

      if (this.totalTasks === 0) {
        this.showNoTasksMessage(true);
        this.showTasksInExternalEvents(false);
      } else {
        this.showNoTasksMessage(false);
        this.showTasksInExternalEvents(true);
      }

      this.updateTasksCounter();
      this.currentPage = page;

    } catch (error) {
      console.error('Error loading unscheduled tasks:', error);
    } finally {
      this.isLoading = false;
      this.showLoadingIndicator(false);
    }
  }

  showNoTasksMessage(show) {
    const messageEl = document.getElementById('no-tasks-message');
    if (messageEl) {
      messageEl.style.display = show ? 'block' : 'none';
    }
  }

  showTasksInExternalEvents(show) {
    const externalEvents = document.getElementById('external-events');
    if (externalEvents) {
      externalEvents.style.display = show ? 'block' : 'none';
    }
  }

  updateTasksCounter() {
    const loadedCountEl = document.getElementById('loaded-count');
    const totalCountEl = document.getElementById('total-count');

    if (loadedCountEl && totalCountEl) {
      if (this.allTasks.length > this.totalTasks) this.totalTasks = this.allTasks.length;
      loadedCountEl.textContent = this.allTasks.length;
      totalCountEl.textContent = this.totalTasks;
    }
  }

  async loadMoreTasks() {
    if (this.isLoading || this.allTasks.length >= this.totalTasks) return;

    await this.loadUnscheduledTasks(this.currentPage + 1);
  }

  showLoadingIndicator(show) {
    const indicator = document.getElementById('loading-indicator');
    const button = document.getElementById('load-more-btn');

    if (show) {
      indicator.style.display = 'block';
      button.style.display = 'none';
    } else {
      indicator.style.display = 'none';
      button.style.display = 'inline-block';
    }
  }

  createExternalEventElement(message) {
    let state = this.statuses[message?.stateId] || {color: '#a9a9a9', icon: 'fa fa-question-circle'};
    if (message?.stateId === 6) {
      state.icon = 'fa fa-hourglass-half'
    }
    if (message?.stateId === 1) {
      state.icon = 'fa fa-times-circle'
    }
    state.color = state.color || '#a9a9a9';

    const element = jQuery('<div class="task-item external-event ui-draggable ui-draggable-handle">' +
      '<div class="task-item__header">' +
      '<div class="task-item__title"></div>' +
      '<div class="task-item__status status--pending pt-1 pb-1 pr-2 pl-2"></div>' +
      '</div>' +
      '<div class="task-item__meta">' +
      '<div class="task-item__admin"><i class="fa fa-user"></i></div>' +
      '<div class="task-item__duration"><i class="far fa-clock mr-1"></i></div>' +
      '</div>' +
      '</div>');

    element.find('.task-item__header').parent().attr('style', 'border-color: ' + state.color);
    const title = message?.subject || _NO_SUBJECT;
    element.find('.task-item__title').text(title);

    const planInterval = message.planInterval || 120;
    element.find('.task-item__duration').text(planInterval + ' min');

    const adminLogin = message?.resposibleAdminLogin || _NO_RESPONSIBLE;
    element.find('.task-item__admin').append(adminLogin);

    element.find('.task-item__status')
      .append(jQuery('<i></i>').addClass(state?.icon || 'fa fa-question-circle')
        .attr('style', 'color: white !important'))
      .attr('style', 'background-color: ' + state.color);

    const taskId = message.id || ('temp_' + Date.now());
    element.data('task-id', taskId);
    element.data('task-data', message);
    element.attr('data-task-id', taskId);
    element.attr('data-admin', adminLogin);

    return element;
  }

  initCalendar() {
    const self = this;
    this.calendar = new FullCalendar.Calendar(this.calendarEl, {
      locale: self.locale,
      initialView: 'dayGridMonth',
      themeSystem: 'bootstrap',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek'
      },
      dateClick: function (info) {
        const url = window.location.href + '&HOURS=1&DATE=' + info.dateStr;
        window.open(url, '_blank');
      },
      editable: true,
      selectable: true,

      drop: function (info) {
        const event = info.event;
        const draggedEl = info.draggedEl;

        let taskId = null;
        let taskData = null;

        if (event && event.extendedProps) {
          taskId = event.extendedProps.originalTaskId || event.id;
          taskData = event.extendedProps.taskData || event.extendedProps;
        } else if (draggedEl) {
          taskId = jQuery(draggedEl).data('task-id');
          taskData = jQuery(draggedEl).data('task-data');
        }

        if (draggedEl && draggedEl.parentNode) {
          draggedEl.parentNode.removeChild(draggedEl);
        }

        if (taskId) {
          self.removeTaskFromArrays(taskId);
        }

        if (taskId) {
          sendRequest('/api.cgi/msgs/' + taskId, {
            plan_date: info.dateStr
          }, 'PUT').then(function () {
            console.log('Planning date updated for task:', taskId);
          }).catch(function (error) {
            console.error('Error updating planning date:', error);
          });
        } else {
          console.warn('Could not get task ID for update');
        }
      },

      eventReceive: function (info) {
        console.log('Event received:', info.event.title);
      },

      eventResize: function (info) {
        const start = new Date(info.event.startStr);
        const end = new Date(info.event.endStr);
        const diffMs = end - start;
        const planInterval = diffMs / 1000 / 60;

        const eventId = info.event.id;
        if (eventId) {
          sendRequest('/api.cgi/msgs/' + eventId, {plan_interval: planInterval}, 'PUT');
        }
      },

      eventDrop: function (info) {
        console.log('Event moved:', info.event.title, '->', info.event.startStr);

        const eventId = info.event.id;
        if (eventId) {
          sendRequest('/api.cgi/msgs/' + eventId, {
            plan_date: info.event.startStr.split('T')[0],
            plan_time: info.event.startStr.includes('T') ? info.event.startStr.split('T')[1] : '00:00:00'
          }, 'PUT').then(function () {
            console.log('Event updated on server:', eventId);
          }).catch(function (error) {
            console.error('Error updating event:', error);
          });
        }
      },

      events: async function (info, successCallback, failureCallback) {
        try {
          const response = await fetch('/api.cgi/msgs/list?PLAN_DATE=!0000-00-00&PLAN_INTERVAL&RESPOSIBLE_ADMIN_LOGIN');

          if (!response.ok) {
            throw new Error('HTTP error! status: ' + response.status);
          }

          const data = await response.json();
          const events = data.list.map(function (item) {
            const hasTime = item.planTime !== '00:00:00';
            const startStr = hasTime
              ? (item.planDate + 'T' + item.planTime)
              : item.planDate;

            const startDate = new Date(startStr);
            const intervalMinutes = parseInt(item.planInterval, 10) || 120;

            let endDate = null;
            if (hasTime) {
              endDate = new Date(startDate.getTime() + intervalMinutes * 60 * 1000);
            }

            return {
              id: item.id,
              title: item.subject || _NO_SUBJECT,
              start: startStr,
              end: hasTime ? endDate.toISOString() : undefined,
              allDay: !hasTime,
              extendedProps: {
                aid: item.aid,
                chapterId: item.chapterId,
                responsible: item.resposible,
                resposibleAdminLogin: item.resposibleAdminLogin,
                stateId: item.stateId,
                uid: item.uid,
                duration: intervalMinutes,
                planTime: item.planTime
              }
            };
          });

          successCallback(events);
        } catch (error) {
          console.error('Error loading events:', error);
          failureCallback(error);
        }
      },

      eventContent: function (info) {
        return self.createEventContent(info);
      },

      eventDragStart: function (info) {
        jQuery('#external-events-container').addClass('drag-target');
        self.isDroppedToExternal = false;
      },

      eventDragStop: function (info) {
        jQuery('#external-events-container').removeClass('drag-target');

        if (self.isEventDroppedToExternal(info.jsEvent)) {
          self.isDroppedToExternal = true;
          self.moveEventToExternal(info.event);
        }
      },

      eventRevert: function (info) {
        return !self.isDroppedToExternal;
      }
    });

    this.calendar.render();
  }

  removeTaskFromArrays(taskId) {
    if (!taskId) return;

    const taskIdStr = String(taskId);
    this.allTasks = this.allTasks.filter(function (task) {
      return String(task.id) !== taskIdStr;
    });
    this.filteredTasks = this.filteredTasks.filter(function (task) {
      return String(task.id) !== taskIdStr;
    });

    this.updateLoadMoreButton();
    this.updateTasksCounter();
  }

  addTaskToArrays(taskData) {
    this.allTasks.push(taskData);

    if (!this.currentFilter || taskData.resposibleAdminLogin === this.currentFilter) {
      this.filteredTasks.push(taskData);
    }

    if (taskData.resposibleAdminLogin && taskData.resposibleAdminLogin !== _NO_RESPONSIBLE) {
      if (!this.availableAdmins.has(taskData.resposibleAdminLogin)) {
        this.availableAdmins.add(taskData.resposibleAdminLogin);
        this.updateAdminFilter();
      }
    }

    this.updateLoadMoreButton();
    this.updateTasksCounter();
  }

  createEventContent(info) {
    const id = info.event.id;
    const title = info.event.title;
    const extendedProps = info.event.extendedProps;

    let state = this.statuses[extendedProps?.stateId] || {color: '#a9a9a9', icon: 'fa fa-question-circle'};
    const wrapper = jQuery('<div>', {
      class: 'task-calendar d-flex flex-column justify-content-center h-100 w-100',
      id: 'task-' + id,
      style: 'background-color: ' + (state?.color || '#a9a9a9')
    });

    const topDiv = jQuery('<div>', {
      class: 'd-flex bd-highlight align-items-center',
      id: 'title-' + id
    });

    const eyeDiv = jQuery('<div>', {class: 'bd-highlight'});
    const eyeLink = jQuery('<a>', {
      href: '?get_index=msgs_admin&full=1&chg=' + id,
      target: '_blank',
      class: 'p-0 btn text-white',
      id: 'view-' + id
    });
    const eyeSpan = jQuery('<span>', {class: 'fa fa-eye p-1'});

    eyeLink.append(eyeSpan);
    eyeDiv.append(eyeLink);

    const titleDiv = jQuery('<div>', {class: 'bd-highlight flex-grow-1 pt-1 w-50'});
    const titleInner = jQuery('<div>', {class: 'task-calendar-title'}).text(title);
    titleDiv.append(titleInner);

    topDiv.append(eyeDiv, titleDiv);
    wrapper.append(topDiv);

    return {domNodes: [wrapper[0]]};
  }

  isEventDroppedToExternal(jsEvent) {
    const externalEventsEl = document.getElementById('external-events-container');
    const offset = jQuery(externalEventsEl).offset();
    const pageX = jsEvent.pageX;
    const pageY = jsEvent.pageY;

    return (
      pageX >= offset.left &&
      pageX <= offset.left + jQuery(externalEventsEl).outerWidth() &&
      pageY >= offset.top &&
      pageY <= offset.top + jQuery(externalEventsEl).outerHeight()
    );
  }

  moveEventToExternal(event) {
    event.remove();

    const title = event.title;
    const duration = event.extendedProps?.duration || 120;
    const adminLogin = event.extendedProps?.resposibleAdminLogin || _NO_RESPONSIBLE;
    const eventId = event.id;

    const taskData = {
      id: eventId,
      subject: title,
      planInterval: duration,
      resposibleAdminLogin: adminLogin
    };

    for (const key in event.extendedProps) {
      if (event.extendedProps.hasOwnProperty(key)) {
        taskData[key] = event.extendedProps[key];
      }
    }

    this.addTaskToArrays(taskData);

    const newExternalEvent = this.createExternalEventElement(taskData);

    jQuery('#external-events').append(newExternalEvent);
    this.initExternalEvents(newExternalEvent);

    let self = this;
    if (eventId) {
      sendRequest('/api.cgi/msgs/' + eventId, {
        plan_date: '0000-00-00'
      }, 'PUT').then(function () {
        self.showNoTasksMessage(false);
        self.showTasksInExternalEvents(true);
      }).catch(function (error) {
        console.error('Error moving task to unscheduled:', error);
      });
    }
  }

  getAllTasks() {
    return [...this.allTasks];
  }

  getFilteredTasks() {
    return [...this.filteredTasks];
  }

  getAvailableAdmins() {
    return Array.from(this.availableAdmins);
  }

  setAdminFilter(adminLogin) {
    const select = document.getElementById('admin-filter');
    if (select) {
      select.value = adminLogin || '';
      this.filterByAdmin(adminLogin);
    }
  }

  clearFilter() {
    this.setAdminFilter('');
  }

  refreshTasks() {
    this.currentPage = 0;
    this.allTasks = [];
    this.filteredTasks = [];
    this.loadUnscheduledTasks(0);
  }
}