<div class="row">
	<div class="col-md-12">
		<cfif isdefined("rc.login_result.message")>
			<cfoutput><div class="alert alert-error">#rc.login_result.message#. Would you like to <a href="#rc.authorize_url#">try again</a>?</div></cfoutput>
		</cfif>
	</div>
</div>