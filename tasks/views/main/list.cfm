<div id="messages"></div>
<div id="tasks"></div>
<script type="text/javascript">
	window.state = <cfoutput>#serializeJSON(rc.state)#</cfoutput>;
	require([
		"react",
		"models/state",
		"jsx!ui/messages",
		"jsx!ui/tasks/statuses"], 

		function(React,State,Messages,TaskStatuses) {
			React.renderComponent(Messages(State.get("state")),document.getElementById('messages'));
			React.renderComponent(TaskStatuses(State.get("state")),document.getElementById('tasks'));
		}
	);
</script>