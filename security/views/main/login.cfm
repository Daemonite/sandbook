<div class="row">
	<cfloop from="1" to="#arraylen(rc.login_options)#" index="i">
		<div class="col-md-4">
			<cfoutput>
				<a href="#rc.login_options[i].url#" class="btn #rc.login_options[i].button_class# btn-lg btn-block #rc.login_options[i].button_class# <cfif not rc.login_options[i].enabled>disabled</cfif>" >
					#rc.login_options[i].label#
				</a>
			</cfoutput>
		</div>
	</cfloop>
</div>