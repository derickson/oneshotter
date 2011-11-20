xquery version "1.0-ml";

(:import module namespace test="http://marklogic.com/ps/test" at "/test/unit-test.xqy";:)

import module namespace cvt = "http://marklogic.com/cpf/convert" 
      at "/MarkLogic/conversion/convert.xqy";

import module namespace helper="http://marklogic.com/ps/test-helper" at "/test/test-helper.xqy";

declare namespace dir = "http://marklogic.com/xdmp/directory";
declare namespace error = "http://marklogic.com/xdmp/error";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace t="http://marklogic.com/ps/test";

declare variable $FS-PATH  as xs:string := 
    if(xdmp:platform() eq "winnt") then "\" else "/";

declare option xdmp:mapping "false";

(:~
 : Returns a list of the available tests. This list is magically computed based on the modules
 :)
declare function t:list() {
  let $suite-ignore-list := (".svn", "CVS", "sample-test", "_img", "_js")
  let $test-ignore-list := (".svn", "CVS", "setup.xqy", "teardown.xqy", "suite-setup.xqy", "suite-teardown.xqy")
  return
    element t:tests {
      let $db-id as xs:unsignedLong := xdmp:modules-database()
      let $root as xs:string := xdmp:modules-root()
      let $suites as xs:string* := 
        if ($db-id = 0) then
          xdmp:filesystem-directory(fn:concat($root, $FS-PATH, "test/suites"))/dir:entry[dir:type = "directory" and fn:not(dir:filename = $suite-ignore-list)]/dir:filename
        else
          let $uris := 
            try {
              xdmp:eval('cts:uri-match("/test/suites/*")', (), <options xmlns="xdmp:eval"><database>{$db-id}</database></options>)
            }
            catch($ex) {
              xdmp:eval('xdmp:directory("/test/suites/", "infinity")/xdmp:node-uri(.)', (), <options xmlns="xdmp:eval"><database>{$db-id}</database></options>)
            }
          return
            fn:distinct-values(
              for $uri in $uris
              let $path := fn:replace(cvt:basepath($uri), "/test/suites/?", "")
              where $path ne "" and fn:not($path = $suite-ignore-list) 
              return
                $path)
      for $suite as xs:string in $suites
      let $tests as xs:string* :=
        if ($db-id = 0) then
          xdmp:filesystem-directory(fn:concat($root, $FS-PATH, "test/suites/", $suite))/dir:entry[dir:type = "file" and fn:not(dir:filename = $test-ignore-list)]/dir:filename[fn:ends-with(., ".xqy") and fn:not(fn:starts-with(., "_"))]
        else
          let $uris :=
            try {
              xdmp:eval(fn:concat('cts:uri-match("/test/suites/', $suite, '/*")'), (), <options xmlns="xdmp:eval"><database>{$db-id}</database></options>)
            }
            catch($ex) {
              xdmp:eval(fn:concat('xdmp:directory("/test/suites/', $suite, '/", "infinity")/xdmp:node-uri(.)'), (), <options xmlns="xdmp:eval"><database>{$db-id}</database></options>)
            }
          return
            fn:distinct-values(
              for $uri in $uris
              let $path := fn:replace($uri, fn:concat("/test/suites/", $suite, "/"), "")
              where $path ne "" and fn:not($path = $test-ignore-list) and fn:ends-with($path, ".xqy") and fn:not(fn:starts-with($path, "_"))
              return
                $path)
      where $tests
      return
        element t:suite {
          attribute path { $suite },
          element t:tests {
            for $test in $tests
            return
              element t:test {
                attribute path { $test }
              }
          }
        }
    }
};

