var queue = new Array();

$(document).ready(function(){
  
  $.extend($.gritter.options, {
	  position: 'top-right', // possibilities: bottom-left, bottom-right, top-left, top-right
		fade_in_speed: 500, // how fast notifications fade in (string or int)
		fade_out_speed: 300, // how fast the notices fade out
		time: 3000 // hang on the screen for...
	});
	
	// handler for clicking the run tests button
	$("#runtests").click(function(event){		
		run();
	});
	
	// handle for clicking the cancel button
	$("#canceltests").click(function(event){
		cancel();
	});
	
	// handler for toggling the select all checkbox
	$("#checkall").click(function(event){
		$("#tests tbody").find("input.cb").each(function(){
		  $(this).attr("checked", $("#checkall").is(":checked"));
		});
	});
	
	$("input.cb").each(function() {
		if (this.id != "checkall") {
			$(this).click(function(event) {
				var totalBoxes = $("input.cb").length;
				var checkedBoxes = $("input.cb:checked").length;
				if (totalBoxes == checkedBoxes) {
					$("#checkall").attr("checked", true);
				}
				else {
					$("#checkall").attr("checked", false);
				}
			});
		}
	});
	
	$("input.check-all-tests").click(function(event){
	  parentCheck = $(this);
	  parentCheck.parent().next("ul.tests").find("input.test-cb").each(function() {
	    $(this).attr("checked", parentCheck.is(":checked"));
	  });
	  parentCheck.parents("tr").prev("tr").find("input.cb").attr("checked", parentCheck.is(":checked"));
	});
	
  $("input.test-cb").each(function() {
    $(this).click(function(event) {
      var checkAll = $(this).parents("div.tests").find("input.check-all-tests");
      var runTest = $(this).parents("tr").prev("tr").find("input.cb");
      var totalBoxes = $(this).parents("ul.tests").find("input.test-cb").length;
      var checkedBoxes = $(this).parents("ul.tests").find("input.test-cb:checked").length;
      if (totalBoxes == checkedBoxes) {
        checkAll.attr("checked", true);
      }
      else {
        checkAll.attr("checked", false);
      }
      
      runTest.attr("checked", checkedBoxes > 0);
    });
  });

  $("div.test-name").click(function(event) {
    // $(this).toggle();
    $(this).find("img.tests-toggle-minus").toggle();
    $(this).find("img.tests-toggle-plus").toggle();
    $(this).parents("tr").next().find("div.tests").toggle();
  });
  
	$("#runtests").focus();
	
	$(window).keypress(function(event) {
      if (event.keyCode == 13 && event.metaKey) {
        run();
        event.preventDefault();
        return false;
      }
      else if (event.keyCode == 27) {
        cancel();
        event.preventDefault();
        return false;
      }
  });
});

function run() {
  $('tr.result').remove();
  $('span.outcome').text("");
  $('span#passed-count').text("");
  $('span#failed-count').text("");
  $("td.failed").text("-");
  $("td.passed").text("-");
  $('div.failure').remove();

  queue = new Array();
	$("input.cb:checked").each(function(){
		queue.push(this.value);
	});
	

	if (queue.length > 0) {
		$("#failed-count").text("Running...");
		$("#runtests").hide();
		$("#canceltests").show();
		queue.reverse();
		runSuite(queue.pop());
	}	
};

function cancel() {
  queue.length = 0;
	$("#failed-count").text("Stopping tests...");
	$("#canceltests").hide();
};

function runSuite(suite) {
	var check = $("input:checked[value='" + suite + "']");
	var parent = check.parents("tr");
	var tests = [];
	parent.next().find("input.test-cb:checked").each(function() {
	  tests.push($(this).val());
	});

	parent.addClass('running');
	
	var suiteTearDown = $("#runsuiteteardown").prop("checked");
	var tearDown = $("#runteardown").prop("checked");
	var spinner = parent.find("span.spinner");
	spinner.show();
  
	$.ajax({
		url: "run",
		data: {
		  suite: suite,
		  tests: tests.join(","),
		  runsuiteteardown: suiteTearDown,
		  runteardown: tearDown
		},
		dataType: "xml",
		success: function(data) {
			suiteSuccess(parent, data);
		},
		error: function(data) {
			suiteFailure(parent, data);
		}
	});
}

