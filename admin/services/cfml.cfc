component {
	
	variables.newline = "
";

	public any function init( fw ){
		variables.fw = arguments.fw;

		return this;
	}


	public struct function processTag( required struct config, required string filepath, required string text ){
		var result = {
			"config" : arguments.config,
			"filepath" : arguments.filepath,
			"tag" : {
				"name" : listfirst(listlast(arguments.filepath,"/"),"."),
				"single" : true,
				"xmlstyle" : true,
				"bdocument" : true,
				"bDeprecated" : false
			},
			"attributes" : []
		};
		var aCommentClose = listtoarray("@@,--->"); // Possible closing strings for comment variables
		var aCommentMatches = arraynew(1); // Comment matches
		var aVarMatches = arraynew(1); // Variable matches
		var i = 0; // Loop index
		var j = 0; // Loop index
		var key = ""; // Comment variable name
		var aCode = arraynew(1); // Code snippets in value
		var k = 0; // Loop index

		// Find all comments that don't immediately follow a tag element (as the attribute comments do)
		aCommentMatches = scrapeAll(source=arguments.text,regex="(^|\s)<\!---.*?--->",regexref=1);
		for (i=1; i<=arraylen(aCommentMatches); i++){
			if (find("@@",aCommentMatches[i])){
				aVarMatches = scrapeAll(source=aCommentMatches[i],regex="@@[^:]+:(.*?)(@@|--->)",regexref=1);
				for (j=1; j<=arraylen(aVarMatches); j++){
					key = scrape(source=aVarMatches[j],regex="@@([^:]+):",regexref=2);
					result.tag[key] = scrape(source=aVarMatches[j],regex="@@[^:]+:(.*?)(?:@@|--->)",regexref=2);
					aCode = scrapeAll(source=result.tag[key],regex="<code>(.*?)</code>",regexref=2);
					for (k=1; k<=arraylen(aCode); k++){
						result.tag[key] = replace(result.tag[key],aCode[k],htmleditformat(aCode[k]));
					}
				}
			}
		}

		// Tag attributes
		aAttributes = scrapeAll(source=arguments.text,regex="(?:<!---)?<cfparam[^>]*name=(?:'|"")attributes\.[^>]*>(?:--->)?(?:<!---[^>]*>)?",regexref=1);
		for (i=1; i<=arraylen(aAttributes); i++){
			arrayappend(result.attributes,scrapeAttribute(source=aAttributes[i]));
		}

		return result;
	}

	public struct function scrapeAttribute(required string source){
		var stResult = structnew(); // Attribute metadata
		var aCommentClose = arraynew(1); // Possible closing strings for comment variables
		var aMatches = arraynew(1); // Scrape matches
		var i = 0; // Loop index

		aCommentClose[1] = "@@";
		aCommentClose[2] = "--->";

		param name="stResult.options" default="";
		param name="stResult.hint" default="";

		// Attribute name
		stResult["name"] = scrape(source=arguments.source,regex="name=(?:'|"")attributes\.([^'""]*)",regexref=2);

		// Attribute type
		stResult["type"] = scrape(source=arguments.source,regex="type=(?:'|"")([^'""]*)",regexref=2,default="string");

		// Attribute default
		stResult["default"] = scrape(source=arguments.source,regex="default=('|"")(.*?)\1(?!\1)",regexref=3,default="");

		// Required?
		stResult["required"] = (len(scrape(source=arguments.source,regex="default=('|"").*?\1(?!\1)",regexref=1,default=false)) eq 0);

		// Comment variables
		structappend(stResult,scrapeCommentVariables(source=source,remap="attrhint:hint,_:hint"),true);

		return stResult;
	}

	public struct function scrapeCommentVariables(required string source, string remap="", boolean escapeCode=false){
		var stResult = structnew();
		var stRemap = structnew();
		var thismap = "";
		var varName = "";
		var varVal = "";
		var aCode = arraynew(1);
		var k = 0;
		var aMap = listtoarray(arguments.remap);
		var i = 0;

		for (i=1; i<=arraylen(aMap); i++){
			stRemap[listfirst(aMap[i],":")] = listlast(aMap[i],":");
		}

		// Comment variables
		if (find("@@",arguments.source)){
			aMatches = scrapeAll(source=arguments.source,regex="@@[\w\d]+:(.*?)(?:@@|--->)",regexref=1);
			for (i=1; i<=arraylen(aMatches); i++){
				// Get variable name and value
				varName = scrape(source=aMatches[i],regex="@@([\w\d]+):",regexref=2);
				varVal = scrape(source=aMatches[i],regex="@@[\w\d]+:(.*?)(?:@@|--->)",regexref=2);

				// Find and escape <code> sections
				if (arguments.escapeCode){
					aCode = scrapeAll(source=varVal,regex="<code>(.*?)</code>",regexref=2,trim=false);
					for (k=1; k<=arraylen(aCode); k++){
						varVal = replace(varVal,aCode[k],cleanCode(code=aCode[k]));
					}

					// Convert to highlightable pre
					varVal = replacelist(varVal,"<code>,</code>","<pre class='brush: coldfusion'>,</pre>");
				}

				if (structkeyexists(stRemap,varName)){
					stResult[stRemap[varName]] = varVal;
				}
				else{
					stResult[varName] = varVal;
				}
			}
		}
		elseif (structkeyexists(stRemap,"_")){
			stResult[stRemap["_"]] = scrape(source=arguments.source,regex="<!--- (.*) --->",regexref=2,default="");
		}

		return stResult;
	}



	public struct function processCFC( required struct config, required string filepath, required string text ){
		var result = {
			"config" : arguments.config,
			"filepath" : arguments.filepath,
			"component" : {},
			"properties" : [],
			"functions" : {}
		};
		var functions = [];
		var i = 0;
		var st = {};
		var properties = "";

		// component attributes
		if (findnocase("<"&"cfcomponent ",arguments.text)){
			st = processAttributes(
				rereplacenocase(
					arguments.text,
					".*<"&"cfcomponent([^>]*)>.*",
					"\1"
				)
			);
			structappend(result.component, st);

			if (refind("^\s*<!---",arguments.text)){
				structappend(result.component, processComment(rereplace(arguments.text,"^\s*(<"&"!---.*?--->).*","\1")));
			}

			// component properties
			properties = scrapeAll(source=rereplace(arguments.text,"<!---.*?--->","","ALL"), regex="<"&"cfproperty[^>]+>", regexref=1);
			for (i=1; i<=arraylen(properties); i++){
				arrayappend(result.properties, processProperty(properties[i]));
			}

			// component functions
			functions = scrapeAll(source=arguments.text, regex="(<"&"!---(?:(?!--->).)*?--->[\s\n\r]*)?<"&"cffunction .*?<"&"/cffunction>", regexref=1);
			for (i=1; i<=arraylen(functions); i++){
				st = processFunction(functions[i]);
				if (structkeyexists(result.functions,st.name))
					structappend(result.functions[st.name],st);
				else
					result.functions[st.name] = st;
			}
		}
		else if (findnocase("component ",arguments.text)){
			st = processAttributes(
				rereplacenocase(
					arguments.text,
					".*component([^\}]*)\{.*",
					"\1"
				)
			);
			structappend(result.component, st);

			if (refind("^/*",arguments.text)){
				structappend(result.component, processComment(rereplace(arguments.text,"^\s*(\/\*.*?\*\/).*","\1")));
			}

			// component properties
			properties = scrapeAll(source=rereplace(arguments.text,"/\*.*?\*/","","ALL"), regex="\n\s*property(\s+\w+=[""'][^""']+[""'])", regexref=1);
			for (i=1; i<=arraylen(properties); i++){
				arrayappend(result.properties, processProperty(properties[i]));
			}

			// component functions
			functions = scrapeAll(source=arguments.text, regex="(?:\/\*.*?\*\/\s*)?[\w\s]*function [^\{]+", regexref=1);
			for (i=1; i<=arraylen(functions); i++){
				st = processFunction(functions[i]);
				if (structkeyexists(result.functions,st.name))
					structappend(result.functions[st.name],st);
				else
					result.functions[st.name] = st;
			}
		}

		return result;
	}

	public struct function processProperty( required string text ){
		var result = {};

		if (findnocase("<"&"cfproperty",arguments.text)){
			result = processAttributes(rereplacenocase(arguments.text,"^\s+<"&"cfproperty(.*?)/?>$","\1"));
		}
		else{
			result = processAttributes(rereplacenocase(arguments.text,"^\s+property(.*?)$","\1"));
		}

		return result;
	}

	public struct function processFunction( required string text ){
		var result = {
			"arguments" : []
		};
		var args = [];
		var i = 0;
		var st = {};

		if (findnocase("<"&"cffunction",arguments.text)){
			st = processAttributes(
				rereplacenocase(
					arguments.text,
					".*(<"&"cffunction[^>]+>).*",
					"\1"
				)
			);
			structappend(result, st);

			if (refind("^\s*<!---",arguments.text)){
				structappend(result, processComment(rereplace(arguments.text,"^\s*(<"&"!---.*?--->).*","\1")));
			}

			args = scrapeAll(source=arguments.text, regex="<"&"cfargument[^>]+>", regexref=1);
			for (i=1; i<=arraylen(args); i++)
				arrayappend(result.arguments, processArgument(args[i]));
		}
		else{
			st = processAttributes(
				rereplacenocase(
					arguments.text,
					".*[^\/]+ function([^\(]+).*",
					"\1"
				)
			);
			structappend(result, st);
			if (refindnocase(".*(private|package|public|remote)( [\w\.]+)? function\s",arguments.text))
				result["access"] = rereplacenocase(arguments.text,".*(private|package|public|remote)( [\w\.]+)? function\s([^\(]+).*","\1");
			if (refindnocase(".*[\w\.]+ function([^\(]+).*",arguments.text)){
				result["returntype"] = rereplacenocase(arguments.text,".*([\w\.]+) function([^\(]+).*","\1");
				if (listfindnocase("private,package,public,remote",result.returntype))
					structdelete(result,"returntype");
			}

			if (refind("^/*",arguments.text))
				structappend(result, processComment(rereplace(arguments.text,"^\s*(\/\*.*?\*\/).*","\1")));

			args = listtoarray(rereplacenocase(arguments.text,"function[^\(]+\(([^\)]+)\).*","\1"),",");
			for (i=1; i<=arraylen(args); i++)
				arrayappend(result.arguments, processArgument(args[i]));
		}

		return result;
	}

	public struct function processArgument( required string text ){
		var result = {};

		if (findnocase("<"&"cfargument",arguments.text)){
			result = processAttributes(rereplacenocase(arguments.text,"^<"&"cfargument(.*?)/?>$","\1"))
		}
		else{
			if (listfindnocase("required,optional",listfirst(arguments.text," "))){
				result["required"] = listfirst(arguments.text," ") eq "required";
				arguments.text = listrest(arguments.text," ");
			}
			if (refindnocase("^[-\w\._]+\s[-\w\._]+",arguments.text)){
				result["type"] = listfirst(arguments.text," ");
				arguments.text = listrest(arguments.text," ");
			}
			if (refindnocase("^[-\w\._]+=",arguments.text)){
				result["name"] = listfirst(arguments.text,"=");
				result["default"] = listrest(arguments.text,"=");
				if (refindnocase("^[""'].*[""']$",result["default"]))
					result["default"] = mid(result["default"],2,len(result["default"]-2));
			}
		}

		return result;
	}

	public struct function processAttributes( required string text ){
		var attrs = scrapeAll(source=arguments.text, regex="(?:^|\s)[\w_]+=(?:\w+|(['""]).*?\1)", regexref=1);
		var result = {};
		var i = 0;
		var key = "";
		var value = "";

		for (i=1; i<=arraylen(attrs); i++){
			key = trim(listfirst(attrs[i],"="));
			value = listdeleteat(attrs[i],1,"=");

			if (refindnocase("^[""'].*[""']$",value))
				result[key] = mid(value,2,len(value)-2);
			else
				result[key] = value;
		}

		return result;
	}

	public struct function processComment( required string text, escapeCode=true ){
		var stResult = structnew();
		var thismap = "";
		var varName = "";
		var varVal = "";
		var aCode = arraynew(1);
		var k = 0;
		
		// Comment variables
		if (find("@@",arguments.text)){
			aMatches = scrapeAll(source=arguments.text, regex="@@[\w\d]+:(.*?)(?:@@|--->)", regexref=1);
			
			for (i=1; i<=arraylen(aMatches); i++){
				// Get variable name and value
				varName = scrape(source=aMatches[i],regex="@@([\w\d]+):",regexref=2);
				varVal = scrape(source=aMatches[i],regex="@@[\w\d]+:(.*?)(?:@@|--->)",regexref=2);
				
				// Find and escape <code> sections
				if (arguments.escapeCode){
					aCode = scrapeAll(source=varVal,regex="<code>(.*?)</code>",regexref=2,trim=false);
					for (k=1; k<=arraylen(aCode); k++){
						varVal = replace(varVal,aCode[k],cleanCode(code=aCode[k]));
					}
					
					// Convert to highlightable pre
					varVal = replacelist(varVal,"<code>,</code>","<pre class='brush: coldfusion'>,</pre>");
				}
				
				stResult[varName] = varVal;
			}
		}
		
		return stResult;
	}
	
	public string function cleanCode(required string code){
		var newVal = "";
		var bestWhitespace = 100;
		var thisWhitespace = 0;
		var thisline = "";
		var thischar = 0;
		var lines = [];
		var i = 0;
		
		arguments.code = replace(htmleditformat(arguments.code),chr(9),"    ","ALL");
		lines = listtoarray(arguments.code,"#chr(10)##chr(13)#");

		// remove empty lines at start and end
		while (arraylen(lines) && len(trim(lines[1])) == 0){
			arraydeleteat(lines,1);
		}
		while (arraylen(lines) && len(trim(lines[arraylen(lines)])) == 0){
			arraydeleteat(lines,arraylen(lines));
		}
		
		// find the common indent of the code
		for (i=1; i<=arraylen(lines); i++){
			thisline = lines[i];

			if (len(trim(thisline))){
				thisWhitespace = len(rereplace(thisline,"^(\s+).*","\1"));
				bestWhitespace = min(thisWhitespace,bestWhitespace);
			}
		}

		// fix redundant indenting
		for (i=1; i<=arraylen(lines); i++){
			lines[i] = rereplace(lines[i],"^#repeatstring(" ",bestWhitespace)#","");
		}

		return arraytolist(lines,variables.newline);
	}
	

	public any function scrape( required string source, string regex, string regexref, string open, any close, string default, boolean trim=false){
		var start = 0; // Position of start of matched string
		var end = 0; // Position of end of matched string
		var temppos = 0; // Temporary position variable
		var i = 0; // Iterator
		var stResult = structnew(); // Regex match result
		var thisregexref = ""; // Loop variable for arguments.regexref
		var aReturn = arraynew(1); // Returnable result
		var pattern = ""; // Java regex pattern
		var matcher = ""; // Java regex matcher
		
		if (structkeyexists(arguments,"open") and len(arguments.open) and structkeyexists(arguments,"close")){ 
			// Open and closing strings
			
			start = findnocase(arguments.open,arguments.source);
			if (start){
				if (isarray(arguments.close)){
				
					for (i=1; i<=arraylen(arguments.close); i++){
						temppos = find(arguments.close[i],arguments.source,start+len(arguments.open)) - 1;
						
						if (temppos lt end or end lte 0){
							end = temppos;
						}
					}
					
				}
				else {
					
					end = find(arguments.close,arguments.source,start+len(arguments.open)) - 1;
					
				}
				
				if (end lte 0){
					end = len(arguments.source);
				}
				
				if (arguments.trim){
					return trim(mid(arguments.source,start+len(arguments.open),end-start-len(arguments.open)));
				}
				else{
					return mid(arguments.source,start+len(arguments.open),end-start-len(arguments.open));
				}
			}

		}
		elseif (structkeyexists(arguments,"regex") and len(arguments.regex)){
			// Regex
			
			stResult = refindnocase(arguments.regex,arguments.source,1,true);
			for (i=1; i<=listlen(arguments.regexref); i++){
				thisregexref = listgetat(arguments.regexref,i);

				if (arraylen(stResult.pos) gte thisregexref and stResult.pos[1]){
					if (arguments.trim){
						arrayappend(aReturn,trim(mid(arguments.source,stResult.pos[thisregexref],stResult.len[thisregexref])));
					}
					else {
						arrayappend(aReturn,mid(arguments.source,stResult.pos[thisregexref],stResult.len[thisregexref]));
					}
				}
			}
			
			if (listlen(arguments.regexref) eq 1 and arraylen(aReturn)){
				return aReturn[1];
			}
			elseif (arraylen(aReturn)){
				return aReturn;
			}
			
		}
		
		return arguments.default;
	}

	public array function scrapeAll(required string source, string regex, numeric regexref, string open, any close, boolean trim=true){
		var start = -1; // Position of start of matched string
		var end = 0; // Position of end of matched string
		var temppos = 0; // Temporary position variable
		var i = 0; // Iterator
		var stResult = structnew(); // Regex match result
		var aResult = arraynew(1); // The resulting array of matching strings
		
		if (structkeyexists(arguments,"open") and len(arguments.open) and structkeyexists(arguments,"close")){
			// Open and closing strings
			
			while (start eq -1 or start gt 0){
			
				if (start gt 0){
					start = findnocase(arguments.open,arguments.source,start);
				}
				else{
					start = findnocase(arguments.open,arguments.source);
				}
				
				if (start gt 0){
					if (isarray(arguments.close)){
					
						for (i=1; i<=arraylen(arguments.close); i++){
							temppos = find(arguments.close[i],arguments.source,start+len(arguments.open)) - 1;
							
							if (temppos lt end or end lte 0){
								end = temppos;
							}
						}
						
					}
					else{
						
						end = find(arguments.close,arguments.source,start+len(arguments.open)) - 1;
						
					}
					
					if (end lte 0){
						end = len(arguments.source);
					}
					
					start = end;
					
					if (arguments.trim){
						arrayappend(aResult,trim(mid(arguments.source,start+len(arguments.open),end-start-len(arguments.open))));
					}
					else{
						arrayappend(aResult,mid(arguments.source,start+len(arguments.open),end-start-len(arguments.open)));
					}
				}
				else{
				
					break;
					
				}
			
			}
		
		}
		elseif (structkeyexists(arguments,"regex") and len(arguments.regex)){
			// Regex
		
			while (structisempty(stResult) or stResult.pos[1]){
				
				if (structisempty(stResult)){
					stResult = refindnocase(arguments.regex,arguments.source,1,true);
				}
				else{
					stResult = refindnocase(arguments.regex,arguments.source,stResult.pos[arguments.regexref]+1,true);
				}
				
				if (arraylen(stResult.pos) gte arguments.regexref and stResult.pos[1]){
					if (arguments.trim){
						arrayappend(aResult,trim(mid(arguments.source,stResult.pos[arguments.regexref],stResult.len[arguments.regexref])));
					}
					else{
						arrayappend(aResult,mid(arguments.source,stResult.pos[arguments.regexref],stResult.len[arguments.regexref]));
					}
				}
				
			}
		
		}
		
		return aResult;
	}

}