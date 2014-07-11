component {

	function init(fw) {
		variables.fw = fw;

		variables.google = createobject("component","security.services.google");
		if (structkeyexists(variables.google,"init"))
			variables.google.init(variables.fw);

		return this;
	}

	public void function login( struct rc ){
		var stResult = {};

		arguments.rc.title = "Google Login";
		arguments.rc.message = "";
		arguments.rc.authorize_url = variables.google.getOption().url;

		if (isdefined("arguments.rc.code")){
			arguments.rc.redirectURL = "http://#cgi.http_host#" & variables.fw.buildURL( 'security:google.login' );
			arguments.rc.login_result = variables.google.checkLogin(argumentCollection=arguments.rc);

			if (arguments.rc.login_result.success){
				session.user = arguments.rc.login_result;
				param name="session.redirectAction" default="#variables.fw.buildURL( 'admin:main.default' )#";
				variables.fw.redirect( "main.finishLogin" );
			}
		}
	}

}