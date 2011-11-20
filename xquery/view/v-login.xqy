xquery version "1.0-ml";

(:
    Render function for the login page
:)

module namespace vl = "http://azathought.com/oneshotter/view/login";

import module namespace vp = "http://azathought.com/oneshotter/view/page" at "/view/v-page.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare option xdmp:output "indent=no";

declare variable $ERROR_MESSAGE := ();

(:  Render function :)
declare function vl:login() {
    
    let $content := 
        (
            <div id="logincontainer" class="actionbox">
                Please login with one of the following options:
				<div>
					<a class="app-button" href="/facebook">Facebook</a>
				</div>
				
            </div>
        )

        

    return
        vp:one-column($content, ())
};

(:  render function for displaying the error message :)
declare function vl:bad-login() {
    xdmp:set($ERROR_MESSAGE, "Error: Authentication failed."),
    vl:login()
};



