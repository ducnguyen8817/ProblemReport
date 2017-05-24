<html>
<head>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
</head>
<body>
<div class = "container">
<form id = "problemReport" action ="report.jsp" method="post">
<label for="clientId">ClientId:</label>
<select name = "clientId">
<option value="">Select</option>
<option value = '94000000'>94000000</option>
<option value = '147000000'>147000000</option>
</select>
<label for="reportType">ReportType:</label>
<select name = "reportType">
<option value="">Select</option>
<option value="duplicate">DuplicatePayment</option>
<option value="postProblem">PostProblem</option>
<option value="amountProblem">PaymentAmountProblem</option>
<option value="transidProblem">TransIdProblem</option>
<option value="reversalProblem">ReversalProblem</option>
<option value="all">All</option>
</select>
<label for="from">From: </label>
<input type = "date" name = "from"/>
<label for="to">To: </label>
<input type = "date" name = "to"/>
<button type="submit">Submit</button>
</form>
</div>
<div id="notice" style="color:red">
</div>
<div id="result">
</div>
<script type="text/javascript">
	$("#problemReport").submit(function(event){
		var value = $(this).serialize();
		event.preventDefault();
		url = $(this).attr('action');
		var posting = $.post(url, value);
		$("#notice").html("Sending... Please wait...");
		posting.done(function(res){
			$("#problemReport")[0].reset();
			$("#notice").html("Sent successfully");
			setTimeout(function(){
				$("#notice").html("");
			},1000);
			$("#result").html(res);
			
			
		});
		posting.fail(function(err){
			console.log(err);
		});
		
});
</script>

</body>
</html>