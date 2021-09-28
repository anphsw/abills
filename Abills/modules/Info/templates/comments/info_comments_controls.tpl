<div class='btn-group btn-group-xs'>
  <a role='button' class='btn btn-xs btn-primary commentAddBtn' data-toggle='modal' data-target='#info_comments_modal' title='_{ADD}_ _{COMMENTS}_'>
    <span class='fa fa-plus'></span>
  </a>

  <button role='button' class='btn btn-xs btn-success' id='info_comments_refresh'
          data-object_id='%OBJECT_ID%' data-object_type='%TABLE_NAME%'
          data-renews='#commentsBlock' data-source='info_comments_renew' title='_{REFRESH}_'>
    <span class='fa fa-refresh'></span>
  </button>
</div>
<input id='OBJECT_TYPE' type='hidden' value='%TABLE_NAME%'>
<input id='OBJECT_ID' type='hidden' value='%OBJECT_ID%'>
<input id='ADD_INDEX' type='hidden' value='%ADD_COMMENT_INDEX%'>