<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="org.apache.commons.lang3.StringEscapeUtils, java.net.*, java.util.ArrayList, com.datacollector.*, java.sql.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<%
Class.forName("com.mysql.jdbc.Driver");
DatabaseConnector myConnector=(DatabaseConnector)session.getAttribute("connector");
if(myConnector==null)
{
	myConnector=new DatabaseConnector(getServletContext());
	session.setAttribute("connector", myConnector);
}
TestingConnectionSource myConnectionSource = myConnector.getConnectionSource();

Connection dbConn = myConnectionSource.getDatabaseConnection();
String event = request.getParameter("event");
String admin = request.getParameter("admin");
String query = "SELECT * FROM `openDataCollectionServer`.`Event` INNER JOIN `openDataCollectionServer`.`EventContact` ON `openDataCollectionServer`.`Event`.`event` = `openDataCollectionServer`.`EventContact`.`event` WHERE `openDataCollectionServer`.`Event`.`event` = ? AND `openDataCollectionServer`.`Event`.`adminEmail` = ? AND `publicEvent` = 1";
String desc = "";
String start = "";
String end = "";
boolean publicEvent = false;
boolean publicData = false;
boolean dynamicToken = false;
ArrayList contactName = new ArrayList();
ArrayList contacts = new ArrayList();

String requestedToken = request.getParameter("token");
String requestedEmail = request.getParameter("email");
if(requestedEmail == null)
{
	requestedEmail = "anonymous";
}
String requestedName = request.getParameter("name");
if(requestedName == null)
{
	requestedName = "anonymous";
}

try
{
	PreparedStatement queryStmt = dbConn.prepareStatement(query);
	queryStmt.setString(1, event);
	queryStmt.setString(2, admin);
	ResultSet myResults = queryStmt.executeQuery();
	if(!myResults.next())
	{
		return;
	}
	publicEvent = myResults.getInt("publicEvent") == 1;
	publicData = myResults.getInt("public") == 1;
	dynamicToken = myResults.getInt("dynamicTokens") == 1;
	desc = myResults.getString("description");
	start = myResults.getString("start");
	end = myResults.getString("end");
	admin = myResults.getString("adminEmail");
	contactName.add(myResults.getString("name"));
	contacts.add(myResults.getString("contact"));
	while(myResults.next())
	{
		contactName.add(myResults.getString("name"));
		contacts.add(myResults.getString("contact"));
	}
}
catch(Exception e)
{
	e.printStackTrace();
}
boolean failed = false;
boolean insertedRequest = false;
if((!dynamicToken) && publicEvent && requestedToken != null && !requestedToken.equals(""))
{
	insertedRequest = true;
	try
	{
		String requestInsert = "INSERT INTO `TokenRequest`(`event`, `adminEmail`, `requestedUsername`, `requesterName`, `requesterEmail`) VALUES (?,?,?,?,?)";
		
		PreparedStatement requestStmt = dbConn.prepareStatement(requestInsert);
		requestStmt.setString(1, event);
		requestStmt.setString(2, admin);
		requestStmt.setString(3, StringEscapeUtils.escapeHtml4(requestedToken).replaceAll(",", "").replaceAll("\"", ""));
		requestStmt.setString(4, StringEscapeUtils.escapeHtml4(requestedName).replaceAll("\"", ""));
		requestStmt.setString(5, StringEscapeUtils.escapeHtml4(requestedEmail).replaceAll("\"", ""));
		requestStmt.execute();
	}
	catch(Exception e)
	{
		failed = true;
		e.printStackTrace();
	}
}

if(dynamicToken && requestedToken != null && !requestedToken.equals(""))
{
	insertedRequest = true;
	try
	{
		String requestInsert = "INSERT INTO `UserList`(`event`, `adminEmail`, `username`, `name`, `email`) VALUES (?,?,?,?,?)";
		
		PreparedStatement requestStmt = dbConn.prepareStatement(requestInsert);
		requestStmt.setString(1, event);
		requestStmt.setString(2, admin);
		requestStmt.setString(3, StringEscapeUtils.escapeHtml4(requestedToken).replaceAll(",", "").replaceAll("\"", ""));
		requestStmt.setString(4, StringEscapeUtils.escapeHtml4(requestedName).replaceAll("\"", ""));
		requestStmt.setString(5, StringEscapeUtils.escapeHtml4(requestedEmail).replaceAll("\"", ""));
		requestStmt.execute();
	}
	catch(Exception e)
	{
		failed = true;
		e.printStackTrace();
	}
}

%>
<title><%=event %></title>
</head>
<body>
<div align="center">
<h1><%=event %></h1>

<%
if(publicEvent)
{
%>
<table width="60%">
<%
if(insertedRequest)
{
%>
<tr>
<td>
<%
if(!dynamicToken && !failed)
{
%>
<h5>Your token request was added.  You may request additional tokens.</h5>
<%
}
else if (!failed)
{
%>
<h5>Your token was added and is available to use.</h5>
<%
}
else
{
%>
<h5>Your token request failed.</h5>
<%
}
%>
</td>
</tr>
<%
}
%>
<tr>
<td>
<h2>Want to participate but don't have a token?</h2>
<p>
Anyone may request to participate in this event, so you can ask the organizer for a token by filling out this form.
</p>
</td>
</tr>
<tr>
<td>
<h4>Your Name</h4>
</td>
</tr>
<tr>
<td>
<input type="hidden" id="event" name="event" value="<%=event %>" form="tokenrequestform">
<input type="hidden" id="admin" name="admin" value="<%=admin %>" form="tokenrequestform">
<input type="text" id="name" name="name" form="tokenrequestform">
</td>
</tr>
<tr>
<td>
<h4>Your Email</h4>
</td>
</tr>
<tr>
<td>
<input type="text" id="email" name="email" form="tokenrequestform">
</td>
</tr>
<tr>
<td>
<h4>Desired Token</h4>
</td>
</tr>
<tr>
<td>
<input type="text" id="token" name="token" form="tokenrequestform">
</td>
</tr>
<tr>
<td>
<form action="getToken.jsp" id="tokenrequestform">
<input type="submit" value="Submit">
</form>
</td>
</tr>
</table>
<%
}
%>
</div>
</body>
</html>