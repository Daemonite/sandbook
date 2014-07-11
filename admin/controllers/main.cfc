component {

	public any function init(fw){
		variables.fw = arguments.fw;

		return this;
	}

	public void function before(struct rc){
		arguments.rc.title = "AutoDoc";
	}

    public void function default( struct rc ) {
    	arguments.rc.state = {
    		"repositories" = application.services["admin.services.repo"].getRepoList( variables.fw.getADConfig("repos") )
    	};
    	arguments.rc.machinename = variables.fw.getADConfig("machinename","Unknown");
    }

    public void function error( struct rc ){
    	if (isdefined("arguments.rc.accepts") && arguments.rc.accepts == "json"){
            if (isJSON(request.exception.detail))
                request.exception.detail = deserializeJSON(request.exception.detail);
    		variables.fw.renderData("json",request.exception);
        }
        try{
            writeLog(file="exception",text=serializeJSON(request.exception));
        }catch(any e){}
    	arguments.rc.title = "Error";
    }

}