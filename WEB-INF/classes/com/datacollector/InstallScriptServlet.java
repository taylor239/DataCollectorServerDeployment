package com.datacollector;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.UUID;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;

/**
 * Servlet implementation class InstallScriptServlet
 */
@WebServlet(name="InstallScript", urlPatterns= {"/openDataCollection/installDataCollection.sh", "/openDataCollection/installDataCollection.bat"})
public class InstallScriptServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public InstallScriptServlet()
    {
        super();
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		HttpSession session = request.getSession(true);
		
		String curUsername = request.getParameter("username");
		String curEvent = request.getParameter("event");
		String curAdmin = request.getParameter("admin");
		String curDevice = request.getParameter("devicetype");
		
		
		
		String osPrefix = "";
		
		int screenshotTime = 120000;
		if(curDevice.equals("debvm"))
		{
			screenshotTime = 15000;
		}
		else if(curDevice.equals("debrpi"))
		{
			screenshotTime = 240000;
		}
		else if(curDevice.equals("fedvm"))
		{
			screenshotTime = 60000;
			osPrefix = "yum install apt";
		}
		else if(curDevice.equals("winvm"))
		{
			screenshotTime = 15000;
			osPrefix = "";
		}
		
		String continuous = "";
		String taskgui = "";
		String password = "";
		
		
		
		DatabaseConnector myConnector=(DatabaseConnector)session.getAttribute("connector");
		if(myConnector==null)
		{
			myConnector=new DatabaseConnector(getServletContext());
			session.setAttribute("connector", myConnector);
		}
		TestingConnectionSource myConnectionSource = myConnector.getConnectionSource();
		
		
		Connection dbConn = myConnectionSource.getDatabaseConnection();
		
		try
		{
			
			String eventQuery = "SELECT * FROM `Event` WHERE `Event`.`event` = ? AND `Event`.`adminEmail` = ?";
			PreparedStatement queryStmt = dbConn.prepareStatement(eventQuery);
			System.out.println(curEvent);
			System.out.println(curAdmin);
			queryStmt.setString(1, curEvent);
			queryStmt.setString(2, curAdmin);
			ResultSet myResults = queryStmt.executeQuery();
			if(!myResults.next())
			{
				System.out.println("No event");
				return;
			}
			password = myResults.getString("password");
			continuous = myResults.getString("continuous");
			if(myResults.wasNull())
			{
				continuous = "";
			}
			taskgui = myResults.getString("taskgui");
			if(myResults.wasNull())
			{
				taskgui = "";
			}
			myResults.close();
			queryStmt.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
		boolean foundOK = false;
		String myNewToken = "";
		Gson myGson = new Gson();
		try
		{
			myNewToken = UUID.randomUUID().toString();
			
			String firstQuery = "SELECT * FROM `UserList` WHERE `event` = ? AND `username` = ? AND `adminEmail` = ?";
			PreparedStatement queryStmt = dbConn.prepareStatement(firstQuery);
			queryStmt.setString(1, curEvent);
			queryStmt.setString(2, curUsername);
			queryStmt.setString(3, curAdmin);
			
			ResultSet firstResults = queryStmt.executeQuery();
			if(!firstResults.next())
			{
				System.out.println(curUsername + ": no such user");
				response.getWriter().append("Supplied token was wrong");
				response.getWriter().close();
				firstResults.close();
				queryStmt.close();
				dbConn.close();
				return;
			}
			
			//String args = java.net.URLEncoder.encode("username=" + curUsername + "&event=" + curEvent + "&verifier=" + password + "&admin=" + curAdmin, "UTF-8");
			/* Old serverside web request to other server endpoints /OWO\
			String args = "username=" + curUsername + "&event=" + java.net.URLEncoder.encode(curEvent, "UTF-8") + "&verifier=" + password + "&admin=" + curAdmin + "&token=" + java.net.URLEncoder.encode(myNewToken, "UTF-8");
			String verifierURL = "http://localhost:8080/DataCollectorServer/openDataCollection/UserEventStatus?" + args;
			System.out.println(verifierURL);
			URL myURL = new URL(verifierURL);
			InputStream in = myURL.openStream();
			String reply = org.apache.commons.io.IOUtils.toString(in);
			org.apache.commons.io.IOUtils.closeQuietly(in);
			System.out.println(reply);
			HashMap replyMap = myGson.fromJson(reply, HashMap.class);
			if(reply.isEmpty() || replyMap.get("result").equals("nokay") || !replyMap.get("result").equals("ok"))
			{
				return;
			}
			*/
			
			
			while(!foundOK)
			{
				myNewToken = UUID.randomUUID().toString();
				
				String query = "SELECT * FROM `UploadToken` WHERE `event` = ? AND `username` = ? AND `token` = ? AND `adminEmail` = ?";
				PreparedStatement toInsert = dbConn.prepareStatement(query);
				
				toInsert.setString(1, curEvent);
				toInsert.setString(2, curUsername);
				toInsert.setString(3, myNewToken);
				toInsert.setString(4, curAdmin);
				ResultSet myResults = toInsert.executeQuery();
				
				if(!myResults.next())
				{
					System.out.println(myNewToken + ": no such token");
					foundOK = true;
				}
				
				/* Old code where we did localhost web requests on the same server, nothing to see here >_>
				//args = java.net.URLEncoder.encode("username=" + curUsername + "&event=" + curEvent + "&verifier=" + password + "&admin=" + curAdmin, "UTF-8");
				args = "username=" + curUsername + "&event=" + java.net.URLEncoder.encode(curEvent, "UTF-8") + "&verifier=" + password + "&admin=" + curAdmin + "&token=" + java.net.URLEncoder.encode(myNewToken, "UTF-8");
				verifierURL = "http://localhost:8080/DataCollectorServer/openDataCollection/TokenStatus?" + args;
				System.out.println(verifierURL);
				myURL = new URL(verifierURL);
				in = myURL.openStream();
				reply = org.apache.commons.io.IOUtils.toString(in);
				org.apache.commons.io.IOUtils.closeQuietly(in);
				System.out.println(reply);
				replyMap = myGson.fromJson(reply, HashMap.class);
				if(!(replyMap == null) && replyMap.containsKey("result") && replyMap.get("result").equals("nokay"))
				{
					foundOK = true;
				}
				*/
			}
			
			int isContinuous = 0;
			if(!continuous.equals(""))
			{
				isContinuous = 1;
			}
			
			String query = "INSERT INTO `UploadToken` (`event`, `username`, `token`, `continuous`, `adminEmail`) VALUES (?, ?, ?, ?, ?);";
			
			PreparedStatement toInsert = dbConn.prepareStatement(query);
			toInsert.setString(1, curEvent);
			toInsert.setString(2, curUsername);
			toInsert.setString(3, myNewToken);
			toInsert.setInt(4, isContinuous);
			toInsert.setString(5, curAdmin);
			toInsert.execute();
			
			/* This hacky solution brought to you by earlier versions and already existing server
			 * endpoints, cringeeeeee <_<
			args = "username=" + curUsername + "&event=" + java.net.URLEncoder.encode(curEvent, "UTF-8") + "&token=" + java.net.URLEncoder.encode(myNewToken, "UTF-8") + "&admin=" + curAdmin + "&mode=continuous&verifier=" + password;
			System.out.println("http://localhost:8080/DataCollectorServer/openDataCollection/AddToken?" + args);
			String addTokenURL = "http://localhost:8080/DataCollectorServer/openDataCollection/AddToken?" + args;
			myURL = new URL(addTokenURL);
			in = myURL.openStream();
			reply = org.apache.commons.io.IOUtils.toString(in);
			org.apache.commons.io.IOUtils.closeQuietly(in);
			*/
			if(!continuous.equals(""))
			{
				continuous = "-continuous " + myNewToken + " " + continuous;
			}
			
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
		if(dbConn != null)
		{
			try
			{
				dbConn.close();
			}
			catch (SQLException e)
			{
				e.printStackTrace();
			}
		}
		
		//Reverse proxy made this necessary, since URL URL does not match actual server domain
		//Add a config file to change this I guess :/
		String serverName = "revenge.cs.arizona.edu";
		String port = "80";
		
		String mariaPassword = "LFgVMrQ8rqR41StN";
		
		String output = "";
		if(curDevice.equals("debvm") || curDevice.equals("debrpi"))
		{
			output = "#!/bin/bash" 
			+ "\nclear" 
			+ "\n" 
			+ "\necho \"You are about to install the data collection suite from the Catalyst Open Data Collection engine.  Please review the documentation for this software at the location you downloaded it.  Generalized documentation for this software and information about your particular event can also be found at the following locations:\"" 
			+ "\n" 
			+ "\necho \"\"" 
			+ "\n" 
			+ "\necho \"http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/index.jsp\"" 
			+ "\necho \"http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/event.jsp?event=" + curEvent + "&admin=" + curAdmin + "\"" 
			+ "\n" 
			+ "\necho \"\"" 
			+ "\n" 
			+ "\necho \"When you downloaded this software, you were given a consent document.  Do you agree to the appropriate consent document and to use this software as intended and described in the links above, with no warranty and understanding the risks of using this software?  Please enter yes or no.  If you enter yes, you agree that you have read and agree to any and all appropriate consent agreements.  To confirm, do you agree to the appropriate consent terms located at the links above?  Entering yes will install the data collection software suite and restart your device to launch the data collection software.\"" 
			+ "\n" 
			+ "\nread CONSENT" 
			+ "\n" 
			+ "\nCONSENT=${CONSENT,,}" 
			+ "\necho $CONSENT" 
			+ "\n" 
			+ "\nif [ \"$CONSENT\" != \"yes\" ]" 
			+ "\nthen" 
			+ "\n\techo \"You did not enter yes.  Exiting now.\"" 
			+ "\n\texit 1" 
			+ "\nfi" 
			+ "\n"
			+ "\nsuccessfulInstall=true"
			+ "\n" 
			+ "\necho \"Starting data collection install\"" 
			+ "\n" 
			+ "\necho \"Updating OS\"" 
			+ "\nsudo rm /var/lib/dpkg/lock >> installOutput.txt"
			+ "\nsudo rm /var/cache/apt/archives/lock >> installOutput.txt"
			+ "\nsudo dpkg --configure -a >> installOutput.txt" 
			+ "\nsudo apt-get -y clean >> installOutput.txt" 
			+ "\nsudo rm /var/lib/dpkg/lock >> installOutput.txt"
			+ "\nsudo rm /var/cache/apt/archives/lock >> installOutput.txt"
			+ "\nsudo dpkg --configure -a >> installOutput.txt" 
			+ "\nsudo apt-get -y update --fix-missing >> installOutput.txt"
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: OS update failed\""
			+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"OS update successful\""
			+ "\nfi"
			+ "\necho \"Synchronizing clock with chrony\""
			+ "\ntimeout 30 sudo apt-get -y install chrony >> installOutput.txt"
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: chrony install failed\""
			+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"chrony install successful\""
			+ "\nfi"
			+ "\ntimeout 30 sudo chronyd -q >> installOutput.txt"
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: chrony sync failed, attempting to sync with other tools but assuming clock is accurate already\""
			+ "\n\tsudo timedatectl set-ntp True >> installOutput.txt"
			+ "\n\tsudo timedatectl >> installOutput.txt"
			+ "\n\tsudo apt-get -y install ntpdate >> installOutput.txt"
			+ "\n\tsudo /etc/init.d/ntp stop >> installOutput.txt"
			+ "\n\tsudo ntpd -q -g >> installOutput.txt"
			+ "\n\tsudo /etc/init.d/ntp start >> installOutput.txt"
			//+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"chrony sync successful\""
			+ "\nfi"
			+ "\necho \"Installing wget\""
			+ "\nsudo apt-get -y install wget >> installOutput.txt" 
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: wget install failed\""
			+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"wget install successful\""
			+ "\nfi"
			+ "\necho \"Installing Java JRE\""
			//+ "\nsudo apt-get -y install default-jre >> installOutput.txt" 
			+ "\nsudo add-apt-repository -y ppa:linuxuprising/java >> installOutput.txt" 
			+ "\nsudo apt-get -y update >> installOutput.txt" 
			+ "\nsudo apt-get -y install oracle-java16-installer" 
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: Oracle Java install failed, trying default OpenJDK.  Warning: OpenJDK may not work with Wayland, so convert to X11 if you have issues.\""
			//+ "\n\tsuccessfulInstall=false"
			+ "\n\tsudo apt-get -y install default-jre >> installOutput.txt" 
			+ "\n\tif [[ $? > 0 ]]"
			+ "\n\tthen"
			+ "\n\t\techo \"Warning: Java install failed.\""
			+ "\n\t\tsuccessfulInstall=false"
			+ "\n\telse"
			+ "\n\t\techo \"Java install successful\""
			+ "\n\tfi"
			+ "\nelse"
			+ "\n\techo \"Java install successful\""
			+ "\nfi"
			//+ "\nsudo apt-get -y install mariadb-server" 
			+ "\necho \"Installing SQL database, options are MySql and MariaDB\""
			+ "\necho \"Attempting to install MySql\""
			+ "\nsudo apt-get -y install mysql-server >> installOutput.txt" 
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ 		"\n\techo \"Warning: MySql install failed, trying MariaDB\""
			+ 		"\n\tsudo apt-get -y install mariadb-server >> installOutput.txt" 
			+ 		"\n\tif [[ $? > 0 ]]"
			+ 		"\n\tthen"
			+ 			"\n\t\techo \"Warning: MariaDB install failed\""
			+ 			"\n\t\tsuccessfulInstall=false"
			+ 		"\n\telse"
			+ 			"\n\t\techo \"MariaDB install successful\""
			+ 		"\n\tfi"
			+ "\nelse"
			+ 		"\n\techo \"MySql install successful\""
			+ "\nfi"
			+ "\necho \"Installing Tomcat, attempting versions 8 and 9\""
			+ "\necho \"Attempting to install Tomcat 8\""
			+ "\nsudo apt-get -y install tomcat8 >> installOutput.txt" 
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ 		"\n\techo \"Warning: version 8 install failed, trying version 9\""
			+ 		"\n\tsudo apt-get -y install tomcat9 >> installOutput.txt" 
			+ 		"\n\tif [[ $? > 0 ]]"
			+ 		"\n\tthen"
			+ 			"\n\t\techo \"Warning: Version 9 install failed\""
			+ 			"\n\t\tsuccessfulInstall=false"
			+ 		"\n\telse"
			+ 			"\n\t\techo \"Version 9 install successful, downloading webapp\""
			+ 			"\n\t\twget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war  >> installOutput.txt"
			+ 		"\n\tfi"
			+ "\nelse"
			+ 		"\n\techo \"Version 8 install successful, downloading webapp\""
			+ 		"\n\twget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war  >> installOutput.txt"
			+ "\nfi"
			+ "\n\nsudo service mysql start >> installOutput.txt"
			+ "\necho \"Configuring mysql as service\""
			+ "\nsudo update-rc.d mysql enable >> installOutput.txt"
			//+ "\n\nsudo update-rc.d mysql defaults"
			//+ "\n\nsudo rm /etc/init/mysql.override"
			//+ "\n\nsudo /sbin/chkconfig mysqld on"
			
			+ "\necho \"Building data collection directory at /opt/dataCollector/\""
			+ "\nsudo mkdir -p /opt/dataCollector/ >> installOutput.txt" 
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: Directory creation unsuccessful\""
			+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"Directory creation successful\""
			+ "\nfi"
			+ "\necho \"Downloading SQL configuration file\""
			+ "\n\nsudo wget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/dataCollection.sql -O /opt/dataCollector/dataCollection.sql >> installOutput.txt"
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: Download failed\""
			+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"Download successful\""
			+ "\nfi"
			//+ "\n\nsudo mariadb -u root < /opt/dataCollector/dataCollection.sql"
			//+ "\nsudo mariadb -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\""
			//+ "\nsudo mariadb -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\""
			//+ "\nsudo mariadb -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\""
			+ "\necho \"Configuring database\""
			+ "\n\nsudo mysql -u root < /opt/dataCollector/dataCollection.sql >> installOutput.txt"
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: Database config failed\""
			+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"Database config successful\""
			+ "\nfi"
			+ "\nsudo mysql -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\" >> installOutput.txt"
			+ "\nsudo mysql -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\"  >> installOutput.txt"
			+ "\nsudo mysql -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\"  >> installOutput.txt"
			+ "\n"
			//+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war  >> installOutput.txt"
			//+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat9/webapps/CybercraftDataCollectionConnector.war  >> installOutput.txt"
			+ "\n"
			+ "\n# Copy jar to install dir" 
			+ "\n" 
			//+ "\n#mv ./DataCollector.jar /opt/dataCollector/" 
			+ "\necho \"Downloading data collection executable\""
			+ "\nsudo wget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/DataCollector.jar -O /opt/dataCollector/DataCollector.jar >> installOutput.txt" 
			+ "\nif [[ $? > 0 ]]"
			+ "\nthen"
			+ "\n\techo \"Warning: Download failed\""
			+ "\n\tsuccessfulInstall=false"
			+ "\nelse"
			+ "\n\techo \"Download successful\""
			+ "\nfi"
			+ "\nsudo chmod +777 /opt/dataCollector" 
			+ "\nsudo chmod +777 /opt/dataCollector/" 
			+ "\nsudo chmod +777 /opt/dataCollector/*" 
			+ "\nsudo chmod +777 /opt/dataCollector/DataCollector.jar" 
			+ "\nsudo chmod +x /opt/dataCollector/DataCollector.jar" 
			+ "\n" 
			+ "\n" 
			+ "\necho \"Configuring launch at startup\""
			+ "\ntee /opt/dataCollector/DataCollectorStart.sh > /dev/null <<'EOF'" 
			+ "\n#!/bin/bash" 
			//+ "\nservice mysql start" 
			//+ "\nservice tomcat8 start"
			//+ "\nservice tomcat9 start"
			+ "\nservice mysql start"
			+ "\nwhile true;" 
			+ "\ndo" 
			+ "\npkill -f \"/usr/bin/java -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar\"" 
			//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curUsername + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/openDataCollection/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
			+ "\n/usr/bin/java -Xmx1536m -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar -user " + curUsername + " -server " + serverName + ":" + port + " -adminemail " + curAdmin + " -event '" + curEvent + "' " + continuous + " " + taskgui + " -screenshot " + screenshotTime + " >> /opt/dataCollector/log.log 2>&1" 
			+ "\necho \"Got a crash: $(date)\" >> /opt/dataCollector/log.log" 
			+ "\nsleep 2" 
			+ "\ndone" 
			+ "\nEOF" 
			+ "\n" 
			+ "\nsudo chmod +777 /opt/dataCollector/DataCollectorStart.sh" 
			+ "\nsudo chmod +x /opt/dataCollector/DataCollectorStart.sh" 
			+ "\n" 
			+ "\nsudo touch /opt/dataCollector/log.log" 
			+ "\nsudo chmod +777 /opt/dataCollector/log.log" 
			+ "\n" 
			+ "\n# Launch script" 
			+ "\n" 
			+ "\nLOG_NAME=$(logname)" 
			+ "\nmkdir /home/$LOG_NAME/.config/autostart/"
			+ "\ntee /home/$LOG_NAME/.config/autostart/DataCollector.desktop > /dev/null <<'EOF'" 
			+ "\n[Desktop Entry]" 
			+ "\nType=Application" 
			+ "\nExec=\"/opt/dataCollector/DataCollectorStart.sh\"" 
			+ "\nHidden=false" 
			+ "\nNoDisplay=false" 
			+ "\nX-GNOME-Autostart-enabled=true" 
			+ "\nName[en_IN]=DataCollector" 
			+ "\nName=DataCollector" 
			+ "\nComment[en_IN]=Collects data" 
			+ "\nComment=Collects data" 
			+ "\nEOF" 
			+ "\n" 
			//+ "\nservice mysql start" 
			//+ "\nservice tomcat8 start"
			//+ "\nservice tomcat9 start"
			+ "\n"
			//+ "\n/opt/dataCollector/DataCollectorStart.sh & disown" ;
			+ "\nif $successfulInstall ;"
			+ "\nthen"
			+ "\n\tif [ \"$XDG_SESSION_TYPE\" != \"x11\" ]; then"
			+ "\n\t\techo \"Warning: Not currently running x11.  Note that wayland is not currently compatible with this software.  Proceed at your own risk and contact admins if you want to check whether the data collection is working.  This software will attempt to run upon reboot.\""
			+ "\n\telse"
			+ "\n\t\treboot"
			+ "\n\tfi"
			+ "\nelse"
			+ "\n\techo \"Warning: Installer completed with errors.  See installOutput.txt for a log.\""
			+ "\nfi;" ;
			//+ "\nsudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password " + mySqlPassword + "'" 
			//+ "\nsudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password " + mySqlPassword + "'" 
			//+ "\nsudo apt-get -y install mysql-server" 
			//+ "\nsudo apt-get -y install mysql-client" 
			/*
			+ "\n\nservice mysql start"
			+ "\nmkdir -p /opt/dataCollector/" 
			+ "\n\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/dataCollection.sql -O /opt/dataCollector/dataCollection.sql"
			+ "\n\nmariadb -u root < /opt/dataCollector/dataCollection.sql"
			+ "\nmariadb -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\""
			+ "\nmariadb -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\""
			+ "\nmariadb -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\""
			+ "\n"
			+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war"
			+ "\n"
			+ "\n# Copy jar to install dir" 
			+ "\n" 
			+ "\n#mv ./DataCollector.jar /opt/dataCollector/" 
			+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/DataCollector.jar -O /opt/dataCollector/DataCollector.jar" 
			+ "\nchmod +777 /opt/dataCollector/DataCollector.jar" 
			+ "\nchmod +x /opt/dataCollector/DataCollector.jar" 
			+ "\n" 
			+ "\n" 
			+ "\ntee /opt/dataCollector/DataCollectorStart.sh > /dev/null <<'EOF'" 
			+ "\n#!/bin/bash" 
			+ "\nservice mysql start" 
			+ "\nservice tomcat8 start"
			+ "\nservice tomcat9 start"
			+ "\nwhile true;" 
			+ "\ndo" 
			+ "\npkill -f \"/usr/bin/java -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar\"" 
			//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curUsername + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/openDataCollection/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
			+ "\n/usr/bin/java -Xmx1536m -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar -user " + curUsername + " -server " + serverName + ":" + port + " -event " + curEvent + " " + continuous + " " + taskgui + " -screenshot " + screenshotTime + " >> /opt/dataCollector/log.log 2>&1" 
			+ "\necho \"Got a crash: $(date)\" >> /opt/dataCollector/log.log" 
			+ "\nsleep 2" 
			+ "\ndone" 
			+ "\nEOF" 
			+ "\n" 
			+ "\nchmod +777 /opt/dataCollector/DataCollectorStart.sh" 
			+ "\nchmod +x /opt/dataCollector/DataCollectorStart.sh" 
			+ "\n" 
			+ "\ntouch /opt/dataCollector/log.log" 
			+ "\nchmod +777 /opt/dataCollector/log.log" 
			+ "\n" 
			+ "\n# Launch script" 
			+ "\n" 
			+ "\nmkdir ~/.config/autostart/"
			+ "\ntee ~/.config/autostart/DataCollector.desktop > /dev/null <<'EOF'" 
			+ "\n[Desktop Entry]" 
			+ "\nType=Application" 
			+ "\nExec=\"/opt/dataCollector/DataCollectorStart.sh\"" 
			+ "\nHidden=false" 
			+ "\nNoDisplay=false" 
			+ "\nX-GNOME-Autostart-enabled=true" 
			+ "\nName[en_IN]=DataCollector" 
			+ "\nName=DataCollector" 
			+ "\nComment[en_IN]=Collects data" 
			+ "\nComment=Collects data" 
			+ "\nEOF" 
			+ "\n" 
			+ "\nservice mysql start" 
			+ "\nservice tomcat8 start"
			+ "\nservice tomcat9 start"
			+ "\n"
			+ "\n/opt/dataCollector/DataCollectorStart.sh & disown" ;
			*/
		}
		else if(curDevice.equals("fedvm"))
		{
			output = "#!/bin/bash" 
					+ "\nclear" 
					+ "\n" 
					+ "\necho \"You are about to install the data collection suite from the Catalyst Open Data Collection engine.  Please review the documentation for this software at the location you downloaded it.  Generalized documentation for this software and information about your particular event can also be found at the following locations:\"" 
					+ "\n" 
					+ "\necho \"\"" 
					+ "\n" 
					+ "\necho \"http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/openDataCollection/index.jsp\"" 
					+ "\necho \"http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/openDataCollection/event.jsp?event=" + curEvent + "\"" 
					+ "\n" 
					+ "\necho \"\"" 
					+ "\n" 
					+ "\necho \"When you downloaded this software, you were given and agreed to a consent document.  Do you agree to the appropriate consent document?  Please enter yes or no.  If you enter yes, you agree that you have read and agree to the appropriate consent agreement.  To confirm, do you agree to the appropriate consent terms located at the links above?  Entering yes will install the data collection software suite.\"" 
					+ "\n" 
					+ "\nread CONSENT" 
					+ "\n" 
					+ "\nCONSENT=${CONSENT,,}" 
					+ "\necho $CONSENT" 
					+ "\n" 
					+ "\nif [ \"$CONSENT\" != \"yes\" ]" 
					+ "\nthen" 
					+ "\n\techo \"You did not enter yes.  Exiting now.\"" 
					+ "\n\texit 1" 
					+ "\nfi" 
					+ "\n" 
					+ "\necho \"Starting data collection install\"" 
					+ "\n" 
					+ "\nsudo dnf update -y"
					+ "\nsudo dnf upgrade -y"
					+ "\nsudo dnf update -y"
					+ "\n"
					+ "\nsudo dnf install java-11 -y"
					+ "\nsudo dnf install javapackages-tools -y"
					+ "\n"
					+ "\nsudo dnf install mariadb-server -y"
					+ "\nsudo systemctl start mariadb.service"
					+ "\nsudo systemctl enable mariadb.service"
					+ "\n"
					+ "\nsudo dnf install tomcat -y"
					+ "\nsudo systemctl start tomcat.service"
					+ "\nsudo systemctl enable tomcat.service"
					+ "\n"
					+ "\nmkdir -p /opt/dataCollector/" 
					+ "\n\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/dataCollection.sql -O /opt/dataCollector/dataCollection.sql"
					+ "\n\nmariadb -u root < /opt/dataCollector/dataCollection.sql"
					+ "\nmariadb -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\""
					+ "\nmariadb -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\""
					+ "\nmariadb -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\""
					+ "\n"
					+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war"
					+ "\n"
					+ "\n# Copy jar to install dir" 
					+ "\n" 
					+ "\n#mv ./DataCollector.jar /opt/dataCollector/" 
					+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/DataCollector.jar -O /opt/dataCollector/DataCollector.jar" 
					+ "\nchmod +777 /opt/dataCollector/DataCollector.jar" 
					+ "\nchmod +x /opt/dataCollector/DataCollector.jar" 
					+ "\n" 
					+ "\n" 
					+ "\ntee /opt/dataCollector/DataCollectorStart.sh > /dev/null <<'EOF'" 
					+ "\n#!/bin/bash" 
					+ "\nwhile true;" 
					+ "\ndo" 
					+ "\nservice mysql start" 
					+ "\nservice tomcat8 start"
					+ "\nservice tomcat9 start"
					+ "\npkill -f \"/usr/bin/java -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar\"" 
					//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curUsername + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/openDataCollection/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
					+ "\n/usr/bin/java -Xmx1536m -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar -user " + curUsername + " -server " + serverName + ":" + port + " -event '" + curEvent + "' " + continuous + " " + taskgui + " -screenshot " + screenshotTime + " >> /opt/dataCollector/log.log 2>&1" 
					+ "\necho \"Got a crash: $(date)\" >> /opt/dataCollector/log.log" 
					+ "\nsleep 2" 
					+ "\ndone" 
					+ "\nEOF" 
					+ "\n" 
					+ "\nchmod +777 /opt/dataCollector/DataCollectorStart.sh" 
					+ "\nchmod +x /opt/dataCollector/DataCollectorStart.sh" 
					+ "\n" 
					+ "\ntouch /opt/dataCollector/log.log" 
					+ "\nchmod +777 /opt/dataCollector/log.log" 
					+ "\n" 
					+ "\n# Launch script" 
					+ "\n" 
					+ "\nmkdir ~/.config/autostart/"
					+ "\ntee ~/.config/autostart/DataCollector.desktop > /dev/null <<'EOF'" 
					+ "\n[Desktop Entry]" 
					+ "\nType=Application" 
					+ "\nExec=\"/opt/dataCollector/DataCollectorStart.sh\"" 
					+ "\nHidden=false" 
					+ "\nNoDisplay=false" 
					+ "\nX-GNOME-Autostart-enabled=true" 
					+ "\nName[en_IN]=DataCollector" 
					+ "\nName=DataCollector" 
					+ "\nComment[en_IN]=Collects data" 
					+ "\nComment=Collects data" 
					+ "\nEOF" 
					+ "\n" 
					+ "\nservice mysql start" 
					+ "\nservice tomcat8 start"
					+ "\nservice tomcat9 start"
					+ "\n"
					+ "\n/opt/dataCollector/DataCollectorStart.sh & disown" ;
		}
		else if(curDevice.equals("winvm"))
		{
			output = "@ECHO OFF\n" + 
					"echo You are about to install the data collection suite from the Catalyst Open Data Collection engine.  Please review the documentation for this software at the location you downloaded it.  Generalized documentation for this software and information about your particular event can also be found at the following locations:\n" + 
					"\n" + 
					"echo\n" + 
					"\n" + 
					"echo http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/openDataCollection/index.jsp\n" + 
					"echo http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/openDataCollection/event.jsp?event=ReverseEngineeringStudy2\n" + 
					"\n" + 
					"echo\n" + 
					"\n" + 
					"echo When you downloaded this software, you were given and agreed to a consent document.  Do you agree to the appropriate consent document?  Please enter yes or no.  If you enter yes, you agree that you have read and agree to the appropriate consent agreement.  To confirm, do you agree to the appropriate consent terms located at the links above?  Entering yes will install the data collection software suite.\n" + 
					"\n" + 
					"set /p ans=Do you agree?: \n" + 
					"if NOT \"%ans%\" == \"Yes\" (exit)\n" + 
					"\n" + 
					"mkdir C:\\mysql\\logs\n" + 
					"mkdir C:\\mysql\\mydb\n" + 
					"\n" + 
					"\n" + 
					"bitsadmin /transfer myDownloadJob /download /priority high https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.23-winx64.zip C:\\mysql\\mysql-8.0.23-winx64.zip\n" + 
					"tar -xf C:\\mysql\\mysql-8.0.23-winx64.zip -C C:\\mysql\\\n" + 
					"\n" + 
					"bitsadmin /transfer myDownloadJob /download /priority high http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/config.ini C:\\mysql\\config.ini\n" + 
					"\"C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysqld.exe\" --defaults-file=\"C:\\\\mysql\\\\config.ini\" --initialize-insecure --console\n" + 
					"\n" + 
					"start /B C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysqld.exe --defaults-file=\"C:\\\\mysql\\\\config.ini\"\n" + 
					"bitsadmin /transfer myDownloadJob /download /priority high http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/dataCollection.sql C:\\mysql\\dataCollection.sql\n" + 
					":wait_for_mysql\n" + 
					"	C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysql.exe -uroot < C:\\mysql\\dataCollection.sql\n" + 
					"	IF ERRORLEVEL 1 GOTO wait_for_mysql\n" + 
					"C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysql.exe -uroot -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY 'LFgVMrQ8rqR41StN';\"\n" + 
					"C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysql.exe -uroot -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\"\n" + 
					"C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysql.exe -uroot -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\"\n" + 
					"\n" + 
					"\n" + 
					"\n" + 
					"mkdir C:\\datacollector\n" + 
					"bitsadmin /transfer myDownloadJob /download /priority high http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/DataCollectorOld.jar C:\\datacollector\\DataCollector.jar\n" + 
					"\n" + 
					"echo start /B C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysqld.exe --defaults-file=\"C:\\\\mysql\\\\config.ini\"> \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\StartDataCollection.bat\"\n" + 
					"echo :wait_for_mysql>> \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\StartDataCollection.bat\"\n" + 
					"echo 	C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysql.exe -uroot -e \";\">> \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\StartDataCollection.bat\"\n" + 
					"echo 	IF ERRORLEVEL 1 GOTO wait_for_mysql>> \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\StartDataCollection.bat\"\n" +
					"echo start /B java -jar -XX:+IgnoreUnrecognizedVMOptions C:\\datacollector\\DataCollector.jar -user " + curUsername + " -server " + serverName + ":" + port + " -adminemail " + curAdmin + " -event '" + curEvent + "' " + continuous + " " + taskgui + " -screenshot " + screenshotTime + ">> \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\StartDataCollection.bat\"\n" + 
					"shutdown /R\n" + 
					"";
		}
		response.getWriter().append(output);
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		doGet(request, response);
	}

}
