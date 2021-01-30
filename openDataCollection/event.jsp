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
boolean insertedRequest = false;
if(publicEvent && requestedToken != null && !requestedToken.equals(""))
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
Then, follow the following instructions to install the data
collection software:
<ol>
<li>Download and install a virtual machine player/hypervisor for your device.  We recommend
either VMWare or VirtualBox; select an appropriate option for your operating
system.  If you are not familiar with virtual machine technology, please do some
research before continuing.  A good introduction to virtual machines can be
found <a href="https://www.howtogeek.com/196060/beginner-geek-how-to-create-and-use-virtual-machines/">
here</a>.</li>
<li>Download and install a virtual machine.  This software has been tested on
Ubuntu and Kali Linux, but may work on other versions of Linux.  We recommend Kali
Linux for security competitions, as it has handy tools for these problems.</li>
<li>On your virtual device, navigate back to this page and make sure your
token is entered in the field above.  <b>If you have navigated back to this page and
your token is already entered, please re-enter it to ensure your browser has updated
the link below properly.</b></li>
<li>Download <a id="installScriptLink" href="./installDataCollection.sh?event=<%=java.net.URLEncoder.encode(event, "UTF-8") %>" download>this script</a>.</li>
<li>Enable execution of the script.  How to do this is operating system specific.
On most Linux distributions, you can do this by right clicking the file in the file system interface,
select "properties" or something similar, and find an execution option under "permissions".</li>
<li>Install the data collection software by opening a terminal in the folder with
the script (on Linux, this can be done by right clicking in the folder and selecting "open terminal") and entering:<br />
<span style="font-family: Courier New,Courier,Lucida Sans Typewriter,Lucida Typewriter,monospace;"><b>sudo ./install_data_collection.sh</b></span></li>
<li>
This installation step might take a few minutes.
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
<h5>Your token request was added.  You may request additional tokens.</h5>
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