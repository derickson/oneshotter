xquery version "1.0-ml";

module namespace cf = "http://azathought.com/oneshotter/controller/friends";

import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";
import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";

declare function cf:get-friends() as element(cf:friends) {
	let $user := ls:get-session-user()
	let $url := fn:concat("https://graph.facebook.com/me/friends?access_token=",mu:get-user-auth-token($user))
	let $json := json:parse( xdmp:binary-decode( xdmp:http-get($url)[2] , "UTF-8" ) )
	return
		element cf:friends {
			for $friend in $json/json:data/json:item
			let $name := $friend/json:name/text()
			let $id := $friend/json:id/text()
			let $doc := mu:get-user-doc-by-id($id)
			let $display-name := if(fn:exists($doc)) then $doc//mu:display_name/text() else $name
			where fn:exists($doc)
			order by $display-name ascending
			return
				element cf:friend {
					element cf:name { $name },
					element cf:id { $id },
					element cf:picture { fn:concat("http://graph.facebook.com/", $id , "/picture" ) },
					element cf:uses-this-app { fn:exists($doc) },
					element cf:display-name { $display-name }
				}
		}
};