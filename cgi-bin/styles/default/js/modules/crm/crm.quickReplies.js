class QuickReplies {
  constructor(apiUrl, repliesBtnId, quickRepliesContainerId, inputId) {
    this.apiUrl = apiUrl;
    this.btn = document.getElementById(repliesBtnId);
    this.quickRepliesContainer = document.getElementById(quickRepliesContainerId);
    this.input = document.getElementById(inputId);
    this.replyTextField = 'text';
    this.replyTitleField = 'title';
    this.quickReplies = [];
    this.quickRepliesIsOpen = false;
    this.searchInput = null;

    this.btn.addEventListener('click', () => this.showQuickReplies());
  }

  async showQuickReplies() {
    if (this.quickRepliesIsOpen) {
      this.closeQuickReplies();
      return;
    }

    const container = this.createQuickRepliesContainer();
    const repliesList = container.querySelector('#quick-replies-list');

    if (this.quickReplies.length > 0) {
      this.populateQuickReplies(repliesList);
    } else {
      try {
        const data = await this.fetchQuickReplies();
        this.quickReplies = data.map(reply => ({
          title: reply[this.replyTitleField],
          text: reply[this.replyTextField],
        }));
        this.populateQuickReplies(repliesList);
      } catch (error) {
        console.error('Failed to fetch quick replies:', error);
      }
    }

    this.quickRepliesContainer.appendChild(container);
    this.quickRepliesIsOpen = true;
  }

  async fetchQuickReplies() {
    try {
      const response = await sendRequest(this.apiUrl, {}, 'GET');
      if (!response || !Array.isArray(response.list)) {
        console.warn('Invalid response format:', response);
        return [];
      }
      return response.list;
    } catch (error) {
      console.error('Failed to fetch quick replies:', error);
      return [];
    }
  }


  createQuickRepliesContainer() {
    const container = this.createElement('div', 'quick-reply-container text-left');

    const topContainer = this.createElement('div', 'd-flex p-2 sticky-header');
    const searchContainer = this.createElement('div', 'modal-title w-100');
    this.searchInput = this.createElement('input', 'form-control search-input');
    searchContainer.appendChild(this.searchInput);

    const closeBtn = this.createElement('button', 'ml-2 close', '×');
    closeBtn.addEventListener('click', () => this.closeQuickReplies());

    topContainer.append(searchContainer, closeBtn);
    container.appendChild(topContainer);

    const repliesList = this.createElement('ul', 'list-group', null, 'quick-replies-list');
    container.appendChild(repliesList);

    this.addSearchHandler(repliesList);
    return container;
  }

  addSearchHandler(repliesList) {
    this.searchInput.addEventListener('input', () => {
      const searchTerm = this.searchInput.value.toLowerCase();
      Array.from(repliesList.children).forEach(item => {
        item.style.display = item.textContent.toLowerCase().includes(searchTerm) ? '' : 'none';
      });
    });
  }

  populateQuickReplies(repliesList) {
    this.quickReplies.forEach(reply => {
      const li = this.createReplyElement(reply);
      repliesList.appendChild(li);
    });
  }

  createReplyElement(reply) {
    const li = this.createElement('li', 'list-group-item cursor-pointer');
    const title = this.createElement('h6', 'h6 text-muted', reply.title);
    const text = this.createElement('p', 'mb-1', reply.text);

    li.append(title, text);
    li.addEventListener('click', () => {
      this.input.value += this.input.value.length > 0 ? `\n${reply.text}` : reply.text;
      this.closeQuickReplies();
    });

    return li;
  }

  createElement(tag, className, textContent = null, id = null) {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (textContent) element.textContent = textContent;
    if (id) element.id = id;
    return element;
  }

  closeQuickReplies() {
    this.quickRepliesIsOpen = false;
    this.quickRepliesContainer.innerHTML = '';
  }
}