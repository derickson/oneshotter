xquery version "1.0-ml";

module namespace helper="http://marklogic.com/ps/test-helper";

import module namespace cvt = "http://marklogic.com/cpf/convert" at "/MarkLogic/conversion/convert.xqy";

declare namespace t="http://marklogic.com/ps/test";
declare namespace test="http://marklogic.com/ps/test-helper";
declare namespace ss="http://marklogic.com/xdmp/status/server";
declare namespace xdmp-http="xdmp:http";

declare option xdmp:mapping "false";

declare variable $helper:PREVIOUS_LINE_FILE as xs:string :=
  try {
   fn:error(xs:QName("boom"), "")
  }
  catch($ex) {
    fn:concat($ex/error:stack/error:frame[3]/error:uri, " : Line ", $ex/error:stack/error:frame[3]/error:line)
  };

declare variable $helper:__LINE__ as xs:int :=
  try {
   fn:error(xs:QName("boom"), "")
  }
  catch($ex) {
    $ex/error:stack/error:frame[2]/error:line
  };

declare variable $helper:__FILE__ as xs:string :=
  try {
   fn:error(xs:QName("boom"), "")
  }
  catch($ex) {
    ($ex/error:stack/error:frame[2]/error:uri, "no file")[1]
  };
  
declare variable $helper:__CALLER_FILE__  :=
  try {
   fn:error(xs:QName("boom"), "")
  }
  catch($ex) {
    ($ex/error:stack/error:frame[3]/error:uri, "no file")[1]
  };

declare function helper:load-test-file($filename as xs:string, $database-id as xs:unsignedLong, $uri as xs:string)
{
  let $dir := cvt:basepath($helper:__CALLER_FILE__)
  let $file := helper:get-modules-file(fn:replace(fn:concat($dir, "/", $filename), "//", "/"))
  return
    if ($database-id eq 0) then
      let $uri := fn:replace(fn:concat(xdmp:modules-root(), $uri), "//", "/")
      let $_ :=
        try {
          xdmp:filesystem-directory(cvt:basepath($uri))
        }
        catch($ex) {
          xdmp:filesystem-directory-create(cvt:basepath($uri), 
                      <options xmlns="xdmp:filesystem-directory-create">
                        <create-parents>true</create-parents>
                      </options>)
        }    
      return
        xdmp:save($uri, $file)
    else
      xdmp:eval('
        xquery version "1.0-ml";
      
        declare variable $uri as xs:string external;
        declare variable $file external;
        xdmp:document-insert($uri, $file)
      ',
      (xs:QName("uri"), $uri,
       xs:QName("file"), $file),
      <options xmlns="xdmp:eval">
        <database>{$database-id}</database>
      </options>)
};

declare function helper:build-uri(
  $base as xs:string,
  $suffix as xs:string) as xs:string
{
  fn:string-join(
    (fn:replace($base, "(.*)/$", "$1"),
     fn:replace($suffix, "^/(.*)", "$1")),
    "/")
};

