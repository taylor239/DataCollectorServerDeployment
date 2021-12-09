<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, com.datacollector.*, java.sql.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Catalyst Endpoint Data Collection</title>
</head>
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

if(request.getParameter("email") != null)
{
	session.removeAttribute("admin");
	session.removeAttribute("adminName");
	String adminEmail = request.getParameter("email");
	if(request.getParameter("password") != null)
	{
		String password = request.getParameter("password");
		if(request.getParameter("name") != null)
		{
			String adminName = request.getParameter("name");
			String signupQuery = "INSERT INTO `openDataCollectionServer`.`Admin`(`adminEmail`, `adminPassword`, `name`) VALUES (?, ?, ?)";
			try
			{
				PreparedStatement loginStmt = dbConn.prepareStatement(signupQuery);
				loginStmt.setString(1, adminEmail);
				loginStmt.setString(2, password);
				loginStmt.setString(3, adminName);
				loginStmt.execute();
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}
		String loginQuery = "SELECT * FROM `openDataCollectionServer`.`Admin` WHERE `adminEmail` = ? AND `adminPassword` = ?";
		try
		{
			PreparedStatement queryStmt = dbConn.prepareStatement(loginQuery);
			queryStmt.setString(1, adminEmail);
			queryStmt.setString(2, password);
			ResultSet myResults = queryStmt.executeQuery();
			if(myResults.next())
			{
				session.setAttribute("admin", myResults.getString("adminEmail"));
				session.setAttribute("adminName", myResults.getString("name"));
			}
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	}
}
%>
<body>
<div align="center">
<h1>Welcome to the Catalyst Data Collection Engine!</h1>
<table width="60%">
<tr>
<td>
<h2>Administrator Home</h2>
</td>
</tr>
<%
if(session.getAttribute("admin") == null)
{
	%>
	<tr>
	<td>
	<p>
	Login or signup unsuccessful.  Return to <a href="login.jsp">login page.</a>
	</p>
	</td>
	</tr>
	<%
}
else
{
%>
	<tr>
	<td>
	<h3>
	Welcome Back <%=session.getAttribute("adminName") %>
	</h3>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	Catalyst data collection is organized by administrator (keyed on administrator email) and event.  Each event has participants, each of whom you assign a token.  Participants can either navigate to your current event page to selct their event or individual event pages directly.  Once on an individual event page, participants enter their token, select their environment, and download the installer for their event.  Once they run the installer, their endpoint data will be streamed to this server, where you can use our visualization and analysis tools or export that data directly.  No additional setup is necessary for your participants beyond running the installer.
	</p>
	<p>
	The public page for your current events is located <a href="index.jsp?admin=<%=session.getAttribute("admin") %>">here.</a>  To share that page or event pages linked there, navigate to that page and copy the URL in your browser's address bar.
	</p>
	</td>
	</tr>
<%
String admin = (String)session.getAttribute("admin");
%>
	<tr>
	<td>
	<h3>
	<a href="index.jsp">Catalyst Home Page</a>
	</h3>
	</td>
	</tr>
<tr>
<td>
<h3>
Current Events
</h3>
</td>
</tr>
<tr>
<td>
Please select an event to view from the list below:
</td>
</tr>
<tr>
<td>
<select name="event" form="eventform">
<option value="none">Select here</option>
<%
String query = "SELECT * FROM `openDataCollectionServer`.`Event` WHERE `adminEmail` = ?";
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
<form action="viewEvent.jsp" id="eventform">
<input type="submit" value="Submit">
</form>
</td>
</tr>
<tr>
<td>
<h3>
Create New Event
</h3>
</td>
</tr>
<tr>
<td>
<h4>Event Name</h4>
</td>
</tr>
<tr>
<td>
<input type="hidden" id="newevent" name="newevent" value="newevent" form="createform">
<input type="text" id="eventname" name="eventname" form="createform">
</td>
</tr>
<tr>
<td>
<h4>Start Date</h4>
</td>
</tr>
<tr>
<td>
<input type="date" id="startdate" name="startdate" form="createform">
</td>
</tr>
<tr>
<td>
<h4>End Date</h4>
</td>
</tr>
<tr>
<td>
<input type="date" id="enddate" name="enddate" form="createform">
</td>
</tr>
<tr>
<td>
<h4>Event Password</h4>
</td>
</tr>
<tr>
<td>
<p>This field is used for external access to the event's data, for instance by a web application.</p>
<input type="password" id="eventpassword" name="eventpassword" form="createform">
</td>
</tr>
<tr>
<td>
<h4>Description</h4>
</td>
</tr>
<tr>
<td>
<textarea name="description" id="description" form="createform" style="width:100%;"></textarea>
</td>
</tr>
<tr>
<td>
<h4>Make Data Public?</h4>
</td>
</tr>
<tr>
<td>
<input type="checkbox" id="public" name="public" value="public" form="createform">
</td>
</tr>
<tr>
<td>
<h4>Make Event Public?</h4>
</td>
</tr>
<tr>
<td>
<p>
By making your event public, anyone can request a token to participate.
</p>
<input type="checkbox" id="publicevent" name="publicevent" value="publicevent" form="createform">
</td>
</tr>
<tr>
<td>
<h4>Autoapprove Tokens?</h4>
</td>
</tr>
<tr>
<td>
<p>
If your event is public, this will automatically approve all token requests.
</p>
<input type="checkbox" id="autoapproveevent" name="autoapproveevent" value="autoapproveevent" form="createform">
</td>
</tr>
<tr>
<td>
<h4>Tokens</h4>
</td>
</tr>
<tr>
<td>
<textarea name="tokens" id="tokens" form="createform" style="width:100%;">Use comma separated alphanumeric/punctuation values such as "0001, abcd, !ab3".</textarea>
</td>
</tr>
<tr>
<td>
<h4>Event Contact</h4>
</td>
</tr>
<tr>
<td>
<p>
This info will appear at the bottom of your event page.  On your edit page, you can add more contact entries later, but you are required to have at least one.
</p>
<p>
Name
</p>
<textarea name="contactname" id="contactname" form="createform" style="width:100%;">Typically, this field includes first and last names.</textarea>
<p>
Contact Info
</p>
<textarea name="contactcontact" id="contactcontact" form="createform" style="width:100%;">Typically email or phone number or website address.</textarea>
</td>
</tr>
<tr>
<td>
<h4>Upload Server</h4>
</td>
</tr>
<tr>
<td>
<p>
This is the address participants' data collection will upload to.  The default value is to this server.  If you deploy this server elsewhere or want to run a custom server to receive the data, change this value, otherwise leave it as the default and the data will be available on this server.
</p>
<input type="text" id="eventserver" name="eventserver" form="createform" value="ws://revenge.cs.arizona.edu/DataCollectorServer/UploadData">
</td>
</tr>
<tr>
<td>
<form action="viewEvent.jsp" id="createform">
<input type="submit" value="Submit">
</form>
</td>
</tr>
<%
}
%>
</table>
</div>
</body>
</html>