xquery version "1.0-ml";

(:
	Return layout page
:)

module namespace vp = "http://azathought.com/oneshotter/view/page";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/lib/config.xqy";
import module namespace ls = "http://www.marklogic.com/ps/lib/security" at "/lib/l-security.xqy";
import module namespace mu = "http://www.marklogic.com/ps/model/user" at "/model/m-user.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare option xdmp:output "indent=no";

declare variable $doctype := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';


declare function vp:main-right($main, $right, $title as xs:string?) {
	vp:output(
		(
			<div id="main">{$main}</div>,
			<div id="right">{$right}</div>,
			<br id="clear"/>
		),
		$title
	)
};

declare function vp:one-column($center, $title as xs:string?) {
	vp:output(
		(
			<div id="center">
			{
				$center
			}
			</div>
		),
		$title
	)
	
};

declare function vp:two-column($left, $right, $title as xs:string?){
	vp:output(
		(
			<div id="leftcolumn">
				{$left} 
			</div>,
			<div id="content">
			{
				$right
			}
			</div>
		),
		$title
	)
};





declare function vp:output($content,$title as xs:string?){
	
	let $iphone := fn:contains(fn:lower-case(xdmp:get-request-header("User-Agent")),"iphone")
	let $android := fn:contains(fn:lower-case(xdmp:get-request-header("User-Agent")),"android")
	let $mobile := $iphone or $android
	return (
	
	xdmp:set-response-content-type("text/html; charset=UTF-8"), 
	$doctype,
	<html xml:lang="en" lang="en" xmlns="http://www.w3.org/1999/xhtml">
	
		<head>
			<meta name="description" content="Conspiracy tracker"></meta>
			<meta name="ROBOTS" content="NOINDEX, NOFOLLOW"/>
			<meta http-equiv="Content-Style-Type" content="text/css"></meta>
			<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></meta>
			{
				if($mobile) then
					<meta name="viewport" content="width=device-width, initial-scale=1.0" />
				else
					()
			}
		    
			<title>{if($iphone) then $cfg:SHORT_NAME else $cfg:PROJECT_NAME}</title>
			
			<link rel="icon" type="image/png" href="/img/oneshotter-icon.png"/>
			<link rel="apple-touch-icon" href="/img/oneshotter-icon.png"/>  
			
			<link type="text/css"  title="default" rel="stylesheet" href="/css/reset.css"/>
			<link type="text/css"  title="default" rel="stylesheet" href="/css/text.css"/>
			<link type="text/css"  title="default" rel="stylesheet" href="/css/ui-lightness/jquery-ui-1.8.14.custom.css"/>
			
			<!--link rel="stylesheet" href="/css/screen.css" media="screen"/-->
			{
				if($mobile) then
					<link rel="stylesheet" href="/css/handheld.css"/>
				else
					<link type="text/css"  title="default" rel="stylesheet" href="/css/screen.css"/>
			}
			
			<script type="text/javascript" src="/js/jquery-1.5.2.min.js"></script>
			<script type="text/javascript" src="/js/jquery-ui-1.8.14.custom.min.js"></script>
			<script type="text/javascript" src="/js/highcharts/highcharts.js"></script>
			<script type='text/javascript' src='/js/jquery.tmpl.js'></script>
			<script type='text/javascript' src='/js/knockout-1.3.0beta.js'></script>
			
			<script type="text/javascript" src="/js/app.js"></script>
			<script type="text/javascript" src="/js/tracking.js"></script>
			
		</head>
	
		<body>
			<div class="pagewidth">
				<div id="header">
					<div id="banner">
						<a href="/"><img id="bannerpic" src="/img/oneshotter.png" alt="{$cfg:PROJECT_NAME}"/></a><br/>
						<span id="subtitle">{$cfg:SUBTITLE}</span>
					</div>
					<div id="whoami">
					{
						for $user in ls:get-session-user()
						return
						(
							
							if($mobile) then (
								<div id="picture">
									<a href="/account">
										<img src="{mu:get-user-pic-src($user)}"/>
									</a>
								</div>
							)
							else (
								<div id="picture"><img alt="Account Pic" src="{mu:get-user-pic-src($user)}"/></div>,
								<div id="welcome">
									{if(fn:not($mobile)) then (<span>Welcome {mu:get-display-name($user)}</span>,<br/>) else ()}
									<div id="links"><a href="/account">Account</a> | <a href="/logout">Logout</a></div>
								</div>
							),
							<br class="clear"/>
						) 
					}
					</div>
					<br class="clear"/>
				</div>
				<hr/>
				<div id="body">
					<h2>{$title}</h2>
					{$content}
				</div>
				<hr/>
				<div id="footer">
					<div id="like">
						<iframe src="http://www.facebook.com/plugins/like.php?href=http://oneshotter.com"
								scrolling="no" frameborder="0"
								style="border:none; width:450px; height:80px"></iframe>
					</div>
					<div id="powered">
						Powered by MarkLogic Server<br/>
						© 2011 oneshotter.com <a href="mailto:azathought@gmail.com">Contact</a>
					</div>
					<br class="clear"/>
				</div>
			</div>
		</body>
	
	</html>
	
	)
	
};



