<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="org.apache.commons.lang3.StringEscapeUtils, java.net.*, java.util.ArrayList, com.datacollector.*, java.sql.*, java.util.concurrent.ConcurrentHashMap, java.util.Map.Entry, java.util.Map"%>
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

PreparedStatement queryStmt = null;
ResultSet myResults = null;
try
{
	queryStmt = dbConn.prepareStatement(query);
	queryStmt.setString(1, event);
	queryStmt.setString(2, admin);
	myResults = queryStmt.executeQuery();
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
	myResults.close();
	queryStmt.close();
	dbConn.close();
}
catch(Exception e)
{
	e.printStackTrace();
}
finally
{
	try { if (myResults != null) myResults.close(); } catch(Exception e) { }
    try { if (queryStmt != null) queryStmt.close(); } catch(Exception e) { }
    try { if (dbConn != null) dbConn.close(); } catch(Exception e) { }
}

boolean failed = false;
boolean insertedRequest = false;
if((!dynamicToken) && publicEvent && requestedToken != null && !requestedToken.equals(""))
{
	dbConn = myConnectionSource.getDatabaseConnection();
	insertedRequest = true;
	try
	{
		String requestInsert = "INSERT INTO `TokenRequest`(`event`, `adminEmail`, `requestedUsername`, `requesterName`, `requesterEmail`) VALUES (?,?,?,?,?)";
		
		PreparedStatement requestStmt = dbConn.prepareStatement(requestInsert);
		queryStmt = requestStmt;
		requestStmt.setString(1, event);
		requestStmt.setString(2, admin);
		requestStmt.setString(3, StringEscapeUtils.escapeHtml4(requestedToken).replaceAll(",", "").replaceAll("\"", ""));
		requestStmt.setString(4, StringEscapeUtils.escapeHtml4(requestedName).replaceAll("\"", ""));
		requestStmt.setString(5, StringEscapeUtils.escapeHtml4(requestedEmail).replaceAll("\"", ""));
		requestStmt.execute();
		
		queryStmt.close();
		dbConn.close();
	}
	catch(Exception e)
	{
		failed = true;
		e.printStackTrace();
	}
	finally
	{
	    try { if (queryStmt != null) queryStmt.close(); } catch(Exception e) { }
	    try { if (dbConn != null) dbConn.close(); } catch(Exception e) { }
	}
}

