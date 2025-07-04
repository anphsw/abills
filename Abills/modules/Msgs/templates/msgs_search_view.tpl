<script src='/styles/default/js/modules/msgs/msgs-search-messages.js'></script>
<script>
  try {
    var tableTitles = JSON.parse('%TABLE_TITLES%');
    var statuses = JSON.parse('%STATUSES%');
  } catch (e) {
    console.error(e);
  }

  var _SEARCH = '_{SEARCH}_'
  var _NO_MATCHES_FOUND = '_{MSGS_NO_MATCHES_FOUND}_'
  var _MATCHES_FOUND = '_{MSGS_MATCHES_FOUND}_'

  tableTitles['date'] = '_{DATE}_';
  tableTitles['replyText'] = '_{REPLY}_';
  tableTitles['responsible'] = '_{RESPONSIBLE}_';

  const messagesSearch = new MessagesSearch({ tableId: 'MSGS_LIST_' });
  messagesSearch.setSearchContainer(jQuery('#MSGS_LIST_').parent().find('.row.float-right').first().find('.card-tools').first().find('.col-md-6.float-right'));
  messagesSearch.setTableTitles(tableTitles);
  messagesSearch.setMessageStatuses(statuses);

  jQuery(document).ready(() => {
    messagesSearch.init().catch(error => {
      console.error('Failed to initialize MessagesSearch:', error);
    });
  });
</script>