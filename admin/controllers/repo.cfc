component {
	
	public any function init(fw){
		variables.fw = arguments.fw;

		variables.repo = application.services["admin.services.repo"];

		return this;
	}

	public void function status( struct rc ){
		var repo = variables.fw.getADConfig("repos.#arguments.rc.id#");

		arguments.rc.data = {};
		arguments.rc.data["repository"] = variables.repo.getRepoStatus( repo );
		variables.fw.renderData("json",arguments.rc.data);
	}

	public void function setupRepo( struct rc ){
		var repo = variables.fw.getADConfig("repos.#arguments.rc.id#");
		
		arguments.rc.data = variables.repo.setupRepo( repo );
		arguments.rc.data["repository"] = variables.repo.getRepoStatus( repo );
		variables.fw.renderData("json",arguments.rc.data);
	}

	public void function ignoreRepoRef( struct rc ){
		var repo = variables.fw.getADConfig("repos.#arguments.rc.id#");
		
		variables.repo.ignoreRepoRef( repo, arguments.rc.ref );
		
		arguments.rc.data["repository"] = variables.repo.getRepoStatus( repo );
		variables.fw.renderData("json",arguments.rc.data);
	}

	public void function unignoreRepoRef( struct rc ){
		var repo = variables.fw.getADConfig("repos.#arguments.rc.id#");
		
		variables.repo.unignoreRepoRef( repo, arguments.rc.ref );
		
		arguments.rc.data["repository"] = variables.repo.getRepoStatus( repo );
		variables.fw.renderData("json",arguments.rc.data);
	}

	public void function processRepoRef( struct rc ){
		var repo = variables.fw.getADConfig("repos.#arguments.rc.id#");
		var debug = variables.fw.getADConfig("debug");
		
		application.services["tasks.services.queue"].queueTask("admin.services.repo","processRepoRef",{ repo=repo, ref=arguments.rc.ref, debug=debug },"repo:#arguments.rc.id#:#arguments.rc.ref#","queued","repo:#arguments.rc.id#:#arguments.rc.ref#");
		application.services["tasks.services.queue"].runTasks();
		arguments.rc.data["repository"] = variables.repo.getRepoStatus( repo );
		variables.fw.renderData("json",arguments.rc.data);
	}

	public void function webhookGithubPush( struct rc ){
		var repo = variables.fw.getADConfig("repos.#arguments.rc.id#");
		var rc.data = deserializeJSON(toString(getHttpRequestData().content));
		var debug = variables.fw.getADConfig("debug");

		if (!variables.repo.isRepoRefIgnored(repo, rc.data.ref)){
			application.services["tasks.services.queue"].queueTask("admin.services.repo","processRepoRef",{ repo=repo, ref=rc.data.ref, debug=debug },"repo:#arguments.rc.id#:#rc.data.ref#","queued","repo:#arguments.rc.id#:#rc.data.ref#");
			application.services["tasks.services.queue"].runTasks();
		}

		variables.fw.renderData("json",{ "success" : true });
	}

}