declare function t:run-suite($suite as xs:string, $tests as xs:string*, $run-suite-teardown as xs:boolean, $run-teardown as xs:boolean) {
  let $results :=
    element t:run {
      helper:log(" "),
      helper:log(text {"SUITE:", $suite}),
      try {
        helper:log(" - invoking suite setup"),
        xdmp:invoke(fn:concat("suites/", $suite, "/suite-setup.xqy"))
      }
      catch($ex) {if ($ex//error:code = ("SVC-FILOPN", "XDMP-TEXTNODE", "XDMP-MODNOTFOUND")) then () else helper:log($ex)},
  
      helper:log(" - invoking tests"),

      let $tests as xs:string* :=
        if ($tests) then $tests
        else
          t:list()/t:suite[@path = $suite]/t:tests/t:test/@path
      for $test in $tests
      return
        t:run($suite, $test, fn:concat("suites/", $suite, "/", $test), $run-teardown),
  
      if ($run-suite-teardown eq fn:true()) then
        try {
          helper:log(" - invoking suite teardown"),
          xdmp:invoke(fn:concat("suites/", $suite, "/suite-teardown.xqy"))
        }
        catch($ex) {if ($ex//error:code = ("SVC-FILOPN", "XDMP-TEXTNODE", "XDMP-MODNOTFOUND")) then () else helper:log($ex)}
      else helper:log(" - not running suite teardown"),
      helper:log(" ")
    }
  return
    element t:suite {
      attribute name { $suite },
      attribute total { fn:count($results/t:test/t:result) },
      attribute passed { fn:count($results/t:test/t:result[@type = 'success']) },
      attribute failed { fn:count($results/t:test/t:result[@type = 'fail']) },
      $results
    }
};

declare function t:run($suite as xs:string, $name as xs:string, $module, $run-teardown as xs:boolean) {
  element t:test {
    attribute name { $name },

    helper:log(text { "    TEST:", $name }),
    try {
      helper:log("   ...invoking setup"),
      let $_ := xdmp:invoke(fn:concat("suites/", $suite, "/setup.xqy"))
      return ()
    }
    catch($ex) {if ($ex//error:code = ("SVC-FILOPN", "XDMP-TEXTNODE", "XDMP-MODNOTFOUND")) then () else helper:log($ex)},

    try {
      helper:log("    ...running"),
      xdmp:invoke($module)
    }
    catch($ex) {
      helper:fail($ex)
    },
    
    if ($run-teardown eq fn:true()) then
      try {
        let $_ := helper:log("    ...invoking teardown")
        let $_ := xdmp:invoke(fn:concat("suites/", $suite, "/teardown.xqy"))
        return ()
      }
      catch($ex) {if ($ex//error:code = ("SVC-FILOPN", "XDMP-TEXTNODE", "XDMP-MODNOTFOUND")) then () else helper:log($ex)}
    else helper:log("    ...not running teardown")
  }  
};

declare function local:run() {
  let $suite := xdmp:get-request-field("suite")
  let $tests := fn:tokenize(xdmp:get-request-field("tests", ""), ",")[. ne ""]
  let $run-suite-teardown as xs:boolean := xdmp:get-request-field("runsuiteteardown", "") eq "true"
  let $run-teardown as xs:boolean := xdmp:get-request-field("runteardown", "") eq "true"
  let $format as xs:string := xdmp:get-request-field("format", "xml")
  return
    if ($suite) then
      t:run-suite($suite, $tests, $run-suite-teardown, $run-teardown)
    else ()
};

declare function local:list()
{
  t:list()
};

(:~
 : Provides the UI for the test framework to allow selection and running of tests
 :)
declare function local:main() {
  xdmp:set-response-content-type("text/html"),
  let $app-server := xdmp:server-name(xdmp:server())
  return
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>{$app-server} Unit Tests</title>
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <link rel="stylesheet" type="text/css" href="/test/_css/tests.css" />
        <link rel="stylesheet" type="text/css" href="/test/_css/jquery.gritter.css" />
        <script type="text/javascript" src="/test/_js/jquery-1.6.2.min.js"></script>
        <script type="text/javascript" src="/test/_js/jquery.gritter.min.js"></script>
        <script type="text/javascript" src="/test/_js/tests.js"></script>
      </head>
      <body>
        <div id="warning">
          <img src="_img/warning.png" width="30" height="30"/>BEWARE OF DOG: Unit tests will wipe out your data!!<img src="_img/warning.png" width="30" height="30"/>
          <div id="db-info">Current Database: <span>{xdmp:database-name(xdmp:database())}</span></div>
        </div>
        <div id="overview">
          <h2>{$app-server} Unit Tests:<span id="passed-count"/><span id="failed-count"/></h2>
        </div>
        <table cellspacing="0" cellpadding="0" id="tests">
          <thead>
            <tr>
              <th><input id="checkall" type="checkbox" checked="checked"/>Run</th>
              <th>Test Suite</th>
              <th>Total Test Count</th>
              <th>Tests Run</th>
              <th>Passed</th>
              <th>Failed</th>
            </tr>
          </thead>
        
          <tbody>
          {
            for $suite at $index in t:list()/t:suite
            let $class := if ($index mod 2 = 1) then "odd" else "even"
            return
            (
              <tr class="{$class}">
                <td class="left"><input class="cb" type="checkbox" checked="checked" value="{fn:data($suite/@path)}"/></td>
                <td>
                  <div class="test-name">
                    <img class="tests-toggle-plus" src="_img/arrow-right.gif"/>
                    <img class="tests-toggle-minus" src="_img/arrow-down.gif"/>
                    {fn:data($suite/@path)} <span class="spinner"><img src="_img/spinner.gif"/><b>Running...</b></span>
                  </div>

                </td>
                <td>{fn:count($suite/t:tests/t:test)}</td>
                <td class="tests-run">-</td>
                <td class="passed">-</td>
                <td class="right failed">-</td>
              </tr>,
              <tr class="{$class}">
                <td colspan="6">
                <div class="tests">
                  <div class="wrapper"><input class="check-all-tests" type="checkbox" checked="checked"/>Run All Tests</div>
                  <ul class="tests">
                  {
                    for $test in $suite/t:tests/t:test
                    return
                      <li class="tests"><input class="test-cb" type="checkbox" checked="checked" value="{fn:data($test/@path)}"/>{fn:string($test/@path)}<span class="outcome"></span></li>
                  }
                  </ul>
                </div>
                </td>
              </tr>
            
            )
          }
          </tbody>
        </table>
        <table cellspacing="0" cellpadding="0" >
          <thead>
            <tr>
              <th>Options</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><label for="runsuiteteardown">Run Teardown after each suite</label><input id="runsuiteteardown" type="checkbox" checked="checked"/></td>
            </tr>
            <tr>
              <td><label for="runteardown">Run Teardown after each test</label><input id="runteardown" type="checkbox" checked="checked"/></td>
            </tr>
          </tbody>
        </table>
        <input id="runtests" class="button" type="submit" value="Run Tests" title="(ctrl-enter) works too!"/>
        <input id="canceltests" class="button" type="submit" value="Cancel Tests" title="(Cancel key) works too!"/>
        <p class="render-time">Page Rendered in: {xdmp:elapsed-time()}</p>
      </body>
    </html>
};

let $func := xdmp:function(xs:QName(fn:concat("local:", xdmp:get-request-field("func", "main"))))
return
  xdmp:apply($func)