if(dynamicToken && requestedToken != null && !requestedToken.equals(""))
{
	dbConn = myConnectionSource.getDatabaseConnection();
	insertedRequest = true;
	try
	{
		String requestInsert = "INSERT INTO `UserList`(`event`, `adminEmail`, `username`, `name`, `email`) VALUES (?,?,?,?,?)";
		
		PreparedStatement requestStmt = dbConn.prepareStatement(requestInsert);
		queryStmt = requestStmt;
		requestStmt.setString(1, event);
		requestStmt.setString(2, admin);
		requestStmt.setString(3, StringEscapeUtils.escapeHtml4(requestedToken).replaceAll(",", "").replaceAll("\"", ""));
		requestStmt.setString(4, StringEscapeUtils.escapeHtml4(requestedName).replaceAll("\"", ""));
		requestStmt.setString(5, StringEscapeUtils.escapeHtml4(requestedEmail).replaceAll("\"", ""));
		requestStmt.execute();
		
		queryStmt.close();
		dbConn.close();
	}
	catch(Exception e)
	{
		failed = true;
		e.printStackTrace();
	}
	finally
	{
	    try { if (queryStmt != null) queryStmt.close(); } catch(Exception e) { }
	    try { if (dbConn != null) dbConn.close(); } catch(Exception e) { }
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
<td>
<a href="index.jsp">Catalyst Home</a>
</td>
</tr>
<tr>
<td>
<%=desc %>
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
	document.getElementById('installScriptLink').download='installDataCollection.' + ext;
	document.getElementById('installScriptLink2').href='./installDataCollection.' + ext + '?event=<%=java.net.URLEncoder.encode(event, "UTF-8") %>&admin=<%=java.net.URLEncoder.encode(admin, "UTF-8") %>&username=' + document.getElementById('tokenform').value + '&devicetype=' + document.getElementById('devicetypeform').value;
	document.getElementById('installScriptLink2').download='installDataCollection.' + ext;
}
</script>
<h2>Instructions</h2>
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
consent to all terms on this page, enter your event token here:
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
<p>
Then, follow the following instructions to install the data
collection software:
<ol>
<li>Download and install a virtual machine player/hypervisor for your device if you
are running a virtual machine.  We recommend
either VMWare or VirtualBox; select an appropriate option for your operating
system.  If you are not familiar with virtual machine technology, please do some
research before continuing.  A good introduction to virtual machines can be
found <a href="https://www.howtogeek.com/196060/beginner-geek-how-to-create-and-use-virtual-machines/">
here</a>.</li>
<li>Download and install a virtual machine or install your OS if using a physical device.  This software has been tested on
Ubuntu, Kali, and 32 bit Raspbian Linux, but may work on other versions of Linux.  Debian
based distributions with apt running X11 (not Wayland distros) should work.  With Linux, X86 and X64
architectures work.  ARM 32 bit works, but ARM 64 does not yet.  Windows support
is currently in beta testing but should work on Windows 10.  We recommend Kali
Linux for security competitions, as it has handy tools for these problems.</li>
<li>If you are using a Windows virtual machine, download and install the latest version
of Java.  We use the Oracle JDK but other virtual machines may also work.
Windows support is currently in beta testing, so please keep in contact with
the study admins when using it to ensure data is being uploaded correctly.</li>
<li>On your virtual device, navigate back to this page and make sure your
token is entered in the field above.  <b>Press the "Set" button once you have entered
your token.</b>  This button updates the download links.</li>
<li>Download <a id="installScriptLink" href="./installDataCollection.sh?event=<%=java.net.URLEncoder.encode(event, "UTF-8") %>" download>the installer script</a>.</li>
<li>Enable execution of the script.  How to do this is operating system specific.
On most Linux distributions, you can do this by right clicking the file in the file system interface,
select "properties" or something similar, and find an execution option under "permissions" or with the "chmod" command.</li>
<li>Install the data collection software by opening a terminal in the folder with
the script (on Linux, this can be done by right clicking in the folder and selecting "open terminal" and on Windows this can be done by searching for "cmd" on the start menu, right clicking, and selecting "Run as Administrator" before navigating to the appopriate folder) and running the installer:<br />
<span>For Linux:</span><br>
<span style="font-family: Courier New,Courier,Lucida Sans Typewriter,Lucida Typewriter,monospace;"><b>sudo ./install_data_collection.sh</b></span></li>
<span>For Windows:</span><br>
<span style="font-family: Courier New,Courier,Lucida Sans Typewriter,Lucida Typewriter,monospace;"><b>./install_data_collection.bat</b></span></li>
<li>
This installation step might take a few minutes and will restart your device.
</li>
<li>Use this virtual machine to participate in the competition&mdash;have fun!</li>
</ol>
</p>
<h2>How to Stop Data Collection</h2>
<p>
If you wish to stop your participation at any point, follow the instructions below.
If you would like to have your data collected thus far removed as well, contact
the system admins, listed below.
</p>
<ol>
<li>On your virtual machine, download <a href="./stopDataCollection.sh" download>this script</a>.</li>
<li>Enable execution of the downloaded script.</li>
<li>Open a terminal in the folder with the downloaded script and enter the following: <br/>
<span style="font-family: Courier New,Courier,Lucida Sans Typewriter,Lucida Typewriter,monospace;"><b>sudo ./stopDataCollection.sh.sh</b></span></li>
<li>
<b>This script will restart your computer when you run it to complete the uninstallation.</b>
</li>
<li>
Note that this script leaves a few pieces of software that come with the data collection software
installed so that, if you are running other software using these installations, that other software
will not fail.  In particular, the default Java JDK, tomcat8, and mariadb are left installed, but
have their data collection components removed.  These pieces of software can be removed by using
the apt-get remove command.
</li>
</ol>
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
<form action="event.jsp" id="tokenrequestform">
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