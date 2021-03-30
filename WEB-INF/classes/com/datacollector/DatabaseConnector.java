package com.datacollector;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.TimeZone;
import java.util.concurrent.ConcurrentHashMap;

import javax.imageio.ImageIO;
import javax.servlet.ServletContext;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;




public class DatabaseConnector
{
	private java.util.Calendar cal = Calendar.getInstance();
	
	private String totalQuery = "SELECT *, 'keyboard' AS `fromInput`, `MouseInput`.`xLoc` AS `xLoc`, `MouseInput`.`yLoc` AS `yLoc`, `KeyboardInput`.`type` AS `type`, `KeyboardInput`.`button` AS `button`, `KeyboardInput`.`inputTime` AS `overallTime`, `KeyboardInput`.`timeChanged` AS `overallTimeChanged`, `Window`.`username` AS `overallUser`, `Window`.`session`  AS `overallSession`, `Window`.`pid` AS `overallPid`, `Window`.`xid` AS `overallXid` FROM `openDataCollectionServer`.`KeyboardInput`\n" + 
			"LEFT JOIN\n" + 
			"`openDataCollectionServer`.`MouseInput` ON `KeyboardInput`.`username` = `MouseInput`.`username` AND `KeyboardInput`.`session` = `MouseInput`.`session` AND `KeyboardInput`.`event` = `MouseInput`.`event` AND `KeyboardInput`.`adminEmail` = `MouseInput`.`adminEmail` AND `KeyboardInput`.`inputTime` = `MouseInput`.`inputTime`\n" + 
			"INNER JOIN `WindowDetails` ON `KeyboardInput`.`username` = `WindowDetails`.`username` AND `KeyboardInput`.`session` = `WindowDetails`.`session` AND `KeyboardInput`.`event` = `WindowDetails`.`event` AND `KeyboardInput`.`adminEmail` = `WindowDetails`.`adminEmail` AND `KeyboardInput`.`user` = `WindowDetails`.`user` AND `KeyboardInput`.`pid` = `WindowDetails`.`pid` AND `KeyboardInput`.`start` = `WindowDetails`.`start` AND `KeyboardInput`.`xid` = `WindowDetails`.`xid` AND `KeyboardInput`.`timeChanged` = `WindowDetails`.`timeChanged`\n" + 
			"INNER JOIN `Window` ON `Window`.`username` = `WindowDetails`.`username` AND `Window`.`session` = `WindowDetails`.`session` AND `Window`.`event` = `WindowDetails`.`event` AND `Window`.`adminEmail` = `WindowDetails`.`adminEmail` AND `Window`.`user` = `WindowDetails`.`user` AND `Window`.`pid` = `WindowDetails`.`pid` AND `Window`.`start` = `WindowDetails`.`start` AND `Window`.`xid` = `WindowDetails`.`xid`\n" + 
			"INNER JOIN `ProcessAttributes` ON `WindowDetails`.`username` = `ProcessAttributes`.`username` AND `WindowDetails`.`session` = `ProcessAttributes`.`session` AND `WindowDetails`.`event` = `ProcessAttributes`.`event` AND `WindowDetails`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `WindowDetails`.`user` = `ProcessAttributes`.`user` AND `WindowDetails`.`pid` = `ProcessAttributes`.`pid` AND `WindowDetails`.`start` = `ProcessAttributes`.`start` AND `WindowDetails`.`timeChanged` = `ProcessAttributes`.`timestamp`\n" + 
			"INNER JOIN `Process` ON `Window`.`username` = `Process`.`username` AND `Window`.`session` = `Process`.`session` AND `Window`.`event` = `Process`.`event` AND `Window`.`adminEmail` = `Process`.`adminEmail` AND `Window`.`user` = `Process`.`user` AND `Window`.`pid` = `Process`.`pid` AND `Window`.`start` = `Process`.`start`\n" + 
			"UNION\n" + 
			"SELECT *, 'mouse' AS `fromInput`, `MouseInput`.`xLoc` AS `xLoc`, `MouseInput`.`yLoc` AS `yLoc`, `MouseInput`.`type` AS `type`, `KeyboardInput`.`button` AS `button`, `MouseInput`.`inputTime` AS `overallTime`, `MouseInput`.`timeChanged` AS `overallTimeChanged`, `Window`.`username` AS `overallUser`, `Window`.`session`  AS `overallSession`, `Window`.`pid` AS `overallPid`, `Window`.`xid` AS `overallXid` FROM `openDataCollectionServer`.`MouseInput`\n" + 
			"LEFT JOIN\n" + 
			"`openDataCollectionServer`.`KeyboardInput` ON `KeyboardInput`.`username` = `MouseInput`.`username` AND `KeyboardInput`.`session` = `MouseInput`.`session` AND `KeyboardInput`.`event` = `MouseInput`.`event` AND `KeyboardInput`.`adminEmail` = `MouseInput`.`adminEmail` AND `KeyboardInput`.`inputTime` = `MouseInput`.`inputTime`\n" + 
			"INNER JOIN `WindowDetails` ON `MouseInput`.`username` = `WindowDetails`.`username` AND `MouseInput`.`session` = `WindowDetails`.`session` AND `MouseInput`.`event` = `WindowDetails`.`event` AND `MouseInput`.`adminEmail` = `WindowDetails`.`adminEmail` AND `MouseInput`.`user` = `WindowDetails`.`user` AND `MouseInput`.`pid` = `WindowDetails`.`pid` AND `MouseInput`.`start` = `WindowDetails`.`start` AND `MouseInput`.`xid` = `WindowDetails`.`xid` AND `MouseInput`.`timeChanged` = `WindowDetails`.`timeChanged`\n" + 
			"INNER JOIN `Window` ON `Window`.`username` = `WindowDetails`.`username` AND `Window`.`session` = `WindowDetails`.`session` AND `Window`.`event` = `WindowDetails`.`event` AND `Window`.`adminEmail` = `WindowDetails`.`adminEmail` AND `Window`.`user` = `WindowDetails`.`user` AND `Window`.`pid` = `WindowDetails`.`pid` AND `Window`.`start` = `WindowDetails`.`start` AND `Window`.`xid` = `WindowDetails`.`xid`\n" + 
			"INNER JOIN `ProcessAttributes` ON `WindowDetails`.`username` = `ProcessAttributes`.`username` AND `WindowDetails`.`session` = `ProcessAttributes`.`session` AND `WindowDetails`.`event` = `ProcessAttributes`.`event` AND `WindowDetails`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `WindowDetails`.`user` = `ProcessAttributes`.`user` AND `WindowDetails`.`pid` = `ProcessAttributes`.`pid` AND `WindowDetails`.`start` = `ProcessAttributes`.`start` AND `WindowDetails`.`timeChanged` = `ProcessAttributes`.`timestamp`\n" + 
			"INNER JOIN `Process` ON `Window`.`username` = `Process`.`username` AND `Window`.`session` = `Process`.`session` AND `Window`.`event` = `Process`.`event` AND `Window`.`adminEmail` = `Process`.`adminEmail` AND `Window`.`user` = `Process`.`user` AND `Window`.`pid` = `Process`.`pid` AND `Window`.`start` = `Process`.`start`\n" + 
			"WHERE `Window`.`event` = ? AND `Window`.`adminEmail` = ?\n" + 
			"ORDER BY `overallUser`, `overallSession`, `overallTime`, `overallTimeChanged`, `overallPid`, `overallXid`";
	private String userQuery = "SELECT * FROM `openDataCollectionServer`.`User` WHERE `event` = ? AND `adminEmail` = ? ORDER BY `username`, `session` ASC";
	
	private String keyboardQuery = "SELECT *, 'keyboard' AS `fromInput` FROM `openDataCollectionServer`.`KeyboardInput`\n" + 
			"WHERE `event` = ? AND `adminEmail` = ?\n" + 
			"ORDER BY `inputTime`, `insertTimestamp` ASC";
	
	private String mouseQuery = "SELECT *, 'mouse' AS `fromInput` FROM `openDataCollectionServer`.`MouseInput`\n" + 
			"WHERE `event` = ? AND `adminEmail` = ?\n" + 
			"ORDER BY `inputTime`, `insertTimestamp` ASC";
	
	private String taskQuery = "SELECT * FROM `openDataCollectionServer`.`Task` LEFT JOIN `TaskEvent` ON `Task`.`username` = `TaskEvent`.`username` AND `Task`.`event` = `TaskEvent`.`event` AND `Task`.`adminEmail` = `TaskEvent`.`adminEmail` AND `Task`.`taskName` = `TaskEvent`.`taskName` WHERE `Task`.`event` = ? AND `Task`.`adminEmail` = ? ORDER BY `TaskEvent`.`eventTime`, `TaskEvent`.`insertTimestamp` ASC";
	
