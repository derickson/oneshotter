xquery version "1.0-ml";

(:  page.xqy
    Resource handler for / RESTful target
    Resource handler for /page/* RESTful target
:)

import module namespace vl = "http://azathought.com/oneshotter/view/login" at "/view/v-login.xqy";
import module namespace va = "http://azathought.com/oneshotter/view/account" at "/view/v-account.xqy";

import module namespace vp = "http://azathought.com/oneshotter/view/page" at "/view/v-page.xqy";
import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";
     
declare option xdmp:output "indent=no";

declare function local:login()  { vl:login( ) };
declare function local:badlogin()  { vl:bad-login( ) };
declare function local:account()  { va:account( ) };

try          { xdmp:apply( h:function() ) } 
catch ( $e ) {  h:error( $e ) }
