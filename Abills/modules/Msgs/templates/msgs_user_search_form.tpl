<input type='hidden' name='index' value='%index%'/>

<script src='/styles/default/js/modules/msgs/msgs-search-messages.js'></script>
<script>
  var tableTitles = {};
  var statuses = {};

  try {
    tableTitles = JSON.parse('%TABLE_TITLES%');
    statuses = JSON.parse('%STATUSES%');
  } catch (e) {
    console.error(e);
  }

  var _SEARCH = '_{SEARCH}_'
  var _NO_MATCHES_FOUND = '_{MSGS_NO_MATCHES_FOUND}_'
  var _MATCHES_FOUND = '_{MSGS_MATCHES_FOUND}_'

  tableTitles['date'] = '_{DATE}_';
  tableTitles['message'] = '_{MESSAGE}_';
  tableTitles['replyText'] = '_{REPLY}_';
  tableTitles['responsible'] = '_{RESPONSIBLE}_';

  jQuery(document).ready(() => {
    const messagesSearch = new MessagesSearch({
      tableId: 'MSGS_LIST_',
      searchEndpoint: '/api.cgi/user/msgs/search/',
      defaultSearchParams: {
        message: '_SHOW',
        replyText: '_SHOW',
        state: '_SHOW',
        date: '_SHOW',
        subject: '_SHOW',
        desc: 'DESC'
      },
      hiddenColumns: ['chapter', 'uid'],
      messageUrl: `?index=${jQuery('[name="index"]').val()}&ID=`,
    });
    let searchContainer = jQuery(`<div class='search-container mt-2 mb-2'></div>`);
    jQuery('#MSGS_LIST_').parent().prepend(searchContainer)
    messagesSearch.setSearchContainer(searchContainer);
    messagesSearch.setTableTitles(tableTitles);
    messagesSearch.setMessageStatuses(statuses);

    messagesSearch.init().catch(error => {
      console.error('Failed to initialize MessagesSearch:', error);
    });
  });
</script>