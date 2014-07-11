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
	<body class="alt">
		<div class="navbar navbar-fixed-top navbar-inverse">
			<div class="navbar-inner">
				<div class="container-fluid">
					<button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
					</button>
					<h1 class="brand"><cfif len(data.indextitle)>
						<cfif structkeyexists(data,"indexpath") and len(data.indexpath)><a href="/index.html"></cfif>
						<cfoutput>#data.indextitle#</cfoutput>
						<cfif structkeyexists(data,"indexpath") and len(data.indexpath)></a></cfif><cfif len(data.title)> /</cfif>
					</cfif>
					<cfoutput><small>#data.title#</small></cfoutput></h1>
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
			<div class="container">
				<div class="page-header">
					<h1><cfoutput>#data.title#</cfoutput></h1>
				</div> 
				<cfoutput>#data.body#</cfoutput>
			</div> 
		</div> 
		<div id="footer">
			<div class="container">
				<cfoutput>#data.footer#</cfoutput>
			</div> 
		</div> 
	</body> 
</html>