	private String imageQuery = "SELECT * FROM `openDataCollectionServer`.`Screenshot` WHERE `username` = ? AND `session` = ? AND `event` = ? AND `adminEmail` = ? ORDER BY abs(? - (UNIX_TIMESTAMP(`taken`) * 1000)) LIMIT 1";
	private String imageQueryExact = "SELECT * FROM `openDataCollectionServer`.`Screenshot` WHERE `username` = ? AND `session` = ? AND `event` = ? AND `adminEmail` = ? AND (UNIX_TIMESTAMP(`taken`) * 1000) = ?";
	//" AND (UNIX_TIMESTAMP(`taken`) * 1000) > ?" - after time
	//" AND (UNIX_TIMESTAMP(`taken`) * 1000) < ?" - before time
	private String allImageQuery = "SELECT * FROM `openDataCollectionServer`.`Screenshot` WHERE `event` = ? AND `adminEmail` = ? ORDER BY `taken`, `insertTimestamp` ASC";
	
	
	private String filterQuery = "SELECT * FROM `openDataCollectionServer`.`VisualizationFilters` WHERE `VisualizationFilters`.`event` = ? AND `VisualizationFilters`.`adminEmail` = ? ORDER BY `VisualizationFilters`.`saveName`, `VisualizationFilters`.`filterNum` ASC";
	
	//private String allProcessQueryOld = "SELECT * FROM `Process` LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start` WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ? ORDER BY `ProcessAttributes`.`insertTimestamp` ASC";
	
	private String allProcessQuery = "SELECT * FROM `Process` LEFT JOIN \n" + 
			"(\n" + 
			"SELECT `event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, GROUP_CONCAT(`arg` ORDER BY `numbered` ASC SEPARATOR ' ') AS `arguments` FROM `ProcessArgs` GROUP BY `ProcessArgs`.`event`, `ProcessArgs`.`adminEmail`, `ProcessArgs`.`username`, `ProcessArgs`.`session`, `ProcessArgs`.`user`, `ProcessArgs`.`pid`, `ProcessArgs`.`start`\n" + 
			") a\n" + 
			"USING (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`)\n" + 
			"LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start`\n" + 
			"WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ? ORDER BY `ProcessAttributes`.`timestamp`, `ProcessAttributes`.`insertTimestamp` ASC";
	
	private String allProcessQueryFix = "SELECT * FROM `Process` LEFT JOIN \n" + 
			"(\n" + 
			"SELECT `event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, GROUP_CONCAT(`arg` ORDER BY `numbered` ASC SEPARATOR ' ') AS `arguments` FROM `ProcessArgs` GROUP BY `ProcessArgs`.`event`, `ProcessArgs`.`adminEmail`, `ProcessArgs`.`username`, `ProcessArgs`.`session`, `ProcessArgs`.`user`, `ProcessArgs`.`pid`, `ProcessArgs`.`start`\n" + 
			") a\n" + 
			"USING (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`)\n" + 
			"LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start`\n" + 
			"WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ? ORDER BY `ProcessAttributes`.`insertTimestamp`, `ProcessAttributes`.`timestamp` ASC";
	
	private String allWindowQuery = "SELECT * FROM `Window` LEFT JOIN `WindowDetails`ON `Window`.`event` = `WindowDetails`.`event` AND `Window`.`adminEmail` = `WindowDetails`.`adminEmail` AND `Window`.`username` = `WindowDetails`.`username` AND `Window`.`session` = `WindowDetails`.`session` AND `Window`.`user` = `WindowDetails`.`user` AND `Window`.`pid` = `WindowDetails`.`pid` AND `Window`.`start` = `WindowDetails`.`start` AND `Window`.`xid` = `WindowDetails`.`xid` WHERE `WindowDetails`.`event` = ? AND `WindowDetails`.`adminEmail` = ? ORDER BY `WindowDetails`.`timeChanged`, `WindowDetails`.`insertTimestamp` ASC";
	
	private String insertFilter = "INSERT INTO `VisualizationFilters`(`event`, `adminEmail`, `level`, `field`, `value`, `server`, `saveName`, `filterNum`) VALUES ";
	private String insertFilterValues = "(?,?,?,?,?,?,?,?)";
	
	private String deleteFilter = "DELETE FROM `VisualizationFilters` WHERE `event` = ? AND `adminEmail` = ? AND `saveName` = ?";
	
	private String insertTask = "INSERT INTO `Task`(`event`, `adminEmail`, `username`, `session`, `taskName`, `completion`, `startTimestamp`) VALUES (?,?,?,?,?,?, FROM_UNIXTIME(? / 1000))";
	private String insertTaskEvent = "INSERT INTO `TaskEvent`(`event`, `adminEmail`, `username`, `session`, `taskName`, `eventTime`, `eventDescription`, `startTimestamp`, `source`) VALUES (?,?,?,?,?,FROM_UNIXTIME(? / 1000),?,FROM_UNIXTIME(? / 1000),?)";
	
	private String deleteTaskEvents = "DELETE FROM `TaskEvent` WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `source` = ? AND `startTimestamp` = FROM_UNIXTIME(? / 1000)";
	private String selectTaskEvents = "SELECT * FROM `TaskEvent` WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `startTimestamp` = FROM_UNIXTIME(? / 1000)";
	private String deleteTask = "DELETE FROM `Task` WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `startTimestamp` = FROM_UNIXTIME(? / 1000)";
	
	private String sessionDetailsQuery = "SELECT * FROM `openDataCollectionServer`.`User` WHERE `event` = ? AND `adminEmail` = ? ORDER BY `insertTimestamp` ASC";
	
	private String limiter = " LIMIT ?, ?";
	
	private String checkPerms = "SELECT `adminEmail` FROM `EventPassword` WHERE `event` = ? AND `adminEmail` = ? AND `password` = ?";
	
	private TestingConnectionSource mySource;
	
	private String databaseName = "dataserver";
	
	//public DatabaseConnector()
	//{
		//ConcurrentHashMap tmp=DatabaseInformationManager.getInstance().getNext(databaseName);
	//	mySource = new TestingConnectionSource();
	//	setupConnectionSource();
	//}
	
	public DatabaseConnector(ServletContext sc)
	{
		cal.setTimeZone(TimeZone.getDefault());
		setupDBManager(sc);
		setupConnectionSource();
		
	}
	
	public DatabaseConnector(ServletContext sc, String dbname)
	{
		cal.setTimeZone(TimeZone.getDefault());
		setupDBManager(sc);
		databaseName = dbname;
		setupConnectionSource();
	}
	
	public void setupConnectionSource()
	{
		cal.setTimeZone(TimeZone.getDefault());
		ConcurrentHashMap tmp=DatabaseInformationManager.getInstance().getNext(databaseName);
		//(String)tmp.get("address"), (String)tmp.get("driver"), (String)tmp.get("username"), (Integer)tmp.get("maxconnections"), (String)tmp.get("password")
		mySource = new TestingConnectionSource((String)tmp.get("username"), (String)tmp.get("password"), (String)tmp.get("address"));
	}
	
	public TestingConnectionSource getConnectionSource()
	{
		cal.setTimeZone(TimeZone.getDefault());

		return mySource;
	}
	
	public void setupDBManager(ServletContext sc)
	{
		cal.setTimeZone(TimeZone.getDefault());
		DatabaseInformationManager manager=DatabaseInformationManager.getInstance();
		//ServletContext sc=getServletContext();
		String reportPath=sc.getRealPath("/WEB-INF/conf");
		reportPath+="/databases.xml";
		manager.addInfoFile(reportPath);
		/*DatabaseConnector myConnector=(DatabaseConnector)session.getAttribute("connector");
		if(myConnector==null)
		{
			myConnector=new DatabaseConnector("pillar");
			try {
				myConnector.connect();
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			session.setAttribute("connector", myConnector);
		}*/
	}
	
	/*public static void main(String[] args)
	{
		DatabaseConnector myConnector = new DatabaseConnector();
		ArrayList results = myConnector.getUsers();
		for(int x=0; x<results.size(); x++)
		{
			System.out.println(results.get(x));
			
		}
		System.out.println("\n");
		ArrayList filteredResults = myConnector.getStartNodes(results);
		for(int x=0; x<filteredResults.size(); x++)
		{
			System.out.println(filteredResults.get(x));
			
		}
		
		System.out.println(myConnector.toJSON(filteredResults));
	}*/
	
