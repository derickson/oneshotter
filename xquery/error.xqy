xquery version "1.0-ml" ;

"Error"

(:
import module namespace vp = "http://azathought.com/ldi/view/page" at "/view/v-page.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";

declare namespace error = "http://marklogic.com/xdmp/error";

declare variable $error:errors as node()* external;

try{
    let $content := 
    (
        <div id="errorcontainer">
            {
                if($cfg:SHOW_ERRORS) then
                    <pre>{ xdmp:quote($error:errors) }</pre>
                else
                    <div>
                        <br/>
                        This application has encountered an error while running.<br/>
                        We appologize for the inconvenience.
                    </div>
            }
        </div>
    )
            
    let $crumbs := (
        <a href="/">land development information</a>,
        <span>error page</span>
    )
            
    return (
        xdmp:set-response-code(200, "Error page"),
        xdmp:log($error:errors,"error"),
        vp:one-column($content, $crumbs, "Error")
    )
} catch ($err) {
    xdmp:set-response-code(200, "Error page"),
    xdmp:set-response-content-type("text/html"),
    xdmp:log($err,"error"),
    xdmp:log($error:errors,"error"),
    <html>
        <body>
            This application has encountered an error while running.  We appologize for the inconvenience.
        </body>
    </html>
}
    
    :)