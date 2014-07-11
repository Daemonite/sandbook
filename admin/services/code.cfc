component {
	
	public any function init( fw ){
		variables.fw = arguments.fw;

		return this;
	}


	public struct function parseDirectory( required string codedir, required struct config, string filepath="", array interestingFiles=[] ){
		var directories = [];
		var children = directorylist( path=arguments.codedir & arguments.filepath, listInfo="query" );
		var i = 0;
		var cfhttp = {};
		var processors = [];
		var result = {};

		for (i=1; i<=children.recordcount; i++){
			if (children.type[i] == "dir"){
				parseDirectory( arguments.codedir, arguments.config, filepath & "/" & children.name[i], arguments.interestingFiles );
			}
			else{
				processors = getProcessors( arguments.config, arguments.filepath & '/' & children.name[i] );

				if (arraylen(processors)){
					arrayappend(arguments.interestingFiles, arguments.filepath & '/' & children.name[i]);
				}
			}
		}

		if (arguments.filepath == ""){
			for (i=1; i<=arraylen(arguments.interestingFiles); i++){
				application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "#round(i/arraylen(arguments.interestingFiles)*100)#% parsing #arguments.interestingFiles[i]#");
	        	http url="http://#cgi.http_host##variables.fw.buildURL(action='processing.process',queryString=session.URLToken)#" method="POST" {
					httpparam type="formField" name="codedir" value="#arguments.codedir#";
					httpparam type="formField" name="config" value="#serializeJSON(arguments.config)#";
					httpparam type="formField" name="filepath" value="#arguments.interestingFiles[i]#";
					httpparam type="header" name="Accept" value="application/json";
				}
				if (cfhttp.statuscode != "200 OK" || !isJSON(cfhttp.filecontent.toString()))
					throw(message="Error processing file: #cfhttp.statuscode#",detail=cfhttp.filecontent.toString());
				result[arguments.interestingFiles[i]] = deserializeJSON(cfhttp.filecontent.toString());
			}
		}

		return result;
	}

	public array function getProcessors( required struct config, required string filepath ){
		var i = 0;
		var processors = [];
		var allprocessors = listtoarray(structkeylist(arguments.config));
		var thistype = "";

		for (i=1; i<=arraylen(allprocessors); i++){
			thistype = allprocessors[i];
			match = false;

			for (j=1; j<=arraylen(arguments.config[thistype].filter) && !match; j++){
				match = match || refindnocase(arguments.config[thistype].filter[j], arguments.filepath) > 0;
			}

			if (match){
				arrayappend(processors,thistype);
			}
		}

		return processors;
	}

	public struct function parseFile( required string codedir, required struct config, required string filepath="" ){
		var i = "";
		var parsetypes = getProcessors(argumentCollection=arguments);
		var thistype = "";
		var output = structnew();
		var text = fileread( arguments.codedir & arguments.filepath );

		for (i=1; i<=arraylen(parsetypes); i++){
			thistype = parsetypes[i];

			output[thistype] = application.services[arguments.config[thistype].service][arguments.config[thistype].method](
				arguments.config[thistype],
				arguments.filepath,
				text
			);
		}

		return output;
	}



	public struct function compileResults( required struct data, required struct config ){
		var results = {
			"children" : {},
			"links" : {}
		};
		var i = 0;
		var k = "";
		var processorConfig = {};
		var processors = [];
		var processed = "";
		var datasets = [];

		for (k in arguments.config){
			datasets = [];
			processorConfig = arguments.config[k];

			for (i in arguments.data){
				if (listfind(arraytolist(getProcessors(arguments.config,i)),k))
					arrayappend(datasets,arguments.data[i]);
			}

			application.services[processorConfig.service][processorConfig.method]( results, processorConfig, datasets );
		}

		return results;
	}

	public struct function compileOutput( required struct repo, required struct data, required struct config, required string processdir ){
		var outputfiles = {};
		var outputdir = "";
		var writeConfig = {};
		var k = "";

		for (k in arguments.config){
			writeConfig = arguments.config[k];

			if (directoryexists(arguments.processdir & "/" & k))
				outputdir = arguments.processdir & "/" & k & "_output";
			else
				outputdir = arguments.processdir & "/" & k;

			directoryCreate(outputdir);

			outputfiles[k] = application.services[writeConfig.service][writeConfig.method]( arguments.repo, arguments.data, writeConfig, outputdir );
			copyStatic( arguments.config[k], outputdir, k );
		}

		return outputfiles;
	}

	public void function copyStatic( required struct config, required string processdir, required string outputkey ){
		if (!structkeyexists(arguments.config,"staticfiles") || !structcount(arguments.config.staticfiles))
			return;

		var aFiles = [];
		var k = "";
		var i = 0;
		var sourcePath = "";
		var targetPath = "";

		for (k in arguments.config.staticfiles){
			sourcePath = expandpath(arguments.config.staticfiles[k]);
			targetPath = arguments.processdir & k;
			aFiles = directoryList(sourcePath,true);

			for (i=1; i<=arraylen(aFiles); i++){
				if (refind("\.\w+$",aFiles[i])){
					application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "#round(i/arraylen(aFiles)*100)#% copying #k##aFiles[i]# to #arguments.outputkey#");
	
					if (!directoryexists(getDirectoryFromPath(replace(aFiles[i],sourcePath,targetPath))))
						directoryCreate(getDirectoryFromPath(replace(aFiles[i],sourcePath,targetPath)));
	
					fileCopy(aFiles[i],replace(aFiles[i],sourcePath,targetPath));
				}
			}
		}
	}

	public struct function uploadOutputs( required struct config, required string basePath, required struct s3bucket, required struct outputfiles ){
		var k = "";
		var outputconfig = "";
		var sourcePath = "";
		var targetPath = "";
		var aFiles = "";
		var i = 0;
		var outputurls = {};

		for (k in arguments.outputfiles){
			outputconfig = arguments.config[k];
			sourcePath = arguments.outputfiles[k];
			targetPath = arguments.basePath & outputconfig.targetPath;

			if (directoryExists(sourcePath)){
				aFiles = directoryList(sourcePath,true);

				for (i=1; i<=arraylen(aFiles); i++){
					if (fileexists(aFiles[i])){
						application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "#round(i/arraylen(aFiles)*100)#% uploading #replace(aFiles[i], sourcePath, '')# for #k#");
						application.services["admin.services.s3"].putFile( arguments.s3bucket, targetPath & replace(aFiles[i], sourcePath, "/"), aFiles[i] );
					}
				}

				outputurls[k] = targetPath;
			}
		}

		return outputurls;
	}

}