	public ArrayList getStartNodesTask(ArrayList fullData)
	{
		ArrayList myReturn = new ArrayList();
		
		ConcurrentHashMap prevNode = null;
		ConcurrentHashMap curNode = null;
		ConcurrentHashMap lastNode = null;
		String userName = "";
		String sessionName = "";
		
		for(int x=0; x<fullData.size(); x++)
		{
			curNode = (ConcurrentHashMap) fullData.get(x);
			if(prevNode != null)
			{
				if(!(curNode.get("Username").equals(userName) && curNode.get("Session").equals(sessionName)))
				{
					prevNode.put("End Time MS", lastNode.get("Event Time MS"));
				}
			}
			else
			{
				myReturn.add(curNode);
				prevNode = curNode;
				userName = (String) prevNode.get("Username");
				sessionName = (String) prevNode.get("Session");
				
			}
			lastNode = curNode;
		}
		
		
		return myReturn;
	}
	
	public ArrayList getStartNodes(ArrayList fullData)
	{
		ArrayList myReturn = new ArrayList();
		
		ConcurrentHashMap prevNode = null;
		
		ConcurrentHashMap curNode = null;
		
		ConcurrentHashMap lastNode = null;
		
		String userName = "";
		String sessionName = "";
		
		for(int x=0; x<fullData.size(); x++)
		{
			curNode = (ConcurrentHashMap) fullData.get(x);
			if(prevNode != null)
			{
				if(!(curNode.get("Username").equals(userName) && curNode.get("Session").equals(sessionName)))
				{
					prevNode.put("End Time", lastNode.get("Input Time"));
					prevNode.put("End Time MS", lastNode.get("Input Time MS"));
					myReturn.add(curNode);
					prevNode = curNode;
					userName = (String) prevNode.get("Username");
					sessionName = (String) prevNode.get("Session");
				}
				else if(!prevNode.get("XID").equals(curNode.get("XID")))
				{
					myReturn.add(curNode);
					prevNode.put("End Time", curNode.get("Start Time"));
					if(curNode.containsKey("Start Time MS"))
					{
						prevNode.put("End Time MS", curNode.get("Start Time MS"));
					}
					prevNode = curNode;
				}
			}
			else
			{
				myReturn.add(curNode);
				prevNode = curNode;
				userName = (String) prevNode.get("Username");
				sessionName = (String) prevNode.get("Session");
			}
			lastNode = curNode;
			userName = (String) curNode.get("Username");
			sessionName = (String) curNode.get("Session");
		}
		
		prevNode.put("End Time", curNode.get("Input Time"));
		prevNode.put("End Time MS", curNode.get("Input Time MS"));
		
		return myReturn;
	}
	
	
	public ArrayList convertTime(ArrayList input)
	{
		for(int x=0; x<input.size(); x++)
		{
			ConcurrentHashMap curMap = (ConcurrentHashMap) input.get(x);
			curMap.put("Start Time MS", ((Date) curMap.get("Start Time")).getTime());
			curMap.put("Input Time MS", ((Date) curMap.get("Input Time")).getTime());
			if(curMap.containsKey("End Time"))
			{
				curMap.put("End Time MS", ((Date) curMap.get("End Time")).getTime());
			}
		}
		
		return input;
	}
	
	public ArrayList convertTimeTask(ArrayList input)
	{
		for(int x=0; x<input.size(); x++)
		{
			ConcurrentHashMap curMap = (ConcurrentHashMap) input.get(x);
			curMap.put("Event Time MS", ((Date) curMap.get("Event Time")).getTime());
		}
		
		return input;
	}
	
	public ConcurrentHashMap mergeMaps(ConcurrentHashMap a, ConcurrentHashMap b)
	{
		Iterator bIterator = b.entrySet().iterator();
		while(bIterator.hasNext())
		{
			Map.Entry bEntry = (Entry) bIterator.next();
			if(!a.containsKey(bEntry.getKey()))
			{
				a.put(bEntry.getKey(), bEntry.getValue());
			}
			else
			{
				if(a.get(bEntry.getKey()) instanceof ConcurrentHashMap && bEntry.getValue() instanceof ConcurrentHashMap)
				{
					a.put(bEntry.getKey(), mergeMaps((ConcurrentHashMap)a.get(bEntry.getKey()), (ConcurrentHashMap)bEntry.getValue()));
				}
			}
		}
		return a;
	}
	
	public ArrayList toDirMap(ConcurrentHashMap b, String dir)
	{
		ArrayList myReturn = new ArrayList();
		Iterator bIterator = b.entrySet().iterator();
		while(bIterator.hasNext())
		{
			Map.Entry bEntry = (Entry) bIterator.next();
			String nextDir = (String) bEntry.getKey();
			//System.out.println("Adding dir " + nextDir + " for " + bEntry.getValue().getClass());
			if(bEntry.getValue() instanceof ConcurrentHashMap)
			{
				myReturn.addAll(toDirMap((ConcurrentHashMap) bEntry.getValue(), dir + "/" + nextDir));
			}
			//else if(bEntry.getValue() instanceof ArrayList)
			//{
			//	ArrayList finalFiles = (ArrayList) bEntry.getValue();
			//	for(int x=0; x<finalFiles.size(); x++)
			//	{
			//		
			//	}
			//}
			else
			{
				ConcurrentHashMap fileMap = new ConcurrentHashMap();
				//System.out.println("Final file path: " + dir + "/" + nextDir);
				fileMap.put("filePath", dir + "/" + nextDir);
				fileMap.put("file", bEntry.getValue());
				myReturn.add(fileMap);
			}
		}
		return myReturn;
	}
	
