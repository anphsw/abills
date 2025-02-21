<script src='/styles/default/js/modules/tasks/d3.v7.min.js'></script>
<script src='/styles/default/js/modules/tasks/d3.org.chart.js'></script>
<script src='/styles/default/js/modules/tasks/d3.flextree.js'></script>

<style>
	.node-content {
		pointer-events: none;
	}
	.button-container {
		position: absolute;
		right: -8px;
		top: 50%;
		transform: translateY(-50%);
		display: flex;
		flex-direction: column;
		gap: 5px;
	}

	.add-button, .remove-button {
		pointer-events: all;
		background-color: #4CAF50;
		border: none;
		color: white;
		padding: 2px 6px;
    border: 1px inherit;
    border-radius: 2px;
		cursor: pointer;
	}

	.remove-button {
		background-color: #f44336;
	}

	.chart-container {
		height: 75vh !important;
		width: 100%;
		overflow-y: hidden;
	}
</style>


<input type='hidden' name='TASK_ID' value='%TASK_ID%' id='TASK_ID'>
<input type='hidden' name='ADD_FAKE_ROOT_NODE' value='%ADD_FAKE_ROOT_NODE%' id='ADD_FAKE_ROOT_NODE'>

<div class="chart-container border rounded"></div>

<script>
  var _TASK_IN_WORK = '_{TASK_IN_WORK}_';
  var _TASKS_COMPLETED = '_{TASKS_COMPLETED}_';
  var _TASKS_NOT_COMPLETED = '_{TASKS_NOT_COMPLETED}_';
  var _EDIT = '_{EDIT}_';
  var _UNKNOWN = '_{UNKNOWN}_';
  var _TASK_NAME = '_{TASK_NAME}_';
  var _TASK_DESCRIBE = '_{TASK_DESCRIBE}_';
  var _RESPONSIBLE = '_{RESPONSIBLE}_';
  var _DUE_DATE = '_{DUE_DATE}_';
  var _TASK_TYPE = '_{TASK_TYPE}_';
  var _CANCEL = '_{UNDO}_';
  var _ADD = '_{ADD}_';
  var _CHANGE = '_{CHANGE}_';
  var _GO = '_{GO}_';
  var _NO = '_{NO}_';
  var _YES = '_{YES}_';
  var _CONFIRM_DEL = '_{TASKS_CONFIRM_DELETE_TASK}_<br>_{TASKS_SUBTASKS_WILL_BE_DELETED}_';
  var _DEL = '_{TASKS_DELETE_TASK}_';
  var _TASKS_GENERAL_REPORT = '_{TASKS_GENERAL_REPORT}_';

  var TASK_TYPES = {};
  var ADMINS_HASH = {};
  try {
    TASK_TYPES = JSON.parse('%TASK_TYPES%');
    ADMINS_HASH = JSON.parse('%ADMINS%');
  }
  catch (e) {
    console.log(e);
  }
</script>

<script src='/styles/default/js/modules/tasks/tasks.hierarchical.view.js'></script>
