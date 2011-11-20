xquery version "1.0-ml" ;

(:  l-security.xqy
    Utility library for security functions
:)

module namespace ls = "http://www.marklogic.com/ps/lib/security";

import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";

declare variable $USER_SESSION_FIELD := "user-session-field";

(:  Check whether or not their is an active session.  
    An active session indicates that a user is logged in
:)
declare function ls:has-active-session() as xs:boolean {
    if(ls:get-session-user()) then
        fn:true()
    else
        fn:false()
};

(:  Remove all session variables :)
declare function ls:kill-current-session() {
    for $field in xdmp:get-session-field-names()
    return
        xdmp:set-session-field($field, ()),
        
    xdmp:set-session-field($USER_SESSION_FIELD, ())
};

declare function ls:refresh-session() {
	ls:set-session-user(ls:get-database-user-same-as-session())
};

declare function ls:get-database-user-same-as-session() as element(mu:user) {
	mu:get-user-doc-by-id(mu:get-user-id(ls:get-session-user()))
};

(:  Get the user model XML which is stored in a session variable to represent the user's session :)
declare function ls:get-session-user() as element(mu:user)? {
    xdmp:get-session-field($USER_SESSION_FIELD, ())
};

(:  Save the user's session object :)
declare function ls:set-session-user($user as element(mu:user)) {
    xdmp:set-session-field($USER_SESSION_FIELD, $user)
};



