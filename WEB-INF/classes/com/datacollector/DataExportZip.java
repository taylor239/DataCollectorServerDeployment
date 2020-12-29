package com.datacollector;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.ConcurrentHashMap;
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
import com.google.gson.GsonBuilder;

/**
 * Servlet implementation class DataExportJson
 */
@WebServlet("/openDataCollection/zipExport.zip")
public class DataExportZip extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public DataExportZip() {
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
			ConcurrentHashMap fileWriteMap = new ConcurrentHashMap();
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
				ConcurrentHashMap screenshotPair = myConnector.getScreenshotsHierarchyBinary(eventName, admin, userSelectList);
				ConcurrentHashMap screenshotMap = (ConcurrentHashMap) screenshotPair.get("json");
				ConcurrentHashMap screenshotMapBinary = (ConcurrentHashMap) screenshotPair.get("binary");
				headMap = myConnector.mergeMaps(headMap, screenshotMap);
				fileWriteMap = myConnector.mergeMaps(fileWriteMap, screenshotMapBinary);
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
			
			System.out.println("Zipping");
			
			ServletOutputStream out=response.getOutputStream();
			
			ZipOutputStream zipOut = new ZipOutputStream(out);
			
			ZipEntry jsonFile = new ZipEntry("jsonExport.json");
			
			System.out.println("Sending");
			
			zipOut.putNextEntry(jsonFile);
			zipOut.write(output.getBytes());
			zipOut.closeEntry();
			//response.getWriter().append(output);
			
			System.out.println("Adding files");
			//System.out.println(fileWriteMap);
			ArrayList filesToAdd = myConnector.toDirMap(fileWriteMap, "");
			for(int x=0; x<filesToAdd.size(); x++)
			{
				//System.out.println(filesToAdd.get(x));
				ConcurrentHashMap curFile = (ConcurrentHashMap) filesToAdd.get(x);
				String filePath = (String) curFile.get("filePath");
				ArrayList filesInPath = (ArrayList) curFile.get("file");
				for(int y=0; y<filesInPath.size(); y++)
				{
					ConcurrentHashMap thisFile = (ConcurrentHashMap) filesInPath.get(y);
					byte[] toOutput = (byte[]) thisFile.get("Screenshot");
					String fileName = filePath + "/" + thisFile.get("Index").toString();
					ZipEntry finalFile = new ZipEntry(fileName);
					zipOut.putNextEntry(finalFile);
					zipOut.write(toOutput);
					zipOut.closeEntry();
				}
			}
			
			zipOut.close();
			out.close();
			System.out.println("Done");
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
