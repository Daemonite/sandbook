<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title><cfoutput>#data.title#</cfoutput></title>
		<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Open+Sans:400,300,700">
		<cfoutput>
			<link rel="stylesheet" href="#data.basepath#/css/bootstrap.css">
			<link rel="stylesheet" href="#data.basepath#/css/main.css">
			<script type="text/javascript" src="#data.basepath#/js/jquery.min.js"></script>
			<script type="text/javascript" src="#data.basepath#/js/bootstrap.js"></script>
			<script type="text/javascript" src="#data.basepath#/js/prettify.js"></script>
		</cfoutput>
	</head>
	<body  class="docs" onload="prettyPrint()">
		<div class="navbar navbar-fixed-top navbar-inverse">
			<div class="navbar-inner">
				<div class="container-fluid">
					<button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					<h1 class="brand"><cfoutput><a href="home.html">#data.indextitle#</a> / <small>#data.title#</small></cfoutput></h1>
					<div class="nav-collapse collapse">
						<ul class="nav">
							<cfoutput><li><a href="#data.basepath#/index.html" class="active">Home</a></li></cfoutput>
							<cfloop from="1" to="#arraylen(data.menu)#" index="i">
								<cfoutput><li><a href="#data.menu[i].link#">#data.menu[i].title#</a></li></cfoutput>
							</cfloop>
						</ul> 
					</div> 
					<div id="google-site-search" class="nav-collapse collapse pull-right span4">
						<!--script>
							(function() {
								if (window.location.host === "docs.farcrycore.org"){
									var cx = '015935794000702335563:5nwf36h7b7e';
									var gcse = document.createElement('script'); gcse.type = 'text/javascript';
									gcse.async = true;
									gcse.src = (document.location.protocol == 'https:' ? 'https:' : 'http:') +
									'//www.google.com/cse/cse.js?cx=' + cx;
									var s = document.getElementsByTagName('script')[0];
									s.parentNode.insertBefore(gcse, s);

									function updateInputHeight(){
										var input = $("#google-site-search .gsc-input");
										if (input.size())
											input.css("height","30px");
										else
											setTimeout(updateInputHeight,200);
									}
									updateInputHeight();
								}
							})();
						</script-->
						<gcse:search></gcse:search>
					</div>
				</div> 
			</div> 
		</div> 
		<div id="main">
			<div class="container-fluid">
				<div class="main-side">
					<a class="btn btn-block main-side-toggle" data-toggle="collapse" data-target=".main-side-collapse"><i class="icon-list"></i>Tree</a>
					<div class="main-side-collapse collapse">
						<!--p class="side-header"><a href="getURL(arguments.stParam.section)"><i class="icon-folder-open"></i>getLabel("itemplural")</a></p-->
						<cfset siblings = getSiblings( data.menu, 2 ) />
						<ul>
							<cfloop from="1" to="#arraylen(siblings)#" index="i">
								<li <cfif siblings[i].active>class="active parent"</cfif>>
									<cfoutput><a href="#siblings[i].link#">#siblings[i].title#</a></li></cfoutput>
									<cfif siblings[i].active and structkeyexists(siblings[i],"children") and arraylen(siblings[i].children)>
										<ul>
											<cfloop from="1" to="#arraylen(siblings[i].children)#" index="ii">
												<cfoutput><li <cfif siblings[i].children[ii].active>class="active"</cfif>><a href="#siblings[i].children[ii].link#">#siblings[i].children[ii].title#</a></li></cfoutput>
											</cfloop>
										</ul>
									</cfif>
								</li>
							</cfloop>
						</ul>
					</div><!-- /.main-side-collapse -->
				</div><!-- main-side -->
				<div class="main-content-container">
					<div class="main-content">
						<div class="main-content-title">
							<cfoutput><h1>#data.title#</h1></cfoutput>
						</div><!-- /.main-content-title -->
						<div class="main-content-title">
							<cfoutput><h1>#data.title#</h1></cfoutput>
						</div><!-- /.main-content-title -->

						<cfset aBreadcrumbs = getBreadcrumbs( data.menu ) />
						<ul class="breadcrumb clearfix">
							<cfloop from="1" to="#arraylen(aBreadcrumbs)#" index="i">
								<cfoutput><li><a href="#aBreadcrumbs[i].link#">#aBreadcrumbs[i].title#</a><span class="divider">/</span></li></cfoutput>
							</cfloop>
						</ul><!-- /.breadcrumb .clearfix -->

						<cfoutput>#data.body#</cfoutput>
					</div><!-- /.main-content -->
				</div><!-- /.main-content-container -->
			</div>
		</div> 
		<div id="footer">
			<div class="container">
				<cfoutput>#data.footer#</cfoutput>
			</div> 
		</div> 
	</body> 
</html>
