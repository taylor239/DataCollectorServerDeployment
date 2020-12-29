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
@WebServlet("/installDataCollectionStripped.sh")
public class InstallScriptServletStripped extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public InstallScriptServletStripped()
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
		String curDevice = request.getParameter("devicetype");
		
		String osPrefix = "";
		
		int screenshotTime = 120000;
		if(curDevice.equals("debvm"))
		{
			screenshotTime = 60000;
		}
		else if(curDevice.equals("debrpi"))
		{
			screenshotTime = 240000;
		}
		if(curDevice.equals("fedvm"))
		{
			screenshotTime = 60000;
			osPrefix = "yum install apt";
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
			
			String eventQuery = "SELECT * FROM `openDataCollectionServer`.`Event` WHERE `openDataCollectionServer`.`Event`.`event` = ?";
			PreparedStatement queryStmt = dbConn.prepareStatement(eventQuery);
			queryStmt.setString(1, curEvent);
			ResultSet myResults = queryStmt.executeQuery();
			if(!myResults.next())
			{
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
			String verifierURL = "http://localhost:8080/DataCollectorServer/UserEventStatus?username=" + curEmail + "&event=" + curEvent + "&verifier=" + password;
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
				verifierURL = "http://localhost:8080/DataCollectorServer/TokenStatus?username=" + curEmail + "&event=" + curEvent + "&token=" + myNewToken + "&verifier=" + password;
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
			
			String addTokenURL = "http://localhost:8080/DataCollectorServer/AddToken?username=" + curEmail + "&event=" + curEvent + "&token=" + myNewToken + "&mode=continuous&verifier=" + password;
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
			+ "\necho \"Starting data collection install\"" 
			+ "\n" 
			+ "\nsudo apt-get -y install default-jre" 
			+ "\nsudo apt-get -y install mariadb-server" 
			+ "\nsudo apt-get -y install tomcat8"
			+ "\nsudo apt-get -y install tomcat9" 
			//+ "\nsudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password " + mySqlPassword + "'" 
			//+ "\nsudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password " + mySqlPassword + "'" 
			//+ "\nsudo apt-get -y install mysql-server" 
			//+ "\nsudo apt-get -y install mysql-client" 
			+ "\n\nservice mysql start"
			+ "\nmkdir -p /opt/dataCollector/" 
			+ "\n\nwget http://" + serverName + ":" + port + "/DataCollectorServer/endpointSoftware/dataCollection.sql -O /opt/dataCollector/dataCollection.sql"
			+ "\n\nmariadb -u root < /opt/dataCollector/dataCollection.sql"
			+ "\nmariadb -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\""
			+ "\nmariadb -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\""
			+ "\nmariadb -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\""
			+ "\n"
			+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war"
			+ "\n"
			+ "\n# Copy jar to install dir" 
			+ "\n" 
			+ "\n#mv ./DataCollector.jar /opt/dataCollector/" 
			+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/endpointSoftware/DataCollector.jar -O /opt/dataCollector/DataCollector.jar" 
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
			//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
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
		else if(curDevice.equals("fedvm"))
		{
			output = "#!/bin/bash" 
					+ "\nclear" 
					+ "\necho \"Starting data collection install\"" 
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
					+ "\n\nwget http://" + serverName + ":" + port + "/DataCollectorServer/endpointSoftware/dataCollection.sql -O /opt/dataCollector/dataCollection.sql"
					+ "\n\nmariadb -u root < /opt/dataCollector/dataCollection.sql"
					+ "\nmariadb -u root -e \"CREATE USER 'dataCollector'@'localhost' IDENTIFIED BY '" + mariaPassword + "';\""
					+ "\nmariadb -u root -e \"GRANT USAGE ON *.* TO 'dataCollector'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;\""
					+ "\nmariadb -u root -e \"GRANT ALL PRIVILEGES ON dataCollection.* TO 'dataCollector'@'localhost';\""
					+ "\n"
					+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/endpointSoftware/CybercraftDataCollectionConnector.war -O /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war"
					+ "\n"
					+ "\n# Copy jar to install dir" 
					+ "\n" 
					+ "\n#mv ./DataCollector.jar /opt/dataCollector/" 
					+ "\nwget http://" + serverName + ":" + port + "/DataCollectorServer/endpointSoftware/DataCollector.jar -O /opt/dataCollector/DataCollector.jar" 
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
					//+ "\n/usr/bin/java -Xmx1536m -jar /opt/dataCollector/DataCollector.jar -user " + curEmail + " -server " + serverName + ":" + port + " -event " + curEvent + " -continuous "+ myNewToken + " http://revenge.cs.arizona.edu/DataCollectorServer/UploadData" + " >> /opt/dataCollector/log.log 2>&1" 
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
