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

Connection dbConn = null;

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
			PreparedStatement loginStmt = null;
			try
			{
				dbConn = myConnectionSource.getDatabaseConnection();
				loginStmt = dbConn.prepareStatement(signupQuery);
				loginStmt.setString(1, adminEmail);
				loginStmt.setString(2, password);
				loginStmt.setString(3, adminName);
				loginStmt.execute();
				loginStmt.close();
				dbConn.close();
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
			finally
			{
				try { if (loginStmt != null) loginStmt.close(); } catch(Exception e) { }
			    try { if (dbConn != null) dbConn.close(); } catch(Exception e) { }
			}
		}
		String loginQuery = "SELECT * FROM `openDataCollectionServer`.`Admin` WHERE `adminEmail` = ? AND `adminPassword` = ?";
		PreparedStatement queryStmt = null;
		try
		{
			dbConn = myConnectionSource.getDatabaseConnection();
			queryStmt = dbConn.prepareStatement(loginQuery);
			queryStmt.setString(1, adminEmail);
			queryStmt.setString(2, password);
			ResultSet myResults = queryStmt.executeQuery();
			if(myResults.next())
			{
				session.setAttribute("admin", myResults.getString("adminEmail"));
				session.setAttribute("adminName", myResults.getString("name"));
			}
			queryStmt.close();
			dbConn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			try { if (queryStmt != null) queryStmt.close(); } catch(Exception e) { }
		    try { if (dbConn != null) dbConn.close(); } catch(Exception e) { }
		}
	}
}

String domainURL = ProxyDomainInfo.getProxiedDomain();
String applicationURL = ProxyDomainInfo.getApplicationPath();
if(domainURL.equals(""))
{
	domainURL = request.getServerName();
}
if(applicationURL.equals(""))
{
	applicationURL = "/DataCollectorServerDeployment";
}
UploadMonitor uploadMonitor = UploadMonitor.getUploadMonitor();
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
		<h3>Server Info</h3>
	</td>
</tr>
<tr>
<td colspan=2>
<table>
<tr>
	<td>
		<b>Available Memory:</b>
	</td>
	<td>
		<%=myConnector.freeMemory() %> bytes
	</td>
</tr>
<tr>
	<td>
		<b>Total Active Uploads:</b>
	</td>
	<td>	
		<%=uploadMonitor.getNumTokensActive() %>
	</td>
</tr>
<tr>
	<td>
		<b>Total Users with Uploads:</b>
	</td>
	<td>	
		<%=uploadMonitor.getNumUsersActive() %>
	</td>
</tr>
<tr>
	<td>
		<b>Total Events with Uploads:</b>
	</td>
	<td>	
		<%=uploadMonitor.getNumEventsActive() %>
	</td>
</tr>
<tr>
	<td>
		<b>Total Admins with Uploads:</b>
	</td>
	<td>	
		<%=uploadMonitor.getNumAdminsActive() %>
	</td>
</tr>
</table>
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
PreparedStatement queryStmt = null;
try
{
	dbConn = myConnectionSource.getDatabaseConnection();
	queryStmt = dbConn.prepareStatement(query);
	queryStmt.setString(1, admin);
	ResultSet myResults = queryStmt.executeQuery();
	while(myResults.next())
	{
		String event = myResults.getString("event");
		%>
		<option value="<%=event %>"><%=event %></option>
		<%
	}
	queryStmt.close();
	dbConn.close();
}
catch(Exception e)
{
	e.printStackTrace();
}
finally
{
	try { if (queryStmt != null) queryStmt.close(); } catch(Exception e) { }
    try { if (dbConn != null) dbConn.close(); } catch(Exception e) { }
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
<h4>Autorestart?</h4>
</td>
</tr>
<tr>
<td>
<p>
When subjects install the endpoint monitor, this will automatically restart their devices.
</p>
<input type="checkbox" id="autorestart" name="autorestart" value="autorestart" form="createform">
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
<input type="checkbox" id="collectmetrics" name="collectmetrics" value="collectmetrics" form="createform">
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
	<input type="text" value="100" id="screenshotinterval" name="screenshotinterval" form="createform">
	</td>
	<td>
	<input type="text" value="10000" id="processinterval" name="processinterval" form="createform">
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
					
				</script>
			</td>
		</tr>
	</table>
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
<input type="text" id="eventserver" name="eventserver" form="createform" value="ws://<%=domainURL %><%=applicationURL %>/UploadData">
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