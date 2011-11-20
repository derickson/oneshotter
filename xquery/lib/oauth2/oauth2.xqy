xquery version "1.0-ml";

module namespace oa2 = "/lib/oauth2";
import module namespace oauth2 = "oauth2" at "/lib/oauth2/util.xqy";


(:	Main function for oauth2 login

	$provider-name is reference to //provider/@name in the $config
	$config is control object listing ouath providers
	
	Returns a map full of user profile information or 
	redirects browser appropriately during repeated calles in oauth2 proceedure.
 :)
declare function oa2:oauth2($provider-name as xs:string, $config as element(oauth_config)) {
	(: TODO handle error :)
	let $error			:= xdmp:get-request-field('error',())
	let $error-reason	:= xdmp:get-request-field('error_reason',())
	let $error-reason	:= xdmp:get-request-field('error_description',())
	
	let $code			:= xdmp:get-request-field("code")
	let $provider		:= xdmp:get-request-field("provider")
	let $auth_provider	:= $config//*:provider[@name eq $provider-name]
	let $client_id		:= $auth_provider/id/text()
	let $client_secret	:= $auth_provider/secret/text()
	let $redirect_url	:= $auth_provider/redirect_url/text()
	
	let $scope			:= 	if($auth_provider/scope/text()) then 
								fn:concat("&amp;",$auth_provider/scope/text()) 
							else 
								""

	let $authorization_url := fn:concat($auth_provider/authorize_url/text(),
										"?client_id=", $client_id, 
										"&amp;redirect_uri=", xdmp:url-encode($redirect_url),$scope)

	
	let $access_token_url := fn:concat($auth_provider/access_token_url/text(),
									   "?client_id=",$client_id, 
									   "&amp;redirect_uri=", xdmp:url-encode($redirect_url),
									   "&amp;code=", $code,
									   "&amp;client_secret=", $client_secret
									   )
	
	return
		if(fn:not($code)) then
			let $_ := xdmp:log(text{"authurl:",$authorization_url})
			return
				xdmp:redirect-response($authorization_url) 
		
		else 
			
			let $access_token_response := xdmp:http-get($access_token_url)
			return

				if($access_token_response[1]/*:code/text() eq "200") then
					let $oauth_token_data := oauth2:parseAccessToken($access_token_response[2])
					let $provider_user_data := oauth2:getUserProfileInfo($provider-name, $oauth_token_data)
					return 
						if(fn:exists($provider_user_data)) then
							($provider_user_data)
						else
							fn:error(xs:QName("Error"),"Could not get user information")
				else
					(: if there's a problem just pass along the error :)
					(
					xdmp:log("problem"),
					xdmp:set-response-code($access_token_response[1]/*:code/text(),
										   $access_token_response[1]/*:message/text())
					)
		
};