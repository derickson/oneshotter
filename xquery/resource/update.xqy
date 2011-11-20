xquery version "1.0-ml";

import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";
import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";
import module namespace lr = "http://www.marklogic.com/ps/lib/redirect" at "/lib/l-redirect.xqy";
import module namespace lsv = "http://www.marklogic.com/ps/lib/save" at "/lib/l-save.xqy";
import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";


declare function local:revoke() {
	
	let $user := ls:get-session-user()
	let $user-doc := mu:get-user-doc($user)
	return (
		lsv:eval-delete(xdmp:node-uri($user-doc),$cfg:DATABASE),
		xdmp:http-get(
			fn:concat(
				"https://api.facebook.com/method/auth.revokeAuthorization?access_token=",
				mu:get-user-auth-token($user)
			)
		),
		ls:kill-current-session(),
		lr:do-redirect("/")
	)
	
};


try          { xdmp:apply( h:function() ) } 
catch ( $e ) {  h:error( $e ) }


