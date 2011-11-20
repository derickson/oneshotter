xquery version "1.0-ml";

module namespace vg = "http://azathought.com/oneshotter/view/game";

import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";

declare namespace json = "http://marklogic.com/json";
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function vg:game($id as xs:string) {
	let $game := /*:object[*:id eq $id]
	return
	<div class="game" id="game">
		
		<table>
			<tr>
				<td><label for="name">Name:&nbsp;</label></td>
				<td>{$game//json:name/text()}</td>
			</tr>
			<tr>
				<td><label for="GM">GM:&nbsp;</label></td>
				<td>
				{
					let $owner := $game//json:ownerid/text()
					let $gm := mu:get-user-doc-by-id($owner)
					return (
						<span>{$gm/mu:display_name/text()}&nbsp;</span>,
						<img src="{$gm/mu:picture/text()}" alt="Picture of {$gm/mu:display_name/text()}"/>
					)
				}
				</td>
			</tr>
		</table>
		<input type="hidden" id="ownerid" value="{}"/>
		<p><a class="app-button" href="/">&larr; Back to Home</a></p>
		
	</div>
};

declare function vg:new() {

	<div class="entry" id="game">
		
		<div class="error" id="error"></div>
		<table>
			<tr>
				<td><label for="name">Name:&nbsp;</label></td>
				<td><input name="name" id="name" type="text" size="40"/></td>
			</tr>
			<tr>
				<td><label for="GM">GM:&nbsp;</label></td>
				<td><input class="disabled" name="GM" id="GM" type="text" disabled="true"/></td>
			</tr>
		</table>
		<input type="hidden" id="ownerid"/>
		<a class="app-button" id="save">Save</a>
		
		<script type="text/javascript" src="/js/ko/game.js"></script>
	</div>
	
};