declare function helper:get-modules-file($file as xs:string) {
  if (xdmp:modules-database() eq 0) then
    let $doc :=
      xdmp:document-get(
        helper:build-uri(xdmp:modules-root(), $file),
        <options xmlns="xdmp:document-get">
          <format>text</format>
        </options>)
    return
      try {
        xdmp:unquote($doc)
      }
      catch($ex) {$doc}
  else
  (
    xdmp:eval(
      fn:concat('
        let $doc := fn:doc("', $file, '")
        return
          if ($doc/*) then
            $doc
          else
            try {
              xdmp:unquote($doc)
            }
            catch($ex) {
              $doc
            }'),
      (),
      <options xmlns="xdmp:eval">
        <database>{xdmp:modules-database()}</database>
      </options>)
  )
};

(:~
 : constructs a success xml element
 :)
declare function helper:success() {
  <t:result type="success"/>
};

(:~
 : constructs a failure xml element
 :)
declare function helper:fail($expected as item(), $actual as item()) {
  helper:fail(<oh-nos>Expected {$expected} but got {$actual} at {$helper:PREVIOUS_LINE_FILE}</oh-nos>)
};

(:~
 : constructs a failure xml element
 :)
declare function helper:fail($message as item()*) {
  element t:result {
    attribute type { "fail" },
    typeswitch($message)
      case element(error:error) return $message
      default return
        fn:error(xs:QName("USER-FAIL"), $message)
  }
};

declare function helper:assert-all-exist($count as xs:unsignedInt, $item as item()*) {
  if ($count eq fn:count($item)) then
    helper:success()
  else
    fn:error(xs:QName("ASSERT-ALL-EXIST-FAILED"), "Assert All Exist failed", $item)
};

declare function helper:assert-exists($item as item()*) {
  if (fn:exists($item)) then
    helper:success()
  else
    fn:error(xs:QName("ASSERT-EXISTS-FAILED"), "Assert Exists failed", $item)
};

declare function helper:assert-not-exists($item as item()*) {
  if (fn:not(fn:exists($item))) then
    helper:success()
  else
    fn:error(xs:QName("ASSERT-EXISTS-FAILED"), "Assert Exists failed", $item)
};

declare function helper:assert-at-least-one-equal($expected as item()*, $actual as item()*) {
  if ($expected = $actual) then
    helper:success()
  else
    fn:error(xs:QName("ASSERT-AT-LEAST-ONE-EQUAL-FAILED"), "Assert At Least one Equal failed", ())
};

declare private function helper:are-these-equal($expected as item()*, $actual as item()*) {
  if (fn:count($expected) eq fn:count($actual)) then
    fn:count((for $item at $i in $expected
    return
      fn:deep-equal($item, $actual[$i]))[. = fn:true()]) eq fn:count($expected)
  else
    fn:false()
};

declare function helper:assert-equal($expected as item()*, $actual as item()*) {
  if (helper:are-these-equal($expected, $actual)) then
    helper:success()
  else
    fn:error(xs:QName("ASSERT-EQUAL-FAILED"), "Assert Equal failed", ($expected, $actual))
};

declare function helper:assert-not-equal($expected as item()*, $actual as item()*) {
  if (fn:not(helper:are-these-equal($expected, $actual))) then
    helper:success()
  else
    fn:error(
      xs:QName("ASSERT-NOT-EQUAL-FAILED"),
      fn:concat("test name", ": Assert Not Equal failed"),
      ($expected, $actual))
};

declare function helper:assert-true($supposed-truths as xs:boolean*) {
  helper:assert-true($supposed-truths, $supposed-truths)
};

declare function helper:assert-true($supposed-truths as xs:boolean*, $msg as item()*) {
  if (fn:false() = $supposed-truths) then
    fn:error(xs:QName("ASSERT-TRUE-FAILED"), "Assert True failed", $msg)
  else
    helper:success()
};

declare function helper:assert-false($supposed-falsehoods as xs:boolean*) {
  if (fn:true() = $supposed-falsehoods) then
    fn:error(xs:QName("ASSERT-FALSE-FAILED"), "Assert False failed", $supposed-falsehoods)
  else
    helper:success()
};


declare function helper:assert-meets-minimum-threshold($expected as xs:decimal, $actual as xs:decimal+) {
  if (every $i in 1 to fn:count($actual) satisfies $actual[$i] ge $expected) then
    helper:success()
  else
    fn:error(
      xs:QName("ASSERT-MEETS-MINIMUM-THRESHOLD-FAILED"),
      fn:concat("test name", ": Assert Meets Minimum Threshold failed"),
      ($expected, $actual))
};

declare function helper:assert-meets-maximum-threshold($expected as xs:decimal, $actual as xs:decimal+) {
  if (every $i in 1 to fn:count($actual) satisfies $actual[$i] le $expected) then
    helper:success()
  else
    fn:error(
      xs:QName("ASSERT-MEETS-MAXIMUM-THRESHOLD-FAILED"),
      fn:concat("test name", ": Assert Meets Maximum Threshold failed"), 
      ($expected, $actual))
};

declare function helper:assert-throws-error($function as xdmp:function)
{
  helper:assert-throws-error($function, ())
};

declare function helper:assert-throws-error($function as xdmp:function, $error-code as xs:string?)
{
  helper:assert-throws-error($function, "no-params-please", $error-code)
};

declare function helper:assert-throws-error($function as xdmp:function, $params as item()*, $error-code as xs:string?)
{
  try {
    if (fn:count($params) eq 1 and $params instance of xs:string and $params = "no-params-please") then
      xdmp:apply($function)
    else
      xdmp:apply($function, $params),
    fn:error(xs:QName("ASSERT-THROWS-ERROR-FAILED"), "It did not throw an error")
  }
  catch($ex) {
    if ($ex/error:name eq "ASSERT-THROWS-ERROR-FAILED") then
      xdmp:rethrow()
    else if ($error-code) then
      if ($ex/error:code eq $error-code or $ex/error:name eq $error-code) then
        helper:success()
      else
      (
        xdmp:log($ex),
        fn:error(xs:QName("ASSERT-THROWS-ERROR-FAILED"), fn:concat("Error code was: ", $ex/error:code, " not: ", $error-code))
      )
    else
      helper:success()
  }
};

declare function helper:easy-url($url) as xs:string
{
  if (fn:starts-with($url, "http")) then $url
  else
    fn:concat("http://localhost:", fn:tokenize(xdmp:get-request-header("Host"), ":")[2], if (fn:starts-with($url, "/")) then () else "/", $url)
};

declare function helper:http-get($url as xs:string, $options as node()?)
{
  let $uri :=
    if (fn:starts-with($url, "http")) then $url
    else
      fn:concat("http://localhost:", fn:tokenize(xdmp:get-request-header("Host"), ":")[2], if (fn:starts-with($url, "/")) then () else "/", $url)
  return
    xdmp:http-get($uri, $options)
};

declare function helper:assert-http-get-status($url as xs:string, $options as element(xdmp-http:options), $status-code)
{
  let $response := helper:http-get($url, $options)
  return
    test:assert-equal($status-code, fn:data($response[1]/*:code))
};

(:~
 : Convenience function to remove all xml docs from the data db
 :)
declare function helper:delete-all-xml() {
  xdmp:eval('for $x in (cts:uri-match("*.xml"), cts:uri-match("*.xlsx"))
             where fn:not(fn:contains($x, "config/config.xml")) 
             return
              try {xdmp:document-delete($x)}
              catch($ex) {()}')
};

declare function helper:wait-for-doc($pattern, $sleep) {
  if (xdmp:eval(fn:concat("cts:uri-match('", $pattern, "')"))) then ()
  else
  (
    xdmp:sleep($sleep),
    helper:wait-for-doc($pattern, $sleep)
  )
};

declare function helper:wait-for-truth($truth as xs:string, $sleep) {
  if (xdmp:eval($truth)) then ()
  else
  (
    xdmp:sleep($sleep),
    helper:wait-for-truth($truth, $sleep)
  )
};

declare function helper:wait-for-taskserver($sleep) {
  (: do the sleep first. on some super awesome computers the check for active
     tasks can return 0 before they have a change to queue up :)
  helper:log(fn:concat("Waiting ", $sleep, " msec for taskserver..")),
  xdmp:sleep($sleep),
  
  let $group-servers := xdmp:group-servers(xdmp:group())
  let $task-server := xdmp:server("TaskServer")[. = $group-servers]
  let $status := xdmp:server-status(xdmp:host(), $task-server)
  let $queue-size as xs:unsignedInt := $status/ss:queue-size
  let $active-requests as xs:unsignedInt := fn:count($status/ss:request-statuses/ss:request-status)
  return
	if ($queue-size = 0 and $active-requests = 0) then (
	  helper:log("Done waiting for taskserver!")
	)
	else
	(
	  helper:wait-for-taskserver($sleep)
	)
};

(:~
 : Convenience function to invoke a sleep
 :)
declare function helper:sleep($msec as xs:unsignedInt) as empty-sequence() {
  xdmp:eval('declare variable $msec as xs:unsignedInt external;
             xdmp:sleep($msec)',
            (xs:QName("msec"), $msec))
};

declare function helper:log($items as item()*)
{
  let $_ := fn:trace($items, "UNIT-TEST")
  return ()
};