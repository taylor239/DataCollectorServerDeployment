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
 * Servlet implementation class UsersTaken
 */
@WebServlet("/openDataCollection/tokensTaken.json")
public class UsersTaken extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public UsersTaken() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		
		Gson gson = new GsonBuilder().create();
		
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
			
			String eventName = request.getParameter("event");

			if(request.getParameter("email") != null)
			{
				session.removeAttribute("admin");
				session.removeAttribute("adminName");
				String adminEmail = request.getParameter("email");
				if(request.getParameter("password") != null)
				{
					String password = request.getParameter("password");
					String loginQuery = "SELECT * FROM `openDataCollectionServer`.`Admin` WHERE `adminEmail` = ? AND `adminPassword` = ?";
					try
					{
						PreparedStatement queryStmt = dbConn.prepareStatement(loginQuery);
						queryStmt.setString(1, adminEmail);
						queryStmt.setString(2, password);
						ResultSet myResults = queryStmt.executeQuery();
						if(myResults.next())
						{
							session.setAttribute("admin", myResults.getString("adminEmail"));
							session.setAttribute("adminName", myResults.getString("name"));
						}
					}
					catch(Exception e)
					{
						e.printStackTrace();
					}
				}
			}

			
			String query = "SELECT COUNT(DISTINCT `token`) AS `usercount`, `username` FROM `openDataCollectionServer`.`UploadToken` WHERE `adminEmail` = ? AND `event` = ? GROUP BY `username`";
			
			String admin = (String)session.getAttribute("admin");
			
			PreparedStatement queryStmt = dbConn.prepareStatement(query);
			queryStmt.setString(1, admin);
			queryStmt.setString(2, eventName);
			ResultSet myResults = queryStmt.executeQuery();
			int totalUsers = 0;
			int totalDownloads = 0;
			
			ArrayList toJson = new ArrayList();
			while(myResults.next())
			{
				HashMap curMap = new HashMap();
				int userCount = myResults.getInt("usercount");
				String userName = myResults.getString("username");
				curMap.put("token", userName);
				curMap.put("downloads", userCount);
				toJson.add(curMap);
			}
			queryStmt.close();
			
			
			String output = gson.toJson(toJson);
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
