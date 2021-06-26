package com.datacollector;

import java.io.IOException;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Collections;
import java.util.concurrent.ConcurrentHashMap;
import java.util.zip.ZipOutputStream;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;


/**
 * Servlet implementation class GetClosestScreenshot
 */
@WebServlet(name="Tags", urlPatterns= {"/openDataCollection/getTags.json"})
public class GetTags extends HttpServlet
{
	//private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public GetTags() {
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
			
			eventPassword = (String)session.getAttribute("eventPassword");
			eventAdmin = (String)session.getAttribute("eventAdmin");
			
			
			ArrayList tags = myConnector.getTaskTags(eventName, admin);
			
			Gson gson = new GsonBuilder().create();
			String output = "";
			output = gson.toJson(tags);
			response.getWriter().append(output);
			response.getWriter().close();
			
			
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
