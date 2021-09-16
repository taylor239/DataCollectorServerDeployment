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
 * Servlet implementation class AddTask
 */
@WebServlet("/openDataCollection/addTask.json")
public class AddTask extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public AddTask() {
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
		
		
		String eventName = request.getParameter("event");
		
		String eventPassword = request.getParameter("eventPassword");

		if(eventPassword != null)
		{
			session.setAttribute("eventPassword", eventPassword);
		}
		
		String eventAdmin = request.getParameter("eventAdmin");

		if(eventAdmin != null)
		{
			session.setAttribute("eventAdmin", eventAdmin);
		}
		
		
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
				Connection dbConn = myConnectionSource.getDatabaseConnection();
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
		
		eventPassword = (String)session.getAttribute("eventPassword");
		eventAdmin = (String)session.getAttribute("eventAdmin");
		
		//boolean fromAnon = session.getAttribute("fromAnon").equals("true");
		
		
		boolean anon = false;
		ConcurrentHashMap privs = null;
		
		boolean fromPrivs = false;
		String tagger = null;
		
		if(admin == null || admin.isEmpty())
		{
			fromPrivs = true;
			System.out.println("Privs request");
			privs = myConnector.getPermissionDetails(eventName, eventAdmin, eventPassword);
			anon = (boolean) privs.get("anon");
			admin = (String) privs.get("adminemail");
			if(privs.containsKey("tagger"))
			{
				tagger = (String) privs.get("tagger");
			}
			else
			{
				return;
			}
		}
		
		boolean fromAnon = anon;
		
		ConcurrentHashMap userMap = null;
		ConcurrentHashMap inverseUserMap = null;
		if(fromAnon || anon)
		{
			System.out.println("Building user map");
			userMap = new ConcurrentHashMap();
			inverseUserMap = new ConcurrentHashMap();
			ArrayList userList = myConnector.getUsers(eventName, admin);
			//System.out.println(userList);
			for(int x = 0; x < userList.size(); x++)
			{
				ConcurrentHashMap curUser = (ConcurrentHashMap) userList.get(x);
				//System.out.println(curUser);
				if(!userMap.containsKey(curUser.get("Username")))
				{
					userMap.put(curUser.get("Username"), "User" + x);
					inverseUserMap.put("User" + x, curUser.get("Username"));
				}
			}
			//System.out.println(inverseUserMap);
		}
		
		//String admin = (String)session.getAttribute("admin");
		
		long startTime = Math.round(Double.parseDouble((String)request.getParameter("start")));
		long endTime = Math.round(Double.parseDouble((String)request.getParameter("end")));
		String taskName = (String)request.getParameter("taskName");
		String taskTags = (String)request.getParameter("taskTags");
		String taskGoal = (String)request.getParameter("taskGoal");
		
		if(taskTags == null)
		{
			taskTags = "";
		}
		if(taskGoal == null)
		{
			taskGoal = "";
		}
		String taskLines[] = taskTags.split("\\r?\\n");
		String userName = (String)request.getParameter("userName");
		String sessionName = (String)request.getParameter("sessionName");
		
		ConcurrentHashMap result = null;
		System.out.println("Adding " + eventName + ": " + admin + ": " + userName + ": " + taskName + ": " + tagger + ": " + startTime + ": " + endTime);
		if(tagger == null)
		{
			tagger = admin;
		}
		if(fromAnon)
		{
			result = myConnector.addTask(eventName, (String) inverseUserMap.get(userName), sessionName, admin, startTime, endTime, taskName, taskLines, tagger, taskGoal);
		}
		else
		{
			result = myConnector.addTask(eventName, userName, sessionName, admin, startTime, endTime, taskName, taskLines, tagger, taskGoal);
		}
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
