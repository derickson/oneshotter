xquery version "1.0-ml";

module namespace vh = "http://azathought.com/oneshotter/view/home";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function vh:home() {

	<div id="home">
		<a class="app-button" href="/game/new">+ Create New Game</a>
		{
			for $game in fn:collection("games")
			order by xs:dateTime($game//*:modified) descending
			return
			<div>
				<h3>{$game//*:name/text()}</h3>
				<a href="/game/{$game//*:id/text()}">(link)</a>
			</div>
		}
		
		<script type="text/javascript" src="/js/ko/home.js"></script>
	</div>
	
};