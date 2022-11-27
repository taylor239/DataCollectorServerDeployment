<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, java.util.HashMap, com.datacollector.*, java.sql.*, org.apache.commons.lang3.StringEscapeUtils, java.util.concurrent.ConcurrentHashMap, java.util.Map.Entry, java.util.Map"%>
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

ArrayList taggerList = new ArrayList();

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
boolean newAutoapproveEvent = request.getParameter("autoapproveevent") != null && request.getParameter("autoapproveevent").equals("autoapproveevent");
String newTokens = request.getParameter("tokens");
String newServer = request.getParameter("eventserver");
String contactName = request.getParameter("contactname");
String contactContact = request.getParameter("contactcontact");
String contactNameRemove = request.getParameter("contactnameremove");

boolean newAutorestartEvent = request.getParameter("autorestart") != null && request.getParameter("autorestart").equals("autorestart");
String newDiffType = request.getParameter("diffcomp");
String newImageType = request.getParameter("imagecomp");
String newImageAmount = request.getParameter("compamount");

boolean newMetrics = request.getParameter("collectmetrics") != null && request.getParameter("collectmetrics").equals("collectmetrics");
String newGranularity = request.getParameter("processgranularity");
String newScreenshotInterval = request.getParameter("screenshotinterval");
String newProcessInterval = request.getParameter("processinterval");


String taggerQuery = "SELECT * FROM `EventPassword` WHERE `event` = ? AND `adminEmail` = ? ORDER BY `password` ASC";

