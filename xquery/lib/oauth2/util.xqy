xquery version "1.0-ml";
module namespace oauth2 = "oauth2";
declare namespace xdmphttp="xdmp:http";

import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
import module namespace security-util = "security-util" at "/lib/security-util.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";

(:~
 : Fetch the user profile info for the given provider, basically a router function
 : @param $provider the provider name corresponding the provider config setup
 : @param $oauth_token_data the oauth2 access_token for the current users session
 : @return the provider-data node() block
 :)
declare function oauth2:getUserProfileInfo($provider-name, $oauth_token_data)  {
    let $access_token := map:get($oauth_token_data, "access_token")    
    return
    if($provider-name = "facebook") then
        oauth2:facebookUserProfileInfo($access_token) 
    else if($provider-name = "github") then
        oauth2:githubUserProfileInfo($access_token) 
    else (:buzz:) 
        oauth2:buzzUserProfile($access_token)
};

declare function oauth2:buzzUserProfile($access_token) {
    let $profile_url := fn:concat("https://www.googleapis.com/buzz/v1/people/@me/@self?alt=json&amp;amp;key=", xdmp:url-encode($access_token))
    let $_ := xdmp:log($profile_url)
    let $cmd := fn:concat("xquery version '1.0-ml'; xdmp:http-get('", 
                          $profile_url, 
                          "', <options xmlns='xdmp:http-get'><format xmlns='xdmp:document-get'>text</format></options>)")
    let $_ := xdmp:log($cmd)
    let $profile_response :=  xdmp:eval($cmd)
    return
        if($profile_response[1]/xdmphttp:code/text() eq "200") then
            let $json_response := $profile_response[2]
            let $_ := xdmp:log(fn:concat("self: ",$json_response))
            let $map_response := map:get(xdmp:from-json($profile_response[2]),"data")
            let $provider_user_data :=
                <provider-data name="latitude">
                    <id>{map:get($map_response,"id")}</id>
                    <name>{map:get($map_response,"displayName")}</name>
                    <link>{map:get($map_response,"profileUrl")}</link>
                    <picture>{map:get($map_response,"thumbnailUrl")}</picture>
                </provider-data>
            return
                $provider_user_data
        else 
            xdmp:log(xdmp:quote($profile_response[1]))
};


(:~
 : Given the user_data map, get the request token and call to Facebook to get profile information
 : populate the profile information in the map (see within for those values
 :) 
declare function oauth2:facebookUserProfileInfo($access_token)  {
    let $profile_url := fn:concat("https://graph.facebook.com/me?access_token=", $access_token)
	let $_ := xdmp:log(fn:concat("attempting to get facebook user profile info: ",$profile_url))
    let $cmd := fn:concat("xquery version '1.0-ml'; xdmp:http-get('", 
                          $profile_url, 
                          "', <options xmlns='xdmp:http-get'><format xmlns='xdmp:document-get'>text</format></options>)")
    let $profile_response :=  xdmp:eval($cmd)
    return
        if($profile_response[1]/xdmphttp:code/text() eq "200") then

				let $map := xdmp:from-json($profile_response[2])
				let $token := map:put($map,"access_token",$access_token)
				return
				$map
            
			(: let $provider_user_data :=
                <provider-data name="facebook">
                    <id>{map:get($map_response,"id")}</id>
                    <name>{map:get($map_response,"name")}</name>
                    <first_name>{map:get($map_response,"first_name")}</first_name>
                    <last_name>{map:get($map_response,"last_name")}</last_name>
                    <link>{map:get($map_response,"link")}</link>
                    <gender>{map:get($map_response,"gender")}</gender>
                    <picture>{fn:concat("http://graph.facebook.com/", map:get($map_response,"id"), "/picture" )}</picture>
					<json>{json:parse($json_response)}</json>
                </provider-data>
            return
                $provider_user_data
            :)
        else 
            ()
    
};

(:~
 : Given the user_data map, get the request token and call to Facebook to get profile information
 : populate the profile information in the map (see within for those values
 :) 
declare function oauth2:githubUserProfileInfo($access_token)  {
    let $profile_url := fn:concat("https://github.com/api/v2/xml/user/show?access_token=", $access_token)
    let $cmd := fn:concat("xquery version '1.0-ml'; xdmp:http-get('", 
                          $profile_url, 
                          "')")
    let $profile_response :=  xdmp:eval($cmd)
    return
        if($profile_response[1]/xdmphttp:code/text() eq "200") then
            let $xml_response := $profile_response[2]
            let $provider_user_data :=
                <provider-data name="github">
                    <id>{$xml_response/user/login/text()}</id>
                    <name>{$xml_response/user/name/text()}</name>
                    <link>{fn:concat("http://github.com/", $xml_response/user/login/text())}</link>
                    <picture>{fn:concat("http://www.gravatar.com/avatar/", $xml_response/user/gravatar-id/text())}</picture>
                </provider-data>
            return
                $provider_user_data
        else 
            ()
    
};

(:~
 : Parse the response text of an outh2 access token request into the token and 
 : expiration date
 : @param $responseText response text of the access token request
 : @return map containing access_token, expires
 :)
declare function oauth2:parseAccessToken($responseText) as item()+ {
   let $params := fn:tokenize($responseText, "&amp;")
   let $access_token := fn:tokenize($params[1], "=")[2]
   let $expires_seconds := if($params[2]) then fn:tokenize($params[2], "=")[2] else ()
   let $expires := if($params[2]) then fn:current-dateTime() + xs:dayTimeDuration(fn:concat("PT", $expires_seconds, "S")) else ()
   let $user_data := map:map()
   let $key := map:put($user_data, "access_token", $access_token)
   let $key := map:put($user_data, "expires", $expires)
   let $_ := xdmp:log(fn:concat("access-token: ",$access_token))
   return $user_data
};


