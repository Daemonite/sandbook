<cfoutput>
	<h2>Error Overview</h2>
	<table class="table table-striped">
		<tr><th>Message:</th><td>#request.exception.message#</td></tr>
		<tr><th>Machine:</th><td>#getADConfig("machinename","N/A")#</td></tr>
		<tr><th>Browser:</th><td>#cgi.HTTP_USER_AGENT#</td></tr>
		<tr><th>DateTime:</th><td>#now()#</td></tr>
		<tr><th>Host:</th><td>#cgi.HTTP_HOST#</td></tr>
		<tr><th>Referer:</th><td>#cgi.HTTP_REFERER#</td></tr>
		<tr><th>Query String:</th><td>#cgi.QUERY_STRING#</td></tr>
		<tr><th>Remote Address:</th><td>#cgi.REMOTE_ADDR#</td></tr>
	</table>

	<h2>Error Details</h2>
	<table class="table">
		<cfif structKeyExists(request.exception, "type") and len(request.exception.type)>
			<tr><th>Exception Type:</th><td>#request.exception.type#</td></tr>
		</cfif>
		<cfif structKeyExists(request.exception, "detail") and len(request.exception.detail)>
			<tr><th>Detail:</th><td>#request.exception.detail#</td></tr>
		</cfif>
		<cfif structKeyExists(request.exception, "extended_info") and len(request.exception.extended_info)>
			<tr><th>Extended Info:</th><td>#request.exception.extended_info#</td></tr>
		</cfif>
		<cfif structKeyExists(request.exception, "queryError") and len(request.exception.queryError)>
			<tr><th>Query Error:</th><td>#request.exception.queryError#</td></tr>
		</cfif>
		<cfif structKeyExists(request.exception, "sql") and len(request.exception.sql)>
			<tr><th>SQL:</th><td>#request.exception.sql#</td></tr>
		</cfif>
		<cfif structKeyExists(request.exception, "where") and len(request.exception.where)>
			<tr><th>Where:</th><td>#request.exception.where#</td></tr>
		</cfif>

		<tr><th valign="top">Tag Context:</th><td><ul>
		<cfloop from="1" to="#arraylen(request.exception.TagContext)#" index="i">
			<li>#request.exception.TagContext[i].template# (line: #request.exception.TagContext[i].line#)</li>
		</cfloop>
		</ul></td></tr>

		<cfif structkeyexists(request,"context")>
			<tr><th valign="top">Context:</th><td><cfdump var="#request.context#"></td></tr>
		</cfif>
	</table>
</cfoutput>