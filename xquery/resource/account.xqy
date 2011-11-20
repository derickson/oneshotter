xquery version "1.0-ml";

import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";
import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";


declare option xdmp:update "true";

declare function local:get-account() {
	let $user := ls:get-session-user()
	let $displayName := mu:get-display-name($user)
	return
	json:serialize(
		json:object(
			("displayName", $displayName)
		)
	)
};

declare function local:post-account() {
	let $json := json:parse(xdmp:binary-decode( xdmp:get-request-body("binary"),"UTF-8"))
	let $displayName := $json//json:displayName/text()
	let $doc := ls:get-database-user-same-as-session()
	return
		if($displayName) then 
			xdmp:node-replace( $doc//mu:display_name/text(), text{$displayName})
		else
			()
};


try          { xdmp:apply( h:function() ) } 
catch ( $e ) {  h:error( $e ) }

