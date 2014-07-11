<div id="messages"></div>
<div id="repositories"></div>
<script type="text/javascript">
	window.state = <cfoutput>#serializeJSON(rc.state)#</cfoutput>;
	require([
		"react",
		"models/state",
		"jsx!ui/messages",
		"jsx!ui/repositories/statuses"], 

		function(React,State,Messages,RepositoryStatuses) {
			React.renderComponent(Messages(State.get("state")),document.getElementById('messages'));
			React.renderComponent(RepositoryStatuses(State.get("state")),document.getElementById('repositories'));
		}
	);
</script>