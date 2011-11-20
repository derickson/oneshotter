
function validateAndSave() {
	var name = $("#name").val();
	var gm = $("#GM").val();
	var ownerid = $("#ownerid").val();
	
	if(name == "" || name == null) {
		$("#error").html("Please choose a name for this game.");
	} else {
		$("#error").html("");
		var postData = {"name": name, "GM": gm, "ownerid": ownerid } ;
		$.ajax({
			type: "POST",
			url: "/json/game/new",
			data: JSON.stringify( postData ),
			success: function(r) {
				window.location = "/game/" + r ;
			},
			contentType: "application/json"
		});
	}
}

$(document).ready(function() {

	$("#save").click(function(e){
		e.preventDefault();
		validateAndSave();
	});

	$.ajax({
		type: "get",
		url: "/json/game/new",
		data: null,
		async: false,
		success: function(data) {
			$("#name").val(data.name);
			$("#GM").val(data.GM); 
			$("#ownerid").val(data.ownerid);
		},
		dataType: "json"
	});

});