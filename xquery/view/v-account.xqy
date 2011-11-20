xquery version "1.0-ml";

(:
	Render function for the account page
:)

module namespace va = "http://azathought.com/oneshotter/view/account";

import module namespace vp = "http://azathought.com/oneshotter/view/page" at "/view/v-page.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";

import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare option xdmp:output "indent=no";


(:	Render function :)
declare function va:account() {
	let $_ := ls:refresh-session()
	let $content := 
		(
			<a class="app-button" href="/">&larr; Back to Home</a>,
			<div id="account">
				<div class="actionbox">
					<a class="app-button" href="/account/revoke">Delete my {$cfg:APP_NAME} Account</a> <br/>
					<p>
						<ul class="bullets">
							<li>Revoke this application's ability to access your Facebook account</li>
							<li>Disable your ability to log into {$cfg:APP_NAME}</li>
							<li>Delete's your personal information from this website</li>
						</ul>
						Games and Characters you have created through this website will continue
						to exist and will be recoverable if you log in again.
					</p>
				</div>
				
				<div class="actionbox">
				
					<h3>Account Settings</h3>
					<p>
						Display name: <input id="displayName" name="displayName" class="text" size="20"></input>&nbsp; 
						<input id="save" style="height: 25px;" type="submit" class="app-button" value="Save"></input>
					</p>
				
					<script type="text/javascript" src="/js/ko/account.js"></script>
				</div>
				
				
				<br class="clear"/>
				
				
			</div>
		)

		

	return
		vp:one-column($content, "Account")	
};