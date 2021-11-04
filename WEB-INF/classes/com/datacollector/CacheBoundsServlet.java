package com.datacollector;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;


/**
 * Servlet implementation class CacheBoundsServlet
 */
@WebServlet(name="CacheBounds", urlPatterns= {"/openDataCollection/cacheBounds.json"})
public class CacheBoundsServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
    
	
	
	private class MessageThread implements Runnable, DatabaseUpdateConsumer
    {
		private ConcurrentLinkedQueue messageQueue;
    	boolean keepingAlive = true;
		boolean doneKeepingAlive = false;
		ZipOutputStream zipOut = null;
		boolean zip = false;
		PrintWriter myWriter;
		String messagerID = "";
		
		
		public MessageThread(PrintWriter writer)
		{
			messageQueue = new ConcurrentLinkedQueue();
			myWriter = writer;
		}
		
		
		public void setKeepingAlive(boolean toSet)
		{
			keepingAlive = toSet;
		}
		
		public boolean getDoneKeepingAlive()
		{
			return doneKeepingAlive;
		}
		
		public void setID(String id)
		{
			messagerID = id;
		}
		
		public void run()
		{
			Gson myGson = new Gson();
			while(keepingAlive)
			{
				System.out.println("Looping for messages");
				System.out.println(keepingAlive);
				System.out.println(messageQueue);
				while(!messageQueue.isEmpty())
				{
					myWriter.append("\n" + myGson.toJson(messageQueue.poll()));
				}
				
				myWriter.append(" ");
				try
				{
					Thread.currentThread().sleep(500);
				}
				catch(InterruptedException e)
				{
					e.printStackTrace();
					keepingAlive = false;
					return;
				}
			}
			System.out.println("Finishing last messages:");
			System.out.println(keepingAlive);
			System.out.println(messageQueue);
			while(!messageQueue.isEmpty())
			{
				myWriter.append("\n" + myGson.toJson(messageQueue.poll()));
			}

			myWriter.close();
			doneKeepingAlive = true;
			System.out.println(messageQueue);
		}


		@Override
		public void consumeUpdate(Object update)
		{
			messageQueue.add(update);
		}

		@Override
		public void endConsumption()
		{
			setKeepingAlive(false);
		}
    }
	
	
    /**
     * @see HttpServlet#HttpServlet()
     */
    public CacheBoundsServlet() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		Thread threadToJoin = null;
		System.out.println("Got a cache query");
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
			
			
			HttpSession session = request.getSession(true);
			
			boolean zip = request.getRequestURI().contains(".zip");
			ServletOutputStream out = null;
			
			
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
			
			
			MessageThread padder = new MessageThread(response.getWriter());
			
			
			threadToJoin = new Thread(padder);
			threadToJoin.start();
			
			padder.setID(request.getRequestURL().toString());
			
			myConnector.cacheBounds(eventName, admin, padder);
			
			//padder.consumeUpdate(myConnector.getActiveMinutes( admin, eventName, 5));
			while(!padder.getDoneKeepingAlive())
			{
				try
				{
					Thread.currentThread().sleep(500);
				}
				catch(InterruptedException e)
				{
					e.printStackTrace();
					
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
