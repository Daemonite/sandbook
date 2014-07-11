component {
	
	public any function init(fw) {
		variables.fw = fw;
		return this;
	}

	public struct function getOption(){
		return {
			"url" : variables.fw.buildURL( 'security:local.login' ),
			"enabled" : isEnabled(),
			"button_class" : "btn-success",
			"label" : "Local User"
		}
	}

	public boolean function isEnabled(){
		return arraylen(variables.fw.getADConfig("security.local.users",[]));
	}

	public struct function checkLogin(required string username, required string password){
		var users = variables.fw.getADConfig("security.local.users",[]);

		for (var i=1; i<=arraylen(users); i++){
			if (users[i].username == arguments.username && users[i].password == arguments.password){
				return {
					"success" : true,
					"user" : arguments.username
				}
			}
		}

		return { 
			"success" : false, 
			"message" : "You are not an allowed user" 
		};
	}

}