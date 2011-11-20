xquery version "1.0-ml" ;

(:  l-save.xqy
    Utility library for functions related to saving documents to the database
:)

module namespace lsv = "http://www.marklogic.com/ps/lib/save";

import module namespace lu = "http://www.marklogic.com/ps/lib/util" at "/lib/l-util.xqy";

(:  Batch function for saving sequence of objects to a database in an eval 
    Params:
        $things-to-save -- sequence of documents to save
        $uris           -- corresponding sequence of uri save locations
        $collection     -- a set of collections to apply to saved objects
        $dbname         -- name of the target database
    Returns:
        empty-sequence()
:)    
declare function lsv:eval-save($things-to-save as node()+, $uris as xs:string+, 
                               $collections as xs:string*,$dbname as xs:string) 
                               as empty-sequence(){
                               
    let $_ := lu:assert-read-only()
    let $map := map:map()
    let $_ :=
        for $thing at $x in $things-to-save
        return
            map:put($map, 
                    $uris[$x],
                    $thing)
    let $save-query := 
      fn:concat("xquery version '1.0-ml'; 
       declare variable $map as map:map external;
       for $key in map:keys($map)
       return
       xdmp:document-insert($key,map:get($map,$key),
            xdmp:default-permissions(),
            (",
                fn:string-join(
                    for $collection in $collections 
                    return
                        fn:concat("'",$collection,"'"),
                ""),
            "))")
    return 
        (: evaluate the query string $s using the variables 
           supplied as the second parameter to xdmp:eval :)
        xdmp:eval($save-query, (xs:QName("map"), $map),
        <options xmlns="xdmp:eval">
          <isolation>different-transaction</isolation>
          {if($dbname) then <database>{xdmp:database($dbname)}</database> else ()}
          <prevent-deadlocks>false</prevent-deadlocks>
        </options> )
};

declare function lsv:eval-delete($uris-to-delete as xs:string*, $dbname as xs:string) {
	let $_ := lu:assert-read-only()
    let $map := map:map()
    let $_ :=
        for $uri at $x in $uris-to-delete
        return
            map:put($map, 
                    fn:string($x),
                    $uri)
    let $del-query := 
      fn:concat("xquery version '1.0-ml'; 
       declare variable $map as map:map external;
       for $key in map:keys($map)
       return
          xdmp:document-delete(map:get($map,$key))")
    return 
        (: evaluate the query string $s using the variables 
           supplied as the second parameter to xdmp:eval :)
        xdmp:eval($del-query, (xs:QName("map"), $map),
        <options xmlns="xdmp:eval">
          <isolation>different-transaction</isolation>
          {if($dbname) then <database>{xdmp:database($dbname)}</database> else ()}
          <prevent-deadlocks>true</prevent-deadlocks>
        </options> )
};

