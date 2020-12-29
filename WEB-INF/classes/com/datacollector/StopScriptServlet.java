package com.datacollector;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
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
@WebServlet("/openDataCollection/stopDataCollection.sh")
public class StopScriptServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public StopScriptServlet()
    {
        super();
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		HttpSession session = request.getSession(true);
		
		
		String output = "#!/bin/bash" 
		+ "\nclear" 
		+ "\nmariadb -u root -e \"DROP DATABASE IF EXISTS dataCollection\""
		+ "\n"
		+ "\nrm -rf /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector.war"
		+ "\nrm -rf /var/lib/tomcat8/webapps/CybercraftDataCollectionConnector"
		+ "\n"
		+ "\nrm -rf /opt/dataCollector" 
		+ "\n" 
		+ "\n" 
		+ "\n# Launch script" 
		+ "\n" 
		+ "\nrm -rf ~/.config/autostart/DataCollector.desktop"
		+ "\npkill -f \"/opt/dataCollector/DataCollectorStart.sh\"" 
		+ "\npkill -f \"/usr/bin/java -jar /opt/dataCollector/DataCollector.jar\"" 
		+ "\npkill -f \"/opt/dataCollector/DataCollectorStart.sh\"" 
		+ "\npkill -f \"/usr/bin/java -jar /opt/dataCollector/DataCollector.jar\""
		+ "\nreboot" ;
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
