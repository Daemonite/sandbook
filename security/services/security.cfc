component {
	
	function init(fw) {
		variables.fw = fw;

		var login_services = variables.fw.getADConfig("security.services", ["local","google"]);

		for (var i=1; i<=arraylen(login_services); i++){
			variables[login_services[i]] = createobject("component","security.services.#login_services[i]#");
			if (structkeyexists(variables[login_services[i]],"init"))
				variables[login_services[i]].init(variables.fw);
		}

		return this;
	}

	public boolean function isLoggedIn( struct rc ){
		return isdefined("session.user");
	}

	public boolean function isPublicAction( struct rc ){
		var whitelist = variables.fw.getADConfig("security.publicactions",[]);

		whitelist.addAll(["^security:.*\.login$","^security:main\.logout$","^admin:main\.kick$","^admin:repo\.webhookGithubPush$"]);

		for (var i=1; i<=arraylen(whitelist); i++){
			if (refindnocase(whitelist[i],variables.fw.getFullyQualifiedAction()) > 0)
				return true;
		}

		return false;
	}

	public array function getLoginOptions( struct rc ){
		var login_services = variables.fw.getADConfig("security.services", ["local","google"]);
		var login_options = [];

		for (var i=1; i<=arraylen(login_services); i++){
			arrayappend(login_options,variables[login_services[i]].getOption());
		}

		return login_options;
	}

}