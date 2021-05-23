package com.datacollector;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
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
@WebServlet(name="LogExport", urlPatterns= {"/openDataCollection/logExport.json", "/openDataCollection/logExport.zip"})
public class DataExportLog extends HttpServlet {
	private static final long serialVersionUID = 1L;
    
	private boolean keepingAlive = true;
	private boolean doneKeepingAlive = false;
	private ZipOutputStream zipOut = null;
	private Thread threadToJoin = null;
    /**
     * @see HttpServlet#HttpServlet()
     */
    public DataExportLog() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		
		System.out.println("Got an export query");
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
			
			
			HttpSession session = request.getSession(true);
			
			boolean zip = request.getRequestURI().contains(".zip");
			ServletOutputStream out = null;
			if(zip)
			{
				out=response.getOutputStream();
				
				zipOut = new ZipOutputStream(out);
			}
			
			threadToJoin = new Thread()
			{
				public void run()
				{
					while(keepingAlive)
					{
						ZipEntry paddingFile = null;
						if(zip)
						{
							paddingFile = new ZipEntry("paddingFile.txt");
							try {
								zipOut.putNextEntry(paddingFile);
							} catch (IOException e) {
								e.printStackTrace();
							}
						}
						if(keepingAlive)
						{
							System.out.println("Padding");
							try
							{
								if(zip)
								{
									
									zipOut.write(0);
									zipOut.flush();
								}
								else
								{
									response.getWriter().append(" ");
									response.getWriter().flush();
								}
								
							} catch (Exception e1) {
								// TODO Auto-generated catch block
								e1.printStackTrace();
							}
							try {
								Thread.currentThread().sleep(500);
							} catch (InterruptedException e) {
								e.printStackTrace();
							}
						}
						else
						{
							
						}
					}
					if(zip)
					{
						try {
							zipOut.closeEntry();
						} catch (IOException e) {
							e.printStackTrace();
						}
					}
					doneKeepingAlive = true;
					System.out.println("Stopped padding");
					
				}
			};
			threadToJoin.start();
			
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
			
			
			if(admin == null || admin.isEmpty())
			{
				System.out.println("Anon request");
				anon = true;
				admin = myConnector.getPermission(eventName, eventAdmin, eventPassword);
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
			
			String toSelect = request.getParameter("datasources");
			
			String normalize = request.getParameter("normalize");
			
			//boolean zip = request.getParameter("zip") != null && request.getParameter("zip").equals("true");
			//boolean zip = false;
			
			
			ArrayList userSelectList = new ArrayList();
			
			String usersToSelect = request.getParameter("users");
			
			ArrayList sessionSelectList = new ArrayList();
			
			String sessionNames = request.getParameter("sessions");
			
			String startingTimestamp = request.getParameter("start");
			String endingTimestamp = request.getParameter("end");
			
			String firstIndex = request.getParameter("first");
			String count = request.getParameter("count");
			
			if(firstIndex == null || count == null)
			{
				firstIndex = "";
				count = "";
			}
			
			boolean toFix = request.getParameter("fix") != null && request.getParameter("fix").equals("true");
			
			ConcurrentHashMap fileWriteMap = new ConcurrentHashMap();
			
			System.out.println("Exporting: " + toSelect + " for " + usersToSelect);
			
			if(usersToSelect != null && !usersToSelect.isEmpty() && !usersToSelect.equals("null"))
			{
				String[] userSelectArray = usersToSelect.split(",");
				if(fromAnon)
				{
					for(int x=0; x<userSelectArray.length; x++)
					{
						//System.out.println(userSelectArray[x]);
						userSelectList.add(inverseUserMap.get(userSelectArray[x]));
					}
				}
				else
				{
					Collections.addAll(userSelectList, userSelectArray);
				}
				//System.out.println(userSelectList);
			}
			else
			{
				//userSelectList.add("%");
			}
			
			if(sessionNames != null && !sessionNames.isEmpty() && !sessionNames.equals("null"))
			{
				String[] sessionSelectArray = sessionNames.split(",");
				Collections.addAll(sessionSelectList, sessionSelectArray);
				System.out.println(sessionSelectList);
			}
			else
			{
				//userSelectList.add("%");
			}
			
			ArrayList dataTypes = new ArrayList();
			
			//ArrayList dataList = myConnector.getCollectedData(eventName, admin);
			ConcurrentHashMap headMap = new ConcurrentHashMap();
			if(toSelect.contains("events"))
			{
				dataTypes.add("events");
				ConcurrentHashMap eventMap = myConnector.getTasksHierarchy(eventName, admin, userSelectList, sessionSelectList, firstIndex, count);
				headMap = myConnector.mergeMaps(headMap, eventMap);
			}
			if(toSelect.contains("windows"))
			{
				dataTypes.add("windows");
				ConcurrentHashMap dataMap = myConnector.getWindowDataHierarchy(eventName, admin, userSelectList, sessionSelectList, firstIndex, count);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("processes"))
			{
				dataTypes.add("processes");
				ConcurrentHashMap dataMap = myConnector.getProcessDataHierarchy(eventName, admin, userSelectList, sessionSelectList, firstIndex, count);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("environment"))
			{
				dataTypes.add("environment");
				ConcurrentHashMap dataMap = myConnector.getSessionDetailsHierarchy(eventName, admin, userSelectList, sessionSelectList, firstIndex, count);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("keystrokes"))
			{
				dataTypes.add("keystrokes");
				ConcurrentHashMap dataMap = myConnector.getKeystrokesHierarchy(eventName, admin, userSelectList, sessionSelectList, firstIndex, count);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("mouse"))
			{
				dataTypes.add("mouse");
				ConcurrentHashMap dataMap = myConnector.getMouseHierarchy(eventName, admin, userSelectList, sessionSelectList, firstIndex, count);
				headMap = myConnector.mergeMaps(headMap, dataMap);
			}
			if(toSelect.contains("screenshots"))
			{
				if(zip)
				{
					dataTypes.add("screenshots");
					ConcurrentHashMap screenshotPair = myConnector.getScreenshotsHierarchyBinary(eventName, admin, userSelectList, sessionSelectList, firstIndex, count);
					ConcurrentHashMap screenshotMap = (ConcurrentHashMap) screenshotPair.get("json");
					ConcurrentHashMap screenshotMapBinary = (ConcurrentHashMap) screenshotPair.get("binary");
					headMap = myConnector.mergeMaps(headMap, screenshotMap);
					fileWriteMap = myConnector.mergeMaps(fileWriteMap, screenshotMapBinary);
				}
				else
				{
					dataTypes.add("screenshots");
					ConcurrentHashMap screenshotMap = myConnector.getScreenshotsHierarchy(eventName, admin, userSelectList, sessionSelectList, false, true, firstIndex, count);
					headMap = myConnector.mergeMaps(headMap, screenshotMap);
				}
			}
			if(false || toSelect.contains("video"))
			{
				dataTypes.add("video");
				ConcurrentHashMap screenshotMap = myConnector.getScreenshotsHierarchy(eventName, admin, userSelectList, sessionSelectList, false, false, firstIndex, count);
				screenshotMap = myConnector.normalizeAllTime(screenshotMap);
				ConcurrentHashMap videoPair = toVideo(screenshotMap, zip);
				if(zip)
				{
					ConcurrentHashMap videoMap = (ConcurrentHashMap) videoPair.get("json");
					ConcurrentHashMap videoMapBinary = (ConcurrentHashMap) videoPair.get("binary");
					headMap = myConnector.mergeMaps(headMap, videoMap);
					fileWriteMap = myConnector.mergeMaps(fileWriteMap, videoMapBinary);
				}
				else
				{
					headMap = myConnector.mergeMaps(headMap, videoPair);
				}
			}
			if(toSelect.contains("screenshotindices"))
			{
				dataTypes.add("screenshots");
				ConcurrentHashMap screenshotMap = myConnector.getScreenshotsHierarchy(eventName, admin, userSelectList, sessionSelectList, true, true, firstIndex, count);
				headMap = myConnector.mergeMaps(headMap, screenshotMap);
			}
			
			if(toFix)
			{
				//System.out.println("Trying to fix timestamps");
				//headMap = fixTime(headMap);
			}
			//System.out.println("Removing debug data");
			//headMap = deInsert(headMap);
			headMap = myConnector.normalizeAllTime(headMap);
			
			
			//System.out.println("Exporting " + headMap.size());
			//System.out.println(dataTypes);
			
			ConcurrentHashMap finalMap = new ConcurrentHashMap();
			ArrayList finalList = new ArrayList();
			
			if(anon)
			{
				System.out.println("Anon data");
				ConcurrentHashMap newMap = new ConcurrentHashMap();
				Iterator userIterator = headMap.entrySet().iterator();
				
				//int userNum = 0;
				
				while(userIterator.hasNext())
				{
					Entry userEntry = (Entry) userIterator.next();
					String curUser = (String) userEntry.getKey();
					
					ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
					newMap.put(userMap.get(curUser), sessionMap);
					
					//userNum++;
				}
				
				headMap = newMap;
			}
			
			if(normalize != null && !normalize.equals("none"))
			{
				System.out.println("Normalizing data");
				ArrayList userList = new ArrayList();
				Iterator userIterator = headMap.entrySet().iterator();
				while(userIterator.hasNext())
				{
					Entry userEntry = (Entry) userIterator.next();
					String curUser = (String) userEntry.getKey();
					userList.add(curUser);
					ArrayList sessionList = new ArrayList();
					//System.out.println("User: " + curUser);
					//System.out.println(userEntry.getValue().getClass());
					ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
					//System.out.println(sessionMap.size());
					Iterator sessionIterator = (Iterator) sessionMap.entrySet().iterator();
					while(sessionIterator.hasNext())
					{
						Entry sessionEntry = (Entry) sessionIterator.next();
						String curSession = (String) sessionEntry.getKey();
						sessionList.add(curSession);
						//System.out.println("Sess: " + curSession);
						//System.out.println(sessionEntry.getValue().getClass());
						ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
						ArrayList timelineList = toTimeline(dataMap, dataTypes, "DataType");
						
						ConcurrentHashMap finalUserMap = new ConcurrentHashMap();
						if(finalMap.containsKey(curUser))
						{
							finalUserMap = (ConcurrentHashMap) finalMap.get(curUser);
						}
						
						finalUserMap.put(curSession, timelineList);
						
						finalMap.put(curUser, finalUserMap);
					}
					if(normalize.equals("session") || normalize.equals("user"))
					{
						System.out.println("Normalizing session");
						ConcurrentHashMap finalUserMap = new ConcurrentHashMap();
						if(finalMap.containsKey(curUser))
						{
							finalUserMap = (ConcurrentHashMap) finalMap.get(curUser);
						}
						ArrayList timelineList = toTimeline(finalUserMap, sessionList, "Session");
						finalMap.put(curUser, timelineList);
					}
				}
				if(normalize.equals("user"))
				{
					System.out.println("Normalizing user");
					finalList = toTimeline(finalMap, userList, "User");
				}
				
			}
			else
			{
				finalMap = headMap;
			}
			
			System.out.println("Encoding to JSON");
			
			Gson gson = new GsonBuilder().create();
			String output = "";
			if(normalize.equals("user"))
			{
				output = gson.toJson(finalList);
			}
			else
			{
				output = gson.toJson(finalMap);
			}
			System.out.println("Shutting down padding");
			
			keepingAlive = false;
			
			if(zip)
			{
				while(!doneKeepingAlive)
				{
					keepingAlive = false;
					Thread.currentThread().sleep(100);
				}
				System.out.println("Zipping");
				
				//ServletOutputStream out=response.getOutputStream();
				
				//ZipOutputStream zipOut = new ZipOutputStream(out);
				
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
						byte[] toOutput = null;
						if(thisFile.containsKey("Screenshot"))
						{
							toOutput = (byte[]) thisFile.get("Screenshot");
						}
						if(thisFile.containsKey("Video"))
						{
							toOutput = (byte[]) thisFile.get("Video");
						}
						String fileName = filePath + "/" + thisFile.get("Index").toString();
						ZipEntry finalFile = new ZipEntry(fileName);
						zipOut.putNextEntry(finalFile);
						zipOut.write(toOutput);
						zipOut.closeEntry();
					}
				}
				
