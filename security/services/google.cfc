component {
	
	public any function init(fw) {
		variables.fw = fw;
		return this;
	}

	public struct function getOption(){
		return {
			"url" : getAuthorisationURL(
				redirectURL="http://#cgi.http_host#" & variables.fw.buildURL( 'security:google.login' ), 
				scope='https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email'
			),
			"enabled" : isEnabled(),
			"button_class" : "btn-primary",
			"label" : "Google"
		}
	}

	public boolean function isEnabled(){
		return len(variables.fw.getADConfig("security.google.client_id",""))
			&& len(variables.fw.getADConfig("security.google.client_secret",""))
			&& arraylen(variables.fw.getADConfig("security.google.allow",[]));
	}
  	
	public string function getAuthorisationURL(required string redirectURL, string scope="https://www.googleapis.com/auth/userinfo.profile", string state="")
	{
		var client_id = variables.fw.getADConfig("security.google.client_id","");
		var redirectURL_ = urlencodedformat(arguments.redirectURL);
		var scope_ = urlencodedformat(arguments.scope);
		var state_ = urlencodedformat(arguments.state);

		return "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#client_id#&redirect_uri=#redirectURL_#&scope=#scope_#&access_type=offline&state=#state_#";
	}

	private struct function getTokens(required string authorizationCode, required string redirectURL)
	{
		var cfhttp = {};
		var stResult = {};
		var client_id = variables.fw.getADConfig("security.google.client_id","");
		var client_secret = variables.fw.getADConfig("security.google.client_secret","");

		http url="https://accounts.google.com/o/oauth2/token" method="POST" {
			httpparam type="formfield" name="code" value=arguments.authorizationCode;
			httpparam type="formfield" name="client_id" value=client_id;
			httpparam type="formfield" name="client_secret" value=client_secret;
			httpparam type="formfield" name="redirect_uri" value=arguments.redirectURL;
			httpparam type="formfield" name="grant_type" value="authorization_code";
		}

		if (not cfhttp.statuscode == "200 OK") {
			throw(message="Error accessing Google API: #cfhttp.statuscode#",details={ endpoint="https://accounts.google.com/o/oauth2/token", response=trim(cfhttp.filecontent),args=arguments});
		}

		stResult = deserializeJSON(cfhttp.FileContent.toString());
		stResult.access_token_expires = dateadd("s",stResult.expires_in,now());

		return stResult;
	}

	public string function getAccessToken(required string refresh_token, required string access_token, required date access_token_expires)
	{
		var cfhttp = {};
		var stResult = {};
		var client_id = variables.fw.getADConfig("security.google.client_id","");
		var client_secret = variables.fw.getADConfig("security.google.client_secret","");

		if (isdefined("arguments.refresh_token") && datecompare(arguments.access_token_expires,now()) < 0)
		{
			http url="https://accounts.google.com/o/oauth2/token" method="POST" {
				httpparam type="formfield" name="refresh_token" value=arguments.refreshToken;
				httpparam type="formfield" name="client_id" value=client_id;
				httpparam type="formfield" name="client_secret" value=client_secret;
				httpparam type="formfield" name="grant_type" value="refresh_token";
			}

			if (not cfhttp.statuscode == "200 OK")
			{
				throw(message="Error accessing Google API: #cfhttp.statuscode#",details={endpoint="https://accounts.google.com/o/oauth2/token",response=cfhttp.filecontent,argumentCollection=arguments});
			}

			stResult = deserializeJSON(cfhttp.FileContent.toString());

			return stResult.access_token;
		}
		else if (not isdefined("arguments.refresh_token"))
		{
			throw(message="Error accessing Google API: access token has expired and no refresh token is available",details={endpoint="https://accounts.google.com/o/oauth2/token",response=cfhttp.filecontent,argumentCollection=arguments});
		}

		return arguments.access_token;
	}

	private struct function getTokenInfo(required string accessToken)
	{
		var cfhttp = {};
		var stResult = {};

		http url="https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=#arguments.accessToken#" method="GET";

		if (not cfhttp.statuscode == "200 OK"){
			throw(message="Error accessing Google API: #cfhttp.statuscode#",details={endpoint="https://www.googleapis.com/oauth2/v1/tokeninfo",response=cfhttp.filecontent,argumentCollection=arguments});
		}

		stResult = deserializeJSON(cfhttp.FileContent.toString());

		if (structkeyexists(stResult,"error")){
			throw(message="Error accessing Google API: #stResult.error#",details={endpoint="https://www.googleapis.com/oauth2/v1/tokeninfo",response=cfhttp.filecontent,argumentCollection=arguments});
		}
		else if (stResult.audience != variables.fw.getADConfig("security.google.client_id","")){
			throw(message="Error accessing Google API: Authorisation is for the wrong application",details={endpoint="https://www.googleapis.com/oauth2/v1/tokeninfo",response=cfhttp.filecontent,argumentCollection=arguments});
		}

		return stResult;
	}

	private struct function getGoogleProfile(required string accessToken){
		var cfhttp = {};
		var stResult = {};

		http url="https://www.googleapis.com/oauth2/v1/userinfo" method="GET" {
			httpparam type="header" name="Authorization" value="Bearer #arguments.accessToken#";
		}

		if (not cfhttp.statuscode == "200 OK"){
			throw(message="Error accessing Google API: #cfhttp.statuscode#",details={endpoint="https://www.googleapis.com/oauth2/v1/userinfo",response=cfhttp.filecontent,argumentCollection=arguments});
		}

		stResult = deserializeJSON(cfhttp.FileContent.toString());

		return stResult;
	}

	public struct function checkLogin(required string code, required string redirectURL){
		var stResult = {};

		try{
			var stTokens = getTokens(arguments.code,arguments.redirectURL);
			var stTokenInfo = getTokenInfo(stTokens.access_token);
			var stProfile = getGoogleProfile(stTokens.access_token);

			if (isAllowed(stProfile.email)){
				return {
					"success" : true,
					"user" : stProfile.email,
					"tokens" : stTokens,
					"profile" : stProfile
				}
			}
			else {
				return {
					"success" : false,
					"message" : "You are not an allowed user"
				}
			}
		}
		catch (any e){
			return {
				"success" : false,
				"message" : e.message
			}
		}
	}

	public boolean function isAllowed(required string email){
		var allow = variables.fw.getADConfig("security.google.allow",[]);
		
		for (var i=1; i<=arraylen(allow); i++){
			if (refindnocase("^" & allow[i] & "$",arguments.email)){
				return true;
			}
		}

		return false;
	}

}