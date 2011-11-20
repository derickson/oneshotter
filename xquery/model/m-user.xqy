xquery version "1.0-ml";

(:	m-model.xqy
	Model for User
:)

module namespace mu = "http://www.marklogic.com/ps/model/user";

declare option xdmp:output 'indent=no';

(: constructor :)
declare function mu:user($oauth_token_data) as element(mu:user) {
	element mu:user {
		element mu:display_name {map:get($oauth_token_data,"name")},
		element mu:username {map:get($oauth_token_data,"name")},
		element mu:token{ map:get($oauth_token_data, "access_token")   },
		element mu:id {map:get($oauth_token_data,"id")},
		element mu:name {map:get($oauth_token_data,"name")},
		element mu:first_name {map:get($oauth_token_data,"first_name")},
		element mu:last_name {map:get($oauth_token_data,"last_name")},
		element mu:link {map:get($oauth_token_data,"link")},
		element mu:gender {map:get($oauth_token_data,"gender")},
		element mu:picture {fn:concat("http://graph.facebook.com/", map:get($oauth_token_data,"id"), "/picture" )}
		
	}
};

declare function mu:login-update($existing-user as element(mu:user)?, $user as element(mu:user))  as element(mu:user) {
	if($existing-user) then
		element mu:user {
			$existing-user/mu:display_name,
			$user/node()[ fn:not( fn:local-name( . ) = "display_name") ]		
		}
	else
		$user
};

declare function mu:get-display-name($user as element(mu:user)) as xs:string? {
	$user//mu:display_name/text()
};

declare function mu:get-user-name($user as element(mu:user)) as xs:string? {
	$user//mu:username/text()
};

declare function mu:get-user-pic-src($user as element(mu:user)) as xs:string? {
	$user//mu:picture/text()
};

declare function mu:get-user-auth-token($user as element(mu:user)) as xs:string? {
	$user//mu:token/text()
};

declare function mu:get-user-id($user as element(mu:user)) as xs:string? {
	$user//mu:id/text()
};

declare function mu:get-user-doc-by-id($id as xs:string?) as element(mu:user)? {
	/mu:user[mu:id eq $id]
};

declare function mu:get-user-doc($user as element(mu:user)) as element(mu:user)? {
	mu:get-user-doc-by-id(mu:get-user-id($user))
};
