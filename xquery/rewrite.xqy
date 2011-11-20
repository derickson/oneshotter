xquery version "1.0-ml" ;

(:  rewrite.xqy

    This application uses the rewrite Open Source project for RESTful URL rewriting in MarkLogic
    https://github.com/dscape/rewrite
:)

import module namespace r = "routes.xqy" at "/lib/rewrite/routes.xqy";
import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";
import module namespace lr = "http://www.marklogic.com/ps/lib/redirect" at "/lib/l-redirect.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";


    (: let rewrite library determine destination URL, use routes configuration in config lib :)
	let $selected-url    := r:selectedRoute( $cfg:ROUTES )
	let $_      := xdmp:log(text{"Rewrite target:",$selected-url},'fine')
	return
		let $url := $selected-url
		let $path :=   xdmp:get-request-path() 
		let $params := fn:substring-after($selected-url, "?")[. ne ""]
		return
			if ($cfg:TEST_ENABLED and fn:matches($url, "^/test$")) then
				$url
			else if ($cfg:TEST_ENABLED and fn:matches($url, "^/test/")) then
				if (fn:matches($url, "(_js|_img|_css)")) then 
					$url
				else
					let $func := (fn:tokenize($path, "/")[3][. ne ""], "main")[1]
					return
						fn:concat("/test/default.xqy?func=", $func, if ($params) then concat("&amp;", $params) else ())
			else
    
				let $rewrite-url :=
					(:	if the user is not logged in yet then remember 
						where they want to go and send them to login page :) 
					if( fn:not(ls:has-active-session()) and 
						fn:not(fn:starts-with($selected-url,"/static/css")) and
						fn:not(fn:starts-with($selected-url,"/static/js")) and
						fn:not(fn:starts-with($selected-url,"/static/img")) and
						fn:not(fn:starts-with($selected-url,"/resource/auth.xqy")) and
						fn:not(fn:starts-with($selected-url,"/resource/oauth2.xqy")) and
						fn:not($selected-url eq r:selectedRoute( $cfg:ROUTES, "/page/login", "GET" )) and
						fn:not($selected-url eq r:selectedRoute( $cfg:ROUTES, "/page/badlogin", "GET" )) ) then                   
					
						let $_ := lr:set-redirect(xdmp:get-request-url())
						return
							r:selectedRoute( $cfg:ROUTES, "/page/login", "GET" )

					else 
						(: send them to the rewrite target :)
						$selected-url
                    
				let $_ := xdmp:log(text{"Rewrite decision:",$rewrite-url},'fine') 
				return
            
                $rewrite-url 