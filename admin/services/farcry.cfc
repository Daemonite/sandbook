component {
	
	public any function init( fw ){
		variables.fw = arguments.fw;

		return this;
	}

	variables.newline = "
";

	public void function compileFormtools( required struct result, required struct config, required array data ){
		var i = 0;
		var k = "";

		if (not structkeyexists(arguments.result.children, "formtools")){
			if (structkeyexists(arguments.config,"defaults")){
				arguments.result.children["formtools"] = duplicate(arguments.config.defaults);
			}

			structappend(arguments.result.children["formtools"],{
				"title" : "",
				"body" : [],
				"children" : {},
				"links" : {}
			},false);
		}

		if (!structkeyexists(arguments.config,"libsingular"))
			arguments.config["libsingular"] = "formtool";
		if (!structkeyexists(arguments.config,"fnplural"))
			arguments.config["fnplural"] = "";

		for (i=1; i<=arraylen(arguments.data); i++){
			compileFormtool(arguments.result.children.formtools, arguments.config, arguments.data[i].cfc);
		}

		structappend(arguments.result.links,arguments.result.children.formtools.links,true);
	}

	public void function compileFormtool( required struct result, required struct config, required struct data ){
		var st = {};
		var formtool = "";
		var i = 0;
		var fn = {};
		var j = 0;
		var keys = [];

		formtool = listfirst(listlast(arguments.data.filepath,"/"),".");
		if (!structkeyexists(arguments.result.children, formtool)){
			if (structkeyexists(arguments.config,"libdefaults")){
				arguments.result.children[formtool] = duplicate(arguments.config.libdefaults);
			}

			structappend(arguments.result.children[formtool],{
				"title" : "",
				"body" : []
			},false);
		}
		st = arguments.result.children[formtool];
		arguments.result.links["formtools.#formtool#"] = "formtools.#formtool#";

		// title
		if (structkeyexists(arguments.data.component,"displayname")){
			st["title"] = arguments.data.component.displayname;
		}
		else {
			st["title"] = listfirst(listlast(arguments.data.filepath,"/"),".");
		}
		
		// deprecated?
		if (structkeyexists(arguments.data.component,"bDeprecated") && arguments.data.component.bDeprecated)
			addContent(st.body, "<p class='Deprecated'>This #arguments.config.libsingular# has been deprecated.</p>");
		
		// inline readme
		if (structkeyexists(arguments.data.component,"readme"))
			addContent(st.body, arguments.data.component.readme);
		elseif (structkeyexists(arguments.data.component,"description"))
			addContent(st.body, arguments.data.component.description);
		elseif (structkeyexists(arguments.data.component,"hint"))
			addContent(st.body, arguments.data.component.hint);

		// examples
		if (structkeyexists(arguments.data.component,"examples") && len(trim(arguments.data.component.examples)))
			addContent(st.body, cleanExamples(arguments.data.component.examples));

		// properties
		addContent(st.body, "<h3>Attributes</h3>");
		addContent(st.body, "<table class='table table-bordered table-striped'><thead><tr><th>Name</th><th>Required</th><th>Default</th><th>Options</th><th>Description</th></tr></thead><tbody>");

		if (arraylen(arguments.data.properties)){
			for (j=1; j<=arraylen(arguments.data.properties); j++){
				if (!structkeyexists(arguments.data.properties[j],"required"))
					arguments.data.properties[j].required = false;
				if (!structkeyexists(arguments.data.properties[j],"default"))
					arguments.data.properties[j].default = "";
				if (!structkeyexists(arguments.data.properties[j],"options"))
					arguments.data.properties[j].options = "";
				if (!structkeyexists(arguments.data.properties[j],"hint"))
					arguments.data.properties[j].hint = "";
				addContent(st.body, "<tr><td>#arguments.data.properties[j].name#</td><td>#yesnoformat(arguments.data.properties[j].required)#</td><td>#arguments.data.properties[j].default#</td><td>#arguments.data.properties[j].options#</td><td>#arguments.data.properties[j].hint#</td></tr>")
			}

			addContent(st.body, "</tbody></table>");
		}
		else{
			addContent(st.body, "<tr><td colspan='6'>None</td></tr>");
		}
	}

	public void function compileTagLibraries( required struct result, required struct config, required array data ){
		var libs = {};
		var libid = "";
		var tagid = "";

		if (not structkeyexists(arguments.result.children, "tags")){
			if (structkeyexists(arguments.config,"defaults")){
				arguments.result.children["tags"] = duplicate(arguments.config.defaults);
			}

			structappend(arguments.result.children["tags"],{
				"title" : "",
				"body" : [],
				"children" : {},
				"links" : {}
			},false);
		}

		if (!structkeyexists(arguments.config,"libplural"))
			arguments.config["libplural"] = "tag libraries";
		if (!structkeyexists(arguments.config,"libsingular"))
			arguments.config["libsingular"] = "tag library";
		if (!structkeyexists(arguments.config,"fnplural"))
			arguments.config["fnplural"] = "tags";
		if (!structkeyexists(arguments.config,"fnplural"))
			arguments.config["fnsingular"] = "tag";

		for (i=1; i<=arraylen(arguments.data); i++){
			if (structkeyexists(arguments.data[i],"tag") && (!structkeyexists(arguments.data[i].tag,"bDocument") || arguments.data[i].tag.bDocument)){
				libid = listgetat(arguments.data[i].tag.filepath,listlen(arguments.data[i].tag.filepath,"/")-1,"/");
				if (not structkeyexists(libs,libid)){
					libs[libid] = {
						"libid" = libid,
						"title" = libid,
						"prefix" = libid,
						"path" = listdeleteat(arguments.data[i].tag.filepath,listlen(arguments.data[i].tag.filepath,"/"),"/"),
						"tags" = {}
					};
				}

				tagid = listfirst(listlast(arguments.data[i].tag.filepath,"/"),".");
				libs[libid].tags[tagid] = arguments.data[i].tag;
			}
		}

		for (libid in libs){
			compileTagLibrary(arguments.result.children.tags, arguments.config, libs[libid]);
		}

		structappend(arguments.result.links,arguments.result.children.tags.links,true);
	}

	public void function compileTagLibrary( required struct result, required struct config, required struct data ){
		var st = {};
		var libid = "";
		var i = 0;
		var tag = {};
		var j = 0;
		var keys = [];

		libid = arguments.data.libid;
		if (!structkeyexists(arguments.result.children, libid)){
			if (structkeyexists(arguments.config,"libdefaults")){
				arguments.result.children[libid] = duplicate(arguments.config.libdefaults);
			}

			structappend(arguments.result.children[libid],{
				"title" : "",
				"body" : []
			},false);
		}
		st = arguments.result.children[libid];
		arguments.result.links["tags.#libid#"] = "tags.#libid#";

		// title
		st["title"] = arguments.data.title;
		
		// deprecated?
		if (structkeyexists(arguments.data,"bDeprecated") && arguments.data.bDeprecated)
			addContent(st.body, "<p class='Deprecated'>This #arguments.config.libsingular# has been deprecated.</p>");
		
		// taglib info
		addContent(st.body, "<table class='table table-bordered table-striped'><tbody>");
		addContent(st.body, "<tr><td>Prefix</td><td>#arguments.data.prefix#</td></tr>");
		addContent(st.body, "<tr><td>Library path</td><td>#arguments.data.path#</td></tr>");
		addContent(st.body, "<tr><td>CFImport</td><td><pre class='linenums prettyprint'><"&"cfimport taglib=""#arguments.data.path#"" prefix=""#arguments.data.prefix#"" /></pre></td></tr>");
		addContent(st.body, "</tbody></table>");

		// inline readme
		if (structkeyexists(arguments.data,"readme"))
			addContent(st.body, arguments.data.readme);
		elseif (structkeyexists(arguments.data,"description"))
			addContent(st.body, arguments.data.description);

		// tags TOC
		keys = listtoarray(listsort(structkeylist(arguments.data.tags),"textnocase"));
		addContent(st.body,"<ul class='components-list nav nav-pills'>")
		for (i=1; i<=arraylen(keys); i++){
			tag = arguments.data.tags[keys[i]];
			addContent(st.body, "<li><a href='tags.#libid#.#tag.tag.name#'>#tag.tag.name#</a></li>");
		}
		addContent(st.body, "</ul>");

		// tag details
		for (i=1; i<=arraylen(keys); i++){
			tag = arguments.data.tags[keys[i]];

			// title
			addContent(st.body, "<h2><a name='#tag.tag.name#'></a>&lt;#arguments.data.prefix#:#tag.tag.name# ...&gt;</h2>");

			// description
			if (structkeyexists(tag.tag,"description"))
				addContent(st.body, "<p>#tag.tag.description#</p>");

			// metadata
			if (structkeyexists(tag.tag,"xmlstyle")){
				addContent(st.body, "<table class='table table-bordered table-striped'><tbody>");
				addContent(st.body, "<tr><td>XML Style</td><td>#yesnoformat(tag.tag.xmlstyle)#</td></tr>");
				addContent(st.body, "</tbody></table>");
			}

			// examples
			if (structkeyexists(tag.tag,"examples") && len(trim(tag.tag.examples)))
				addContent(st.body, cleanExamples(tag.tag.examples));

			// arguments
			addContent(st.body, "<h3>Attributes</h3>");
			addContent(st.body, "<table class='table table-bordered table-striped'><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Default</th><th>Options</th><th>Description</th></tr></thead><tbody>");

			if (arraylen(tag.attributes)){
				for (j=1; j<=arraylen(tag.attributes); j++){
					if (!structkeyexists(tag.attributes[j],"type"))
						tag.attributes[j].type = "string";
					if (!structkeyexists(tag.attributes[j],"required"))
						tag.attributes[j].required = false;
					if (!structkeyexists(tag.attributes[j],"default"))
						tag.attributes[j].default = "";
					if (!structkeyexists(tag.attributes[j],"options"))
						tag.attributes[j].options = "";
					if (!structkeyexists(tag.attributes[j],"hint"))
						tag.attributes[j].hint = "";
					addContent(st.body, "<tr><td>#tag.attributes[j].name#</td><td>#tag.attributes[j].type#</td><td>#yesnoformat(tag.attributes[j].required)#</td><td>#tag.attributes[j].default#</td><td>#tag.attributes[j].options#</td><td>#tag.attributes[j].hint#</td></tr>")
				}

				addContent(st.body, "</tbody></table>");
			}
			else{
				addContent(st.body, "<tr><td colspan='6'>None</td></tr>");
			}

			arguments.result.links["tags.#libid#.#tag.tag.name#"] = "tags.#libid####tag.tag.name#";
		}
	}

	public void function compileLibraries( required struct result, required struct config, required array data ){
		var i = 0;
		var k = "";

		if (not structkeyexists(arguments.result.children, "libraries")){
			if (structkeyexists(arguments.config,"defaults")){
				arguments.result.children["libraries"] = duplicate(arguments.config.defaults);
			}

			structappend(arguments.result.children["libraries"],{
				"title" : "",
				"body" : [],
				"children" : {},
				"links" : {}
			},false);
		}

		if (!structkeyexists(arguments.config,"libsingular"))
			arguments.config["libsingular"] = "library";
		if (!structkeyexists(arguments.config,"fnplural"))
			arguments.config["fnplural"] = "functions";

		for (i=1; i<=arraylen(arguments.data); i++){
			compileLibrary(arguments.result.children.libraries, arguments.config, arguments.data[i].cfc);
		}

		structappend(arguments.result.links,arguments.result.children.libraries.links,true);
	}

	public void function compileLibrary( required struct result, required struct config, required struct data ){
		var st = {};
		var libid = "";
		var i = 0;
		var fn = {};
		var j = 0;
		var keys = [];

		libid = listfirst(listlast(arguments.data.filepath,"/"),".");
		if (!structkeyexists(arguments.result.children, libid)){
			if (structkeyexists(arguments.config,"libdefaults")){
				arguments.result.children[libid] = duplicate(arguments.config.libdefaults);
			}

			structappend(arguments.result.children[libid],{
				"title" : "",
				"body" : []
			},false);
		}
		st = arguments.result.children[libid];
		arguments.result.links["libraries.#libid#"] = "libraries.#libid#";

		// title
		if (structkeyexists(arguments.data.component,"displayname")){
			st["title"] = arguments.data.component.displayname;
		}
		else {
			st["title"] = listfirst(listlast(arguments.data.filepath,"/"),".");
		}
		
		// deprecated?
		if (structkeyexists(arguments.data.component,"bDeprecated") && arguments.data.component.bDeprecated)
			addContent(st.body, "<p class='Deprecated'>This #arguments.config.libsingular# has been deprecated.</p>");
		
		// inline readme
		if (structkeyexists(arguments.data.component,"readme"))
			addContent(st.body, arguments.data.component.readme);
		elseif (structkeyexists(arguments.data.component,"description"))
			addContent(st.body, arguments.data.component.description);

		// functions TOC
		keys = listtoarray(listsort(structkeylist(arguments.data.functions),"textnocase"));
		addContent(st.body,"<ul class='components-list nav nav-pills'>")
		for (i=1; i<=arraylen(keys); i++){
			fn = arguments.data.functions[keys[i]];
			addContent(st.body, "<li><a href='libraries.#libid#.#fn.name#'>#fn.name#</a></li>");
		}
		addContent(st.body, "</ul>");

		// function details
		for (i=1; i<=arraylen(keys); i++){
			fn = arguments.data.functions[keys[i]];

			// title
			addContent(st.body, "<h2><a name='#fn.name#'></a>#fn.name#()</h2>");

			// description
			if (structkeyexists(fn,"description"))
				addContent(st.body, "<p>#fn.description#</p>");
			elseif (structkeyexists(fn, "hint"))
				addContent(st.body, "<p>#fn.hint#</p>");

			// examples
			if (structkeyexists(fn,"examples") && len(trim(fn.examples)))
				addContent(st.body, cleanExamples(fn.examples));

			// arguments
			addContent(st.body, "<h3>Arguments</h3>");
			addContent(st.body, "<table class='table table-bordered table-striped'><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Default</th><th>Options</th><th>Description</th></tr></thead><tbody>");

			if (arraylen(fn.arguments)){
				for (j=1; j<=arraylen(fn.arguments); j++){
					if (!structkeyexists(fn.arguments[j],"type"))
						fn.arguments[j].type = "string";
					if (!structkeyexists(fn.arguments[j],"required"))
						fn.arguments[j].required = false;
					if (!structkeyexists(fn.arguments[j],"default"))
						fn.arguments[j].default = "";
					if (!structkeyexists(fn.arguments[j],"options"))
						fn.arguments[j].options = "";
					if (!structkeyexists(fn.arguments[j],"hint"))
						fn.arguments[j].hint = "";
					addContent(st.body, "<tr><td>#fn.arguments[j].name#</td><td>#fn.arguments[j].type#</td><td>#yesnoformat(fn.arguments[j].required)#</td><td>#fn.arguments[j].default#</td><td>#fn.arguments[j].options#</td><td>#fn.arguments[j].hint#</td></tr>")
				}

				addContent(st.body, "</tbody></table>");
			}
			else{
				addContent(st.body, "<tr><td colspan='6'>None</td></tr>");
			}

			arguments.result.links["libraries.#libid#.#fn.name#"] = "libraries.#libid####fn.name#";
		}
	}


	private string function cleanExamples( required string text ){
		var result = arguments.text;
		var spaces = "";

		// Clean up code tags
		result = replacelist(result,"<pre>,brush: coldfusion,<code>,</code>","<pre class='linenums prettyprint'>,linenums prettyprint,<pre class='linenums prettyprint'>,</pre>");

		// Convert tabs to 4 spaces
		result = result.replaceAll("\t"," ");

		// Remove empty lines at the start and end of code
		result = result.replaceAll("(<pre[^>]+>)[\r\n]+","$1");
		result = result.replaceAll("[\r\n]+(</pre>)","$1");

		// Remove redundant spacing at the start of lines of code - use the first line to figure the spacing
		if (refind("<pre[^>]+> *",result)){
			spaces = rereplace(result,"^.*<pre[^>]+>( *).*$","\1");
			result = result.replaceAll("(?m)(^|<pre[^>]+>)#spaces#(.*?)$","$1$2");
		}

		// Replace lines with only spaces, with empty lines
		result = result.replaceAll("(>|\r?\n) +(\r?\n|<)","$1$2");

		// Squashing a documentation bug - some examples have &tl; instead of &lt; or an actual <
		result = result.replaceAll("&amp;tl;","&lt;");

		// Convert any <p></p> immediately before a <pre></pre> into a code heading
		result = result.replaceAll("<p>(.+?)</p>\s*(<pre )","<span class='pre-header'>$1</span>$2");

		return result;
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