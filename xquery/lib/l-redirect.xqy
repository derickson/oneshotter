xquery version "1.0-ml";

(:  
    Utility library for handling and saving redirects
:)

module namespace lr = 'http://www.marklogic.com/ps/lib/redirect';

declare variable $REDIRECT_FIELD := "requested-url";

(: save a redirect for later :)
declare function lr:set-redirect($url as xs:string) {
    xdmp:set-session-field($REDIRECT_FIELD,$url)
};

(: take action upon the last saved redirect :)
declare function lr:redirect-requested-url() {
    let $url := xdmp:get-session-field($REDIRECT_FIELD)
    let $_ := xdmp:log(fn:concat("Recovering url: ",$url),"fine")
    
    return
    
    if($url) then (
        lr:clear-redirect(),
        lr:do-redirect($url)
    )
    else 
        lr:do-redirect("/")
       
};

(: forget the current saved redirect :)
declare function lr:clear-redirect() {
    xdmp:set-session-field($REDIRECT_FIELD,())
};

(: redirect to url target, with centralized logging :)
declare function lr:do-redirect($url) {
    xdmp:log(text{"Redirecting to:",$url},"fine"),
    xdmp:redirect-response($url)
};

