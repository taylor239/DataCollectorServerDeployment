package com.datacollector;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

/**
 * Servlet implementation class GetUploadListServelet
 */
@WebServlet("/openDataCollection/GetUploadList")
public class GetUploadListServelet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public GetUploadListServelet() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		Gson gson = new GsonBuilder().create();
		String username = request.getParameter("username");
		String verify = request.getParameter("verifier");
		String event = request.getParameter("event");
		String admin = request.getParameter("admin");
		
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
			HttpSession session = request.getSession(true);
			DatabaseConnector myConnector=(DatabaseConnector)session.getAttribute("connector");
			if(myConnector==null)
			{
				myConnector=new DatabaseConnector(getServletContext());
				session.setAttribute("connector", myConnector);
			}
			TestingConnectionSource myConnectionSource = myConnector.getConnectionSource();
			
			
			Connection dbConn = myConnectionSource.getDatabaseConnection();
			
			String eventQuery = "SELECT * FROM `Event` INNER JOIN `EventContact` ON `Event`.`event` = `EventContact`.`event` WHERE `Event`.`event` = ? AND `Event`.`adminEmail` = ?";
			
			String desc = "";
			String start = "";
			String end = "";
			String password = "";
			ArrayList contactName = new ArrayList();
			ArrayList contacts = new ArrayList();
			try
			{
				PreparedStatement queryStmt = dbConn.prepareStatement(eventQuery);
				queryStmt.setString(1, event);
				queryStmt.setString(2, admin);
				ResultSet myResults = queryStmt.executeQuery();
				if(!myResults.next())
				{
					return;
				}
				desc = myResults.getString("description");
				start = myResults.getString("start");
				end = myResults.getString("end");
				password = myResults.getString("password");
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
			
			if(!verify.equals(password))
			{
				System.out.println("Challenge unacceptable");
				return;
			}
			
			String query = "SELECT * FROM `UploadToken` WHERE `username` = ? AND `event` = ? AND `adminEmail` = ?";
			
			System.out.println("Getting uploads from " + event + " " + username);
			
			PreparedStatement toInsert = dbConn.prepareStatement(query);
			toInsert.setString(1, username);
			toInsert.setString(2, event);
			toInsert.setString(3, admin);
			ResultSet myResults = toInsert.executeQuery();
			ArrayList totalOutput = new ArrayList();
			//System.out.println(myResults);
			while(myResults.next())
			{
				int framesUploaded = myResults.getInt("framesUploaded");
				int totalFrames = myResults.getInt("framesRemaining");
				boolean isActive = myResults.getBoolean("active");
				String token = myResults.getString("token");
				Timestamp lastAltered = myResults.getTimestamp("lastAltered");
				HashMap outputMap = new HashMap();
				outputMap.put("framesUploaded", framesUploaded);
				outputMap.put("framesLeft", totalFrames);
				outputMap.put("isActive", isActive);
				outputMap.put("username", username);
				outputMap.put("token", token);
				outputMap.put("event", event);
				outputMap.put("admin", admin);
				outputMap.put("lastAltered", lastAltered);
				totalOutput.add(outputMap);
			}
			String output = gson.toJson(totalOutput);
			response.getWriter().append(output);
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doGet(request, response);
	}

}
