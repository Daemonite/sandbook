<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
	    <title><cfoutput>#rc.title#</cfoutput></title>

		<!-- CSS -->
		<link rel="stylesheet" href="/static/bootstrap-3.1.1-dist/css/bootstrap.min.css">
		<link rel="stylesheet" href="/static/bootstrap-3.1.1-dist/css/bootstrap-theme.min.css">
		<link rel="stylesheet" href="/static/font-awesome-4.1.0/css/font-awesome.css">
		<link rel="stylesheet" href="/static/pietimer/jquery.pietimer.css">
		<link rel="stylesheet" href="/static/main.css">

		<!-- JS -->
		<script src="/static/require-2.1.11/require.js"></script>
		<script src="/static/config.js"></script>
	</head>
    <body>
    	<div class="container">
	    	<nav class="navbar navbar-default" role="navigation">
				<div class="container-fluid">
					<!-- Brand and toggle get grouped for better mobile display -->
					<div class="navbar-header">
						<button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
							<span class="sr-only">Toggle navigation</span>
							<span class="icon-bar"></span>
							<span class="icon-bar"></span>
							<span class="icon-bar"></span>
						</button>
						<a class="navbar-brand" href="#">AutoDoc</a>
					</div>

					<!-- Collect the nav links, forms, and other content for toggling -->
					<div class="collapse navbar-collapse">
						<cfif not structkeyexists(request,"exception") and structkeyexists(rc,"nav")>
							<cfoutput>#view("admin:common/nav",{ nav:rc.nav, class:"nav navbar-nav" })#</cfoutput>
						</cfif>

						<cfif false and application.admin.isSecured() and application.admin.isLoggedIn()>
							<ul class="nav navbar-nav navbar-right">
								<li><a href="/login/logout.cfm">Logout</a></li>
							</ul>
						</cfif>
					</div><!-- /.navbar-collapse -->
				</div><!-- /.container-fluid -->
			</nav>
			<div class="page-header">
				<h1><cfoutput>#rc.title#</cfoutput></h1>
			</div>
			<cfoutput>#body#</cfoutput>
		</div>
   </body>
</html>