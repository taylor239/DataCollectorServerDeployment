package com.datacollector;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
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
 * Servlet implementation class DataExportJson
 */
@WebServlet("/openDataCollection/jsonExport.json")
public class DataExportJson extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public DataExportJson() {
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
			
			String toSelect = request.getParameter("datasources");
			
			ArrayList userSelectList = new ArrayList();
			
			String usersToSelect = request.getParameter("users");
			
			System.out.println("Exporting: " + toSelect + " for " + usersToSelect);
			
			if(usersToSelect != null && !usersToSelect.isEmpty() && !usersToSelect.equals("null"))
			{
				String[] userSelectArray = usersToSelect.split(",");
				Collections.addAll(userSelectList, userSelectArray);
				System.out.println(userSelectList);
			}
			else
			{
				//userSelectList.add("%");
			}
			
			//ArrayList dataList = myConnector.getCollectedData(eventName, admin);
			ConcurrentHashMap headMap = new ConcurrentHashMap();
			if(toSelect.contains("keystrokes"))
			{
				ConcurrentHashMap dataMap = myConnector.getKeystrokesHierarchy(eventName, admin, userSelectList);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("mouse"))
			{
				ConcurrentHashMap dataMap = myConnector.getMouseHierarchy(eventName, admin, userSelectList);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("processes"))
			{
				ConcurrentHashMap dataMap = myConnector.getProcessDataHierarchy(eventName, admin, userSelectList);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("windows"))
			{
				ConcurrentHashMap dataMap = myConnector.getWindowDataHierarchy(eventName, admin, userSelectList);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("events"))
			{
				ConcurrentHashMap eventMap = myConnector.getTasksHierarchy(eventName, admin, userSelectList);
				headMap = myConnector.mergeMaps(headMap, eventMap);
			}
			if(toSelect.contains("screenshots"))
			{
				ConcurrentHashMap screenshotMap = myConnector.getScreenshotsHierarchy(eventName, admin, userSelectList, false);
				headMap = myConnector.mergeMaps(headMap, screenshotMap);
			}
			if(toSelect.contains("screenshotindices"))
			{
				ConcurrentHashMap screenshotMap = myConnector.getScreenshotsHierarchy(eventName, admin, userSelectList, true);
				headMap = myConnector.mergeMaps(headMap, screenshotMap);
			}
			headMap = myConnector.normalizeAllTime(headMap);
			
			System.out.println("Encoding to JSON");
			
			Gson gson = new GsonBuilder().create();
			String output = gson.toJson(headMap);
			
			System.out.println("Sending");
			
			response.getWriter().append(output);
		}
		catch(Exception e)
		{
			
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
