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
<table width="60%">
<tr>
<td>
Event Starts: <%=start %>
</td>
</tr>
<tr>
<td>
Event Ends: <%=end %>
</td>
</tr>
<tr>
</tr>
<tr>
<td>
<script>
function updateLink()
{
	var osSelect = document.getElementById('devicetypeform').value;
	var ext = "sh";
	if(osSelect.match("win"))
	{
		ext = "bat";
	}
	document.getElementById('installScriptLink').href='./installDataCollection.' + ext + '?event=<%=java.net.URLEncoder.encode(event, "UTF-8") %>&admin=<%=java.net.URLEncoder.encode(admin, "UTF-8") %>&username=' + document.getElementById('tokenform').value + '&devicetype=' + document.getElementById('devicetypeform').value;
	document.getElementById('installScriptLink2').href='./installDataCollection.' + ext + '?event=<%=java.net.URLEncoder.encode(event, "UTF-8") %>&admin=<%=java.net.URLEncoder.encode(admin, "UTF-8") %>&username=' + document.getElementById('tokenform').value + '&devicetype=' + document.getElementById('devicetypeform').value;
}
</script>
<h2>Download Data Collection</h2>
<%
if(publicData)
{
%>
<p>
Note that, at present time, the data from this study will be available to the public and may be published.
Anyone, including yourself, will be able to query this data.  The organizers may close this data access at any time.
</p>
<%
}
%>
<p>
If you do not wish to participate in this study, please close this page.  If you
consent to all terms on this page and listed where you got the link thereto, enter your event token here:
</p>
<p>
<input type="text" name="token" id="tokenform" value="Token" onKeyUp="updateLink()">
<input type="button" name="setButton" id="tokenform" value="Set" onclick="updateLink()">
</p>
<p>
Select your device type:
</p>
<p>
<select name="deviceType" id="devicetypeform" onchange="updateLink()">
<option value="debvm">Debian-based Virtual Machine</option>
<option value="debrpi">Debian-based Raspberry PI</option>
<option value="fedvm">Fedora-based Virtual Machine(Broken at the moment)</option>
<option value="winvm">Windows-based Virtual Machine(Beta)</option>
</select>
</p>
<p>
<a id="installScriptLink2" href="./installDataCollection.sh?event=<%=java.net.URLEncoder.encode(event, "UTF-8") %>" download>Download Installer</a>
</p>
<h2>How to Stop Data Collection</h2>
<p>
If you wish to stop your participation at any point, follow the instructions below.
If you would like to have your data collected thus far removed as well, contact
the system admins, listed below.
</p>
</td>
</tr>
</table>
<table width="60%">
<tr>
<td>
<h2>Who should I contact with questions and/or concerns about the study?</h2>
<p>
<ul>
<%
for(int x=0; x<contactName.size(); x++)
{
%>
<li><%=contactName.get(x) %>: <%=contacts.get(x) %></li>
<%
}
%>
</ul>
</p>
</td>
</tr>
</table>
</div>
</body>
</html>