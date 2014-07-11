component {

	function init(fw) {
		variables.fw = fw;

		variables.security = createobject("component","security.services.security");
		if (structkeyexists(variables.security,"init"))
			variables.security.init(variables.fw);

		return this;
	}

	public void function checkSecurity( struct rc ){
		// no security check if the user is logged in
		if (variables.security.isLoggedIn( arguments.rc ))
			return;

		// no security check for public paths
		if (variables.security.isPublicAction( arguments.rc ))
			return;

		// redirect to login
		session.redirectAction = variables.fw.getFullyQualifiedAction();
		if (listfirst(session.redirectAction,":") == "security")
			session.redirectAction = "admin:main.default";
		variables.fw.redirect( "security:main.login" );
	}

	public void function login( struct rc ){
		arguments.rc.title = "Login";
		arguments.rc.login_options = variables.security.getLoginOptions( arguments.rc );
	}

	public void function finishLogin( struct rc ){
		var redirectAction = session.redirectAction;
		structdelete(session,"redirectAction");
		variables.fw.redirect( redirectAction );
	}

}