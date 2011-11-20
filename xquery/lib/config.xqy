xquery version "1.0-ml" ;

(:	config.xqy
	This library module holds configuration variables for the application
:)

module	namespace cfg = "http://www.marklogic.com/ps/lib/config";

(:	The rewrite library route configuration
	Installed to /lib/rewrite
	For documentation see: https://github.com/dscape/rewrite 
:)
declare variable $ROUTES :=
	<routes>
		<root>home#get</root>
		<get path="page/login"><to>page#login</to></get>
		<get path="page/badlogin"><to>page#badlogin</to></get>
		<get path="logout"><to>auth#logout</to></get>
		<get path="facebook"><to>auth#facebook</to></get>
		<get path="account"><to>page#account</to></get>
		<get path="agent"><to>useragent#get</to></get>
		
		<get path="account/revoke"><to>update#revoke</to></get>
		<get path="json/account"><to>account#get-account</to></get>
		<post path="json/account"><to>account#post-account</to></post>
		
		<get path="game/new"><to>game#new</to></get>
		<get path="game/:id"><to>game#get</to></get>
		<get path="json/game/new"><to>game#json-get-new</to></get>
		<post path="json/game/new"><to>game#json-post-new</to></post>
		
		
		<ignore>^/test</ignore>
	</routes>;

declare variable $OAUTH2_CONFIG :=
	<oauth_config>
		<provider name="facebook">
			<id>239412919454212</id>
			<secret>67ec259dd7013e5e0d21201d1f506d4f</secret>
			<access_token_url>https://graph.facebook.com/oauth/access_token</access_token_url>
			<authorize_url>https://www.facebook.com/dialog/oauth</authorize_url>
			<redirect_url>http://oneshotter.com/facebook</redirect_url>
			<scope>scope=user_events,create_event,offline_access,rsvp_event,publish_actions</scope>
		</provider>
	</oauth_config>;

declare variable $DATABASE 		:= "oneshot";
declare variable $TEST_ENABLED 	:= fn:true();
declare variable $SHORT_NAME	:= "OneShotter";
declare variable $PROJECT_NAME 	:= "OneShotter.com";
declare variable $APP_NAME		:= "OneShotter.com";
declare variable $SUBTITLE 		:= "Plan One-Shot Games with Friends";