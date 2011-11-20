xquery version "1.0-ml";


import module namespace vp = "http://azathought.com/oneshotter/view/page" at "/view/v-page.xqy";
import module namespace vh = "http://azathought.com/oneshotter/view/home" at "/view/v-home.xqy";
import module namespace vf = "http://azathought.com/oneshotter/view/friends" at "/view/v-friends.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

vp:main-right(
	vh:home(),
	
	vf:friends(),
	
	()
)