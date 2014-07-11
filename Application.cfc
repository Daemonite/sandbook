component extends="org.corfield.framework" {

	this.Name = "autodoc";
	this.SessionManagement = true;

	variables.framework = {
		usingSubsystems : true,
		defaultSubsystem : 'admin',
		siteWideLayoutSubsystem : 'admin'
	}

	// UPDATE variables as needed for your project
	// Sandbook sample config defaults to looking at its environment for secure variables
	// eg. <cfdump var="#CreateObject("java", "java.lang.System").getProperties()#" />
	stProps = CreateObject("java", "java.lang.System").getProperties();

	variables.config = {
		"security" : {
			"google" : {
				"client_id" : stprops['google_client_id'],
				"client_secret" : stprops['google_client_secret'],
				"allow" : [
					"#stprops['google_allow']#"
				]
			},
			"local" : {
				"users" : [{
					"username" : "admin",
					"password" : stprops['local_users_admin']
				}]
			},
			"services" : [
				"local",
				"google"
			],
			"publicactions" : [
				"^admin:processing.process$" 
			]
		},
		"repos" : {
			"farcrycore" : {
				"label" : "FarCry Core",
				"host" : "github",
				"owner" : "farcrycore",
				"repo" : "core",
				"username" : stprops['farcrycore_username'],
				"access_token" : stprops['farcrycore_access_token'],
				"local_repo_cache" : "../localrepos/core",
				"s3bucket" : "$s3.core",
				"blacklist" : [
					"^refs/heads/justin/esapi$",
					"^refs/heads/p4.*$",
					"^refs/heads/p5.*$",
					"^refs/tags/milestone-4-.*$",
					"^refs/tags/milestone-5-.*$"
				],
				"parsing" : "$parseconfig",
				"compilation" : "$compileconfig",
				"output" : "$writeconfig"
			}
		},
		"s3" : {
			"core" : {
				"bucket" : stProps['s3_core_bucket'],
				"user" : stProps['s3_core_user'],
				"accessKeyId" : stProps['s3_core_accessKeyId'],
				"awsSecretKey" : stProps['s3_core_awsSecretKey'],
				"region" : stProps['s3_core_region'],
				"security" : "public",
				"publicURL" : "http://docs.farcrycore.org",
				"compilation" : {
					"index" : {
						"filter" : [ "^index.json$" ],
						"service" : "admin.services.markdown",
						"method" : "compileS3Index",
						"defaults" : {
							"indextitle" : "FarCry Reference",
							"title" : "FarCry Reference",
							"body" : [],
							"footer" : [{
								"type" : "html",
								"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
							}]
						}
					}
				},
				"output" : {
					"html" : {
						"service" : "admin.services.html",
						"method" : "writeHTML",
						"templates" = {
							"^$" : "/admin/views/doc/home.cfm",
						},
						"staticfiles" = {
							"/css" = "/admin/views/doc/staticfiles/css",
							"/js" = "/admin/views/doc/staticfiles/js"
						},
						"targetPath" = ""
					}
				}
			}
		},
		"machinename" : createObject("java", "java.net.InetAddress").localhost.getHostName(),
		"db" : "$dbs.[#createObject("java", "java.net.InetAddress").localhost.getHostName()#]",
		"debug" : "$debugs.[#createObject("java", "java.net.InetAddress").localhost.getHostName()#]",
		"nav" : [{
			"label" : "Home",
			"action" : "admin:main.default"
		},{
			"label" : "Tasks",
			"action" : "tasks:main.list",
			"children" : [{
				"label" : "Current Tasks",
				"action" : "tasks:main.list"
			},{
				"label" : "Add Task",
				"action" : "tasks:main.add"
			}]
		}],
		"jars" : [
			"/admin/java/org.eclipse.jgit.jar",
			"/admin/java/jsch-0.1.51.jar",
			"/admin/java/markdownj-0.3.0-1.0.2b4.jar"
		],

		"dbs" : {
			"Hobo" : "local",
			"*" : "cloudbees"
		},
		"debugs" : {
			"Hobo" : true,
			"*" : false
		},
		"parseconfig" : {
			"cfc" : {
				"filter" : [
					"\.cfc$"
				],
				"service" : "admin.services.cfml",
				"method" : "processCFC"
			},
			"tag" : {
				"filter" : [
					"^/tags/[^\/]+/[^\/]+\.cfm$"
				],
				"service" : "admin.services.cfml",
				"method" : "processTag"
			}
		},
		"compileconfig" : {
			"index" : {
				"filter" : [ "^/README.md$" ],
				"service" : "admin.services.markdown",
				"method" : "compileIndex",
				"defaults" : {
					"title" : "",
					"body" : [
						{ "type" : "html", "content" : "<div class='row'><div class='span3'><h2>What is this?</h2></div><div class='span9'><div class='main-content'>" },
						{
							"type" : "markdown",
							"content" : 
"This is the output from the automatic build of the API documentation for FarCry - the web framework FarCry not the video game FarCry. Here you will find documentation for all the custom tags, components, and ContentTypes in FarCry core and in FarCry CMS.

------

###### Please, tell me more

Ok, glad you asked. I dig your enthusiasm. You can talk to the developers at [http://discourse.farcrycore.org](http://discourse.farcrycore.org)

------

###### How can I help?

You can read how to decorate your code so that the documentation parser can find your in line help by reading the [auto documentation][https://farcry.jira.com/wiki/display/FCCORE/Auto-Documentation] section on the wiki. You can then dig into the FarCry code and write comments or examples to move this whole process along."
						},
						{ "type" : "html", "content" : "</div></div></div>"}
					],
					"footer" : [{
						"type" : "html",
						"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
					}]
				}
			},
			"library" : {
				"filter" : [
					"^/packages/lib/[^\/]+\.cfc$"
				],
				"service" : "admin.services.farcry",
				"method" : "compileLibraries",
				"defaults" : {
					"title" : "Libraries",
					"footer" : [{
						"type" : "html",
						"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
					}]
				},
				"libdefaults" : {
					"footer" : [{
						"type" : "html",
						"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
					}]
				}
			},
			"tags" : {
				"filter" : [
					"^/tags/[^\/]+/[^\/]+\.cfm$"
				],
				"service" : "admin.services.farcry",
				"method" : "compileTagLibraries",
				"defaults" : {
					"title" : "Tags",
					"footer" : [{
						"type" : "html",
						"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
					}]
				},
				"libdefaults" : {
					"footer" : [{
						"type" : "html",
						"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
					}]
				}
			},
			"formtools" : {
				"filter" : [
					"^/packages/formtools/[^\/]+\.cfc$"
				],
				"service" : "admin.services.farcry",
				"method" : "compileFormtools",
				"defaults" : {
					"title" : "Formtools",
					"footer" : [{
						"type" : "html",
						"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
					}]
				},
				"libdefaults" : {
					"footer" : [{
						"type" : "html",
						"content" : "<p>FarCry Core - <small><a href='http://www.farcrycore.org/'>Main Site</a></small></p>"
					}]
				}
			}
		},
		"writeconfig" : {
			"online" : {
				"service" : "admin.services.html",
				"method" : "writeHTML",
				"templates" = {
					"^$" : "/admin/views/doc/home.cfm",
					"." : "/admin/views/doc/page.cfm" 
				},
				"staticfiles" = {
					"/css" = "/admin/views/doc/staticfiles/css",
					"/js" = "/admin/views/doc/staticfiles/js"
				},
				"parameters" = {},
				"targetPath" = "",
				"label" = "Online Docs",
				"icon" = "icon-globe"
			}
		}
	};
	resolveADConfig();

	public any function getADConfig(required string key, any default){
		var val = variables.config;
		var keys = listtoarray(arguments.key,".");
		var thiskey = "";
		var i = 0;

		for (i=1; i<=arraylen(keys); i++){
			if (left(keys[i],1) == "["){
				thiskey = mid(keys[i],2,len(keys[i]));
				while (right(keys[i],1) != "]"){
					i = i + 1;
					thiskey = thiskey & keys[i];
				}
				thiskey = left(thiskey,len(thiskey)-1);
			}
			else{
				thiskey = keys[i];
			}

			if (structkeyexists(val,thiskey))
				val = val[thiskey];
			else if (structkeyexists(val,"*"))
				val = val["*"];
			else if (structkeyexists(arguments,"default"))
				return arguments.default;
			else
				throw(message="Key '#thiskey#' in '#arguments.key#' not found");
		}

		return val;
	}

	public struct function resolveADConfig( struct config=variables.config ){
		var k = "";

		for (k in arguments.config){
			if (issimplevalue(arguments.config[k]) && left(arguments.config[k],1) == "$"){
				arguments.config[k] = getADConfig(mid(arguments.config[k],2,len(arguments.config[k])));
			}
			if (isstruct(arguments.config[k]))
				resolveADConfig( arguments.config[k] );
		}

		if (structkeyexists(arguments.config,"repos")){
			for (k in arguments.config.repos){
				arguments.config.repos[k].name = k;
				if (!structkeyexists(arguments.config.repos[k],"basePath")){
					arguments.config.repos[k]["basePath"] = "/" & k;
				}
			}
		}

		return arguments.config;
	}

	public void function setupRequest() {
		request.context.headers = GetHttpRequestData().headers;

		request.context.accepts = "html";
		if (structkeyexists(request.context.headers,"accept")){
			var accepts = listtoarray(replace(request.context.headers.accept,", ",",","ALL"));

			for (var i=1; i<=arraylen(accepts); i++){
				if (listfindnocase("application/json,text/javascript",accepts[i])){
					request.context.accepts = "json";
					break;
				}
				else if (listfindnocase("text/xml",accepts[i])){
					request.context.accepts = "xml";
					break;
				}
				else if (listfindnocase("text/plain",accepts[i])){
					request.context.accepts = "text";
					break;
				}
				else if (listfindnocase("text/html",accepts[i])){
					request.context.accepts = "html";
					break;
				}
			}
		}

		controller( 'security:main.checkSecurity' );
	}

	public void function onApplicationStart(){
		super.onApplicationStart(argumentCollection=arguments);

		//schedule action="update" 
		//         task="autodoc_queue" 
		//         startdate="#now()#"
		//         starttime="#now()#" 
		//         interval="60" 
		//         url="http://#cgi.http_host##buildURL('tasks:main.kick')#";

		// initialize services
		application.fw = this;
		application.services = {
			"tasks.services.queue" = createobject("component","tasks.services.queue").init(this),
			"tasks.services.test" = createobject("component","tasks.services.test").init(this),
			"admin.services.repo" = createobject("component","admin.services.repo").init(this),
			"admin.services.s3" = createobject("component","admin.services.s3").init(this),
			"admin.services.java" = createobject("component","admin.services.java").init(this),
			"admin.services.code" = createobject("component","admin.services.code").init(this),
			"admin.services.cfml" = createobject("component","admin.services.cfml").init(this),
			"admin.services.farcry" = createobject("component","admin.services.farcry").init(this),
			"admin.services.markdown" = createobject("component","admin.services.markdown").init(this),
			"admin.services.html" = createobject("component","admin.services.html").init(this)
		};
	}

	public void function before( struct rc ){
		arguments.rc.nav = getADConfig("nav",[]);
	}

}