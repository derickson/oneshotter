xquery version "1.0-ml";

module namespace vf = "http://azathought.com/oneshotter/view/friends";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";
import module namespace cf = "http://azathought.com/oneshotter/controller/friends" at "/controller/c-friends.xqy";


declare default element namespace "http://www.w3.org/1999/xhtml";

declare function vf:friends() {
	let $friends := cf:get-friends()
	return
		<div id="friends">
		<h2>Friends on {$cfg:APP_NAME}</h2>
		{
			for $friend in $friends/cf:friend[cf:uses-this-app eq "true"]
			return (
				<div id="picture">
					<img src="{$friend/cf:picture/text()}" alt="Picture of {$friend/cf:name/text()}"/>
				</div>,
				<div id="name">
					{
						$friend/cf:display-name/text(),
						if(xs:boolean($friend/cf:uses-this-app/text() )) then (
							<br/>,
							<span class="appuser">{$cfg:APP_NAME} user</span>
						) else (
							<br/>,
							<a href="#">Send invite</a>
						)
					}
				</div>
			),
			
			if(fn:not($friends/cf:friend[cf:uses-this-app eq "true"])) then
				<span class="italic">None</span>
			else (),
			
			
			<br class="clear"/>
			
			
		}	
		</div>
};