				zipOut.close();
				out.close();
			}
			else
			{
				System.out.println("Sending");
				while(!doneKeepingAlive)
				{
					keepingAlive = false;
					Thread.currentThread().sleep(100);
				}
				response.getWriter().append(output);
				response.getWriter().close();
			}
			
			
			keepingAlive = false;
			threadToJoin.join();
			System.out.println("Done");
			//Gson gson = new GsonBuilder().create();
			//String output = gson.toJson(headMap);
			//response.getWriter().append(output);
		}
		catch(Exception e)
		{
			
		}
	}
	
	private ConcurrentHashMap fixTime(ConcurrentHashMap toFix)
	{
		Iterator userIterator = toFix.entrySet().iterator();
		while(userIterator.hasNext())
		{
			Entry userEntry = (Entry) userIterator.next();
			String curUser = (String) userEntry.getKey();
			//System.out.println("User: " + curUser);
			//System.out.println(userEntry.getValue().getClass());
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
			//System.out.println(sessionMap.size());
			Iterator sessionIterator = (Iterator) sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Entry sessionEntry = (Entry) sessionIterator.next();
				String curSession = (String) sessionEntry.getKey();
				ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
				long diff = 0;
				long insertDiff = 0;
				
				if(dataMap.containsKey("events"))
				{
					ArrayList eventList = (ArrayList) dataMap.get("events");
					if(!eventList.isEmpty())
					{
						ConcurrentHashMap firstRow = (ConcurrentHashMap) eventList.get(0);
						Timestamp recordedTimeInit = (Timestamp) firstRow.get("EventTime");
						Timestamp startTime = (Timestamp) firstRow.get("StartTime");
						Timestamp insertTime = (Timestamp) firstRow.get("InsertTime");
						diff = startTime.getTime() - recordedTimeInit.getTime();
						insertDiff = startTime.getTime() - insertTime.getTime();
						if(diff > 5000)
						{
							for(int x=0; x<eventList.size(); x++)
							{
								ConcurrentHashMap curRow = (ConcurrentHashMap) eventList.get(x);
								Timestamp recordedTime = (Timestamp) curRow.get("EventTime");
								if(recordedTime.getTime() == 0)
								{
									recordedTime = (Timestamp) curRow.get("InsertTime");
									recordedTime = new Timestamp(recordedTime.getTime() + insertDiff);
									curRow.put("EventTime", recordedTime);
									curRow.put("Index", recordedTime);
								}
								else
								{
									recordedTime = new Timestamp(recordedTime.getTime() + diff);
									curRow.put("EventTime", recordedTime);
									curRow.put("Index", recordedTime);
								}
							}
						}
						//else
						//{
						//	recordedTimeInit = (Timestamp) firstRow.get("InsertTime");
						//	startTime = (Timestamp) firstRow.get("StartTime");
						//	diff = startTime.getTime() - recordedTimeInit.getTime();
						//}
					}
					
				}
				if(dataMap.containsKey("processes"))
				{
					ArrayList eventList = (ArrayList) dataMap.get("processes");
					for(int x=0; x<eventList.size(); x++)
					{
						ConcurrentHashMap curRow = (ConcurrentHashMap) eventList.get(x);
						
						Timestamp recordedTime = (Timestamp) curRow.get("InsertTime");
						Timestamp indexTime = (Timestamp) curRow.get("Index");
						if(indexTime.getTime() == 0)
						{
							recordedTime = new Timestamp(recordedTime.getTime() + insertDiff);
							curRow.put("Index", recordedTime);
							curRow.put("SnapTime", recordedTime);
						}
						
					}
					
				}
			}
		}
		
		return toFix;
	}
	
	private ConcurrentHashMap deInsert(ConcurrentHashMap toFix)
	{
		Iterator userIterator = toFix.entrySet().iterator();
		while(userIterator.hasNext())
		{
			Entry userEntry = (Entry) userIterator.next();
			String curUser = (String) userEntry.getKey();
			//System.out.println("User: " + curUser);
			//System.out.println(userEntry.getValue().getClass());
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
			//System.out.println(sessionMap.size());
			Iterator sessionIterator = (Iterator) sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Entry sessionEntry = (Entry) sessionIterator.next();
				String curSession = (String) sessionEntry.getKey();
				ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
				
				Iterator dataIterator = (Iterator) dataMap.entrySet().iterator();
				while(dataIterator.hasNext())
				{
					Entry dataEntry = (Entry) dataIterator.next();
					ArrayList curDataList = (ArrayList) dataEntry.getValue();
					for(int x=0; x<curDataList.size(); x++)
					{
						ConcurrentHashMap curRow = (ConcurrentHashMap) curDataList.get(x);
						if(curRow.containsKey("InsertTime"))
						{
							curRow.remove("InsertTime");
						}
					}
				}
			}
		}
		
		return toFix;
	}
	
	private ConcurrentHashMap toVideo(ConcurrentHashMap screenshotMap, boolean toZip)
	{
		ConcurrentHashMap toReturn = new ConcurrentHashMap();
		ConcurrentHashMap videoFiles = new ConcurrentHashMap();
		ConcurrentHashMap videoEntrys = new ConcurrentHashMap();
		Iterator userIterator = screenshotMap.entrySet().iterator();
		while(userIterator.hasNext())
		{
			ConcurrentHashMap curUserMap = new ConcurrentHashMap();
			ConcurrentHashMap curUserMapBinary = new ConcurrentHashMap();
			Entry userEntry = (Entry) userIterator.next();
			String curUser = (String) userEntry.getKey();
			//System.out.println("User: " + curUser);
			//System.out.println(userEntry.getValue().getClass());
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
			//System.out.println(sessionMap.size());
			Iterator sessionIterator = (Iterator) sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				ConcurrentHashMap curSessionMap = new ConcurrentHashMap();
				ConcurrentHashMap curSessionMapBinary = new ConcurrentHashMap();
				Entry sessionEntry = (Entry) sessionIterator.next();
				String curSession = (String) sessionEntry.getKey();
				ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
				
				//System.out.println("Doing video for " + curUser + ", " + curSession);
				
				//System.out.println(dataMap.keySet());
				ArrayList screenshotEntries = (ArrayList) dataMap.get("screenshots");
				//System.out.println(screenshotEntries.size());
				BufferedImageVideoEncoder myEncoder = new BufferedImageVideoEncoder();
				
				ArrayList outputList = new ArrayList();
				ArrayList outputListBinary = new ArrayList();
				
				Object curStartDate = null;
				ConcurrentHashMap curImage = (ConcurrentHashMap) screenshotEntries.get(0);
				//System.out.println(curImage.keySet());
				//System.out.println(curImage.get("Index"));
				curStartDate = curImage.get("Index");
				//System.out.println(curStartDate);
				//System.out.println("First video");
				for(int x=0; x<screenshotEntries.size(); x++)
				{
					//System.out.println("Encoding image to video...");
					curImage = (ConcurrentHashMap) screenshotEntries.get(x);
					//System.out.println("Checking if need for new video");
					if(!myEncoder.addImage(curImage) || (x + 1) == screenshotEntries.size())
					{
						//System.out.println("Needs new video or done with session, recording last");
						ConcurrentHashMap dataEntryMap = new ConcurrentHashMap();
						ConcurrentHashMap dataEntryMapBinary = new ConcurrentHashMap();
						byte[] theData = myEncoder.getVideoBytes();
						//System.out.println("Adding dates");
						dataEntryMap.put("Index", curStartDate);
						dataEntryMap.put("Start", curStartDate);
						//System.out.println("Adding paths and data");
						if(toZip)
						{
							dataEntryMapBinary.put("Index", (curStartDate.toString()).replaceAll(" ", "_") + ".mkv");
							dataEntryMap.put("Path", (curStartDate.toString()).replaceAll(" ", "_") + ".mkv");
							dataEntryMapBinary.put("Video", theData);
						}
						else
						{
							dataEntryMap.put("Video", Base64.getEncoder().encodeToString(theData));
						}
						dataEntryMap.put("End", curImage.get("Index"));
						outputListBinary.add(dataEntryMapBinary);
						outputList.add(dataEntryMap);
						if(!((x + 1) == screenshotEntries.size()))
						{
							x--;
							//System.out.println("Next video in same session");
						}
						else
						{
							//System.out.println("Next session");
						}
						curStartDate = curImage.get("Index");
					}
				}
				
				curSessionMap.put("video", outputList);
				curSessionMapBinary.put("video", outputListBinary);
				
				//if(dataMap.containsKey("events"))
				
				curUserMap.put(curSession, curSessionMap);
				curUserMapBinary.put(curSession, curSessionMapBinary);
				
				//System.out.println("Done with session " + curUser + ", " + curSession);
				
			}
			videoEntrys.put(curUser, curUserMap);
			videoFiles.put(curUser, curUserMapBinary);
		}
		if(toZip)
		{
			toReturn.put("binary", videoFiles);
			toReturn.put("json", videoEntrys);
		}
		else
		{
			return videoEntrys;
		}
		return toReturn;
	}
	
	private ArrayList toTimeline(ConcurrentHashMap dataMap, ArrayList dataTypes, String dataLabel)
	{
		//System.out.println(dataMap);
		//System.out.println(dataTypes);
		
		ArrayList myReturn = new ArrayList();
		
		ArrayList nextDataTypes = new ArrayList();
		
		for(int x=0; x<dataTypes.size(); x++)
		{
			if(dataMap.containsKey(dataTypes.get(x)))
			{
				nextDataTypes.add(dataTypes.get(x));
			}
		}
		
		dataTypes = nextDataTypes;
		
		//System.out.println(dataTypes);
		
		while(!dataTypes.isEmpty())
		{
			//System.out.println(dataTypes);
			//System.out.println(dataTypes.get(0));
			//System.out.println(dataMap.get(dataTypes.get(0)));
			ArrayList initList = (ArrayList) dataMap.get(dataTypes.get(0));
			//System.out.println(initList.get(0).getClass());
			ConcurrentHashMap curMap = (ConcurrentHashMap) initList.get(0);
			long minTime = (long) curMap.get("Index MS");
			int curSource = 0;
			
			for(int x=1; x<dataTypes.size(); x++)
			{
				initList = (ArrayList) dataMap.get(dataTypes.get(x));
				curMap = (ConcurrentHashMap) initList.get(0);
				long curTime = (long) curMap.get("Index MS");
				if(curTime < minTime)
				{
					minTime = curTime;
					curSource = x;
				}
			}
			
			initList = (ArrayList) dataMap.get(dataTypes.get(curSource));
			curMap = (ConcurrentHashMap) initList.get(0);
			initList.remove(0);
			curMap.put(dataLabel, dataTypes.get(curSource));
			myReturn.add(curMap);
			
			if(initList.isEmpty())
			{
				dataMap.remove(dataTypes.get(curSource));
				dataTypes.remove(curSource);
			}
		}
		
		return myReturn;
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doGet(request, response);
	}

}
