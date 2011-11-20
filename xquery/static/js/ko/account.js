




$(document).ready(function() {
	
	$("#save").click(function(e) {
		e.preventDefault();
		var postData = {"displayName": $("#displayName").val() } ;
		$.ajax({
			type: "POST",
			url: "/json/account",
			data: JSON.stringify( postData ),
			success: function() {
				window.location = "/account";
			},
			contentType: "application/json",
			//dataType: 'json'
		});
	});
	
	$.ajax({
		url: "/json/account",
		data: null,
		async: false,
		success: function(data) {
			var dn = $("#displayName");
			dn.val(data.displayName); 
		},
		dataType: "json"
	});
});