function suiteSuccess(parent, xml) {
  var suite = $("[nodeName='t:suite']", xml);
  var runCount = suite.attr('total');
  var passedCount = suite.attr('passed');
  var failedCount = suite.attr('failed');

  // var errors = [];
  suite.find("[nodeName = 't:test']").each(function() {
    var name = $(this).attr("name");
    var type = "success";
    var errors = [];
    
    var results = $(this).find("[nodeName = 't:result']");
    results.each(function() {
      if ($(this).attr("type") != "success") {
        type = $(this).attr("type");
        var error = $(this).children();
        if (error.length <= 0) {
          error = $(this).text();
        }
        errors.push(error);
      }
      
    });

    span = parent.next().find('input[value = "' + name + '"]').next('span.outcome');
    
    span.text(type == "success" ? "Passed" : "Failed");
    span.removeClass("success");
    span.removeClass("fail");
    span.addClass(type);
    
    if (type != "success") {
      for (var i = errors.length; i--;) {
        var error = errors[i];
        span.after(renderError(error));
      }
    
      span.next().find("img.plus").click(function(event) {
          $(this).hide();
          $(this).next("img.minus").show();
          $(this).nextAll("div.stack").show();
        });

      span.next().find("img.minus").click(function(event) {
         $(this).hide();
          $(this).prev("img.plus").show();
          $(this).nextAll("div.stack").hide();
        });

    }
  });
  parent.removeClass('running');
  
  parent.find("td.tests-run").text(runCount);
  parent.find("td.passed").text(passedCount);
  parent.find("td.failed").text(failedCount > 0 ? failedCount : '');

	var spinner = parent.find("span.spinner");
	spinner.hide();
	
	runNextTest();
}

function suiteFailure(parent, data) {
	parent.after($(data).find("dl"));	
	var spinner = parent.find("span.spinner");
	spinner.hide();
	
	runNextTest();
}

function runNextTest() {
	if (queue.length > 0) {
		runSuite(queue.pop());
	}
	else {
		// compute total pass/fails
    var totalFails = 0;
    $('td.failed').each(function(){
      fails = parseInt($(this).text(), 10);
      
      if (isNaN(fails)) {
        fails = 0;
      }
      totalFails += fails;
    });

		var totalPasses = 0;
		$('td.passed').each(function() {
		  passes = parseInt($(this).text(), 10);
		  if (isNaN(passes)) {
        passes = 0;
      }
      totalPasses += passes;
		});
		
		var passedText = (totalFails > 0) ? totalPasses : "all";
		passedText += " passed";
		$("#passed-count").text(passedText);
		
		if (totalFails > 0) {
			$("#failed-count").text(totalFails + " failed");
		}
		else {
			$("#failed-count").text("");
		}

		$("#canceltests").hide();
		$("#runtests").show();
		
		var txt = "";
		if (totalPasses > 0 && totalFails <= 0) {
		  txt = '<span class="success">All Passed</span>';
		}
		else if (totalPasses > 0 && totalFails > 0) {
		  txt = '<span class="success">Passed: ' + totalPasses + '</span><span class="failed">Failed: ' + totalFails + '</span>';
		}
		else if (totalPasses <= 0 && totalFails > 0) {
		  txt = '<span class="failed">TOTAL FAILURE!</span>';
		}
		else {
		  txt = '<span class="failed">NO TESTS RUN</span>';
		}
  	$.gritter.add({
  		title: 'Tests finished',
  		text: txt,
  		sticky: false,
  		time: ''
  	});

	}
}

function renderError(error) {
  result =
  '<div class="failure">' + 
    '<div class="test-name">Fail</div>' + 
    '<div class="test-data">';

  if (typeof(error[0]) == 'string') {
    result += '<p>' + error + '</p>';
  }
  else {
    var formatString = error.find("[nodeName = 'error:code']").text() + ': (' + error.find("[nodeName = 'error:name']").first().text() + ') ' + error.find("[nodeName = 'error:expr']").text();
    if (error.find("[nodeName = 'error:code']").text() != error.find("[nodeName = 'error:message']").text()) {
      formatString += ' -- ' + error.find("[nodeName = 'error:message']").text();
    }
    
    
    var datum = error.find("[nodeName = 'error:datum']").children();
    if (datum.length <= 0) {
      datum = '';
    }
  
    if (formatString && formatString.length > 0) {
      result += '<p>' + formatString + '</p>';
    }

    result +=
      '<div>' + datum + '</div>' + 
      '<div class="call-stack-container">' + 
        '<span>Call Stack:</span>' +
        '<img class="plus" src="_img/icon-plus.png"/>' +
        '<img class="minus" src="_img/icon-minus.png" style="display:none"/>' +
        '<div class="stack" style="display:none">';
      
    error.find("[nodeName = 'error:frame']").each(function() {
      var uri = $(this).find("[nodeName = 'error:uri']").text();
      var line = $(this).find("[nodeName = 'error:line']").text();
      var operation = $(this).find("[nodeName = 'error:operation']").text();
      var variables = $(this).find("[nodeName = 'error:variable']");
      result +=
      '<div class="frame"><p class="bold">in ' + uri + ' on line ' + line + ',</p>' +
         '<p>in ' + operation.replace(/</g, "&lt;").replace(/>/g, "&gt;") + '</p>';
         
         if (variables.length > 0) {
           result += '<ul class="variables"><u>variables:</u>';
       
           variables.each(function() {
             var name = $(this).find("[nodeName = 'error:name']").text();
             var value = $(this).find("[nodeName = 'error:value']").text();
             result += '<li>' + name + ' = ' + value.replace(/</g, "&lt;").replace(/>/g, "&gt;") + '</li>';
           });
         }       
      result +=
         '</ul>' +
      '</div>';
    });
  
    result +=
        '</div>' +
      '</div>';
  }
  
  result += 
  '</div>' +
  '</div>';
  
  return $(result);
}