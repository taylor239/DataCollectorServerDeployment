<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, java.util.HashMap, com.datacollector.*, java.sql.*"%>
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

String eventName = request.getParameter("event");

if(request.getParameter("email") != null)
{
	session.removeAttribute("admin");
	session.removeAttribute("adminName");
	String adminEmail = request.getParameter("email");
	if(request.getParameter("password") != null)
	{
		String password = request.getParameter("password");
		
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

if(session.getAttribute("admin") != null)
{
boolean newEvent = request.getParameter("newevent") != null && request.getParameter("newevent").equals("newevent");
String newEventName = request.getParameter("eventname");
if(newEventName != null)
{
	eventName = newEventName;
}
String newStartDate = request.getParameter("startdate");
String newEndDate = request.getParameter("enddate");
String newPassword = request.getParameter("eventpassword");
String newDescription = request.getParameter("description");
boolean newPublic = request.getParameter("public") != null && request.getParameter("public").equals("public");
boolean newPublicEvent = request.getParameter("publicevent") != null && request.getParameter("publicevent").equals("publicevent");
String newTokens = request.getParameter("tokens");
String newServer = request.getParameter("eventserver");
String contactName = request.getParameter("contactname");
String contactContact = request.getParameter("contactcontact");
String contactNameRemove = request.getParameter("contactnameremove");

ArrayList requesterName = new ArrayList();
ArrayList requesterEmail = new ArrayList();
if(request.getParameter("approverequests") != null)
{
String requesterQuery = "SELECT * FROM `TokenRequest` WHERE `event` = ? AND `adminEmail` = ?";
String deleteRequestQuery = "DELETE FROM `TokenRequest` WHERE `event` = ? AND `adminEmail` = ? AND `requestedUsername` = ?";
try
{
	PreparedStatement queryStmt = dbConn.prepareStatement(requesterQuery);
	queryStmt.setString(2, (String)session.getAttribute("admin"));
	queryStmt.setString(1, eventName);
	ResultSet myResults = queryStmt.executeQuery();
	PreparedStatement deleteStmt = dbConn.prepareStatement(deleteRequestQuery);
	deleteStmt.setString(1, eventName);
	deleteStmt.setString(2, (String)session.getAttribute("admin"));
	while(myResults.next())
	{
		if(myResults.getString("requestedUsername") != null)
		{
			if(request.getParameter(myResults.getString("requestedUsername")).equals("accept"))
			{
				if(newTokens == null)
				{
					newTokens = myResults.getString("requestedUsername");
				}
				else
				{
					newTokens += "," + myResults.getString("requestedUsername");
				}
				requesterName.add(myResults.getString("requestedName"));
				requesterEmail.add(myResults.getString("requestedEmail"));
				deleteStmt.setString(3, myResults.getString("requestedUsername"));
				deleteStmt.execute();
			}
			else if(request.getParameter(myResults.getString("requestedUsername")).equals("deny"))
			{
				deleteStmt.setString(3, myResults.getString("requestedUsername"));
				deleteStmt.execute();
			}
		}
	}
	deleteStmt.close();
	queryStmt.close();
}
catch(Exception e)
{
	e.printStackTrace();
}
}

String[] newTokenList = {};
if(newTokens != null && !newTokens.equals(""))
{
	newTokens = newTokens.replaceAll("\\s", "");
	newTokenList = newTokens.split(",");
}

String removeTokens = request.getParameter("removeTokens");
String[] removeTokenList = {};
if(removeTokens != null && !removeTokens.equals(""))
{
	removeTokens = removeTokens.replaceAll("\\s", "");
	removeTokenList = removeTokens.split(",");
}
boolean deleteData = request.getParameter("deletedata") != null && request.getParameter("deletedata").equals("deletedata");


String insertEvent = "INSERT INTO `Event`(`event`, `start`, `end`, `description`, `continuous`, `taskgui`, `password`, `adminEmail`, `public`, `publicEvent`) VALUES (?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE `event` = VALUES(`event`), `start` = VALUES(`start`), `end` = VALUES(`end`), `description` = VALUES(`description`), `continuous` = VALUES(`continuous`), `taskgui` = VALUES(`taskgui`), `password` = VALUES(`password`), `adminEmail` = VALUES(`adminEmail`), `public` = VALUES(`public`), `publicEvent` = VALUES(`publicEvent`)";
if(newEventName != null && !newEventName.equals("") && newDescription != null && !newDescription.equals(""))
{
try
{
	PreparedStatement insertStmt = dbConn.prepareStatement(insertEvent);
	insertStmt.setString(1, newEventName);
	insertStmt.setString(2, newStartDate);
	insertStmt.setString(3, newEndDate);
	insertStmt.setString(4, newDescription);
	insertStmt.setString(5, newServer);
	insertStmt.setString(6, "-taskgui");
	insertStmt.setString(7, newPassword);
	insertStmt.setString(8, (String)session.getAttribute("admin"));
	insertStmt.setBoolean(9, newPublic);
	insertStmt.setBoolean(10, newPublicEvent);
	insertStmt.execute();
	insertStmt.close();
}
catch(Exception e)
{
	e.printStackTrace();
}
}

if(contactName != null && !contactName.equals(""))
{
String insertContact = "INSERT INTO `EventContact`(`event`, `adminEmail`, `name`, `contact`) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE `event` = VALUES(`event`), `adminEmail` = VALUES(`adminEmail`), `name` = VALUES(`name`), `contact` = VALUES(`contact`)";
try
{
	PreparedStatement insertStmt = dbConn.prepareStatement(insertContact);
	insertStmt.setString(1, newEventName);
	insertStmt.setString(2, (String)session.getAttribute("admin"));
	insertStmt.setString(3, contactName);
	insertStmt.setString(4, contactContact);
	insertStmt.execute();
	insertStmt.close();
	
}
catch(Exception e)
{
	e.printStackTrace();
}
}

if(contactNameRemove != null && !contactNameRemove.equals(""))
{
String contactCount = "SELECT COUNT(*) AS `theCount` FROM `openDataCollectionServer`.`Event` INNER JOIN `openDataCollectionServer`.`EventContact` ON `openDataCollectionServer`.`Event`.`event` = `openDataCollectionServer`.`EventContact`.`event` WHERE `openDataCollectionServer`.`Event`.`event` = ? AND `openDataCollectionServer`.`Event`.`adminEmail` = ? AND `publicEvent` = 1";
String insertContact = "DELETE FROM `EventContact` WHERE `event` = ? AND `adminEmail` = ? AND `name` = ?";
try
{
	PreparedStatement insertStmt = dbConn.prepareStatement(contactCount);
	insertStmt.setString(1, newEventName);
	insertStmt.setString(2, (String)session.getAttribute("admin"));
	ResultSet curResults = insertStmt.executeQuery();
	int curCount = 0;
	if(curResults.next())
	{
		curCount = curResults.getInt("theCount");
	}
	insertStmt.close();
	if(curCount > 1)
	{
		insertStmt = dbConn.prepareStatement(insertContact);
		insertStmt.setString(1, newEventName);
		insertStmt.setString(2, (String)session.getAttribute("admin"));
		insertStmt.setString(3, contactNameRemove);
		insertStmt.execute();
		insertStmt.close();
	}
}
catch(Exception e)
{
	e.printStackTrace();
}
}

if(newTokenList.length > 0)
{
String insertToken = "INSERT INTO `UserList`(`event`, `adminEmail`, `username`, `name`, `email`) VALUES (?,?,?,?,?)";
try
{
	int rowCount=0;
	for(int x=1; x<newTokenList.length; x++)
	{
		insertToken += ",(?,?,?,?,?)";
		rowCount++;
	}
	PreparedStatement insertStmt = dbConn.prepareStatement(insertToken);
	for(int x=0; x<newTokenList.length; x++)
	{
		insertStmt.setString(5*x+1, newEventName);
		insertStmt.setString(5*x+2, (String)session.getAttribute("admin"));
		insertStmt.setString(5*x+3, newTokenList[x]);
		insertStmt.setString(5*x+4, (String)requesterName.get(x));
		insertStmt.setString(5*x+5, (String)requesterEmail.get(x));
	}
	insertStmt.execute();
	insertStmt.close();
}
catch(Exception e)
{
	e.printStackTrace();
}
}

if(removeTokenList.length > 0)
{

String removeToken = "DELETE FROM `UserList` WHERE `event`= ? AND`adminEmail` = ? AND `username` = ?";
String removeUpload = "DELETE FROM `UploadToken` WHERE `event` = ? AND `adminEmail` = ? AND `username` = ?";

try
{
	//System.out.println(insertToken);
	PreparedStatement removeStmt = dbConn.prepareStatement(removeToken);
	PreparedStatement deleteStmt = dbConn.prepareStatement(removeUpload);
	for(int x=0; x<removeTokenList.length; x++)
	{
		removeStmt.setString(1, newEventName);
		removeStmt.setString(2, (String)session.getAttribute("admin"));
		removeStmt.setString(3, removeTokenList[x]);
		removeStmt.execute();
		if(deleteData)
		{
			deleteStmt.setString(1, newEventName);
			deleteStmt.setString(2, (String)session.getAttribute("admin"));
			deleteStmt.setString(3, removeTokenList[x]);
			deleteStmt.execute();
		}
	}
	removeStmt.close();
	deleteStmt.close();
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
<h2><%=eventName %></h2>
</td>
</tr>
<%
String selectTotalEvent = "SELECT * FROM `Event` WHERE `event` = ? AND `adminEmail` = ?";

String startDate = "";
String endDate = "";
String password = "";
String description = "";
String serverName = "";
boolean publicEvent = false;
boolean publicPublic = false;
try
{
	PreparedStatement selectStatement = dbConn.prepareStatement(selectTotalEvent);
	selectStatement.setString(1, eventName);
	selectStatement.setString(2, (String)session.getAttribute("admin"));
	ResultSet myResults = selectStatement.executeQuery();
	
	if(!myResults.next())
	{
		session.setAttribute("admin", null);
	}
	else
	{
		startDate = myResults.getString("start");
		endDate = myResults.getString("end");
		password = myResults.getString("password");
		description = myResults.getString("description");
		serverName = myResults.getString("continuous");
		publicEvent = myResults.getInt("publicEvent") == 1;
		publicPublic = myResults.getInt("public") == 1;
	}
}
catch(Exception e)
{
	e.printStackTrace();
}

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
	//event.jsp?event=TestEvent
	String admin = (String)session.getAttribute("admin");
%>
	<tr>
	<td>
	<h3>
	<a href="event.jsp?event=<%=eventName %>&admin=<%=admin %>">Event Page</a>
	</h3>
	</td>
	</tr>
	<tr>
	<td>
	<h3>
	<a href="home.jsp">Administrator Home</a>
	</h3>
	</td>
	</tr>
	<tr>
	<td>
	<h3>
	Participants
	</h3>
	</td>
	</tr>
	<tr>
	<td>
	<%
String query = "SELECT COUNT(DISTINCT `username`) AS `usercount`, `username` FROM `openDataCollectionServer`.`UploadToken` WHERE `adminEmail` = ? AND `event` = ? GROUP BY `username`";
try
{
	PreparedStatement queryStmt = dbConn.prepareStatement(query);
	queryStmt.setString(1, admin);
	queryStmt.setString(2, eventName);
	ResultSet myResults = queryStmt.executeQuery();
	int totalUsers = 0;
	int totalDownloads = 0;
	HashMap userMap = new HashMap();
	while(myResults.next())
	{
		int userCount = myResults.getInt("usercount");
		String username =  myResults.getString("username");
		userMap.put(username, userCount);
		totalUsers++;
		totalDownloads += userCount;
	}
	queryStmt.close();
	query = "SELECT COUNT(DISTINCT `session`) AS `sessioncount`, `username` FROM `openDataCollectionServer`.`User` WHERE `adminEmail` = ? AND `event` = ? GROUP BY `username` ";
	queryStmt = dbConn.prepareStatement(query);
	queryStmt.setString(1, admin);
	queryStmt.setString(2, eventName);
	myResults = queryStmt.executeQuery();
	int totalSession = 0;
	while(myResults.next())
	{
		int sessionCount = myResults.getInt("sessioncount");
		totalSession += sessionCount;
	}
	queryStmt.close();
	
	query = "SELECT `username` FROM `openDataCollectionServer`.`UserList` WHERE `adminEmail` = ? AND `event` = ?";
	queryStmt = dbConn.prepareStatement(query);
	queryStmt.setString(1, admin);
	queryStmt.setString(2, eventName);
	myResults = queryStmt.executeQuery();
	int tokensAvailable = 0;
	while(myResults.next())
	{
		String username =  myResults.getString("username");
		if(!userMap.containsKey(username))
		{
			tokensAvailable++;
		}
	}
	queryStmt.close();
	%>
	<p> A total of <%=totalUsers %> participants downloaded data collection for this event <%=totalDownloads %> times. Those users ran the software for a total of <%=totalSession %> distinct sessions. There are <%=tokensAvailable %> tokens not in use. </p>
	<p> To get a json of taken tokens with number of times downloaded per token, go <a href="tokensTaken.json?event=<%=eventName %>">here</a>. To get a csv of available tokens, go <a href="tokensAvailable.csv?event=<%=eventName %>">here</a>. To get a json of available tokens, go <a href="tokensAvailable.json?event=<%=eventName %>">here</a>.</p>
	<%
}
catch(Exception e)
{
	e.printStackTrace();
}

%>
	</td>
	</tr>
	<tr>
	<td>
	<h3>
	Data
	</h3>
	</td>
	</tr>
	<tr>
	<td>
	<h4>
	<a href="logExport.json?event=<%=eventName %>&datasources=keystrokes,mouse,processes,windows,events&normalize=none">Log JSON Export</a>
	</h4>
	<p>
	A JSON export of the data, structured according to the "normalize" argument as described below.
	</p>
	<h4>
	<a href="logExport.zip?event=<%=eventName %>&datasources=keystrokes,mouse,processes,windows,events,screenshots&normalize=none">Zip Export</a>
	</h4>
	<p>
	A zip version of the export which, additionally, has image files and relative paths to them in the json for screenshots if "screenshots" is specified.
	</p>
	<p>
	Note that these links can be customized with parameters for various purposes.  "email" and "password" can be passed to log you in as you do the export, which is helpful for uses which do no manage a session.
	Additionally, different parameters can be used to filter and limit the data set, allowing for smaller data size.  Those parameters are as follows:
	</p>
	<ul>
		<li>
		<b>"normalize"</b> determines the format of the data export.
			<ul>
			<li><b>none</b> categorizes the data first based on the user, second based on the user session, and third based on data type.  The data within a single type is sorted according to its index.</li>
			<li><b>data</b></li> merges all of the data categories in <b>none</b>, sorted according to time.
			<li><b>session</b> merges all sessions in <b>data</b>, sorted according to time.</li>
			<li><b>user</b> merges all users in <b>session</b>, sorted according to time.</li>
			</ul>
		</li>
		<li>
		<b>"datasources"</b> will tell the server which pieces of data you would like.  Possible comma separated values include:
			<ul>
				<li><b>environment:</b> disabled in default link; adds per-session user environment data such as operating system version.</li>
				<li><b>keystrokes:</b> enabled in default link; includes keyboard input and associated window information.</li>
				<li><b>mouse:</b> enabled in default link; includes mouse input and associated window information.</li>
				<li><b>processes:</b> enabled in default link; contains background process information.</li>
				<li><b>windows:</b> enabled in default link; contains active (foreground) window information.</li>
				<li><b>events:</b> enabled in default link; contains task completion information.</li>
				<li><b>screenshots:</b> disabled in default link; has base64 encoded screenshots.  <b>screenshotindices</b> can also be specified which includes the index data but not the actual encoded image.</li>
				<li><b>video:</b> disabled in default link; builds a mkv formatted video from the screenshots for each session, encoded to base64 for json output.</li>
			</ul>
		</li>
		<li>
		<b>"users"</b> is a comma separated list of user tokens to select.  All other tokens will be ignored.
		</li>
		<li>
		<b>"event"</b> is the name of the event to select from.  In the default link above, it is specified for this event.
		</li>
	</ul>
	</td>
	</tr>
	<tr>
	<td>
	<h4>
	<a href="visualzation.jsp?event=<%=eventName %>">Visualization (Coming Soon)</a>
	</h4>
	</td>
	</tr>

	<tr>
	<td>
	<h3>
	Edit Event
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
	<input type="hidden" id="oldevent" name="oldevent" value="oldevent" form="createform">
	<input type="hidden" id="eventname" name="eventname" value="<%=eventName %>" form="createform">
	<input type="text" id="eventname" name="eventname" disabled value="<%=eventName %>">
	</td>
	</tr>
	<tr>
	<td>
	<h4>Start Date</h4>
	</td>
	</tr>
	<tr>
	<td>
	<input type="text" id="startdate" name="startdate" value="<%=startDate %>" form="createform">
	</td>
	</tr>
	<tr>
	<td>
	<h4>End Date</h4>
	</td>
	</tr>
	<tr>
	<td>
	<input type="text" id="enddate" name="enddate" value="<%=endDate %>" form="createform">
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
	<input type="password" id="eventpassword" name="eventpassword" value="<%=password %>" form="createform">
	</td>
	</tr>
	<tr>
	<td>
	<h4>Description</h4>
	</td>
	</tr>
	<tr>
	<td>
	<textarea name="description" id="description" form="createform" style="width:100%;"><%=description %></textarea>
	</td>
	</tr>
	<tr>
	<td>
	<h4>Make Data Public?</h4>
	</td>
	</tr>
	<tr>
	<td>
	<%
	String publicChecked = "";
	if(publicPublic)
	{
		publicChecked = "checked";
	}
	%>
	<input type="checkbox" id="public" name="public" value="public" <%=publicChecked %> form="createform">
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
	<%
	String publicEventChecked = "";
	if(publicEvent)
	{
		publicEventChecked = "checked";
	}
	%>
	<input type="checkbox" id="publicevent" name="publicevent" value="publicevent" <%=publicEventChecked %> form="createform">
	</td>
	</tr>
	<tr>
	<td>
	<h4>Add Tokens</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	As with the main create page, use comma separated alphanumeric/punctuation values such as "0001, abcd, !ab3".
	</p>
	<textarea name="tokens" id="tokens" form="createform" style="width:100%;"></textarea>
	</td>
	</tr>
	<tr>
	<td>
	<h4>Remove Tokens</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	As with the main create page, use comma separated alphanumeric/punctuation values such as "0001, abcd, !ab3".
	</p>
	<textarea name="removeTokens" id="removeTokens" form="createform" style="width:100%;"></textarea>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	If you would also like to stop these tokens' active uploads, check this box.
	</p>
	<input type="checkbox" id="removeUpload" name="removeUpload" value="removeUpload" form="createform">
	</td>
	</tr>
	<tr>
	<td>
	<h4>Add Event Contact</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	This info will appear at the bottom of your event page.
	</p>
	<p>
	Name
	</p>
	<textarea name="contactname" id="contactname" form="createform" style="width:100%;"></textarea>
	<p>
	Contact Info
	</p>
	<textarea name="contactcontact" id=""contactcontact"" form="createform" style="width:100%;"></textarea>
	</td>
	</tr>
	<tr>
	<td>
	<h4>Remove Event Contact</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	This info will appear at the bottom of your event page.  Only one contact may be removed at a time.
	</p>
	<p>
	Name
	</p>
	<textarea name="contactnameremove" id="contactnameremove" form="createform" style="width:100%;"></textarea>
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
	<input type="text" id="eventserver" name="eventserver" value="<%=serverName %>" form="createform" value="ws://revenge.cs.arizona.edu/DataCollectorServer/UploadData">
	</td>
	</tr>
	<tr>
	<td>
	<form action="viewEvent.jsp" id="createform">
	<input type="submit" value="Submit">
	</form>
	</td>
	</tr>
	<tr>
	<td>
	<h4>Token Requests</h4>
	</td>
	</tr>
	<tr>
			<td>
			<table width=100%>
			<tr>
			<td width="25%">
			Requested Token
			</td>
			<td width="25%">
			Requester Name
			</td>
			<td width="25%">
			Requester Email
			</td>
			<td width="12.5%">
			Accept
			</td>
			<td width="12.5%">
			Deny
			</td>
			</tr>
	<%
	query = "SELECT * FROM `TokenRequest` WHERE `event` = ? AND `adminEmail` = ?";
	try
	{
		PreparedStatement queryStmt = dbConn.prepareStatement(query);
		queryStmt.setString(2, admin);
		queryStmt.setString(1, eventName);
		ResultSet myResults = queryStmt.executeQuery();
		while(myResults.next())
		{
			%>
			<tr>
			<td width="25%">
			<%=myResults.getString("requestedUsername") %>
			</td>
			<td width="25%">
			<%=myResults.getString("requesterName") %>
			</td>
			<td width="25%">
			<%=myResults.getString("requesterEmail") %>
			</td>
			<td width="12.5%">
			<input type="radio" id="<%=myResults.getString("requestedUsername") %>" name="<%=myResults.getString("requestedUsername") %>" value="accept" form="tokenrequestform">
			</td>
			<td width="12.5%">
			<input type="radio" id="<%=myResults.getString("requestedUsername") %>" name="<%=myResults.getString("requestedUsername") %>" value="deny" form="tokenrequestform">
			</td>
			</tr>
			<%
		}
		queryStmt.close();
	}
	catch(Exception e)
	{
		e.printStackTrace();
	}
}
%>
			</table>
	</td>
	</tr>
	<tr>
	<td>
	<input type="hidden" id="approverequests" name="approverequests" value="approverequests" form="tokenrequestform">
	<input type="hidden" id="eventnamerequest" name="eventname" value="<%=eventName %>" form="tokenrequestform">
	<form action="viewEvent.jsp" id="tokenrequestform">
	<input type="submit" value="Submit">
	</form>
	</td>
	</tr>
</table>
</div>
</body>
</html>