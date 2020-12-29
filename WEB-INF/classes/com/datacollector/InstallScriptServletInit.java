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
@WebServlet("/installDataCollectionInit.sh")
public class InstallScriptServletInit extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public InstallScriptServletInit()
    {
        super();
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		HttpSession session = request.getSession(true);
		
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
			
			String eventQuery = "SELECT * FROM `Event` WHERE `Event`.`event` = ?";
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
		
		
		
		
		String serverName = "revenge.cs.arizona.edu";
		String port = "80";
		
		String mariaPassword = "LFgVMrQ8rqR41StN";
		
		String output = "";
		if(curDevice.equals("debvm") || curDevice.equals("debrpi"))
		{
			output = "#!/bin/bash" 
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
			+ "\nclear" 
			+ "\n" 
			+ "\necho \"You are about to install the data collection suite from the Catalyst Open Data Collection engine.  Please review the documentation for this software at the location you downloaded it.  Generalized documentation for this software and information about your particular event can also be found at the following locations:\"" 
			+ "\n" 
			+ "\necho \"\"" 
			+ "\n" 
			+ "\necho \"http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/index.jsp\"" 
			+ "\necho \"http://" + serverName + ":" + port + "/DataCollectorServer/openDataCollection/event.jsp?event=" + curEvent + "\"" 
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
			+ "\necho \"Please enter your token:\""
			+ "\nread TOKEN" 
			+ "\n" 
			+ "\nTOKEN=${TOKEN,,}" 
			+ "\necho $TOKEN" 
			+ "\n" 
			+ "\necho \"Starting data collection install\"" 
			+ "\n" 
			+ "\n\nwget \"http://" + serverName + ":" + port + "/DataCollectorServer/installDataCollectionStripped.sh?username=${TOKEN}&event=" + curEvent + "&devicetype=" + curDevice + "\" -O ./installDataCollectionStripped.sh"
			+ "\nchmod +777 ./installDataCollectionStripped.sh" 
			+ "\n./installDataCollectionStripped.sh" ;
		}
		else if(curDevice.equals("fedvm"))
		{
			
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
