component {

	public any function init(fw){
		variables.fw = arguments.fw;

		return this;
	}

	public void function add( struct rc ){

	}

	public void function list( struct rc ){
		arguments.rc.title = "Tasks";
		arguments.rc.state = {
			"tasks" = application.services["tasks.services.queue"].queryToArray(application.services["tasks.services.queue"].getStatus()),
			"tasklinks" = {},
			"taskactions" = []
		};
		arguments.rc.state["tasklinks"]["refreshalltasks"] = variables.fw.buildURL(action="tasks:main.getAllStatuses");
		arguments.rc.state["tasklinks"]["addtesttask"] = variables.fw.buildURL(action="tasks:main.addTestTask");
		arguments.rc.state["tasklinks"]["startthread"] = variables.fw.buildURL(action="tasks:main.startThread");
		arrayappend(arguments.rc.state["taskactions"],{
            "key"="startthread",
            "icon"="fa fa-play",
            "title"="Start thread",
            "link"="startthread"
        });
		arrayappend(arguments.rc.state["taskactions"],{
            "key"="addtesttask",
            "icon"="fa fa-clock-o",
            "title"="Add test 30s task",
            "link"="addtesttask"
        });

		for (var i=1; i<=arraylen(arguments.rc.state.tasks); i++){
			arguments.rc.state.tasks[i]["key"] = arguments.rc.state.tasks[i].id;
			arguments.rc.state.tasks[i]["arguments"] = deserializeJSON(arguments.rc.state.tasks[i]["arguments"]);
			arguments.rc.state.tasks[i]["actions"] = [];
			arrayappend(arguments.rc.state.tasks[i]["actions"],{
	            "key"="cancel",
	            "icon"="fa fa-times",
	            "title"="Cancel",
	            "link"="cancel"
	        });
			arguments.rc.state.tasks[i]["links"] = {};
            arguments.rc.state.tasks[i]["links"]["cancel"] = variables.fw.buildURL(action="tasks:main.cancelTask",queryString="id=#arguments.rc.state.tasks[i].id#");
        }
	}

	public void function getAllStatuses( struct rc ){
		list(arguments.rc);
		variables.fw.renderData("json",arguments.rc.state);
	}

	public void function addTestTask( struct rc ){
		application.services["tasks.services.queue"].queueTask(component="tasks.services.test",method="sleepFor",args={ period=30 },locks="sleepFor",mergingLocks="sleepFor");
		application.services["tasks.services.queue"].runTasks();
		list(arguments.rc);
		arguments.rc.state["messages"] = [{ "status"="success", "message"="Test task added", "key"=createuuid() }];
		variables.fw.renderData("json",arguments.rc.state);
	}

	public void function cancelTask( struct rc ){
		application.services["tasks.services.queue"].closeTask(arguments.rc.id);
		list(arguments.rc);
		arguments.rc.state["messages"] = [{ "status"="success", "message"="Task canceled", "key"=createuuid() }];
		variables.fw.renderData("json",arguments.rc.state);
	}

	public void function startThread( struct rc ){
		var processid = application.services["tasks.services.queue"].runTasks();
		list(arguments.rc);
		if (len(processid))
			arguments.rc.state["messages"] = [{ "status"="success", "message"="Thread started", "key"=createuuid() }];
		else
			arguments.rc.state["messages"] = [{ "status"="success", "message"="No spare threads", "key"=createuuid() }];
		variables.fw.renderData("json",arguments.rc.state);
	}

    public void function kick( struct rc ){
    	var processid = application.services["tasks.services.queue"].runTasks();

    	if (len(processid))
	    	variables.fw.renderData("json",{ "success" = true, "started" = processid });
	    else
	    	variables.fw.renderData("json",{ "success" = true });
    }

}