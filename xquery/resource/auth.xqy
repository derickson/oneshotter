xquery version "1.0-ml";


(:
	Resource handler for authentication actions
:)

import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";
import module namespace oa2 = "/lib/oauth2" at "/lib/oauth2/oauth2.xqy";
import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";
import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";
import module namespace lr = "http://www.marklogic.com/ps/lib/redirect" at "/lib/l-redirect.xqy";
import module namespace lsv = "http://www.marklogic.com/ps/lib/save" at "/lib/l-save.xqy";


declare option xdmp:output "indent=no";

declare function local:logout() {
    ls:kill-current-session(),
	lr:do-redirect("/")
};

declare function local:facebook()  { 
	let $user_data := oa2:oauth2("facebook", $cfg:OAUTH2_CONFIG) 
	return
		if(fn:exists($user_data) ) then	
			
			let $user-id := map:get($user_data,"id")     
			let $user-uri := fn:concat("/user/",$user-id,".xml")
			let $user-retrieved := mu:user($user_data)
			let $user := mu:login-update(mu:get-user-doc-by-id($user-id), $user-retrieved)
			return (
				lsv:eval-save($user, $user-uri,"users",$cfg:DATABASE),
				ls:set-session-user($user),
				lr:redirect-requested-url() 
			)
		else
			()
};

try          { xdmp:apply( h:function() ) } 
catch ( $e ) {  h:error( $e ) }