	public ConcurrentHashMap normalizeAllTime(ConcurrentHashMap userMap)
	{
		long universalMin = Long.MAX_VALUE;
		long universalMax = Long.MIN_VALUE;
		ConcurrentHashMap userMinMap = new ConcurrentHashMap();
		ConcurrentHashMap userMaxMap = new ConcurrentHashMap();
		ConcurrentHashMap sessionMinMap = new ConcurrentHashMap();
		ConcurrentHashMap sessionMaxMap = new ConcurrentHashMap();
		
		Iterator userIterator = userMap.entrySet().iterator();
		while(userIterator.hasNext())
		{
			Map.Entry userEntry = (Entry) userIterator.next();
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
			String userName = (String) userEntry.getKey();
			//System.out.println(userName);
			Iterator sessionIterator = sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Map.Entry sessionEntry = (Entry) sessionIterator.next();
				String sessionName = (String) sessionEntry.getKey();
				//System.out.println(sessionName);
				ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
				Iterator dataIterator = dataMap.entrySet().iterator();
				while(dataIterator.hasNext())
				{
					Map.Entry dataEntry = (Entry) dataIterator.next();
					ArrayList dataList = (ArrayList) dataEntry.getValue();
					//System.out.println(dataEntry.getKey());
					for(int x=0; x<dataList.size(); x++)
					{
						ConcurrentHashMap curData = (ConcurrentHashMap) dataList.get(x);
						Iterator fieldIterator = curData.entrySet().iterator();
						while(fieldIterator.hasNext())
						{
							Map.Entry fieldEntry = (Entry) fieldIterator.next();
							if(fieldEntry.getValue() instanceof Date && ((String)fieldEntry.getKey()).contains("Index"))
							{
								//System.out.println("Date: " + fieldEntry.getKey());
								curData.put(fieldEntry.getKey() + " MS", ((Date) fieldEntry.getValue()).getTime());
								//System.out.println("Converted");
								long thisTime = (long) curData.get(fieldEntry.getKey() + " MS");
								//System.out.println("Got converted");
								if(universalMin > thisTime)
								{
									//System.out.println("New universal min");
									universalMin = thisTime;
								}
								if(universalMax < thisTime)
								{
									//System.out.println("New universal max");
									universalMax = thisTime;
								}
								
								if(userMinMap.containsKey(userName))
								{
									if((long)userMinMap.get(userName) > thisTime)
									{
										userMinMap.put(userName, thisTime);
									}
									if((long)userMaxMap.get(userName) < thisTime)
									{
										userMaxMap.put(userName, thisTime);
									}
								}
								else
								{
									userMinMap.put(userName, thisTime);
									userMaxMap.put(userName, thisTime);
								}
								//System.out.println("User map updated");
								
								
								if(!sessionMinMap.containsKey(userName))
								{
									sessionMinMap.put(userName, new ConcurrentHashMap());
									sessionMaxMap.put(userName, new ConcurrentHashMap());
								}
								ConcurrentHashMap userSessionMinMap = (ConcurrentHashMap) sessionMinMap.get(userName);
								ConcurrentHashMap userSessionMaxMap = (ConcurrentHashMap) sessionMaxMap.get(userName);
								
								if(userSessionMinMap.containsKey(sessionName))
								{
									if((long)userSessionMinMap.get(sessionName) > thisTime)
									{
										userSessionMinMap.put(sessionName, thisTime);
									}
									if((long)userSessionMaxMap.get(sessionName) < thisTime)
									{
										userSessionMaxMap.put(sessionName, thisTime);
									}
								}
								else
								{
									userSessionMinMap.put(sessionName, thisTime);
									userSessionMaxMap.put(sessionName, thisTime);
								}
								//System.out.println("Session map updated");
							}
						}
					}
				}
			}
		}
		//Gson gson = new GsonBuilder().create();
		//System.out.println(gson.toJson(sessionMinMap));
		//System.out.println(gson.toJson(sessionMaxMap));
		//if(true)
		//{
		//	return userMap;
		//}
		userIterator = userMap.entrySet().iterator();
		while(userIterator.hasNext())
		{
			Map.Entry userEntry = (Entry) userIterator.next();
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
			String userName = (String) userEntry.getKey();
			//System.out.println("Second iteraton " + userName);
			Iterator sessionIterator = sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Map.Entry sessionEntry = (Entry) sessionIterator.next();
				String sessionName = (String) sessionEntry.getKey();
				//System.out.println("Second iteraton " + sessionName);
				ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
				Iterator dataIterator = dataMap.entrySet().iterator();
				while(dataIterator.hasNext())
				{
					Map.Entry dataEntry = (Entry) dataIterator.next();
					ArrayList dataList = (ArrayList) dataEntry.getValue();
					for(int x=0; x<dataList.size(); x++)
					{
						ConcurrentHashMap curData = (ConcurrentHashMap) dataList.get(x);
						Iterator fieldIterator = curData.entrySet().iterator();
						while(fieldIterator.hasNext())
						{
							Map.Entry fieldEntry = (Entry) fieldIterator.next();
							if(fieldEntry.getValue() instanceof Date && ((String)fieldEntry.getKey()).contains("Index"))
							{
								curData.put(fieldEntry.getKey() + " MS Universal", ((Date) fieldEntry.getValue()).getTime() - universalMin);
								curData.put(fieldEntry.getKey() + " MS User", ((Date) fieldEntry.getValue()).getTime() - (long)userMinMap.get(userName));
								ConcurrentHashMap userSessionMinMap = (ConcurrentHashMap) sessionMinMap.get(userName);
								curData.put(fieldEntry.getKey() + " MS Session", ((Date) fieldEntry.getValue()).getTime() - (long)userSessionMinMap.get(sessionName));
								
							}
						}
					}
				}
			}
		}
		
		return userMap;
	}
	
	public ArrayList normalizeTimeTasks(ArrayList input)
	{
		ConcurrentHashMap userMinMap = new ConcurrentHashMap();
		ConcurrentHashMap userMaxMap = new ConcurrentHashMap();
		for(int x=0; x<input.size(); x++)
		{
			ConcurrentHashMap curMap = (ConcurrentHashMap) input.get(x);
			if(userMinMap.containsKey(curMap.get("Username")))
			{
				if((long)userMinMap.get(curMap.get("Username")) > (long)curMap.get("Event Time MS"))
				{
					userMinMap.put(curMap.get("Username"), curMap.get("Event Time MS"));
				}
				if((long)userMaxMap.get(curMap.get("Username")) < (long)curMap.get("Event Time MS"))
				{
					userMaxMap.put(curMap.get("Username"), curMap.get("Event Time MS"));
				}
			}
			else
			{
				userMinMap.put(curMap.get("Username"), curMap.get("Event Time MS"));
				userMaxMap.put(curMap.get("Username"), curMap.get("Event Time MS"));
			}
		}
		
		for(int x=0; x<input.size(); x++)
		{
			ConcurrentHashMap curMap = (ConcurrentHashMap) input.get(x);
			curMap.put("Event Time MS", (long)curMap.get("Event Time MS") - (long)userMinMap.get(curMap.get("Username")));
		}
		
		return input;
	}
	
	public ArrayList normalizeTime(ArrayList input)
	{
		ConcurrentHashMap userMinMap = new ConcurrentHashMap();
		ConcurrentHashMap userMaxMap = new ConcurrentHashMap();
		for(int x=0; x<input.size(); x++)
		{
			ConcurrentHashMap curMap = (ConcurrentHashMap) input.get(x);
			if(userMinMap.containsKey(curMap.get("Username")))
			{
				if((long)userMinMap.get(curMap.get("Username")) > (long)curMap.get("Start Time MS"))
				{
					userMinMap.put(curMap.get("Username"), curMap.get("Start Time MS"));
				}
				if((long)userMaxMap.get(curMap.get("Username")) < (long)curMap.get("Input Time MS"))
				{
					userMaxMap.put(curMap.get("Username"), curMap.get("Input Time MS"));
				}
			}
			else
			{
				userMinMap.put(curMap.get("Username"), curMap.get("Start Time MS"));
				userMaxMap.put(curMap.get("Username"), curMap.get("Input Time MS"));
			}
		}
		
		for(int x=0; x<input.size(); x++)
		{
			ConcurrentHashMap curMap = (ConcurrentHashMap) input.get(x);
			curMap.put("Start Time MS", (long)curMap.get("Start Time MS") - (long)userMinMap.get(curMap.get("Username")));
			curMap.put("Input Time MS", (long)curMap.get("Input Time MS") - (long)userMinMap.get(curMap.get("Username")));
			if(curMap.containsKey("End Time"))
			{
				curMap.put("End Time MS", (long)curMap.get("End Time MS") - (long)userMinMap.get(curMap.get("Username")));
			}
		}
		
		return input;
	}
	
	public String toJSON(ArrayList input)
	{
		String myReturn = "{\n\t" + "\"windowEvents\":" + "\n\t[";
		
		for(int x=0; x <input.size(); x++)
		{
			ConcurrentHashMap curMap = (ConcurrentHashMap) input.get(x);
			String jsonString = "\n\t\t{";
			if(x > 0)
			{
				jsonString = "," + jsonString;
			}
			
			Iterator curIterator = curMap.entrySet().iterator();
			boolean first = true;
			while(curIterator.hasNext())
			{
				if(first)
				{
					first = false;
				}
				else
				{
					jsonString += ",";
				}
				Entry curEntry = (Entry) curIterator.next();
				jsonString += "\n\t\t\t\"" + curEntry.getKey() + "\": ";
				if(curEntry.getValue() instanceof Integer || curEntry.getValue() instanceof Long || curEntry.getValue() instanceof Double || curEntry.getValue() instanceof Float)
				{
					jsonString += curEntry.getValue();
				}
				else
				{
					jsonString += "\"" + curEntry.getValue() + "\"";
				}
			}
			
			jsonString += "\n\t\t}";
			myReturn += jsonString;
		}
		
		myReturn += "\n\t]\n}";
		
		return myReturn;
	}
	
	public String getPermission(String eventName, String eventAdmin, String password)
	{
		String myReturn = "";
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		
		conn = myConnector;
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(checkPerms);
			myStatement.setString(1, eventName);
			myStatement.setString(2, eventAdmin);
			myStatement.setString(3, password);
			ResultSet myResults = myStatement.executeQuery();
			
			while(myResults.next())
			{
				myReturn = myResults.getString("adminEmail");
			}
			
			
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ArrayList getUsers(String event, String admin)
	{
		ArrayList myReturn = new ArrayList();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			//System.out.println(userQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(userQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				nextRow.put("Username", myResults.getString("username"));
				nextRow.put("Session", myResults.getString("session"));
				//System.out.println(nextRow);
				myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ArrayList getFilters(String event, String admin)
	{
		ArrayList myReturn = new ArrayList();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(filterQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				nextRow.put("Level", myResults.getString("level"));
				nextRow.put("Field", myResults.getString("field"));
				nextRow.put("Value", myResults.getString("value"));
				nextRow.put("Server", myResults.getString("server"));
				nextRow.put("SaveName", myResults.getString("saveName"));
				myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap addFilters(String event, String admin, ArrayList toAdd, String saveAs)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			String curStatement = insertFilter;
			for(int x=0; x<toAdd.size(); x++)
			{
				if(x > 0)
				{
					curStatement += ",";
				}
				curStatement += insertFilterValues;
			}
			PreparedStatement myStatement = myConnector.prepareStatement(curStatement);
			//(`event`, `adminEmail`, `level`, `field`, `value`, `server`, `saveName`, `filterNum`)
			for(int x=0; x<toAdd.size(); x++)
			{
				int curStart = 8 * x + 1;
				ConcurrentHashMap curMap = (ConcurrentHashMap) toAdd.get(x);
				
				myStatement.setString(curStart, event);
				myStatement.setString(curStart + 1, admin);
				myStatement.setString(curStart + 2, (String) curMap.get("level"));
				myStatement.setString(curStart + 3, (String) curMap.get("field"));
				myStatement.setString(curStart + 4, (String) curMap.get("value"));
				myStatement.setString(curStart + 5, "0");
				myStatement.setString(curStart + 6, saveAs);
				myStatement.setInt(curStart + 7, x);
			}
			myStatement.execute();
			
			stmt = myStatement;
			
			stmt.close();
			conn.close();
			myReturn.put("result", "okay");
		}
		catch(Exception e)
		{
			myReturn.put("result", "nokay");
			e.printStackTrace();
		}
		finally
		{
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap deleteFilters(String event, String admin, String saveAs)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			String curStatement = deleteFilter;
			
			PreparedStatement myStatement = myConnector.prepareStatement(curStatement);
			//WHERE `event` = ? AND `adminEmail` = ? AND `saveName` = ?
			
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, saveAs);
			
			myStatement.execute();
			
			stmt = myStatement;
			
			stmt.close();
			conn.close();
			myReturn.put("result", "okay");
		}
		catch(Exception e)
		{
			myReturn.put("result", "nokay");
			e.printStackTrace();
		}
		finally
		{
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap addTask(String event, String user, String session, String admin, long start, long end, String taskName)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			String curStatement = insertFilter;
			curStatement = insertTask;
			PreparedStatement myStatement = myConnector.prepareStatement(curStatement);
			//`event`, `adminEmail`, `username`, `session`, `taskName`, `completion`, `startTimestamp`
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, user);
			myStatement.setString(4, session);
			myStatement.setString(5, taskName);
			myStatement.setString(6, "1");
			myStatement.setLong(7, start);
			
			//System.out.println(myStatement);
			
			myStatement.execute();
			myStatement.close();
			
			curStatement = insertTaskEvent;
			myStatement = myConnector.prepareStatement(curStatement);
			//`event`, `adminEmail`, `username`, `session`, `taskName`, `eventTime`, `eventDescription`, `startTimestamp`, `source`
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, user);
			myStatement.setString(4, session);
			myStatement.setString(5, taskName);
			myStatement.setLong(6, start);
			myStatement.setString(7, "start");
			myStatement.setLong(8, start);
			myStatement.setString(9, admin);
			
			myStatement.execute();
			myStatement.close();
			
			myStatement = myConnector.prepareStatement(curStatement);
			//`event`, `adminEmail`, `username`, `session`, `taskName`, `eventTime`, `eventDescription`, `startTimestamp`, `source`
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, user);
			myStatement.setString(4, session);
			myStatement.setString(5, taskName);
			myStatement.setLong(6, end);
			myStatement.setString(7, "end");
			myStatement.setLong(8, start);
			myStatement.setString(9, admin);
			
			myStatement.execute();
			
			
			stmt = myStatement;
			
			stmt.close();
			conn.close();
			myReturn.put("result", "okay");
			
			ArrayList thisUser = new ArrayList();
			thisUser.add(user);
			ArrayList thisSession = new ArrayList();
			thisUser.add(session);
			
			myReturn.put("newEvents", normalizeAllTime(getTasksHierarchy(event, admin, thisUser, thisSession, "", "")));
			
		}
		catch(Exception e)
		{
			myReturn.put("result", "nokay");
			e.printStackTrace();
		}
		finally
		{
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap deleteTask(String event, String admin, String user, String session, String source, String taskName, long startTime)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			String curStatement = deleteTaskEvents;
			PreparedStatement myStatement = myConnector.prepareStatement(curStatement);
			//`event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `source` = ?
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, user);
			myStatement.setString(4, session);
			myStatement.setString(5, taskName);
			myStatement.setString(6, admin);
			myStatement.setLong(7, startTime);
			
			//System.out.println(myStatement);
			
			myStatement.execute();
			myStatement.close();
			
			curStatement = selectTaskEvents;
			myStatement = myConnector.prepareStatement(curStatement);
			//`event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ?
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, user);
			myStatement.setString(4, session);
			myStatement.setString(5, taskName);
			myStatement.setLong(6, startTime);
			
			ResultSet myResults = myStatement.executeQuery();
			if(!(myResults.isBeforeFirst()))
			{
				myResults.close();
				myStatement.close();
				curStatement = deleteTask;
				myStatement = myConnector.prepareStatement(curStatement);
				//`event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `source` = ?
				myStatement.setString(1, event);
				myStatement.setString(2, admin);
				myStatement.setString(3, user);
				myStatement.setString(4, session);
				myStatement.setString(5, taskName);
				myStatement.setLong(6, startTime);
				
				//System.out.println(myStatement);
				
				myStatement.execute();
				myStatement.close();
				
			}
			else
			{
				
				myResults.close();
			}
			
			stmt = myStatement;
			
			stmt.close();
			conn.close();
			myReturn.put("result", "okay");
			
			ArrayList thisUser = new ArrayList();
			thisUser.add(user);
			
			ArrayList thisSession = new ArrayList();
			thisUser.add(session);
			
			myReturn.put("newEvents", normalizeAllTime(getTasksHierarchy(event, admin, thisUser, thisSession, "", "")));
			
			
		}
		catch(Exception e)
		{
			myReturn.put("result", "nokay");
			e.printStackTrace();
		}
		finally
		{
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ArrayList getTasks(String event, String admin)
	{
		ArrayList myReturn = new ArrayList();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(taskQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				nextRow.put("Username", myResults.getString("username"));
				nextRow.put("Session", myResults.getString("session"));
				nextRow.put("Task Name", myResults.getString("taskName"));
				nextRow.put("Completion", myResults.getString("completion"));
				nextRow.put("Event Time", myResults.getTimestamp("eventTime", cal));
				nextRow.put("Event", myResults.getString("event"));
				
				myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return convertTimeTask(myReturn);
	}
	
	public ConcurrentHashMap getTasksHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String taskQuery = this.taskQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = " AND `Task`.`username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			taskQuery = taskQuery.replace("`Task`.`adminEmail` = ?", "`Task`.`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `Task`.`session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			taskQuery = taskQuery.replace("`Task`.`adminEmail` = ?", "`Task`.`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			taskQuery = taskQuery + limiter;
		}
		
		try
		{
			System.out.println(taskQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(taskQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				nextRow.put("Source", myResults.getString("source"));
				nextRow.put("TaskName", myResults.getString("taskName"));
				nextRow.put("Completion", myResults.getString("completion"));
				nextRow.put("EventTime", myResults.getTimestamp("eventTime", cal));
				nextRow.put("StartTime", myResults.getTimestamp("startTimestamp", cal));
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				nextRow.put("Index", myResults.getTimestamp("eventTime", cal));
				//nextRow.put("Event", myResults.getString("event"));
				
				nextRow.put("Description", myResults.getString("eventDescription"));
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("events"))
				{
					sessionMap.put("events", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("events");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap getSessionDetailsHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String taskQuery = sessionDetailsQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			taskQuery = taskQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			taskQuery = taskQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			taskQuery = taskQuery + limiter;
		}
		
		try
		{
			System.out.println(taskQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(taskQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				nextRow.put("UploadTime", myResults.getTimestamp("insertTimestamp", cal));
				//nextRow.put("Index", myResults.getTimestamp("insertTimestamp", cal));
				nextRow.put("Environment", myResults.getString("sessionEnvironment"));
				
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("environment"))
				{
					sessionMap.put("environment", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("environment");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap getScreenshotsHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, boolean onlyIndex, boolean base64, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
        String allImageQuery = this.allImageQuery;
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			allImageQuery = allImageQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			allImageQuery = allImageQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			allImageQuery = allImageQuery + limiter;
		}
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(allImageQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				nextRow.put("Taken", myResults.getTimestamp("taken", cal));
				nextRow.put("Index", myResults.getTimestamp("taken", cal));
				
				byte[] image = myResults.getBytes("screenshot");
				nextRow.put("Size", image.length);
				
				if(!onlyIndex)
				{
					//byte[] image = myResults.getBytes("screenshot");
					if(base64)
					{
						String imageEncoded = Base64.getEncoder().encodeToString(image);
						nextRow.put("Screenshot", imageEncoded);
					}
					else
					{
						nextRow.put("Screenshot", image);
					}
				}
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("screenshots"))
				{
					sessionMap.put("screenshots", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("screenshots");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap getScreenshotsHierarchyBinary(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap toReturn = new ConcurrentHashMap();
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		ConcurrentHashMap myReturnBinary = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
        String allImageQuery = this.allImageQuery;
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			allImageQuery = allImageQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			allImageQuery = allImageQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			allImageQuery = allImageQuery + limiter;
		}
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(allImageQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				nextRow.put("Taken", myResults.getTimestamp("taken", cal));
				nextRow.put("Index", myResults.getTimestamp("taken", cal));
				
				nextRow.put("Path", "./" + userName + "/" + sessionName + "/screenshots/" + ((String)myResults.getTimestamp("taken", cal).toString()).replaceAll(" ", "_") + ".jpg");
				
				ConcurrentHashMap nextRowBinary = new ConcurrentHashMap();
				nextRowBinary.put("Index", ((String)myResults.getTimestamp("taken", cal).toString()).replaceAll(" ", "_") + ".jpg");
				//if(!onlyIndex)
				{
					byte[] image = myResults.getBytes("screenshot");
					//String imageEncoded = Base64.getEncoder().encodeToString(image);
					nextRowBinary.put("Screenshot", image);
					nextRowBinary.put("Size", image.length);
				}
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
					myReturnBinary.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				ConcurrentHashMap userMapBinary = (ConcurrentHashMap) myReturnBinary.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
					userMapBinary.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				ConcurrentHashMap sessionMapBinary = (ConcurrentHashMap) userMapBinary.get(sessionName);
				
				if(!sessionMap.containsKey("screenshots"))
				{
					sessionMap.put("screenshots", new ArrayList());
					sessionMapBinary.put("screenshots", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("screenshots");
				ArrayList eventListBinary = (ArrayList) sessionMapBinary.get("screenshots");
				
				eventList.add(nextRow);
				eventListBinary.add(nextRowBinary);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		toReturn.put("json", myReturn);
		toReturn.put("binary", myReturnBinary);
		
		return toReturn;
	}
	
	public ConcurrentHashMap getProcessDataHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap lastMap = new ConcurrentHashMap();
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String allProcessQuery = this.allProcessQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `ProcessAttributes`.`username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			allProcessQuery = allProcessQuery.replace("`ProcessAttributes`.`adminEmail` = ?", "`ProcessAttributes`.`adminEmail` = ? " + userSelectString);

		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `ProcessAttributes`.`session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			allProcessQuery = allProcessQuery.replace("`ProcessAttributes`.`adminEmail` = ?", "`ProcessAttributes`.`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			allProcessQuery = allProcessQuery + limiter;
		}
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(allProcessQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				Timestamp timeString = myResults.getTimestamp("timestamp", cal);
				//System.out.println(timeString);
				
				nextRow.put("User", myResults.getString("user"));
				nextRow.put("PID", myResults.getString("pid"));
				nextRow.put("Start", myResults.getString("start"));
				nextRow.put("Command", myResults.getString("command"));
				
				
				if(myResults.getObject("arguments") != null)
				{
					nextRow.put("Arguments", myResults.getString("arguments"));
				}
				
				ConcurrentHashMap rowKey = new ConcurrentHashMap(nextRow);
				
				rowKey.put("Username", userName);
				rowKey.put("Session", sessionName);
				if(lastMap.containsKey(rowKey))
				{
					nextRow.put("Prev", lastMap.get(rowKey));
					((ConcurrentHashMap)lastMap.get(rowKey)).put("Next", nextRow);
				}
				lastMap.put(rowKey, nextRow);
				
				if(timeString.toString().contains("0000-00-00"))
				{
					nextRow.put("SnapTime", new Timestamp(0));
				}
				else
				{
					nextRow.put("SnapTime", myResults.getTimestamp("timestamp", cal));
				}
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				nextRow.put("Index", nextRow.get("SnapTime"));
				
				
				nextRow.put("CPU", myResults.getString("cpu"));
				nextRow.put("Mem", myResults.getString("mem"));
				nextRow.put("VSZ", myResults.getString("vsz"));
				nextRow.put("RSS", myResults.getString("rss"));
				nextRow.put("TTY", myResults.getString("tty"));
				nextRow.put("Stat", myResults.getString("stat"));
				nextRow.put("Time", myResults.getString("time"));
				
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("processes"))
				{
					sessionMap.put("processes", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("processes");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		//if(true)
		//{
		//	return myReturn;
		//}
		
		Iterator userIterator = myReturn.entrySet().iterator();
		while(userIterator.hasNext())
		{
			Entry userEntry = (Entry) userIterator.next();
			System.out.println(userEntry.getKey());
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
			Iterator sessionIterator = sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Entry sessionEntry = (Entry) sessionIterator.next();
				//System.out.println(sessionEntry.getKey());
				ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
				ArrayList processList = (ArrayList) dataMap.get("processes");
				//System.out.println(processList);
				ArrayList newProcessList = new ArrayList();
				for(int x=0; x<processList.size(); x++)
				{
					//System.out.println("Got here 1");
					ConcurrentHashMap curProcess = (ConcurrentHashMap) processList.get(x);
					if(curProcess.containsKey("Next"))
					{
						//System.out.println("Got here 2");
						if(curProcess.containsKey("Prev"))
						{
							//System.out.println("Got here 3");
							
							ConcurrentHashMap prevMap = (ConcurrentHashMap) curProcess.get("Prev");
							ConcurrentHashMap nextMap = (ConcurrentHashMap) curProcess.get("Next");
							curProcess.remove("Next");
							curProcess.remove("Prev");
							//System.out.println(curProcess);
							//System.out.println(prevMap);
							//System.out.println(nextMap);
							if(prevMap.get("CPU").equals(nextMap.get("CPU")) && prevMap.get("Mem").equals(nextMap.get("Mem")) && prevMap.get("RSS").equals(nextMap.get("RSS")) && prevMap.get("VSZ").equals(nextMap.get("VSZ")))
							{
								//System.out.println("Got here 4");
								if(curProcess.get("CPU").equals(nextMap.get("CPU")) && curProcess.get("Mem").equals(nextMap.get("Mem")) && curProcess.get("RSS").equals(nextMap.get("RSS")) && curProcess.get("VSZ").equals(nextMap.get("VSZ")))
								{
									//System.out.println("Identical:");
									//System.out.println(nextMap);
									//System.out.println(prevMap);
									//System.out.println(curProcess);
									//prevMap.put("Next", nextMap);
									nextMap.put("Prev", prevMap);
									
								}
								else
								{
									//System.out.println("Not Identical:");
									//System.out.println(nextMap);
									//System.out.println(prevMap);
									//System.out.println(curProcess);
									
									newProcessList.add(curProcess);
								}
							}
							else
							{
								newProcessList.add(curProcess);
							}
						}
						else
						{
							newProcessList.add(curProcess);
						}
					}
					else
					{
						newProcessList.add(curProcess);
					}
					if(curProcess.containsKey("Prev"))
					{
						//System.out.println(curProcess);
						//System.out.println(curProcess.get("Prev"));
						curProcess.remove("Prev");
					}
					if(curProcess.containsKey("Next"))
					{
						//System.out.println(curProcess);
						//System.out.println(curProcess.get("Prev"));
						curProcess.remove("Next");
					}
					//System.out.println();
				}
				dataMap.put("processes", newProcessList);
			}
		}
		
		
		return myReturn;
	}
	
	public ConcurrentHashMap getProcessDataHierarchyFix(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String allProcessQuery = this.allProcessQueryFix;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `ProcessAttributes`.`username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			allProcessQuery = allProcessQuery.replace("`ProcessAttributes`.`adminEmail` = ?", "`ProcessAttributes`.`adminEmail` = ? " + userSelectString);

		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `ProcessAttributes`.`session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			allProcessQuery = allProcessQuery.replace("`ProcessAttributes`.`adminEmail` = ?", "`ProcessAttributes`.`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			allProcessQuery = allProcessQuery + limiter;
		}
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(allProcessQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				Timestamp timeString = myResults.getTimestamp("timestamp", cal);
				//System.out.println(timeString);
				if(timeString.toString().contains("0000-00-00"))
				{
					nextRow.put("SnapTime", new Timestamp(0));
				}
				else
				{
					nextRow.put("SnapTime", myResults.getTimestamp("timestamp", cal));
				}
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				nextRow.put("Index", nextRow.get("SnapTime"));
				
				nextRow.put("User", myResults.getString("user"));
				nextRow.put("PID", myResults.getString("pid"));
				nextRow.put("Start", myResults.getString("start"));
				nextRow.put("Command", myResults.getString("command"));
				nextRow.put("CPU", myResults.getString("cpu"));
				nextRow.put("Mem", myResults.getString("mem"));
				nextRow.put("VSZ", myResults.getString("vsz"));
				nextRow.put("RSS", myResults.getString("rss"));
				nextRow.put("TTY", myResults.getString("tty"));
				nextRow.put("Stat", myResults.getString("stat"));
				nextRow.put("Time", myResults.getTimestamp("time", cal));
				
				if(myResults.getObject("arguments") != null)
				{
					nextRow.put("Arguments", myResults.getString("arguments"));
				}
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("processes"))
				{
					sessionMap.put("processes", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("processes");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		Iterator userIterator = myReturn.entrySet().iterator();
		while(userIterator.hasNext())
		{
			Entry userEntry = (Entry) userIterator.next();
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
			Iterator sessionIterator = sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Entry sessionEntry = (Entry) sessionIterator.next();
				ConcurrentHashMap dataMap = (ConcurrentHashMap) sessionEntry.getValue();
				ArrayList processList = (ArrayList) dataMap.get("processes");
			}
		}
		
		return myReturn;
	}
	
	public ConcurrentHashMap getKeystrokesHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String keyboardQuery = this.keyboardQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			keyboardQuery = keyboardQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			keyboardQuery = keyboardQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			keyboardQuery = keyboardQuery + limiter;
		}
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(keyboardQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				nextRow.put("InputTime", myResults.getTimestamp("inputTime", cal));
				nextRow.put("Index", myResults.getTimestamp("inputTime", cal));
				
				nextRow.put("User", myResults.getString("user"));
				nextRow.put("PID", myResults.getString("pid"));
				nextRow.put("Start", myResults.getString("start"));
				nextRow.put("XID", myResults.getString("xid"));
				nextRow.put("TimeChanged", myResults.getTimestamp("timeChanged", cal));
				
				nextRow.put("Button", myResults.getString("button"));
				nextRow.put("Type", myResults.getString("type"));
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("keystrokes"))
				{
					sessionMap.put("keystrokes", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("keystrokes");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap getMouseHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String mouseQuery = this.mouseQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			mouseQuery = mouseQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			mouseQuery = mouseQuery.replace("`adminEmail` = ?", "`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			mouseQuery = mouseQuery + limiter;
		}
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(mouseQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				nextRow.put("InputTime", myResults.getTimestamp("inputTime", cal));
				nextRow.put("Index", myResults.getTimestamp("inputTime", cal));
				
				nextRow.put("User", myResults.getString("user"));
				nextRow.put("PID", myResults.getString("pid"));
				nextRow.put("Start", myResults.getString("start"));
				nextRow.put("XID", myResults.getString("xid"));
				nextRow.put("TimeChanged", myResults.getTimestamp("timeChanged", cal));
				
				nextRow.put("XLoc", myResults.getString("xLoc"));
				nextRow.put("YLoc", myResults.getString("yLoc"));
				nextRow.put("Type", myResults.getString("type"));
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("mouse"))
				{
					sessionMap.put("mouse", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("mouse");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap getWindowDataHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String allWindowQuery = this.allWindowQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `WindowDetails`.`username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			allWindowQuery = allWindowQuery.replace("`WindowDetails`.`adminEmail` = ?", "`WindowDetails`.`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `WindowDetails`.`session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			allWindowQuery = allWindowQuery.replace("`WindowDetails`.`adminEmail` = ?", "`WindowDetails`.`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			allWindowQuery = allWindowQuery + limiter;
		}
		
		try
		{
			System.out.println(allWindowQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(allWindowQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			int secondSessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				nextRow.put("ChangeTime", myResults.getTimestamp("timeChanged", cal));
				nextRow.put("Index", myResults.getTimestamp("timeChanged", cal));
				
				nextRow.put("User", myResults.getString("user"));
				nextRow.put("PID", myResults.getString("pid"));
				nextRow.put("Start", myResults.getString("start"));
				nextRow.put("XID", myResults.getString("xid"));
				nextRow.put("FirstClass", myResults.getString("firstClass"));
				nextRow.put("SecondClass", myResults.getString("secondClass"));
				nextRow.put("X", myResults.getString("x"));
				nextRow.put("Y", myResults.getString("y"));
				nextRow.put("Width", myResults.getString("width"));
				nextRow.put("Height", myResults.getString("height"));
				nextRow.put("Name", myResults.getString("name"));
				nextRow.put("Active", myResults.getString("active"));
				
				
				if(!myReturn.containsKey(userName))
				{
					myReturn.put(userName, new ConcurrentHashMap());
				}
				ConcurrentHashMap userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				if(!userMap.containsKey(sessionName))
				{
					userMap.put(sessionName, new ConcurrentHashMap());
				}
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				if(!sessionMap.containsKey("windows"))
				{
					sessionMap.put("windows", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("windows");
				
				eventList.add(nextRow);
				//myReturn.add(nextRow);
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ArrayList getCollectedData(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ArrayList myReturn = new ArrayList();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String totalQuery = this.totalQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			userSelectString = "AND `Window`.`username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			totalQuery = totalQuery.replace("`Window`.`adminEmail` = ?", "`Window`.`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `Window`.`session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			totalQuery = totalQuery.replace("`Window`.`adminEmail` = ?", "`Window`.`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			totalQuery = totalQuery + limiter;
		}
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(totalQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				
				
				String userName = myResults.getString("username");
				//nextRow.put("Username", userName);
				
				String sessionName = myResults.getString("session");
				//nextRow.put("Session", sessionName);
				
				String user = myResults.getString("user");
				nextRow.put("User", user);
				String pid = myResults.getString("pid");
				nextRow.put("PID", pid);
				String startData = myResults.getString("start");
				nextRow.put("Start", startData);
				//ArrayList processKey = new ArrayList();
				//processKey.add(user);
				//processKey.add(pid);
				//processKey.add(start);
				
				String command = myResults.getString("command");
				nextRow.put("Command", command);
				
				
				Date timeChanged = myResults.getTimestamp("timeChanged", cal);
				nextRow.put("SnapTime", timeChanged);
				
				double cpu = myResults.getDouble("cpu");
				nextRow.put("CPU", cpu);
				double mem = myResults.getDouble("mem");
				nextRow.put("Memory Use", mem);
				double vsz = myResults.getLong("vsz");
				nextRow.put("VSZ", vsz);
				double rss = myResults.getLong("rss");
				nextRow.put("RSS", rss);
				String tty = myResults.getString("tty");
				nextRow.put("TTY", tty);
				String stat = myResults.getString("stat");
				nextRow.put("Stat", stat);
				Timestamp time = myResults.getTimestamp("time", cal);
				nextRow.put("Time", time);
				
				
				String xid = myResults.getString("xid");
				nextRow.put("XID", xid);
				
				String name = myResults.getString("name");
				nextRow.put("Name", name);
				String firstClass = myResults.getString("firstClass");
				nextRow.put("FirstClass", firstClass);
				String secondClass = myResults.getString("secondClass");
				nextRow.put("SecondClass", secondClass);
				
				if(myResults.getString("fromInput").equals("mouse"))
				{
					String source = myResults.getString("fromInput");
					nextRow.put("Source", source);
					String type = myResults.getString("type");
					nextRow.put("Type", type);
					int xLoc = myResults.getInt("xLoc");
					nextRow.put("IX", xLoc);
					int yLoc = myResults.getInt("yLoc");
					nextRow.put("IY", yLoc);
					Date inputTime = myResults.getTimestamp("overallTime", cal);
					nextRow.put("Time", inputTime);
					nextRow.put("Index", inputTime);
				}
				else if(myResults.getString("fromInput").equals("keyboard"))
				{
					String source = myResults.getString("fromInput");
					nextRow.put("Source", source);
					String type = myResults.getString("type");
					nextRow.put("Type", type);
					String button = myResults.getString("button");
					nextRow.put("Button", type);
					Date inputTime = myResults.getTimestamp("overallTime", cal);
					nextRow.put("Time", inputTime);
					nextRow.put("Index", inputTime);
				}
				
				
				int x = myResults.getInt("x");
				nextRow.put("WX", x);
				int y = myResults.getInt("y");
				nextRow.put("WY", y);
				int width = myResults.getInt("width");
				nextRow.put("WWidth", width);
				int height = myResults.getInt("height");
				nextRow.put("WHeight", height);
				
				
				
				myReturn.add(nextRow);
				
				
				
				/*
				ConcurrentHashMap userMap;
				if(myReturn.containsKey(userName))
				{
					userMap = (ConcurrentHashMap) myReturn.get(userName);
				}
				else
				{
					userMap = new ConcurrentHashMap();
				}
				
				ConcurrentHashMap processMap;
				if(userMap.containsKey(processKey))
				{
					processMap = (ConcurrentHashMap) userMap.get(processKey);
				}
				else
				{
					processMap = new ConcurrentHashMap();
				}
				
				processMap.put("command", command);
				
				
				
				
				
				userMap.put(processKey, processMap);
				myReturn.put(userMap, userMap);
				*/
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(SQLException e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public ConcurrentHashMap getCollectedDataHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String totalQuery = this.totalQuery;
		String userSelectString = "";
		if(!usersToSelect.isEmpty())
		{
			System.out.println("Adding users");
			userSelectString = "AND `Window`.`username` IN (";
			for(int x=0; x<usersToSelect.size(); x++)
			{
				userSelectString += "?";
				if(!(x + 1 == usersToSelect.size()))
				{
					userSelectString += ", ";
				}
			}
			userSelectString += ")";
			totalQuery = totalQuery.replace("`Window`.`adminEmail` = ?", "`Window`.`adminEmail` = ? " + userSelectString);
		}
		
		String sessionSelectString = "";
		if(!sessionsToSelect.isEmpty())
		{
			sessionSelectString = " AND `Window`.`session` IN (";
			for(int x=0; x<sessionsToSelect.size(); x++)
			{
				sessionSelectString += "?";
				if(!(x + 1 == sessionsToSelect.size()))
				{
					sessionSelectString += ", ";
				}
			}
			sessionSelectString += ")";
			totalQuery = totalQuery.replace("`Window`.`adminEmail` = ?", "`Task`.`adminEmail` = ? " + sessionSelectString);
		}
		
		if(!start.isEmpty() && !end.isEmpty())
		{
			totalQuery = totalQuery + limiter;
		}
		
		try
		{
			System.out.println(totalQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(totalQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				myStatement.setInt(3 + sessionOffset + secondSessionOffset, Integer.parseInt(start));
				myStatement.setInt(4 + sessionOffset + secondSessionOffset, Integer.parseInt(end));
			}
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				
				
				String userName = myResults.getString("username");
				//nextRow.put("Username", userName);
				
				ConcurrentHashMap userMap = null;
				if(!myReturn.containsKey(userName))
				{
					userMap = new ConcurrentHashMap();
					myReturn.put(userName, userMap);
				}
				userMap = (ConcurrentHashMap) myReturn.get(userName);
				
				String sessionName = myResults.getString("session");
				//nextRow.put("Session", sessionName);
				
				ConcurrentHashMap sessionMap = null;
				if(!userMap.containsKey(sessionName))
				{
					//System.out.println("Adding " + userName + ":" + sessionName);
					sessionMap = new ConcurrentHashMap();
					userMap.put(sessionName, sessionMap);
				}
				sessionMap = (ConcurrentHashMap) userMap.get(sessionName);
				
				ArrayList ioList = null;
				if(!sessionMap.containsKey("io"))
				{
					ioList = new ArrayList();
					sessionMap.put("io", ioList);
				}
				ioList = (ArrayList) sessionMap.get("io");
				
				String user = myResults.getString("user");
				nextRow.put("User", user);
				String pid = myResults.getString("pid");
				nextRow.put("PID", pid);
				String startData = myResults.getString("start");
				nextRow.put("Start", startData);
				//ArrayList processKey = new ArrayList();
				//processKey.add(user);
				//processKey.add(pid);
				//processKey.add(start);
				
				String command = myResults.getString("command");
				nextRow.put("Command", command);
				
				
				Date timeChanged = myResults.getTimestamp("timeChanged", cal);
				nextRow.put("SnapTime", timeChanged);
				
				double cpu = myResults.getDouble("cpu");
				nextRow.put("CPU", cpu);
				double mem = myResults.getDouble("mem");
				nextRow.put("Mem", mem);
				double vsz = myResults.getLong("vsz");
				nextRow.put("VSZ", vsz);
				double rss = myResults.getLong("rss");
				nextRow.put("RSS", rss);
				String tty = myResults.getString("tty");
				nextRow.put("TTY", tty);
				String stat = myResults.getString("stat");
				nextRow.put("Stat", stat);
				Timestamp time = myResults.getTimestamp("time", cal);
				nextRow.put("Time", time);
				
				
				String xid = myResults.getString("xid");
				nextRow.put("XID", xid);
				
				String name = myResults.getString("name");
				nextRow.put("WName", name);
				String firstClass = myResults.getString("firstClass");
				nextRow.put("FirstClass", firstClass);
				String secondClass = myResults.getString("secondClass");
				nextRow.put("SecondClass", secondClass);
				
				if(myResults.getString("fromInput").equals("mouse"))
				{
					String source = myResults.getString("fromInput");
					nextRow.put("Source", source);
					String type = myResults.getString("type");
					nextRow.put("Type", type);
					int xLoc = myResults.getInt("xLoc");
					nextRow.put("IX", xLoc);
					int yLoc = myResults.getInt("yLoc");
					nextRow.put("IY", yLoc);
					Date inputTime = myResults.getTimestamp("overallTime", cal);
					nextRow.put("Time", inputTime);
					nextRow.put("Index", inputTime);
				}
				else if(myResults.getString("fromInput").equals("keyboard"))
				{
					String source = myResults.getString("fromInput");
					nextRow.put("Source", source);
					String type = myResults.getString("type");
					nextRow.put("Type", type);
					String button = myResults.getString("button");
					nextRow.put("Button", type);
					Date inputTime = myResults.getTimestamp("overallTime", cal);
					nextRow.put("Time", inputTime);
					nextRow.put("Index", inputTime);
				}
				
				
				int x = myResults.getInt("x");
				nextRow.put("WX", x);
				int y = myResults.getInt("y");
				nextRow.put("WY", y);
				int width = myResults.getInt("width");
				nextRow.put("WWidth", width);
				int height = myResults.getInt("height");
				nextRow.put("WHeight", height);
				
				
				
				ioList.add(nextRow);
				
				
				
				/*
				ConcurrentHashMap userMap;
				if(myReturn.containsKey(userName))
				{
					userMap = (ConcurrentHashMap) myReturn.get(userName);
				}
				else
				{
					userMap = new ConcurrentHashMap();
				}
				
				ConcurrentHashMap processMap;
				if(userMap.containsKey(processKey))
				{
					processMap = (ConcurrentHashMap) userMap.get(processKey);
				}
				else
				{
					processMap = new ConcurrentHashMap();
				}
				
				processMap.put("command", command);
				
				
				
				
				
				userMap.put(processKey, processMap);
				myReturn.put(userMap, userMap);
				*/
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(SQLException e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public byte[] getScreenshot(String username, String session, String myTimestamp, String event, String admin)
	{
		byte[] myReturn = null;
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnection();
		conn = myConnector;
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(imageQuery);
			myStatement.setString(1, username);
			myStatement.setString(2, session);
			myStatement.setString(3, event);
			myStatement.setString(4, admin);
			myStatement.setString(5, myTimestamp);
			//System.out.println(myTimestamp);
			//myStatement.setString(3, myTimestamp);
			//System.err.println(myStatement.toString());
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				byte[] imageBytes = myResults.getBytes("screenshot");
				//BufferedImage img = ImageIO.read(new ByteArrayInputStream(imageBytes));
				myReturn = imageBytes;
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		return myReturn;
	}
	
	public byte[] getScreenshotExact(String username, String session, String myTimestamp, String event, String admin)
	{
		//System.out.println("Got to method");
		byte[] myReturn = null;
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		//System.out.println("Got connection");
		conn = myConnector;
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(imageQueryExact);
			myStatement.setString(1, username);
			myStatement.setString(2, session);
			myStatement.setString(3, event);
			myStatement.setString(4, admin);
			myStatement.setString(5, myTimestamp);
			//System.out.println(myTimestamp);
			//myStatement.setString(3, myTimestamp);
			//System.err.println(myStatement.toString());
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				byte[] imageBytes = myResults.getBytes("screenshot");
				//BufferedImage img = ImageIO.read(new ByteArrayInputStream(imageBytes));
				myReturn = imageBytes;
			}
			stmt = myStatement;
			rset = myResults;
			
			rset.close();
			stmt.close();
			conn.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		//System.out.println("Finished query");
		
		return myReturn;
	}
}
