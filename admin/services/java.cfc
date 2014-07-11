component {
	
	public any function init( fw ){
		var tmppaths = arguments.fw.getADConfig("jars",[])

		variables.fw = arguments.fw;
		variables.paths = [];
		for (var i=1; i<=arraylen(tmppaths); i++)
			arrayappend(variables.paths,expandPath(tmppaths[i]));
		variables.loader = createObject("component","admin.java.JavaLoader").init(variables.paths);

		return this;
	}

	public any function loadClass( required string path ){

		return variables.loader.create( arguments.path );
	}

}