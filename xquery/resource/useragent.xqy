xquery version "1.0-ml";

import module namespace h = "helper.xqy" at "/lib/rewrite/helper.xqy";

declare function local:get() {
	xdmp:get-request-header("User-Agent")
	
};


try          { xdmp:apply( h:function() ) } 
catch ( $e ) {  h:error( $e ) }

