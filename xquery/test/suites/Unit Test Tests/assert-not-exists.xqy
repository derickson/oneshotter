import module namespace test="http://marklogic.com/ps/test-helper" at "/test/test-helper.xqy";

declare function local:case1()
{
  test:assert-not-exists("a")
};

test:assert-not-exists(()),
test:assert-throws-error(xdmp:function(xs:QName("local:case1")), "ASSERT-EXISTS-FAILED")