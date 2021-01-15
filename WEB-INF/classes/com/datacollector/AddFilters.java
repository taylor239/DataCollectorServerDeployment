package com.datacollector;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

/**
 * Servlet implementation class AddFilters
 */
@WebServlet("/openDataCollection/addFilters.json")
public class AddFilters extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public AddFilters() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
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
				
				PreparedStatement outerStmt = null;
				ResultSet outerSet = null;
				
				try
				{
					PreparedStatement queryStmt = dbConn.prepareStatement(loginQuery);
					outerStmt = queryStmt;
					queryStmt.setString(1, adminEmail);
					queryStmt.setString(2, password);
					ResultSet myResults = queryStmt.executeQuery();
					outerSet = myResults;
					if(myResults.next())
					{
						session.setAttribute("admin", myResults.getString("adminEmail"));
						session.setAttribute("adminName", myResults.getString("name"));
					}
					
					myResults.close();
					queryStmt.close();
					dbConn.close();
				}
				catch(Exception e)
				{
					e.printStackTrace();
				}
				finally
				{
					try { if (outerSet != null) outerSet.close(); } catch(Exception e) { }
		            try { if (outerStmt != null) outerStmt.close(); } catch(Exception e) { }
		            try { if (dbConn != null) dbConn.close(); } catch(Exception e) { }
				}
			}
		}
		
		String admin = (String)session.getAttribute("admin");
		
		String saveName = (String)request.getParameter("saveName");
		
		int x=0;
		ArrayList filtersToAdd = new ArrayList();
		while(request.getParameter("filterLevel" + x) != null)
		{
			String curLevel = (String)request.getParameter("filterLevel" + x);
			String curField = (String)request.getParameter("filteField" + x);
			if(curField == null)
			{
				curField = "";
			}
			String curValue = (String)request.getParameter("filterValue" + x);
			ConcurrentHashMap curFilter = new ConcurrentHashMap();
			curFilter.put("level", curLevel);
			curFilter.put("field", curField);
			curFilter.put("value", curValue);
			filtersToAdd.add(curFilter);
			x++;
		}
		ConcurrentHashMap result = myConnector.addFilters(eventName, admin, filtersToAdd, saveName);
		Gson gson = new GsonBuilder().create();
		
		
		response.getWriter().append(gson.toJson(result));
		
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doGet(request, response);
	}

}
