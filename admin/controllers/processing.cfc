component {

	public any function init(fw){
		variables.fw = arguments.fw;

		return this;
	}

	public void function process( rc ){
		arguments.rc.data = application.services["admin.services.code"].parseFile(
			arguments.rc.codedir,
			deserializeJSON(arguments.rc.config),
			arguments.rc.filepath
		);
		variables.fw.renderData("json",arguments.rc.data);
	}

}