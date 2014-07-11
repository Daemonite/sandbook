component {

	function init(fw) {
		variables.fw = fw;

		variables.local = createobject("component","security.services.local");
		if (structkeyexists(variables.local,"init"))
			variables.local.init(variables.fw);

		return this;
	}

	public void function login( struct rc ){
		var stResult = {};

		arguments.rc.title = "Local Login";
		arguments.rc.message = "";

		if (isdefined("arguments.rc.username") && isdefined("arguments.rc.password")){
			arguments.rc.login_result = variables.local.checkLogin(argumentCollection=arguments.rc);

			if (arguments.rc.login_result.success){
				session.user = arguments.rc.login_result;
				variables.fw.redirect( "main.finishLogin" );
			}
		}
	}

}