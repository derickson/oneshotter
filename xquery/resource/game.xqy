xquery version "1.0-ml";

import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";

import module namespace vg = "http://azathought.com/oneshotter/view/game" at "/view/v-game.xqy";
import module namespace vf = "http://azathought.com/oneshotter/view/friends" at "/view/v-friends.xqy";
import module namespace vp = "http://azathought.com/oneshotter/view/page" at "/view/v-page.xqy";

import module namespace json = "http://marklogic.com/json" at "/lib/mljson/json.xqy";
import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";
import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";
import module namespace lsv = "http://www.marklogic.com/ps/lib/save" at "/lib/l-save.xqy";


declare function local:new() {
	
	vp:main-right(
		vg:new(),
		vf:friends(),
		"Create New Game"
	)
	
	
};

declare function local:get() {
	
	vp:main-right(
		vg:game(h:id()),
		vf:friends(),
		"Game"
	)
	
	
};

declare function local:json-get-new() {
	let $user := ls:get-session-user()
	let $displayName := mu:get-display-name($user)
	return
	json:serialize(
		json:object(
			(
				"name", "", 
				"GM", $displayName,
				"ownerid", mu:get-user-id($user)
			)
		)
	)
};

declare function local:json-post-new() {
	let $json := json:parse(xdmp:binary-decode( xdmp:get-request-body("binary"),"UTF-8"))
	let $rand := fn:string(xdmp:random())
	let $doc := element object {
		element id {$rand},
		element created {fn:current-dateTime()},
		element modified {fn:current-dateTime()},
		element json {
			$json
		}
	}
	return (
		lsv:eval-save($doc, fn:concat("/game/",$rand,".xml"),"games",$cfg:DATABASE),
		$rand
	)
};


try          { xdmp:apply( h:function() ) } 
catch ( $e ) {  h:error( $e ) }

