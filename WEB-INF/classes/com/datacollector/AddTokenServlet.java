package com.datacollector;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Servlet implementation class AddTokenServlet
 */
@WebServlet(name = "AddToken", urlPatterns = { "/openDataCollection/AddToken" })
public class AddTokenServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public AddTokenServlet() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
		String username = request.getParameter("username");
		String event = request.getParameter("event");
		String admin = request.getParameter("admin");
		String token = request.getParameter("token");
		String mode = request.getParameter("mode");
		String verify = request.getParameter("verifier");
		
		
		int isContinuous = 0;
		if(mode != null && mode.equals("continuous"))
		{
			isContinuous = 1;
		}
		
		if(event == null || event.isEmpty() || event.equalsIgnoreCase("null"))
		{
			event = "";
		}
		
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
				System.out.println("Event not found to add token " + event + ", " + admin);
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
		
		String query = "INSERT INTO `UploadToken` (`event`, `username`, `token`, `continuous`, `adminEmail`) VALUES (?, ?, ?, ?, ?);";
		try
		{
			PreparedStatement toInsert = dbConn.prepareStatement(query);
			toInsert.setString(1, event);
			toInsert.setString(2, username);
			toInsert.setString(3, token);
			toInsert.setInt(4, isContinuous);
			toInsert.setString(5, admin);
			toInsert.execute();
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
		
		response.getWriter().append("Served at: ").append(request.getContextPath());
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doGet(request, response);
	}

}
