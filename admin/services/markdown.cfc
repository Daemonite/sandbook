component {
	
	variables.newline = "
";

	public any function init( fw ){
		variables.fw = arguments.fw;

		return this;
	}

	public void function compileIndex( required struct result, required struct config, required array data ){
		var i = 0;
		var k = "";

		if (structkeyexists(arguments.config,"defaults")){
			structappend(arguments.result, arguments.config.defaults, false);
		}

		for (i=1; i<=arraylen(arguments.data); i++){
			//compileLibrary(arguments.result.children.libraries, arguments.config, arguments.data[i]);
		}
	}

	public void function compileS3Index( required struct result, required struct config, required array data ){
		var i = 0;
		var k = "";
		var l = "";
		var m = "";
		var first = true;

		if (structkeyexists(arguments.config,"defaults")){
			structappend(arguments.result, arguments.config.defaults, false);
		}

		for (i=1; i<=arraylen(arguments.data); i++){
			for (k in arguments.data[i]){
				if (not listfindnocase("lastupdated",k)){
					addContent( arguments.result.body, "<div class='row'><div class='span3'><h2>#arguments.data[i][k].title#</h2></div><div class='span9'><div class='main-content'>" );

					for (l in arguments.data[i][k].refs){
						if (!structkeyexists(arguments.data[i][k].refs[l],"ignore")){
							addContent( arguments.result.body, "<h3>#arguments.data[i][k].refs[l].title#</h3><div class='well well-small'>" );

							first = true;
							for (m in arguments.data[i][k].refs[l].outputs){
								if (!first){
									addContent( arguments.result.body, " | " );
								}
								if (right(arguments.data[i][k].refs[l].outputs[m].path,1) eq "/"){
									arguments.data[i][k].refs[l].outputs[m].path = arguments.data[i][k].refs[l].outputs[m].path & "index.html";
								}
								addContent( arguments.result.body, "<a href='.#arguments.data[i][k].refs[l].outputs[m].path#'>" );
								addContent( arguments.result.body, "<i class='#arguments.data[i][k].refs[l].outputs[m].icon#'></i> #arguments.data[i][k].refs[l].outputs[m].title#" );
								addContent( arguments.result.body, "</a>" );
								first = false;
							}

							addContent( arguments.result.body, "</div>" );

							addContent( arguments.result.body, "<small>updated #timeformat(arguments.data[i][k].refs[l].lastupdated,'HH:mm')#, #dateformat(arguments.data[i][k].refs[l].lastupdated,'d mmm yyyy')#; commit <a href='#arguments.data[i][k].refs[l].commit_url#'>#arguments.data[i][k].refs[l].commit#</a></small>");
						}
					}

					addContent( arguments.result.body, "</div></div></div>" );
				}
			}
		}
	}

	private void function addContent( aContent, content ){
		var type = "";

		if (left(trim(arguments.content),1) eq "<"){
			type = "html";
		}
		else{
			type = "markdown";
		}

		if (arraylen(arguments.aContent) && arguments.aContent[arraylen(arguments.aContent)].type == type){
			arguments.aContent[arraylen(arguments.aContent)].content &= variables.newline & arguments.content;
		}
		else{
			arrayappend(arguments.aContent,{
				"content" : arguments.content,
				"type" : type
			});
		}
	}

}