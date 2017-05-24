<%@ page import="java.util.*,java.sql.*,act.util.*, java.lang.*, java.text.*, java.math.*"
%><%
	String temp = null;
	String dataSource 	= "jdbc/production";
	String currentDate	= getCurrentDate();
	String defaultDate	= getDefaultDate();
	String fromAddress  = "test@lgbs.com";
	String toAddress	= "duc.nguyen@lgbs.com";
	
	long clientId 		= nvl(request.getParameter("clientId"),0);
	String reportType	= request.getParameter("reportType");
	String from			= nvl(request.getParameter("from"),defaultDate);
	String to			= nvl(request.getParameter("to"),currentDate);
	
	
	try {
		out.println(sendReport(fromAddress, toAddress, dataSource, clientId, from, to, reportType, request));
	} catch (Exception e){
		out.println(e);
	}

%><%!

	class PaymentIssue {
		
		public PaymentIssue(){}
		
		public String clientId 		= null;
		public String account  		= null;
		
		public String transDate 	= null;
		public String method		= null;
		
		public String seq			= null;
		public String tid			= null;
		public String pTid			= null;
		public String status		= null;
		public String paidFlag		= null;
		
		public String name 			= null;
		public Double amount 		= 0.0;
		
		public String reason		= null;
		
	
	}
	
	public String getDuplicatePayments(String dataSource, long clientId, String from, String to) throws Exception{
	
		Connection 				conn 		= null;
		PreparedStatement		ps 			= null;
		ResultSet				rs			= null;
		StringBuffer			buffer		=  new StringBuffer();
		
		String 					reportType	= "duplicate";
		
		buffer.append("<pre>");
		buffer.append("<Strong>&#9679;&nbsp;<u>Duplicate Problem</u></Strong><br><br>");
		buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
	
		
		
		try{
			conn = Connect.open(dataSource);
			try{
			
				ps = conn.prepareStatement("select can as \"Account\", totpaid as \"TotalPaid\","
										  +"	trunc(chngdate) as \"PaymentDate\","
										  +"	count(*) as \"total\" "
										  +" from credit_card_data"
										  +" where client_id = ?"
										  +"	and chngdate > trunc(to_date(?,'yyyy-mm-dd')) and chngdate < trunc(to_date(?,'yyyy-mm-dd'))"
										  +"	and ppstatus in ('AP','RT')"
										  +" group by can, totpaid, trunc(chngdate)"
										  +" having count(*)>1"
										  +" order by trunc(chngdate) desc"
										 );
				ps.setLong(1, clientId);
				ps.setString(2,from);
				ps.setString(3,to);
			
				rs = ps.executeQuery();
				
				
				if(!rs.isBeforeFirst()){
					buffer.setLength(0);
					buffer.append("<pre>");
					buffer.append("<Strong>&#9679;&nbsp;<u>Duplicate Problem</u></Strong><br><br>");
					buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
					buffer.append("There are't any duplicate payments ");
					buffer.append("</pre>");
				}
				
				while(rs.next()){
					buffer.append(TransactionDetail(dataSource, clientId, "", nvl(rs.getString("Account")), nvl(rs.getString("PaymentDate")), nvl(rs.getString("TotalPaid"),0.0), reportType));
		
				}
				buffer.append("</pre>");
			
			} catch (Exception e){
				throw e;
			} 
		
		} catch (Exception e){
			throw e;
		} finally{
			try { conn.close();} catch (Exception ignore){}
			try { ps.close();} catch (Exception ignore){}
			try { rs.close();} catch (Exception ignore){}
		}
	
		return buffer.toString();
	}
	
	public String getPostProblems(String dataSource, Long clientId, String from, String to) throws Exception{
		Connection 		    conn 		= null;
		PreparedStatement   ps 	   		= null;
		ResultSet		    rs 	 		= null;
		StringBuffer	    buffer 		= new StringBuffer();
		
		String 				reportType	= "post";
		
		buffer.append("<pre>");
		buffer.append("<Strong>&#9679;&nbsp;<u>Post Problem</u></Strong><br><br>");
		buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
		
		try {
			conn = Connect.open(dataSource);
			try {
				ps = conn.prepareStatement("select distinct transid as \"TID\" "
										  +" from credit_card_data "
										  +" where client_id = ?"
										  +"	and ppstatus = 'AP'"
										  +"	and paidflag = 'Y'"
										  +"	and chngdate > trunc(to_date(?,'yyyy-mm-dd')) "
										  +"	and chngdate < trunc(to_date(?,'yyyy-mm-dd')) "
										);
				
				ps.setLong(1, clientId);
				ps.setString(2,from);
				ps.setString(3,to);
				
				rs = ps.executeQuery();
				
				if(!rs.isBeforeFirst()) {
					buffer.setLength(0);
					buffer.append("<pre>");
					buffer.append("<Strong>&#9679;&nbsp;<u>Post Problem</u></Strong><br><br>");
					buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
					buffer.append("There aren't any post problems");
					buffer.append("<br></pre>");
				}
				
				while(rs.next()) {
					buffer.append(TransactionDetail(dataSource, clientId, nvl(rs.getString("TID")),"","", 0.0, reportType));
				}
				buffer.append("</pre>");
			
			} catch (Exception e) {
				throw e;
			}
		
		} catch (Exception e){
			throw e;
		} finally{
			try { conn.close();} catch (Exception ignore){}
			try { ps.close();} catch (Exception ignore){}
			try { rs.close();} catch (Exception ignore){}
		}
		
		return buffer.toString();
	
	}
	
	
	public String getTotalPaidProblems(String dataSource, Long clientId, String from, String to) throws Exception {
		Connection 		    conn 		= null;
		PreparedStatement   ps 	   		= null;
		ResultSet		    rs 	 		= null;
		StringBuffer	    buffer 		= new StringBuffer();
		
		String 				reportType	= "totalPaid";
		
		buffer.append("<pre>");
		buffer.append("<Strong>&#9679;&nbsp;<u>Amount Problem</u></Strong><br><br>");
		buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
		
		try {
			conn = Connect.open(dataSource);
			try {
				ps = conn.prepareStatement("select distinct transid as \"TID\" "
										  +" from credit_card_data "
										  +" where client_id = ? "
										  +"	and chngdate > trunc(to_date(?,'yyyy-mm-dd')) "
										  +"	and chngdate < trunc(to_date(?,'yyyy-mm-dd')) "
										  +" group by transid "
										  +" having sum(nvl(ppamount,0))+ min(nvl(fee_amount,0)) != min(totpaid) "
										  );
				
				ps.setLong(1,clientId);
				ps.setString(2,from);
				ps.setString(3,to);
				
				rs = ps.executeQuery();
				if(!rs.isBeforeFirst()) {
					buffer.setLength(0);
					buffer.append("<pre>");
					buffer.append("<Strong>&#9679;&nbsp;<u>Amount Problem</u></Strong><br><br>");
					buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
					buffer.append("There aren't any  mismatch  problems");
					buffer.append("<br></pre>");
				}
				
				while(rs.next()){
					buffer.append(TransactionDetail(dataSource, clientId, nvl(rs.getString("TID")),"","", 0.0, reportType));
				}
				
				buffer.append("</pre>");
				
			} catch (Exception e){
				throw e;
			}
			
		} catch (Exception e){
			throw e;
		} finally{
			try { conn.close();} catch (Exception ignore){}
			try { ps.close();} catch (Exception ignore){}
			try { rs.close();} catch (Exception ignore){}
		}
		
		return buffer.toString();
		
	}
	
	public String getTransIdProblem(String dataSource,Long clientId, String from, String to) throws Exception{
		Connection 		    conn 		= null;
		PreparedStatement   ps 	   		= null;
		ResultSet		    rs 	 		= null;
		StringBuffer	    buffer 		= new StringBuffer();
		
		String 				reportType	= "transid";
		
		buffer.append("<pre>");
		buffer.append("<Strong>&#9679;&nbsp;<u>Transid Problem</u></Strong><br><br>");
		buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
		
		
		
		try {
			conn = Connect.open(dataSource);
			
			
			try {
				
				ps = conn.prepareStatement("select distinct transid as \"TID\" "
										  +" from credit_card_data "
										  +" where client_id = ?"
										  +"	and (credit_sequence not between transid-15 and transid+15) "
										  +"	and chngdate > trunc(to_date(?,'yyyy-mm-dd')) "
										  +"	and chngdate < trunc(to_date(?,'yyyy-mm-dd')) "
										  );
				
				ps.setLong(1,clientId);
				ps.setString(2,from);
				ps.setString(3,to);
				
				rs = ps.executeQuery();
				
				if(!rs.isBeforeFirst()){
					buffer.setLength(0);
					buffer.append("<pre>");
					buffer.append("<Strong>&#9679;&nbsp;<u>Transid Problem</u></Strong><br><br>");
					buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
					buffer.append("There are't any transid problems");
					buffer.append("<br></pre>");
				}
				
				while(rs.next()){
					buffer.append(TransactionDetail(dataSource, clientId, nvl(rs.getString("TID")), "", "", 0.0, reportType));
				}
				
				buffer.append("</pre>");
			
			} catch (Exception e){
				throw e;
			}
		
		} catch (Exception e){
			throw e;
		} finally{
			try { conn.close();} catch (Exception ignore){}
			try { ps.close();} catch (Exception ignore){}
			try { rs.close();} catch (Exception ignore){}
		}
		
		return buffer.toString();
	
	
	}
	
	
	public String getReversalProblem(String dataSource, Long clientId, String from, String to) throws Exception{
		Connection 		    conn 		= null;
		PreparedStatement   ps 	   		= null;
		ResultSet		    rs 	 		= null;
		StringBuffer	    buffer 		= new StringBuffer();
		
		String 				reportType	= "reversal";
		
	
		buffer.append("<pre>");
		buffer.append("<Strong>&#9679;&nbsp;<u>Reversal Problem</u></Strong><br><br>");
		buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
		
		try {
			conn = Connect.open(dataSource);
			
			try {
				ps = conn.prepareStatement("select distinct transid as \"TID\" "
										  +" from credit_card_data "
										  +" where client_id = ?"
										  +"	and (ppstatus = 'IP'or ppstatus = '??')"
										  +"	and chngdate > trunc(to_date(?,'yyyy-mm-dd')) "
										  +"	and chngdate < trunc(to_date(?,'yyyy-mm-dd')) "
										  );
			
				ps.setLong(1,clientId);
				ps.setString(2,from);
				ps.setString(3,to);
				
				rs = ps.executeQuery();
				
				if(!rs.isBeforeFirst()){
					buffer.setLength(0);
					buffer.append("<pre>");
					buffer.append("<Strong>&#9679;&nbsp;<u>Reversal Problem</u></Strong><br><br>");
					buffer.append("<Strong>ClientId: <Strong>"+ clientId+"<br><br>");
					buffer.append("There are't any reversal problems");
					buffer.append("<br></pre>");
				}
				
				while(rs.next()){
					buffer.append(TransactionDetail(dataSource, clientId, nvl(rs.getString("TID")),"","", 0.0, reportType));
				}
				
				buffer.append("</pre>");
			
			
			} catch (Exception e){
				throw e;
			}
		
		} catch (Exception e){
			throw e;
		} finally{
			try { conn.close();} catch (Exception ignore){}
			try { ps.close();} catch (Exception ignore){}
			try { rs.close();} catch (Exception ignore){}
		}
		
	
		return buffer.toString();
	}
	
	public String TransactionDetail(String dataSource, Long clientId, String tid, String can, String date, Double amount, String reportType) throws Exception{
		Connection 				conn 		= null;
		PreparedStatement 		ps 			= null;
		ResultSet		  		rs 			= null;
		StringBuffer			buffer      = new StringBuffer();
		
		BigDecimal				total 		= new BigDecimal("0.00");
		
		try {
			conn = Connect.open(dataSource);
			buffer.append("<br>");
			buffer.append(String.format("%-10s %-25s %-3s %-3s %-20s %-10s %-70s %-10s %s\n",
								   "Tid",
								   "DateTime",
								   "",
								   "",
								   "Account",
								   "Amount",
								   "PTID",
								   "SID",
								   "Name"
								   ));
			buffer.append(String.format("%-10s %-25s %-3s %-3s %-20s %-10s %-70s %-10s %s\n",
								   "--------",
								   "----------------------",
								   "---",
								   "---",
								   "----------",
								   "----------",
								   "------------------------------------------------",
								   "--------",
								   "---------------"
								   ));
			try{
				ps = conn.prepareStatement("select transid as \"TID\","
										  +"	to_char(chngdate, 'MON DD,YYYY HH24:MI AM') as \"DateTime\","
										  +"	trans_type as \"Method\","
										  +"	ppstatus as \"Status\","
										  +"	can as \"Account\","
										  +"	ppamount as \"Amount\","
										  +"	nvl(cyber_order, vendortid) as \"PTID\","
										  +"	credit_sequence as \"SID\","
										  +"	anameline1 as \"Name\" "
										  +" from credit_card_data "
										  +" where client_id = ? "
										  +"	and (transid = ? "
										  +"	or (can = ? "
										  +"	and trunc(chngdate) = CAST(TO_TIMESTAMP( ? , 'YYYY-MM-DD HH24:MI:SS,FF9') AS DATE) "
										  +"	and totpaid = ?))"
										  );
				
				ps.setLong(1, clientId);
				ps.setString(2, tid);
				ps.setString(3, can);
				ps.setString(4, date);
				ps.setDouble(5, amount);
				rs = ps.executeQuery();
				int row = 0;
				
				if(!rs.isBeforeFirst()){
					buffer.append("<br>");
					buffer.setLength(0);
					buffer.append("Transaction is not found with TID: "+tid);
					buffer.append("<br>");
				}
				
				while(rs.next()){
					row++;
					
					total = total.add( new BigDecimal(rs.getString("Amount").replace(",","").trim()));
					buffer.append(String.format("%-10s %-25s %-3s %-3s %-20s %-10s %-70s %-10s %s\n",
								   ((row < 2 || reportType.equals("duplicate")) ? nvl(rs.getString("TID")) :""),
								   ((row < 2 || reportType.equals("duplicate"))  ? nvl(rs.getString("DateTime")):""),
								   nvl(rs.getString("Method")),
								   nvl(rs.getString("Status")),
								   nvl(rs.getString("Account")),
								   nvl(rs.getString("Amount"),0.0),
								   ((row < 2 || reportType.equals("duplicate")) ? nvl(rs.getString("PTID")):""),
								   nvl(rs.getString("SID")),
								   ((row < 2 || reportType.equals("duplicate")) ? nvl(rs.getString("Name")):"")
								   ));
					}
					
					if( row >1 ){
						buffer.append("<br>");
						buffer.append(String.format("%-10s %-25s %-3s %-3s %20s %-10s %-70s %-10s %s\n",
													"",
													"",
													"",
													"",
													"Total:",
													total,
													"",
													"",
													""
													));
					}
				
				buffer.append("<br><hr>");
			
			} catch (Exception e) {
				throw e;
			}
		
		
		} catch (Exception e){
			throw e;
		} finally{
			try { conn.close();} catch (Exception ignore){}
			try { ps.close();} catch (Exception ignore){}
			try { rs.close();} catch (Exception ignore){}
		}
		
		return buffer.toString();
	}
	
	
	public String sendReport(String fromAddress, String toAddress, String dataSource,
									Long clientId, String from, String to, String reportType,
									javax.servlet.http.HttpServletRequest request) throws Exception {
									
									
		StringBuffer	report 		= new StringBuffer();
		String 			duplicate	= null;
		String 			post		= null;
		String 			totalPaid	= null;
		String 			transid		= null;
		String 			reversal	= null;
		
		
		
		try {
			
			report.append("Date: "+ (new java.util.Date()).toString()+"<br>"
								  +"Server: "+  java.net.InetAddress.getLocalHost()+"<br>"
								  +"Page: "+ request.getRequestURL()+"<br>"
								  +"From IP Addr: "+ request.getRemoteAddr()
										+ (request.getRemoteAddr().equals(request.getRemoteHost())? "": "&ndash;"+request.getRemoteHost())+"<br>"
								  +"Database: "+ dataSource+" ("+Connect.getName(dataSource)+")<br><br>"
								  );
			report.append("<h3><Strong>Report From "+ from + " To "+ to + "</Strong></h3><br>");
		
			switch(reportType){
				case "duplicate":
					duplicate = getDuplicatePayments(dataSource, clientId, from, to);
					report.append(duplicate);
					break;
				case "postProblem":
					post = getPostProblems(dataSource, clientId, from, to);
					report.append(post);
					break;
				case "amountProblem":
					totalPaid = getTotalPaidProblems(dataSource, clientId, from, to);
					report.append(totalPaid);
					break;
				case "transidProblem":
					transid = getTransIdProblem(dataSource, clientId, from, to);
					report.append(transid);
					break;
				case "reversalProblem":
					reversal = getReversalProblem(dataSource, clientId, from, to);
					report.append(reversal);
					break;
				case "all":
					duplicate = getDuplicatePayments(dataSource, clientId, from, to);
					post = getPostProblems(dataSource, clientId, from, to);
					totalPaid = getTotalPaidProblems(dataSource, clientId, from, to);
					transid = getTransIdProblem(dataSource, clientId, from, to);
					reversal = getReversalProblem(dataSource, clientId, from, to);
					report.append(duplicate+"<br>"+post+"<br>"
								 +totalPaid+"<br>"+transid+"<br>"
								 +reversal);
					break;
			}
				
		act.util.EMail.sendHtml(fromAddress,toAddress,"",report.toString());
		
		} catch (Exception ignore) {}
		
		return report.toString();
	}
	
	
	
		// //////////////////////////////////////////////////////////////////////
		// Utility/Convenience Methods
		// //////////////////////////////////////////////////////////////////////
		
		public boolean notDefined(String val) { return (val==null || val.length()==0);}
		public String nvl(String val){ return (val == null ? "":val);}
		public String nvl(String val, String def){ return(notDefined(val) ? def:val);}
		public Double nvl(String val, double def){ try{ return Double.parseDouble(val);} catch (Exception e){return def;}}
		public Long nvl(String val, long def) { try{ return Long.parseLong(val);} catch (Exception e) {return def;}}
		public String getCurrentDate(){
			DateFormat df 	= new SimpleDateFormat("yyyy-MM-dd");
			Calendar cal = Calendar.getInstance();
			
			return df.format(cal.getTime());
		}
		public String getDefaultDate(){
			DateFormat df 	= new SimpleDateFormat("yyyy-MM-dd");
			Calendar cal = Calendar.getInstance();
			cal.add(Calendar.DATE,-7);
			
			return df.format(cal.getTime());
		}
		
	

%>