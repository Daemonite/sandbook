<div class="row">
	<div class="col-md-12">
		<cfif isdefined("rc.login_result.message")>
			<cfoutput><div class="alert alert-error">#rc.login_result.message#</div></cfoutput>
		</cfif>

		<form role="form" action="" method="POST" class="form-horizontal">
			<div class="form-group">
				<label for="username" class="col-sm-2 control-label">Username</label>
				<div class="col-sm-10">
					<input type="username" class="form-control" id="username" name="username" placeholder="some_guy">
				</div>
			</div>
			<div class="form-group">
				<label for="password" class="col-sm-2 control-label">Password</label>
				<div class="col-sm-10">
					<input type="password" class="form-control" id="password" name="password" placeholder="password123">
				</div>
			</div>
			<div class="form-group">
				<div class="col-sm-offset-2 col-sm-10">
					<button type="submit" class="btn btn-default">Log In</button>
				</div>
			</div>
		</form>
	</div>
</div>
<script type="text/javascript">
	require([
		"jquery"], 

		function($) {
			$(function(){
				$("#username").focus();
			});
		}
	);
</script>