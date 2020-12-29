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
 * Servlet implementation class TokensAvailableCSV
 */
@WebServlet("/openDataCollection/tokensAvailable.csv")
public class TokensAvailableCSV extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public TokensAvailableCSV() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

		
		
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

			
			String query = "SELECT COUNT(DISTINCT `username`) AS `usercount`, `username` FROM `openDataCollectionServer`.`UploadToken` WHERE `adminEmail` = ? AND `event` = ? GROUP BY `username`";
			
			String admin = (String)session.getAttribute("admin");
			
			PreparedStatement queryStmt = dbConn.prepareStatement(query);
			queryStmt.setString(1, admin);
			queryStmt.setString(2, eventName);
			ResultSet myResults = queryStmt.executeQuery();
			int totalUsers = 0;
			int totalDownloads = 0;
			
			HashMap userMap = new HashMap();
			while(myResults.next())
			{
				int userCount = myResults.getInt("usercount");
				String userName = myResults.getString("username");
				userMap.put(userName, userCount);
			}
			queryStmt.close();
			
			query = "SELECT `username` FROM `openDataCollectionServer`.`UserList` WHERE `adminEmail` = ? AND `event` = ?";
			queryStmt = dbConn.prepareStatement(query);
			queryStmt.setString(1, admin);
			queryStmt.setString(2, eventName);
			myResults = queryStmt.executeQuery();
			while(myResults.next())
			{
				String username =  myResults.getString("username");
				if(!userMap.containsKey(username))
				{
					response.getWriter().append(username + ",");
				}
			}
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
