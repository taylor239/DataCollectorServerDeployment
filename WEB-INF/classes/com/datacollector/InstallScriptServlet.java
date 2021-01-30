package com.datacollector;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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
		
		String curEmail = request.getParameter("username");
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
		
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
			DatabaseConnector myConnector=(DatabaseConnector)session.getAttribute("connector");
			if(myConnector==null)
			{
				myConnector=new DatabaseConnector(getServletContext());
				session.setAttribute("connector", myConnector);
			}
			TestingConnectionSource myConnectionSource = myConnector.getConnectionSource();
			
			
			Connection dbConn = myConnectionSource.getDatabaseConnection();
			
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
			//String args = java.net.URLEncoder.encode("username=" + curEmail + "&event=" + curEvent + "&verifier=" + password + "&admin=" + curAdmin, "UTF-8");
			String args = "username=" + curEmail + "&event=" + java.net.URLEncoder.encode(curEvent, "UTF-8") + "&verifier=" + password + "&admin=" + curAdmin + "&token=" + java.net.URLEncoder.encode(myNewToken, "UTF-8");
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
			
			
			while(!foundOK)
			{
				myNewToken = UUID.randomUUID().toString();
				//args = java.net.URLEncoder.encode("username=" + curEmail + "&event=" + curEvent + "&verifier=" + password + "&admin=" + curAdmin, "UTF-8");
				args = "username=" + curEmail + "&event=" + java.net.URLEncoder.encode(curEvent, "UTF-8") + "&verifier=" + password + "&admin=" + curAdmin + "&token=" + java.net.URLEncoder.encode(myNewToken, "UTF-8");
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
			}
			args = "username=" + curEmail + "&event=" + java.net.URLEncoder.encode(curEvent, "UTF-8") + "&token=" + java.net.URLEncoder.encode(myNewToken, "UTF-8") + "&admin=" + curAdmin + "&mode=continuous&verifier=" + password;
			System.out.println("http://localhost:8080/DataCollectorServer/openDataCollection/AddToken?" + args);
			String addTokenURL = "http://localhost:8080/DataCollectorServer/openDataCollection/AddToken?" + args;
			myURL = new URL(addTokenURL);
			in = myURL.openStream();
			reply = org.apache.commons.io.IOUtils.toString(in);
			org.apache.commons.io.IOUtils.closeQuietly(in);
			if(!continuous.equals(""))
			{
				continuous = "-continuous " + myNewToken + " " + continuous;
			}
			
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
		
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
			+ "\nsudo rm /var/lib/dpkg/lock"
			+ "\nsudo rm /var/cache/apt/archives/lock"
			+ "\nsudo dpkg --configure -a" 
			+ "\nsudo apt-get -y clean" 
			+ "\nsudo rm /var/lib/dpkg/lock"
			+ "\nsudo rm /var/cache/apt/archives/lock"
			+ "\nsudo dpkg --configure -a" 
			+ "\nsudo apt-get -y update --fix-missing" 
			+ "\nsudo rm /var/lib/dpkg/lock"
			+ "\nsudo rm /var/cache/apt/archives/lock"
			+ "\nsudo dpkg --configure -a" 
			+ "\nsudo apt-get -y upgrade" 
			+ "\nsudo rm /var/lib/dpkg/lock"
			+ "\nsudo rm /var/cache/apt/archives/lock"
			+ "\nsudo dpkg --configure -a" 
			+ "\nsudo apt-get -y update --fix-missing" 
			+ "\nsudo rm /var/lib/dpkg/lock"
			+ "\nsudo rm /var/cache/apt/archives/lock"
			+ "\nsudo dpkg --configure -a" 
			+ "\nsudo apt-get -y dist-upgrade" 
			+ "\nsudo rm /var/lib/dpkg/lock"
			+ "\nsudo rm /var/cache/apt/archives/lock"
			+ "\nsudo dpkg --configure -a" 
			+ "\nsudo apt-get -y update --fix-missing" 
			+ "\nsudo rm /var/lib/dpkg/lock"
			+ "\nsudo rm /var/cache/apt/archives/lock"
			+ "\nsudo dpkg --configure -a" 
			+ "\nsudo apt-get -y install default-jre" 
			//+ "\nsudo apt-get -y install mariadb-server" 
			+ "\nsudo apt-get -y install mysql-server" 
			+ "\nsudo apt-get -y install mariadb-server" 
			+ "\nsudo apt-get -y install tomcat8"
			+ "\nsudo apt-get -y install tomcat9" 
			+ "\n\nsudo service mysql start"
			
			+ "\nsudo update-rc.d mysql enable"
			//+ "\n\nsudo update-rc.d mysql defaults"
			//+ "\n\nsudo rm /etc/init/mysql.override"
			//+ "\n\nsudo /sbin/chkconfig mysqld on"
			
			+ "\nmkdir -p /opt/dataCollector/" 
			+ "\n\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/dataCollection.sql -O /opt/dataCollector/dataCollection.sql"
			//+ "\n\nsudo mariadb -u root < /opt/dataCollector/dataCollection.sql"
			//+ "\nsudo mariadb -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\""
			//+ "\nsudo mariadb -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\""
			//+ "\nsudo mariadb -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\""
			+ "\n\nsudo mysql -u root < /opt/dataCollector/dataCollection.sql"
			+ "\nsudo mysql -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\""
			+ "\nsudo mysql -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\""
			+ "\nsudo mysql -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\""
			+ "\n"
			+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war"
			+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat9/webapps/CybercraftDataCollectionConnector.war"
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
			//+ "\nservice mysql start" 
			//+ "\nservice tomcat8 start"
			//+ "\nservice tomcat9 start"
			+ "\nservice mysql start"
			+ "\nwhile true;" 
			+ "\ndo" 
			+ "\npkill -f \"/usr/bin/java -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar\"" 
			//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/openDataCollection/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
			+ "\n/usr/bin/java -Xmx1536m -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -adminemail " + curAdmin + " -event " + curEvent + " " + continuous + " " + taskgui + " -screenshot " + screenshotTime + " >> /opt/dataCollector/log.log 2>&1" 
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
			+ "\nreboot" ;
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
			//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/openDataCollection/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
			+ "\n/usr/bin/java -Xmx1536m -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -event " + curEvent + " " + continuous + " " + taskgui + " -screenshot " + screenshotTime + " >> /opt/dataCollector/log.log 2>&1" 
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
					//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/openDataCollection/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
					+ "\n/usr/bin/java -Xmx1536m -jar -XX:+IgnoreUnrecognizedVMOptions /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -event " + curEvent + " " + continuous + " " + taskgui + " -screenshot " + screenshotTime + " >> /opt/dataCollector/log.log 2>&1" 
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
					"tar -xf C:\\mysql\\mysql-8.0.23-winx64.zip\n" + 
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
					"bitsadmin /transfer myDownloadJob /download /priority high http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/endpointSoftware/DataCollector.jar C:\\datacollector\\DataCollector.jar\n" + 
					"\n" + 
					"echo start /B C:\\mysql\\mysql-8.0.23-winx64\\bin\\mysqld.exe --defaults-file=\"C:\\\\mysql\\\\config.ini\"> \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\StartDataCollection.bat\"\n" + 
					"echo start /B java -jar -XX:+IgnoreUnrecognizedVMOptions C:\\datacollector\\DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -adminemail " + curAdmin + " -event " + curEvent + " " + continuous + " " + taskgui + " -screenshot " + screenshotTime + ">> \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\StartDataCollection.bat\"\n" + 
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
