package com.datacollector;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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
 * Servlet implementation class TokenStatusServlet
 */
@WebServlet("/openDataCollection/TokenStatus")
public class TokenStatusServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public TokenStatusServlet() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		System.out.println("Got a request");
		Gson gson = new GsonBuilder().create();
		
		String username = request.getParameter("username");
		System.out.println(username);
		String event = request.getParameter("event");
		System.out.println(event);
		String token = request.getParameter("token");
		System.out.println(token);
		String admin = request.getParameter("admin");
		System.out.println(admin);
		String verify = request.getParameter("verifier");
		System.out.println(verify);
		
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
					HashMap outputMap = new HashMap();
					outputMap.put("result", "nokay");
					String output = gson.toJson(outputMap);
					response.getWriter().append(output);
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
				HashMap outputMap = new HashMap();
				outputMap.put("result", "nokay");
				String output = gson.toJson(outputMap);
				response.getWriter().append(output);
				return;
			}
			
			String query = "SELECT * FROM `UploadToken` WHERE `event` = ? AND `username` = ? AND `token` = ? AND `adminEmail` = ?";
			
			PreparedStatement toInsert = dbConn.prepareStatement(query);
			toInsert.setString(1, event);
			toInsert.setString(2, username);
			toInsert.setString(3, token);
			toInsert.setString(4, admin);
			ResultSet myResults = toInsert.executeQuery();
			if(!myResults.next())
			{
				System.out.println("no such token");
				HashMap outputMap = new HashMap();
				outputMap.put("result", "nokay");
				String output = gson.toJson(outputMap);
				response.getWriter().append(output);
				return;
			}
			int framesUploaded = myResults.getInt("framesUploaded");
			int totalFrames = myResults.getInt("framesRemaining");
			boolean isActive = myResults.getBoolean("active");
			boolean isContinuous = myResults.getBoolean("continuous");
			HashMap outputMap = new HashMap();
			outputMap.put("result", "ok");
			outputMap.put("framesUploaded", framesUploaded);
			outputMap.put("framesLeft", totalFrames);
			outputMap.put("isActive", isActive);
			outputMap.put("continuous", isContinuous);
			outputMap.put("username", username);
			outputMap.put("token", token);
			outputMap.put("admin", admin);
			String output = gson.toJson(outputMap);
			response.getWriter().append(output);
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
		
		//response.getWriter().append("Served at: ").append(request.getContextPath());
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doGet(request, response);
	}

}
