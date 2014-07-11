component {
	
    public any function init(fw){
        variables.fw = arguments.fw;

        return this;
    }

    public array function getRepoList( repos ) {
        var repolist = [];
        var repohash = {};
        var thisrepo = {};
        var k = "";

        for (k in arguments.repos){
            thisrepo = arguments.repos[k];
        	arrayappend(repolist,thisrepo.label);
        	repohash[thisrepo.label] = duplicate(thisrepo);
            repohash[thisrepo.label]["key"] = k;
        	repohash[thisrepo.label]["links"] = {};
            repohash[thisrepo.label]["links"]["detail"] = variables.fw.buildURL(action="repo.detail",queryString="id=#k#");
            repohash[thisrepo.label]["links"]["status"] = variables.fw.buildURL(action="repo.status",queryString="id=#k#");
            repohash[thisrepo.label]["links"]["setuprepo"] = variables.fw.buildURL(action="repo.setuprepo",queryString="id=#k#");
            switch (thisrepo.host){
                case "github":
                    repohash[thisrepo.label]["links"]["pushhook"] = "http://" & cgi.http_host & variables.fw.buildURL(action="repo.webhookGithubPush",queryString="id=#k#");
                    break;
            }
        }
        
        arraysort(repolist,"text");

        for (var i=1; i<=arraylen(repolist); i++)
        	repolist[i] = repohash[repolist[i]];

        return repolist;
    }

    public boolean function isVisible( required struct repo, required string ref ){

    	if (refindnocase("^refs/pull/.*$",arguments.ref)){
    		return false;
    	}

    	if (structkeyexists(arguments.repo,"whitelist")){
    		for (var i=1; i<=arraylen(arguments.repo.whitelist); i++){
    			if (refindnocase(arguments.repo.whitelist[i],arguments.ref))
    				return true;
    		}
    	}

        if (structkeyexists(arguments.repo,"blacklist")){
    		for (var i=1; i<=arraylen(arguments.repo.blacklist); i++){
    			if (refindnocase(arguments.repo.blacklist[i],arguments.ref))
    				return false;
    		}
        }

		return true;
    }

    public array function getReferences( required struct repo ){
    	var cfhttp = {};
    	var data = [];
    	var result = [];

    	if (!structkeyexists(arguments.repo,"owner") || !structkeyexists(arguments.repo,"repo") || !structkeyexists(arguments.repo,"access_token"))
    		throw(type="repo",message="Missing access details for repo [#arguments.repo.repo#]");
        
        switch (arguments.repo.host){
            case "github":
            	http url="https://api.github.com/repos/#arguments.repo.owner#/#arguments.repo.repo#/git/refs" {
            		httpparam type="header" name="Accept" value="application/vnd.github.v3+json";
            		httpparam type="header" name="Authorization" value="token #arguments.repo.access_token#";
            	}

            	data = deserializeJSON(cfhttp.filecontent.toString());

                if (isStruct(data) AND structKeyExists(data, "message")) {
                    throw(type="repo",message="#data.message# [#arguments.repo.repo#]", detail=cfhttp.filecontent);                    
                }

            	for (var i=1; i<=arraylen(data); i++){
            		if (isVisible(arguments.repo,data[i].ref)){
            			if (refindnocase("^refs/heads/.*$",data[i].ref))
            				data[i]["type"] = "branch";
            			else if (refindnocase("^refs/tags/.*$",data[i].ref))
            				data[i]["type"] = "tag";
            			data[i]["name"] = listlast(data[i].ref,"/");
                        data[i]["key"] = data[i].ref;
                        data[i]["links"] = {};
                        data[i]["links"]["ignorereporef"] = variables.fw.buildURL(action="repo.ignoreRepoRef",queryString="id=#arguments.repo.name#&ref=#data[i].ref#");
                        data[i]["links"]["unignorereporef"] = variables.fw.buildURL(action="repo.unignoreRepoRef",queryString="id=#arguments.repo.name#&ref=#data[i].ref#");
                        data[i]["links"]["processreporef"] = variables.fw.buildURL(action="repo.processRepoRef",queryString="id=#arguments.repo.name#&ref=#data[i].ref#");
                        
            			arrayappend(result,data[i]);
            		}
            	}
                break;
        }

    	return result;
    }

    public struct function getRepoStatus( required struct repo ){
    	var stResult = {};
    	var s3index = getBucketIndex(arguments.repo.s3bucket);
        var references = getReferences( repo );
        var repoindex = { "refs" : {} };
        var i = "";
        var k = "";

    	if (structkeyexists(s3index,arguments.repo.name)){
	    	stResult = { 
                "status"="success", 
                "status_message"="Up to date", 
                "refs"=references,
                "actions"=[]
            };
            if (structkeyexists(s3index,arguments.repo.name));
                repoindex = s3index[arguments.repo.name];

	    	for (i=1; i<=arraylen(stResult["refs"]); i++){
                if (structkeyexists(repoindex.refs,stResult["refs"][i].ref) && structkeyexists(repoindex.refs[stResult["refs"][i].ref],"ignore")){
                    stResult["refs"][i]["status"] = "info";
                    stResult["refs"][i]["status_message"] = "Ignored";
                    stResult["refs"][i]["actions"] = [];

                    arrayappend(stResult["refs"][i]["actions"],{
                        "key"="unignorereporef",
                        "icon"="fa fa-eye",
                        "title"="Unignore",
                        "link"="unignorereporef"
                    });
                }
	    		else if (structkeyexists(repoindex.refs,stResult["refs"][i].ref) && repoindex.refs[stResult["refs"][i].ref].commit == stResult["refs"][i].object.sha){
	    			stResult["refs"][i]["status"] = "success";
                    stResult["refs"][i]["status_message"] = "Up to date";
                    stResult["refs"][i]["actions"] = [];

                    arrayappend(stResult["refs"][i]["actions"],{
                        "key"="processreporef",
                        "icon"="fa fa-bolt",
                        "title"="Process",
                        "link"="processreporef"
                    });
                    for (k in repoindex.refs[stResult["refs"][i].ref].outputs){
                        stResult["refs"][i]["links"]["output_#k#"] = arguments.repo.s3bucket.publicURL & repoindex.refs[stResult["refs"][i].ref].outputs[k].path;
                        arrayappend(stResult["refs"][i]["actions"],{
                            "key"=k,
                            "icon"="fa fa-link",
                            "title"=repoindex.refs[stResult["refs"][i].ref].outputs[k].title,
                            "link"="output_#k#",
                            "type"="normal"
                        });
                    }
	    		}
	    		else if (structkeyexists(repoindex.refs,references[i].ref)){
	    			stResult["status"] = "warning";
	    			stResult["status_message"] = "Exists, but not up to date";
                    stResult["refs"][i]["status"] = "warning";
                    stResult["refs"][i]["status_message"] = "Exists, but not up to date";
                    stResult["refs"][i]["actions"] = [];

                    arrayappend(stResult["refs"][i]["actions"],{
                        "key"="processreporef",
                        "icon"="fa fa-bolt",
                        "title"="Process",
                        "link"="processreporef"
                    });
                    for (k in repoindex.refs[stResult["refs"][i].ref].outputs){
                        stResult["refs"][i]["links"]["output_#k#"] = arguments.repo.s3bucket.publicURL & repoindex.refs[stResult["refs"][i].ref].outputs[k].path;
                        arrayappend(stResult["refs"][i]["actions"],{
                            "key"=k,
                            "icon"="fa fa-link",
                            "title"=repoindex.refs[stResult["refs"][i].ref].outputs[k].title,
                            "link"="output_#k#",
                            "type"="normal"
                        });
                    }
	    		}
	    		else{
	    			stResult["status"] = "warning";
	    			stResult["status_message"] = "Exists, but not up to date";
                    stResult["refs"][i]["status"] = "danger";
                    stResult["refs"][i]["status_message"] = "Not created";
                    stResult["refs"][i]["actions"] = [];

                    arrayappend(stResult["refs"][i]["actions"],{
                        "key"="ignorereporef",
                        "icon"="fa fa-eye-slash",
                        "title"="Ignore",
                        "link"="ignorereporef"
                    });
                    arrayappend(stResult["refs"][i]["actions"],{
                        "key"="processreporef",
                        "icon"="fa fa-bolt",
                        "title"="Process",
                        "link"="processreporef"
                    });
	    		}
	    	}
	    }
	    else{
	    	stResult = { "status"="danger", "status_message"="Not created", "refs"=[], "actions"=[] };
	    }

        arrayappend(stResult["actions"],{
            "key"="refreshstatus",
            "icon"="fa fa-refresh",
            "title"="Refresh",
            "link"="status"
        });

        switch (stResult["status_message"]) {
            case "Not created":
                arrayappend(stResult["actions"],{
                    "key"="setuprepo",
                    "icon"="fa fa-plus",
                    "title"="Create",
                    "link"="setuprepo"
                });
                break;
        }

	    return stResult;
    }

    public void function isRepoRefIgnored( required struct repo, required string ref ){
        var s3index = getBucketIndex(arguments.repo.s3bucket);
        
        if (structkeyexists(s3index,arguments.repo.name) && 
            structkeyexists(s3index[arguments.repo.name],"refs") && 
            structkeyexists(s3index[arguments.repo.name].refs,arguments.ref) &&
            structkeyexists(s3index[arguments.repo.name].refs[arguments.ref],"ignore"))

            return s3index[arguments.repo.name].refs[arguments.ref].ignore;

        return false;
    }

    public void function ignoreRepoRef( required struct repo, required string ref ){
        // bucket index
        updateBucketIndex( repo=arguments.repo, ref=arguments.ref, ignore=true );
    }

    public void function unignoreRepoRef( required struct repo, required string ref ){
        // bucket index
        updateBucketIndex( repo=arguments.repo, ref=arguments.ref, ignore=false );
    }

    public void function processRepoRef( required struct repo, required string ref, boolean debug=false ){
        var processdir = getTempDirectory() & createuuid();
        var repodir = "";
        var parseResults = {};
        var compileResults = {};
        var outputfiles = {};
        var outputurls = {};
        var s3data = {};
        var s3compile = {};
        var s3files = {};
        var s3urls = {};
        var k = "";

        // repo docs
        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "cloning repository");
        repodir = cloneRepo(arguments.repo, arguments.ref, processdir);

        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "parsing files");
        parseResults = application.services["admin.services.code"].parseDirectory( repodir.path, arguments.repo.parsing );
        fileWrite(processdir & "/01_parsedata.json",serializeJSON(parseResults));

        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "compiling information");
        compileResults = application.services["admin.services.code"].compileResults( parseResults, arguments.repo.compilation );
        compileResults["indextitle"] = arguments.repo.label & " - " & listlast(arguments.ref,"/");
        fileWrite(processdir & "/02_compilation.json",serializeJSON(compileResults));

        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "writing html");
        outputfiles = application.services["admin.services.code"].compileOutput( arguments.repo, compileResults, arguments.repo.output, processdir, arguments.ref );
        fileWrite(processdir & "/03_outputfiles.json",serializeJSON(outputfiles));

        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "uploading outputs to S3");
        outputurls = application.services["admin.services.code"].uploadOutputs( arguments.repo.output, arguments.repo.basePath & "/" & listlast(arguments.ref,'/'), arguments.repo.s3bucket, outputfiles );
        fileWrite(processdir & "/04_outputurls.json",serializeJSON(outputurls));

        // bucket index
        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "update index data");
        s3data = { "index.json" : updateBucketIndex( repo=arguments.repo, ref=arguments.ref, commit=repodir.commit, outputurls=outputurls ) };
        fileWrite(processdir & "/05_s3data.json",serializeJSON(s3data));

        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "compiling index");
        s3compile = application.services["admin.services.code"].compileResults( s3data, arguments.repo.s3bucket.compilation );
        fileWrite(processdir & "/06_s3compile.json",serializeJSON(s3compile));

        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "writing index");
        s3files = application.services["admin.services.code"].compileOutput( {}, s3compile, arguments.repo.s3bucket.output, processdir, "" );
        fileWrite(processdir & "/07_s3files.json",serializeJSON(s3files));

        application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "uploading index to S3");
        s3urls = application.services["admin.services.code"].uploadOutputs( arguments.repo.s3bucket.output, "", arguments.repo.s3bucket, s3files );
        fileWrite(processdir & "/08_s3urls.json",serializeJSON(s3urls));

        if (!arguments.debug){
            // clear temporary files
            application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "removing clone");
            directorydelete(processdir,true);
        }
    }

    public struct function updateBucketIndex( required struct repo, required string ref, string commit, struct outputurls, boolean ignore ){
        var s3index = getBucketIndex(arguments.repo.s3bucket);
        var k = "";

        if (!structkeyexists(s3index,arguments.repo.name)){
            s3index[arguments.repo.name] = { "refs" = {} };
        }

        s3index["lastupdated"] = now();
        s3index[arguments.repo.name]["title"] = arguments.repo.label;
        s3index[arguments.repo.name]["lastupdated"] = now();

        if (structkeyexists(arguments,"ignore") && arguments.ignore){
            s3index[arguments.repo.name].refs[arguments.ref] = {
                "ignore" = true
            }
        }
        elseif (structkeyexists(arguments,"ignore") && !arguments.ignore){
            if (structkeyexists(s3index[arguments.repo.name].refs,arguments.ref)){
                structdelete(s3index[arguments.repo.name].refs,arguments.ref);
            }
        }
        else{
            s3index[arguments.repo.name].refs[arguments.ref] = {
                "title" = listlast(arguments.ref,"/"),
                "commit" = arguments.commit,
                "lastupdated" = now(),
                "outputs" = {}
            };
            switch (arguments.repo.host){
                case "github":
                    s3index[arguments.repo.name].refs[arguments.ref]["commit_url"] = "https://github.com/#arguments.repo.owner#/#arguments.repo.repo#/commit/#arguments.commit#"
            }
            for (k in arguments.outputurls){
                s3index[arguments.repo.name].refs[arguments.ref].outputs[k] = {
                    "title" = arguments.repo.output[k].label,
                    "icon" = arguments.repo.output[k].icon,
                    "path" = arguments.outputurls[k]
                };
            }
        }

        putBucketIndex(arguments.repo.s3bucket,s3index);

        return s3index;
    }

    public struct function cloneRepo( required struct repo, required string ref, required string processdir ){
        var Git = application.services["admin.services.java"].loadClass("org.eclipse.jgit.api.Git");
        var tmpdir = arguments.processdir & "/repo";
        var remoteURL = "";
        var FileRepositoryBuilder = application.services["admin.services.java"].loadClass("org.eclipse.jgit.storage.file.FileRepositoryBuilder");
        var SetupUpstreamMode = application.services["admin.services.java"].loadClass("org.eclipse.jgit.api.CreateBranchCommand$SetupUpstreamMode");
        var builder = FileRepositoryBuilder.init();
        var repository = "";
        var tmpdirFile = createobject("java","java.io.File").init(tmpdir);
        var thisgit = "";

        if (structkeyexists(arguments.repo,"local_repo_cache") && directoryExists(expandPath(arguments.repo.local_repo_cache))){
            remoteURL = expandPath(arguments.repo.local_repo_cache);
        }
        else{
            switch (arguments.repo.host){
                case "github":
                    remoteURL = "https://#arguments.repo.username#:#arguments.repo.access_token#@github.com/#arguments.repo.owner#/#arguments.repo.repo#.git"
            }
        }

        directorycreate(tmpdir);

        // clone repository locally
        repository = Git.cloneRepository()
            .setURI(remoteURL)
            .setDirectory(tmpdirFile)
            .call();
        //thisgit = Git.init(repository);

        // checkout requested reference
        repository.branchCreate().setName(listlast(arguments.ref,"/")).setUpstreamMode(SetupUpstreamMode.SET_UPSTREAM).setStartPoint("origin/"&listlast(arguments.ref,"/")).setForce(true).call();
        
        repository.close();

        return {
            "path" : tmpdir,
            "commit" : rereplace(repository.getRepository().getRef(listlast(arguments.ref,"/")).getObjectId().toString(),"^[^\[]+\[([^\]]+)\]$","\1")
        };
    }

    public void function setupRepo( required struct repo ){
        var stResult = {};
        var s3bucket = repo.s3bucket;
        var s3index = getBucketIndex(s3bucket);

        s3index[arguments.repo.name] = {
            "lastupdated" : int(getTickCount() / 1000),
            "refs" : {}
        };
        putBucketIndex(s3bucket,s3index);
    }



    public any function getBucketIndex( required struct s3bucket ){
        var result = structnew();

        try {
            result = deserializeJSON(application.services["admin.services.s3"].getFile(arguments.s3bucket, "/index.json"));
        }
        catch(e){
            if (findnocase("The specified key does not exist.",e.message) eq 0)
                rethrow;
        }

        return result;
    }

    public void function putBucketIndex( required struct s3bucket, required struct index ){

        application.services["admin.services.s3"].putFile(arguments.s3bucket, "/index.json", serializeJSON(arguments.index));
    }

}