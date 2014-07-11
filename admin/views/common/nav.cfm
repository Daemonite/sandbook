<cfoutput><ul class="#local.class#">
	<cfloop from="1" to="#arraylen(local.nav)#" index="i">
		<cfset local.active = getFullyQualifiedAction() == local.nav[i].action />
		<cfset local.children = structkeyexists(local.nav[i],"children") and arraylen(local.nav[i].children) />
		<li class="<cfif local.active>active</cfif> <cfif local.children>download</cfif>">
			<cfif local.children>
				<a href="#buildURL(local.nav[i].action)#" class="dropdown-toggle" data-toggle="dropdown">#local.nav[i].label#</a>
				<cfoutput>#view("admin:common/nav",{ nav:rc.nav[i].children, class:"dropdown-menu" })#</cfoutput>
			<cfelse>
				<a href="#buildURL(local.nav[i].action)#">#local.nav[i].label#</a>
			</cfif>
		</li>
	</cfloop>
</ul></cfoutput>