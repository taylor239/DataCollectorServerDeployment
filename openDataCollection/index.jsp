<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, com.datacollector.*, java.sql.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Catalyst Endpoint Data Collection</title>
</head>
<body>
<div align="center">
<h1>Welcome to the Catalyst Data Collection Engine!</h1>
<table width="60%">
<tr>
<td>
<h2>About Catalyst Data Collection</h2>
</td>
</tr>
<tr>
<td>
<p>
In computer science, and particularly in computer security, humans often
play a huge role in achieving various goals.  For instance, a human might
classify data manually to train machine learning or use various types of
security tools in order to compromise a server.  Understanding this
symbiosis of human and machine allows researchers to determine the limits
of what the combination might accomplish.  This, in the examples above,
has the potential to quantify the resources needed to train machine
learning models or how potent a given attack might be.
</p>
<p>
Capture the flag (CTF) style events have become increasingly popular
events for recruitment, training, evaluation, and recreation in the field
of computer security.
Although it may be used in a variety of research areas, the Catalyst Data
Collection Extreme Endpoint Monitoring System (CDC) is
designed to aid in conducting research to understand and evaluate
efficacy of methods, tools, and strategies in computer security, as well as
evaluate training efforts and individuals' and teams' ability within the
area of computer security.  It does this by monitoring what individuals do
within CTF style events.  In order to
analyze the combination of human and computer action, CDC records local
system resources on a participant's device while the participant
completes tasks.  While CDC is built into several engines, such as
<a href="http://revenge.cs.arizona.edu">RevEngE</a>, the version hosted here
works alongside external event completion engines&mdash;software which hosts
and monitors users completing tasks.  As an example of such an engine,
a computer security capture-the-flag competition monitors users as they
complete computer security tasks, such as decrypting encrypted
communications.  CDC's role in this is to collect data which shows what
participants do while completing the tasks in the engine.
</p>
<p>
CDC collects human input to devices and data showing the state of the device.
In particular, CDC collects:
<ol>
<li>Mouse Input</li>
<li>Keyboard Input</li>
<li>Device Processes</li>
<li>Device Displays</li>
<li>Task Data</li>
</ol>
Depending on the particular event, this data is either streamed to a data
aggregation point in real time, or participants must manually activate the
upload after completing the event.
</p>
<p>
The terms of use, including compliance with applicable laws, are issued on
a per-event basis.  To continue using CDC as a participant, select your
event below.  For those interested in using CDC for their own event, please <a href="login.jsp">
sign up or login here</a>.  If you are already signed in, you can navigate directly to your <a href="home.jsp">home page</a>.  As a final note, <b>never install
CDC software on any device you will use outside of your event.  Always install
the software on virtualized devices, such as virtual machines.  If this software is used on a device, it
will record sensitive data, including passwords, the user enters on that
device.  The software does include a pause feature to stop collection while entering sensitive data,
but enter that data at your own risk.</b>
</p>
<p>
For more information about the inspiration for Catalyst, see <a href="Getting_Revenge.pdf">Getting RevEngE: A System for Analyzing Reverse Engineering Behavior</a>.
</p>
</td>
</tr>
<%
boolean publicEvents = false;
String admin = request.getParameter("admin");
if(admin == null || admin.isEmpty())
{
	publicEvents = true;
	admin = "cgtboy1988@yahoo.com";
}
%>
<tr>
<td>
<%
if(publicEvents)
{
	%>
	Showing public events because no event administrator was specified.<br>
	<%
}
else
{
	%>
	Showing events for <%=admin %>.<br>
	<%
}
%>
Please select your event from the list below:
</td>
</tr>
<tr>
<td>
<select name="event" form="eventform">
<option value="none">Select here</option>
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
String query = "SELECT * FROM `openDataCollectionServer`.`Event` WHERE `adminEmail` = ? AND `publicEvent` = 1";
try
{
	PreparedStatement queryStmt = dbConn.prepareStatement(query);
	queryStmt.setString(1, admin);
	ResultSet myResults = queryStmt.executeQuery();
	while(myResults.next())
	{
		String event = myResults.getString("event");
		%>
		<option value="<%=event %>"><%=event %></option>
		<%
	}
}
catch(Exception e)
{
	e.printStackTrace();
}

%>
</select>
<form action="event.jsp" id="eventform">
<input type="submit" value="Submit">
<input type="hidden" name="admin" value="<%=admin %>">
</form>
</td>
</tr>
</table>
</div>
</body>
</html>