try
{
	
	if(request.getParameter("addviewer") != null)
	{
		String addStmtString = "INSERT INTO `EventPassword`(`event`, `adminEmail`, `password`, `tagger`, `anon`) VALUES (?,?,?,?,?)";
		PreparedStatement addStmt = dbConn.prepareStatement(addStmtString);
		addStmt.setString(2, (String)session.getAttribute("admin"));
		addStmt.setString(1, eventName);
		addStmt.setString(3, request.getParameter("viewerpassword"));
		if(!request.getParameter("viewertagger").equals(""))
		{
			addStmt.setString(4, request.getParameter("viewertagger"));
		}
		else
		{
			addStmt.setString(4, null);
		}
		if(request.getParameter("vieweranon") != null)
		{
			addStmt.setInt(5, 1);
		}
		else
		{
			addStmt.setInt(5, 0);
		}
		addStmt.execute();
		addStmt.close();
	}
	
	PreparedStatement queryStmt = dbConn.prepareStatement(taggerQuery);
	queryStmt.setString(2, (String)session.getAttribute("admin"));
	queryStmt.setString(1, eventName);
	ResultSet myResults = queryStmt.executeQuery();
	if(request.getParameter("updateviewer") != null)
	{
		String deleteRequestQuery = "DELETE FROM `EventPassword` WHERE `event` = ? AND `adminEmail` = ? AND `password` = ?";
		PreparedStatement deleteStmt = dbConn.prepareStatement(deleteRequestQuery);
		
		deleteStmt.setString(2, (String)session.getAttribute("admin"));
		deleteStmt.setString(1, eventName);
		
		while(myResults.next())
		{
			String curPassword = myResults.getString("password");
			if(request.getParameter(curPassword) != null)
			{
				deleteStmt.setString(3, curPassword);
				deleteStmt.execute();
			}
		}
		
		deleteStmt.close();
		myResults = queryStmt.executeQuery();
	}
	
	while(myResults.next())
	{
		HashMap curTaggerMap = new HashMap();
		curTaggerMap.put("password", myResults.getString("password"));
		curTaggerMap.put("tagger", myResults.getString("tagger"));
		if(myResults.wasNull())
		{
			curTaggerMap.put("tagger", "<i>Cannot Tag</i>");
		}
		curTaggerMap.put("anon", myResults.getString("anon"));
		taggerList.add(curTaggerMap);
	}
}
catch(Exception e)
{
	e.printStackTrace();
}



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
		if(StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername")) != null)
		{
			if(request.getParameter(StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername"))).equals("accept"))
			{
				if(newTokens == null)
				{
					newTokens = StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername"));
				}
				else
				{
					newTokens += "," + StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername"));
				}
				requesterName.add(myResults.getString("requestedName"));
				requesterEmail.add(myResults.getString("requestedEmail"));
				deleteStmt.setString(3, StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername")));
				deleteStmt.execute();
			}
			else if(request.getParameter(StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername"))).equals("deny"))
			{
				deleteStmt.setString(3, StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername")));
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


String insertEvent = "INSERT INTO `Event`"
+"(`event`, `start`, `end`, `description`, `continuous`, `taskgui`, `password`, `adminEmail`, `public`, `publicEvent`, `dynamicTokens`, `autorestart`, `diffType`, `compType`, `compAmount`, `metrics`, `processGranularity`, `screenshotInterval`, `processInterval`) "
+"VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) "
+"ON DUPLICATE KEY UPDATE "
+"`event` = VALUES(`event`), `start` = VALUES(`start`), `end` = VALUES(`end`), `description` = VALUES(`description`), `continuous` = VALUES(`continuous`), `taskgui` = VALUES(`taskgui`), `password` = VALUES(`password`), `adminEmail` = VALUES(`adminEmail`), `public` = VALUES(`public`), `publicEvent` = VALUES(`publicEvent`), `dynamicTokens` = VALUES(`dynamicTokens`), `autorestart` = VALUES(`autorestart`), `diffType` = VALUES(`diffType`), `compType` = VALUES(`compType`), `compAmount` = VALUES(`compAmount`), `metrics` = VALUES(`metrics`), `processGranularity` = VALUES(`processGranularity`), `screenshotInterval` = VALUES(`screenshotInterval`), `processInterval` = VALUES(`processInterval`)";
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
	insertStmt.setBoolean(11, newAutoapproveEvent);
	insertStmt.setBoolean(12, newAutorestartEvent);
	insertStmt.setString(13, newDiffType);
	insertStmt.setString(14, newImageType);
	insertStmt.setString(15, newImageAmount);
	insertStmt.setBoolean(16, newMetrics);
	insertStmt.setString(17, newGranularity);
	insertStmt.setString(18, newScreenshotInterval);
	insertStmt.setString(19, newProcessInterval);
	insertStmt.execute();
	insertStmt.close();
}
catch(Exception e)
{
	%>
	<script>
	console.log("Got an event error, check server log for details");
	</script>
	<%
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
	%>
	<script>
	console.log("Got a contact error, check server log for details");
	</script>
	<%
	e.printStackTrace();
}
}

if(contactNameRemove != null && !contactNameRemove.equals(""))
{
String contactCount = "SELECT COUNT(*) AS `theCount` FROM `openDataCollectionServer`.`Event` INNER JOIN `openDataCollectionServer`.`EventContact` ON `openDataCollectionServer`.`Event`.`event` = `openDataCollectionServer`.`EventContact`.`event` WHERE `openDataCollectionServer`.`Event`.`event` = ? AND `openDataCollectionServer`.`Event`.`adminEmail` = ?";
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
	%>
	<script>
	console.log("Got a contact delete error, check server log for details");
	</script>
	<%
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
	System.out.println(insertToken);
	PreparedStatement insertStmt = dbConn.prepareStatement(insertToken);
	for(int x=0; x<newTokenList.length; x++)
	{
		System.out.println(newTokenList[x]);
		System.out.println(requesterName.get(x));
		System.out.println(requesterName.get(x));
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
	%>
	<script>
	console.log("Got a token add error, check server log for details");
	</script>
	<%
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
	%>
	<script>
	console.log("Got a token remove error, check server log for details");
	</script>
	<%
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
boolean autoapproveEvent = false;
boolean autoapprove = false;

boolean autorestart = false;
String diffType = "";
String compType = "";
String compAmount = "";

boolean metrics = false;
String processGranularity = "";
String screenshotInterval = "";
String processInterval = "";

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
		autoapproveEvent = myResults.getInt("dynamicTokens") == 1;
		
		autorestart = myResults.getInt("autorestart") == 1;
		diffType = myResults.getString("diffType");
		compType = myResults.getString("compType");
		compAmount = myResults.getString("compAmount");
		
		metrics = myResults.getInt("metrics") == 1;
		processGranularity = myResults.getString("processGranularity");
		screenshotInterval = myResults.getString("screenshotInterval");
		processInterval = myResults.getString("processInterval");
	}
}
catch(Exception e)
{
	%>
	<script>
	console.log("Got an event read error, check server log for details");
	</script>
	<%
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
	<p> To get a json of taken tokens with number of times downloaded per token, go <a href="tokensTaken.json?event=<%=eventName %>">here</a>. To get a csv of available tokens, go <a href="tokensAvailable.csv?event=<%=eventName %>">here</a>. To get a json of available tokens, go <a href="tokensAvailable.json?event=<%=eventName %>">here</a>. To get a json with identifying information, go <a href="getUserIdentification.json?event=<%=eventName %>">here</a>, and to see this data in a searchable table go <a href="identitytable.jsp?event=<%=eventName %>">here</a>.</p>
	<%
}
catch(Exception e)
{
	e.printStackTrace();
}


UploadMonitor uploadMonitor = UploadMonitor.getUploadMonitor();
ConcurrentHashMap uploadMap = uploadMonitor.getEventMap(admin, eventName);
if(uploadMap != null)
{
	int numUploaders = uploadMap.size();
	%>
		<p> There are currently <%=numUploaders %> uploads active for this event.  Details on each upload can be viewed <a href="activeUploadTable.jsp?event=<%=eventName %>">here</a>. </p>
	<%
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
	Note that these links can be customized with parameters for various purposes.  "email" and "password" can be passed to log you in as you do the export, which is helpful for uses which do no manage a session.  <b>These links also serve the entirety of this event's data, which could cause the server to crash if the data size is too larget for the server's memory.</b>  The data may be segmented by using the following arguments:
	<ul>
		<li><b>first</b> and <b>count</b>, which select only <i>count</i> individual pieces of data, per data category selected, starting at index <i>first</i>.  The data is sorted according to time, so the entire event data can be reconstructed efficiently one frame at a time with this method.</li>
		<li><b>users</b>, which specifies the user tokens (in a comma separated list) to export data for.</li>
		<li><b>sessions</b>, which similarly only selects data from sessions in the supplied comma separated list.</li>
	</ul>
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
				<li><b>screenshots:</b> disabled in default link; has base64 encoded screenshots or actual image files in .zip output.  <b>screenshotindices</b> can also be specified which includes the index data but not the actual encoded image.</li>
				<li><b>compositedscreenshots:</b> same as screenshots, but will reconstruct complete frames from diff frames instead of serving those frames as raw diffs.</li>
				<li><b>video:</b> disabled in default link; builds a mkv formatted video from the screenshots for each session, encoded to base64 for json output.  Currently broken and disabled.</li>
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
	<a href="vissplash.jsp?event=<%=eventName %>">Visualization</a>
	</h4>
	</td>
	</tr>
	<tr>
	<td>
	<h4>
	<a href="cacheBounds.json?event=<%=eventName %>">Manually Cache Statistics</a>
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
	<h4>Autoapprove Tokens?</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	If your event is public, this will automatically approve all token requests.
	</p>
	<%
	String autoapproveEventChecked = "";
	if(autoapproveEvent)
	{
		autoapproveEventChecked = "checked";
	}
	%>
	<input type="checkbox" id="autoapproveevent" name="autoapproveevent" value="autoapproveevent" <%=autoapproveEventChecked %> form="createform">
	</td>
	</tr>
	<tr>
	<td>
	<h4>Autorestart?</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	When subjects install the endpoint monitor, this will automatically restart their devices.
	</p>
	<%
	String autorestartChecked = "";
	if(autorestart)
	{
		autorestartChecked = "checked";
	}
	%>
	<input type="checkbox" id="autorestart" name="autorestart" value="autorestart" <%=autorestartChecked %> form="createform">
	</td>
	</tr>
	<tr>
	<td>
	<h4>Collect Metrics?</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	This option causes the endpoint monitor (on new installs) to collect metrics in order to identify bottlenecks in the data collection software.
	</p>
	<%
	String metricsChecked = "";
	if(metrics)
	{
		metricsChecked = "checked";
	}
	%>
	<input type="checkbox" id="collectmetrics" name="collectmetrics" value="collectmetrics" <%=metricsChecked %> form="createform">
	</td>
	</tr>
	<tr>
	<td>
	<h4>Polling Intervals</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	These options change the polling intervals for screenshots and process data.
	The shorter the interval, the more data gets collected and the higher the
	resource use.  Specifically, the screenshot interval is the period the endpoint
	monitor waits between the completion of one screenshot record and the start of
	the next screenshot record.  Window data gets polled with screenshots as well;
	both of these data sources also get captured upon input from the keyboard or
	mouse.  Likewise, process data polling collects a complete snapshot of running
	system processes (and, potentially, threads) with the listed interval between
	each poll.  Polls are in microseconds and are multiplied for lower performance
	devices such as RPIs.
	</p>
	<table width="100%">
		<tr>
		<td width="50%">
		Screenshot Interval
		</td>
		<td width="50%">
		Process Interval
		</td>
		</tr>
		<tr>
		<td>
		<input type="text" value="<%=screenshotInterval %>" id="screenshotinterval" name="screenshotinterval" form="createform">
		</td>
		<td>
		<input type="text" value="<%=processInterval %>" id="processinterval" name="processinterval" form="createform">
		</td>
		</tr>
	</table>
	</td>
	</tr>
	<tr>
	<td>
	<h4>Process Granularity</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	The endpoint monitor process information may be either limited to just the process or include thread level granularity.
	</p>
	<select name="processgranularity" id="processgranularity" form="createform">
		<option value="process">process</option>
		<option value="thread">thread</option>
	</select>
	<script>
	document.getElementById("processgranularity").value = "<%=processGranularity %>";
	</script>
	</td>
	</tr>
	<tr>
	<td>
	<h4>Image Compression</h4>
	</td>
	</tr>
	<tr>
	<td>
	<p>
	This option selects the type of image compression subjects will use.  This option, if
	changed, will only apply to future installs and will not alter the compression for
	devices with the software installed already.  Images are compressed according to a
	<i>diff algorithm</i> and an <i>image compression algorithm</i>.
	</p>
	<br />
	<p>
	The <i>diff
	algorithm</i> can be set to store either a full-frame, pixel by pixel difference
	between a frame and its previous frame with the "diff" option; store the smallest
	possible rectangular portion of the screenshot encompassing differences between a frame
	and the previous frame with the "boundrect" option; or skip diff compression altogether
	by selecting "none".  Both diff algorithms support image reconstruction and do not
	inherently cause lossiness, though the <i>image compression algorithm</i> lossiness
	level may be influenced by the diff algorithm selected.  The two diff algorithm options
	result in less data required for storage and transfer for the visualization or download.
	They also have differing performance impacts on the endpoint monitor, including
	possibly decreasing frame rate or increasing CPU use, depending on the particular
	device running the software.  Key frames (full frames) periodically taken prevent data
	corruption in the event of glitches/bugs or accumulating lossiness due to the
	<i>image compression algorithm</i> used.
	</p>
	<br />
	<p>
	The <i>image compression algorithm</i> compresses individual frames (or frame portions)
	in order to reduce storage requirements.  The algorithm supports whichever compression
	algorithms are available in the Java distribution installed, which typically offers
	"png" and "jpg" algorithms - these are the only options offered here for simplicity.  For full frame diff, an alpha (transparency) layer must
	be supported in the compression algorithm, so jpg will not work; png is the safest
	option to use with this particular diff algorithm.  In addition to a compression type,
	a compression level enables greater compression at the cost of lossiness in the data -
	ie., screenshots will not be perfect copies of the source data from subjects' devices
	if lossy compression levels/algorithms are used.  Compression levels range from a max
	of 0 (lossless for png formats) to a minimum of 1.
	</p>
		<table width="100%">
			<tr>
				<td width="33.333%">
				Diff Compression Type
				</td>
				<td width="33.333%">
				Image Compression Type
				</td>
				<td width="33.333%">
				Image Compression Amount
				</td>
			</tr>
			<tr>
				<td>
				<select name="diffcomp" id="diffcomp" form="createform">
					<option value="diff">diff</option>
					<option value="boundrect">boundrect</option>
					<option value="">none</option>
				</select>
				</td>
				<td>
				<select name="imagecomp" id="imagecomp" form="createform">
					<option id="pngselect" value="png">png</option>
					<option id="jpgselect" value="jpg" disabled>jpg</option>
				</select>
				</td>
				<td>
					<table>
					<tr>
					<td>
					<input type="range" min="0" max="100" value="0" id="comprange">
					</td>
					<td>
					<input type="text" size="3" id="compamount" name="compamount" form="createform" value="0">
					</td>
					</tr>
					</table>
					<script>
						var compSlider = document.getElementById("comprange");
						var compForm = document.getElementById("compamount");
						compForm.value = compSlider.value;
						compSlider.oninput = function()
						{
							compForm.value = Number(this.value) / 100;
						}
						
						var diffSelect = document.getElementById("diffcomp");
						var imageSelect = document.getElementById("imagecomp");
						diffSelect.onchange = function()
						{
							var curComp = this.value;
							if(curComp == "diff")
							{
								document.getElementById("jpgselect").setAttribute("disabled", "");
								if(imageSelect.value == "jpg")
								{
									imageSelect.value = "png";
								}
							}
							else
							{
								document.getElementById("jpgselect").removeAttribute("disabled");
							}
						}
						<%
						//if(diffType.equals(""))
						//{
						//	diffType = "none";
						//}
						%>
						diffSelect.value = "<%=diffType %>";
						imageSelect.value = "<%=compType %>";
						compForm.value = <%=compAmount %>;
						compSlider.value = <%=compAmount %> * 100;
						
						var curComp = diffSelect.value;
						if(curComp == "diff")
						{
							document.getElementById("jpgselect").setAttribute("disabled", "");
							if(imageSelect.value == "jpg")
							{
								imageSelect.value = "png";
							}
						}
						else
						{
							document.getElementById("jpgselect").removeAttribute("disabled");
						}
						
					</script>
				</td>
			</tr>
		</table>
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
			<%=StringEscapeUtils.escapeHtml4(StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername"))) %>
			</td>
			<td width="25%">
			<%=StringEscapeUtils.escapeHtml4(myResults.getString("requesterName")) %>
			</td>
			<td width="25%">
			<%=StringEscapeUtils.escapeHtml4(myResults.getString("requesterEmail")) %>
			</td>
			<td width="12.5%">
			<input type="radio" id="<%=StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername")) %>" name="<%=StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername")) %>" value="accept" form="tokenrequestform">
			</td>
			<td width="12.5%">
			<input type="radio" id="<%=StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername")) %>" name="<%=StringEscapeUtils.escapeHtml4(myResults.getString("requestedUsername")) %>" value="deny" form="tokenrequestform">
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
	<tr>
	<td>
	<h4>Viewers</h4>
	</td>
	</tr>
	
	
	<tr>
	<td>
		<table width="100%">
		<tr>
		<td width="40%">
		<b>Password and Link</b>
		</td>
		<td width="40%">
		<b>Tag ID</b>
		</td>
		<td width="10%">
		<b>Anon</b>
		</td>
		<td width="10%">
		<b>Delete</b>
		</td>
		</tr>
		<form action="viewEvent.jsp" id="updateviewerform">
		<input type="hidden" id="updateviewer" name="updateviewer" value="updateviewer" form="updateviewerform">
		<input type="hidden" id="eventnamerequest" name="eventname" value="<%=eventName %>" form="updateviewerform">
		<%
		
		for(int x = 0; x < taggerList.size(); x++)
		{
			HashMap curMap = (HashMap)taggerList.get(x);
			%>
			<tr>
			<td width="40%">
			<a href="vissplash.jsp?event=<%=eventName %>&eventPassword=<%=curMap.get("password") %>&eventAdmin=<%=(String)session.getAttribute("admin") %>"><%=curMap.get("password") %></a>
			</td>
			<td width="40%">
			<%=curMap.get("tagger") %>
			</td>
			<td width="10%">
			<%
			if(curMap.get("anon").equals("1"))
			{
				%>
				X
				<%
			}
			else
			{
				
			}
			%>
			</td>
			<td width="10%">
			<input type="checkbox" id=<%=curMap.get("password") %> name=<%=curMap.get("password") %> value=<%=curMap.get("password") %> form="updateviewerform">
			</td>
			</tr>
			<%
		}
		
		%>
		<tr>
		<td colspan=3>
		</td>
		<td>
		<input type="submit" value="Submit" form="updateviewerform">
		</td>
		</tr>
		</form>
		</table>
	</td>
	</tr>
	
	<tr>
	<td>
	<h4>Add Viewer</h4>
	</td>
	</tr>
	
	<tr>
	<td>
		<table width="100%">
		<tr>
		<td width="40%">
		Password
		</td>
		<td width="40%">
		Tag ID
		</td>
		<td width="10%">
		Anon
		</td>
		<td width="10%">
		</td>
		</tr>
		<form action="viewEvent.jsp" id="viewerrequestform">
		<input type="hidden" id="addviewer" name="addviewer" value="addviewer" form="viewerrequestform">
		<input type="hidden" id="eventnamerequest" name="eventname" value="<%=eventName %>" form="viewerrequestform">
		<tr>
		<td width="40%">
		<input type="text" id="viewerpassword" name="viewerpassword" value="" form="viewerrequestform">
		</td>
		<td width="40%">
		<input type="text" id="viewertagger" name="viewertagger" value="" form="viewerrequestform">
		</td>
		<td width="10%">
		<input type="checkbox" id="vieweranon" name="vieweranon" value="vieweranon"  form="viewerrequestform">
		</td>
		<td width="10%">
		<input type="submit" value="Submit" form="viewerrequestform">
		</td>
		</tr>
		</form>
		</table>
	</td>
	</tr>
	
</table>
</div>
</body>
</html>