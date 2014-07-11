component {

	variables.newline = "
";

	public any function init( fw ){
		variables.fw = arguments.fw;

		return this;
	}


	public string function writeHTML( required struct repo, required struct data, required struct config, required string processdir ){
		var files = flattenData(arguments.data);
		var menu = createMenu(arguments.data,arguments.config).children;
		var links = arguments.data.links;
		var indextitle = arguments.data.indextitle;

		if (!structIsEmpty(arguments.repo))
			arguments.repo.label = arguments.repo.label;

		generateFiles( files, arguments.config, indextitle, menu, links, arguments.processdir );

		return arguments.processdir & "/";
	}

	private struct function flattenData( required struct data, string page="", struct result={} ){
		var k = "";
		var filename = "";

		if (len(arguments.page))
			filename = "/" & replace(arguments.page,".","/","all") & ".html";
		else
			filename = "/index.html";

		arguments.data.id = arguments.page;
		arguments.result[filename] = arguments.data;

		// do children
		if (structkeyexists(arguments.data,"children") && structcount(arguments.data.children)){
			for (k in arguments.data.children){
				flattenData( arguments.data.children[k], listappend(arguments.page,k,"."), arguments.result );
			}
		}

		return arguments.result;
	}

	private void function generateFiles( required struct files, required struct config, required string indextitle, required array menu, required struct links, required string basePath ){
		var k = "";
		var data = {};
		var htmltemplate = "";
		var html = "";
		var filename = "";
		var links = {};
		var aFiles = listtoarray(structkeylist(arguments.files));
		var j = 0;
		var thisfile = "";

		for (j=1; j<=arraylen(aFiles); j++){
			thisfile = arguments.files[aFiles[j]];
			application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "#round(j/arraylen(aFiles)*100)#% writing html #aFiles[j]#");
			htmltemplate = getTemplate(arguments.config, thisfile.id);

			// create page
			if (len(htmltemplate)){
				// get links as relative URLs
				links = relativeLinks( arguments.links, thisfile.id );
				
				data = {
					"indextitle" = arguments.indextitle,
					"title" = thisfile.title,
					"body" = renderContentArray(thisfile.body, links),
					"menu" = relativeMenu( arguments.menu, thisfile.id ),
					"basePath" = ".",
					"home" = links["home"]
				};

				// figure out path to use to get to base of directory structure
				if (listlen(thisfile.id,".") > 1){
					data["basePath"] = repeatString("../",listlen(thisfile.id,".")-1);
					data["basePath"] = left(data["basePath"],len(data["basePath"])-1);
				}

				// render footer
				if (structkeyexists(thisfile,"footer"))
					data["footer"] = renderContentArray( thisfile.footer, links );
				else
					data["footer"] = "";

				// run template
				savecontent variable="html"{
					include template="#htmltemplate#";
				}

				// write file
				if (len(trim(html))){
					filename = arguments.basePath & aFiles[j];

					if (!directoryExists(getDirectoryFromPath(filename))){
						directoryCreate(getDirectoryFromPath(filename));
					}

					fileWrite(filename, html);
				}
			}
		}
	}

	private string function getTemplate( required struct config, required string page ){
		var k = "";

		for (k in arguments.config.templates){
			if (refindnocase(k, arguments.page) || (k=="^$" && arguments.page==""))
				return arguments.config.templates[k];
		}

		return "";
	}

	private string function renderContentArray( required array data, required struct links ){
		var result = "";
		var i = 0;

		for (i=1; i<=arraylen(arguments.data); i++){
			switch (arguments.data[i].type){
				case "html":
					result = result & variables.newline & renderHTML(arguments.data[i].content, arguments.links);
					break;
				case "markdown":
					result = result & variables.newline & renderMarkdown(arguments.data[i].content, arguments.links);
					break;
			}
		}

		return result;
	}

	private string function renderHTML( required string content, required struct links ){
		var k = "";

		for (k in arguments.links){
			arguments.content = replace(arguments.content,"href='#k#'","href='#arguments.links[k]#'","all");
			arguments.content = replace(arguments.content,'href="#k#"',"href='#arguments.links[k]#'","all");
		}

		return arguments.content;
	}

	private string function renderMarkdown( required content, required struct links ){
		if (!structkeyexists(variables,"md")){
			variables.md = application.services["admin.services.java"].loadClass("com.petebevin.markdown.MarkdownProcessor").init();
		}
writeLog(file="debug",text=arguments.content & variables.newline & markdownLinks(arguments.links));
		return variables.md.markdown(arguments.content & variables.newline & markdownLinks(arguments.links));
	}


	private struct function createMenu( required struct data, required struct config, string id="" ){
		var thisitem = {
			"title" : "Untitled",
			"id" : arguments.id,
			"children" : []
		};
		var i = 0;
		var childorder = "";
		var swapped = false;
		var n = 0;
		var tmp = "";

		if (structkeyexists(arguments.data,"title"))
			thisitem["title"] = arguments.data.title;
		else
			thisitem["title"] = "Untitled";

		if (structkeyexists(arguments.data,"children")){
			// put children in alphabetical order
			childorder = listtoarray(structkeylist(arguments.data.children));
			n = arraylen(childorder);
		    do {
				swapped = false;
				for (i=2; i<=n-1; i++){
					if (arguments.data.children[childorder[i-1]].title > arguments.data.children[childorder[i]].title){
						tmp = childorder[i-1];
						childorder[i-1] = childorder[i];
						childorder[i] = tmp;
						swapped = true;
					}
				}
				n = n - 1;
		    } while (swapped);

		    for (i=1; i<=arraylen(childorder); i++){
		    	arrayappend(thisitem.children, createMenu(arguments.data.children[childorder[i]],arguments.config,listappend(thisitem.id,childorder[i],".")));
		    }
		}

		return thisitem;
	}

	private string function relativeURL( required string fromURL, required string toURL ){
		var i = 0;

		if (len(arguments.fromURL) == ""){
			arguments.fromURL = "index.html";
		}

		if (len(arguments.toURL) == ""){
			arguments.toURL = "index.html";
		}

		while (len(arguments.fromURL) && len(arguments.toURL) && listfirst(arguments.fromURL,"/") == listfirst(arguments.toURL,"/")){
			arguments.fromURL = listdeleteat(arguments.fromURL,1,"/");
			arguments.toURL = listdeleteat(arguments.toURL,1,"/");
		}

		for (i=1; i<=listlen(arguments.fromURL,"/")-1; i++){
			arguments.toURL = "../" & arguments.toURL;
		}

		return arguments.toURL;
	}

	private array function relativeMenu( required array menu, required string page ){
		var i = 0;
		var result = [];
		
		for (i=1; i<=arraylen(arguments.menu); i++){
			result[i] = duplicate(arguments.menu[i]);
			if (len(result[i].id)){
				result[i]["link"] = relativeURL(replace(arguments.page,".","/","all") & ".html", replace(result[i].id,".","/","all") & ".html");
				if (refind("^" & replace(result[i].id,".","\.","ALL") & "($|\.)", arguments.page)){
					result[i]["active"] = true;
				}
				else{
					result[i]["active"] = false;
				}
			}
			else{
				result[i]["link"] = relativeURL(replace(arguments.page,".","/","all") & ".html", "index.html");
				result[i]["active"] = true;
			}
			result[i]["children"] = relativeMenu(arguments.menu[i].children,arguments.page);
		}

		return result;
	}

	private array function getSiblings( required array menu, required numeric level ){
		var children = arguments.menu;
		var thislevel = 1;
		var i = 0;
		var goagain = arraylen(children) > 0;

		while (thislevel < arguments.level && goagain){
			goagain = false;

			for (i=1; i<=arraylen(children); i++){
				if (children[i].active){
					children = children[i].children;
					thislevel = thislevel + 1;
					goagain = true;
					break;
				}
			}
		}

		if (thislevel == arguments.level){
			return children;
		}
		else{
			return [];
		}
	}

	private array function getBreadcrumbs( required array menu ){
		var children = arguments.menu;
		var result = [];
		var i = 0;
		var goagain = arraylen(children) > 0;

		while (goagain){
			goagain = false;

			for (i=1; i<=arraylen(children); i++){
				if (children[i].active){
					arrayappend(result,children[i]);
					children = children[i].children;
					goagain = true;
					break;
				}
			}
		}

		return result;
	}

	private struct function relativeLinks( required struct links, required string page ){
		var newlinks = {};
		var k = "";

		for (k in arguments.links){
			if (refindnocase("^https?://",arguments.links[k]) || left(arguments.links[k],1) == "/"){
				// already valid link
				newlinks[k] = arguments.links[k];
			}
			else{
				newlinks[k] = relativeURL( replace(arguments.page,".","/","all") & ".html", replace(listfirst(arguments.links[k],"##"),".","/","all") & ".html" );
				if (find("##",arguments.links[k])){
					newlinks[k] = newlinks[k] & "##" & listlast(arguments.links[k],"##");
				}
			}
		}

		newlinks["home"] = relativeURL( replace(arguments.page,".","/","all") & ".html", "index.html" );

		return newlinks;
	}

	private string function markdownLinks( required struct links ){
		var result = [];
		var k = "";

		for (k in arguments.links){
			arrayappend(result,"[#k#]: #arguments.links[k]#");
		}

		return variables.newline & variables.newline & arraytolist(result,variables.newline);
	}

}