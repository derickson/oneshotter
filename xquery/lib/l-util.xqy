xquery version "1.0-ml" ;

(:  l-util.xqy
    General utility libaries
:)

module namespace lu = "http://www.marklogic.com/ps/lib/util";

(:  if the transaction is a not read-only, throw an error :)
declare function lu:assert-read-only() as empty-sequence() {
    if(xdmp:request-timestamp() eq ()) then
        fn:error(xs:QName("Error"),"This transaction should have been read only.")
    else
        ()
};

(:  return a copy of an XML tree in a specific namespace 
    Params:
        $pre -- the prefix (not used)
        $ns  -- the target namespace uri
        $node -- the XML to be copied
:)
declare function lu:alter-ns($pre as xs:string,$ns as xs:string,$node as node()) {
    typeswitch($node)
        case text() return
            $node
        case element() return
            let $ln := fn:local-name($node)
            return
            element {fn:QName($ns,$ln)} {
                $node/@*,
                lu:alter-ns($pre,$ns,$node/node())
            }
        default return
            ()
};
    