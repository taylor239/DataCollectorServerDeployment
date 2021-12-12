package com.datacollector;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.zip.GZIPInputStream;

import javax.servlet.http.HttpSession;
import javax.websocket.EndpointConfig;
import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

@ServerEndpoint(value = "/UploadData", configurator = GetHttpSessionConfigurator.class)
public class UploadDataWebsocket
{
	private Session wsSession;
	private HttpSession httpSession;
	
	@OnOpen
	public void start(Session session, EndpointConfig config)
	{
		wsSession = session;
		Set<Session> curSessions = wsSession.getOpenSessions();
		Iterator<Session> sessionIter = curSessions.iterator();
		while(sessionIter.hasNext())
		{
			Session curSession = sessionIter.next();
			
			System.out.println("Checking sessions:");
			
			System.out.println(curSession.getId());
			System.out.println(curSession);
			
			
			System.out.println(session.getId());
			System.out.println(session);
			
			if(!curSession.equals(session))
			{
				System.out.println("Closing stale session");
				try
				{
					HashMap outputMap = new HashMap();
					outputMap.put("result", "nokay");
					outputMap.put("problem", "session colission");
					Gson gson = new GsonBuilder().create();
					String toWrite = gson.toJson(outputMap);
					session.getBasicRemote().sendText(toWrite);
					curSession.close();
				}
				catch (IOException e)
				{
					e.printStackTrace();
				}
			}
		}
		
		httpSession = (HttpSession) config.getUserProperties().get(HttpSession.class.getName());
		System.out.println("Got new data upload");
		session.setMaxTextMessageBufferSize(400826410);
	}
	
	@OnClose
	public void end()
	{
		System.out.println("Server ended");
	}
	
	@OnMessage
	public void incoming(String message, Session session)
	{
		long remainingSize = 0;
		
		System.out.println("Got message:");
		System.out.println(message.length());
		if(message.equals("end"))
		{
			try {
				session.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			return;
		}
		
		byte[] compressed = Base64.getDecoder().decode(message);
		ByteArrayInputStream input = new ByteArrayInputStream(compressed);
		GZIPInputStream ungzip = null;
		try {
			ungzip = new GZIPInputStream(input);
		} catch (IOException e2) {
			// TODO Auto-generated catch block
			e2.printStackTrace();
		}
		ByteArrayOutputStream output = new ByteArrayOutputStream();
		byte[] buffer = new byte[1024];
		int length = 0;
		try
		{
		while((length = ungzip.read(buffer)) > 0)
		{
			output.write(buffer, 0, length);
		}
		ungzip.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		byte[] uncompressed = output.toByteArray();
		String uncompressedString = new String(uncompressed);
		if(uncompressedString.length() > 200)
		{
			System.out.println(uncompressedString.substring(0, 200));
		}
		else
		{
			System.out.println(uncompressedString);
		}
		
		Gson gson = new GsonBuilder().create();
		HashMap fromJSON = gson.fromJson(uncompressedString, HashMap.class);
		//System.out.println(fromJSON.keySet());
		System.out.println(fromJSON.get("username"));
		System.out.println(fromJSON.get("token"));
		String username = (String) fromJSON.get("username");
		String token = (String) fromJSON.get("token");
		String event = (String) fromJSON.get("event");
		String admin = (String) fromJSON.get("admin");
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
			//HttpSession session = request.getSession(true);
			DatabaseConnector myConnector=(DatabaseConnector)httpSession.getAttribute("connector");
			if(myConnector==null)
			{
				myConnector=new DatabaseConnector(httpSession.getServletContext());
				httpSession.setAttribute("connector", myConnector);
			}
			TestingConnectionSource myConnectionSource = myConnector.getConnectionSource();
			
			
			Connection dbConn = myConnectionSource.getDatabaseConnectionNoTimeout();
			conn = dbConn;
			
			String query = "SELECT * FROM `UploadToken` INNER JOIN `Event` ON `UploadToken`.`event` = `Event`.`event`  WHERE `username` = ? AND `token` = ? AND `UploadToken`.`event` = ? AND `UploadToken`.`adminEmail` = ?";
			
			PreparedStatement toInsert = dbConn.prepareStatement(query);
			stmt = toInsert;
			toInsert.setString(1, username);
			toInsert.setString(2, token);
			toInsert.setString(3, event);
			toInsert.setString(4, admin);
			ResultSet myResults = toInsert.executeQuery();
			rset = myResults;
			if(!myResults.next())
			{
				System.out.println("no such token: " + username + ", " + event + ", " + admin + ", " + token);
				HashMap outputMap = new HashMap();
				outputMap.put("result", "nokay");
				outputMap.put("problem", "token not recognized");
				String toWrite = gson.toJson(outputMap);
				session.getBasicRemote().sendText(toWrite);
				return;
			}
			else
			{
				boolean isActive = myResults.getBoolean("active");
				boolean isContinuous = myResults.getBoolean("continuous");
				Timestamp endDate = myResults.getTimestamp("end");
				if(!isActive && !isContinuous)
				{
					System.out.println("inactive");
					HashMap outputMap = new HashMap();
					outputMap.put("result", "nokay");
					outputMap.put("problem", "token stale");
					String toWrite = gson.toJson(outputMap);
					session.getBasicRemote().sendText(toWrite);
					return;
				}
				else if(isContinuous)
				{
					Date curDate = new Date();
					if(curDate.after(endDate))
					{
						System.out.println("after end date");
						HashMap outputMap = new HashMap();
						outputMap.put("result", "nokay");
						outputMap.put("problem", "event stale");
						String toWrite = gson.toJson(outputMap);
						session.getBasicRemote().sendText(toWrite); //session.close();
						return;
					}
				}
				
				
				if(fromJSON.containsKey("User") && ((List)fromJSON.get("User")).size() > 0)
				{
					List<Map> userList = (List) fromJSON.get("User");
					Map<String, Object> firstUser = (Map) userList.get(0);
					int listSize = userList.size();
					
					String headings = "(";
					String values = "(";
					boolean first = true;
					Set<String> masterKeySet = firstUser.keySet();
					for(String heading : masterKeySet)
					{
						if(first)
						{
							
						}
						else
						{
							values += ", ";
							headings += ", ";
						}
						values += "?";
						headings += heading;
						first = false;
					}
					values += ")";
					headings += ")";
					
					String userInsert = "INSERT IGNORE INTO `User` " + headings + " VALUES ";
					StringBuilder totalQuery = new StringBuilder();
					totalQuery.append(userInsert);
					first = true;
					for(int x=0; x<listSize; x++)
					{
						if(first)
						{
							
						}
						else
						{
							totalQuery.append(", ");
						}
						totalQuery.append(values);
						first = false;
					}
					userInsert = totalQuery.toString();
					//System.out.println(userInsert);
					//System.out.println(userList);
					
					PreparedStatement insertStatement = dbConn.prepareStatement(userInsert);
					stmt.close();
					stmt = insertStatement;
					
					int curEnt = 1;
					boolean broken = false;
					for(Map entry : userList)
					{
						if(!entry.get("username").equals(username))
						{
							System.out.println("Invalid user: " + entry.get("username") + ", " + username);
							broken = true;
							break;
						}
						//else if(!entry.get("session").equals(session))
						//{
						//	System.out.println("Invalid session: " + entry.get("username") + ", " + username);
						//	broken = true;
						//	break;
						//}
						else if(!entry.get("event").equals(event))
						{
							System.out.println("Invalid event: " + entry.get("username") + ", " + username);
							broken = true;
							break;
						}
						else if(!entry.get("adminEmail").equals(admin))
						{
							System.out.println("Invalid adminEmail: " + entry.get("username") + ", " + username);
							broken = true;
							break;
						}
						else for(String key : masterKeySet)
						{
							//System.out.println(entry.get(key).getClass());
							insertStatement.setString(curEnt, "" + entry.get(key));
							curEnt++;
						}
					}
					
					if(!broken)
					{
						insertStatement.execute();
					}
					insertStatement.close();
				}
				
				long totalSize = 0;
				List<Map> userList = (List) fromJSON.get("Screenshot");
				totalSize += userList.size();
				userList = (List) fromJSON.get("Process");
				totalSize += userList.size();
				userList = (List) fromJSON.get("ProcessArgs");
				totalSize += userList.size();
				userList = (List) fromJSON.get("ProcessAttributes");
				totalSize += userList.size();
				userList = (List) fromJSON.get("Window");
				totalSize += userList.size();
				userList = (List) fromJSON.get("WindowDetails");
				totalSize += userList.size();
				userList = (List) fromJSON.get("MouseInput");
				totalSize += userList.size();
				userList = (List) fromJSON.get("KeyboardInput");
				totalSize += userList.size();
				userList = (List) fromJSON.get("Task");
				totalSize += userList.size();
				userList = (List) fromJSON.get("TaskEvent");
				totalSize += userList.size();
				
				String updateNumQuery = "UPDATE `UploadToken` SET `framesRemaining` = `framesRemaining` + ? WHERE `UploadToken`.`username` = ? AND `UploadToken`.`token` = ? AND `UploadToken`.`adminEmail` = ? AND `UploadToken`.`event` = ?";
				PreparedStatement toUpdate = dbConn.prepareStatement(updateNumQuery);
				toUpdate.setLong(1, totalSize);
				toUpdate.setString(2, username);
				toUpdate.setString(3, token);
				toUpdate.setString(4, admin);
				toUpdate.setString(5, event);
				toUpdate.execute();
				toUpdate.close();
				
				String updateUploadedQuery = "UPDATE `UploadToken` SET `framesUploaded` = `framesUploaded` + ?, `framesRemaining` = `framesRemaining` - ?, `lastAltered` = CURRENT_TIMESTAMP WHERE `UploadToken`.`username` = ? AND `UploadToken`.`token` = ? AND `UploadToken`.`adminEmail` = ? AND `UploadToken`.`event` = ?";
				toUpdate = dbConn.prepareStatement(updateUploadedQuery);
				
				toUpdate.setString(3, username);
				toUpdate.setString(4, token);
				toUpdate.setString(5, admin);
				toUpdate.setString(6, event);
				
				remainingSize = totalSize;
				long curLong = insertInto("Screenshot", fromJSON, dbConn, username, event, admin);
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("Process", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("ProcessArgs", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("ProcessAttributes", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("Window", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("WindowDetails", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("MouseInput", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("KeyboardInput", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("Task", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				curLong = (insertInto("TaskEvent", fromJSON, dbConn, username, event, admin));
				toUpdate.setLong(1, curLong);
				toUpdate.setLong(2, curLong);
				remainingSize -= curLong;
				toUpdate.execute();
				
				toUpdate.close();
				//double totalDoneTmp = (Double) fromJSON.get("totalDone");
				//double totalToDoTmp = (Double) fromJSON.get("totalToDo");
				//int totalDone = (int)totalDoneTmp;
				//int totalToDo = (int)totalToDoTmp;
				
				/*String updateNumQuery = "UPDATE `UploadToken` SET `framesUploaded` = ?, `framesRemaining` = ? WHERE `UploadToken`.`username` = ? AND `UploadToken`.`token` = ? AND `UploadToken`.`adminEmail` = ? AND `UploadToken`.`event` = ?";
				PreparedStatement toUpdate = dbConn.prepareStatement(updateNumQuery);
				toUpdate.setInt(1, totalDone);
				toUpdate.setInt(2, totalToDo);
				toUpdate.setString(3, username);
				toUpdate.setString(4, token);
				toUpdate.setString(5, admin);
				toUpdate.setString(6, event);
				toUpdate.execute();
				stmt = toUpdate;
				stmt.close();
				
				if(totalToDo <= 0)
				{
					String inactiveQuery = "UPDATE `UploadToken` SET `active` = '0' WHERE `UploadToken`.`username` = ? AND `UploadToken`.`token` = ?";
					PreparedStatement toInactive = dbConn.prepareStatement(inactiveQuery);
					toInactive.setString(1, username);
					toInactive.setString(2, token);
					toInactive.execute();
					stmt = toInactive;
					stmt.close();
				}
				*/
				//dbConn.commit();
				dbConn.close();
			}
			if (conn != null) conn.close();
			
		}
		catch(Exception e)
		{
			try
			{
				Class.forName("com.mysql.jdbc.Driver");
				//HttpSession session = request.getSession(true);
				DatabaseConnector myConnector=(DatabaseConnector)httpSession.getAttribute("connector");
				if(myConnector==null)
				{
					myConnector=new DatabaseConnector(httpSession.getServletContext());
					httpSession.setAttribute("connector", myConnector);
				}
				TestingConnectionSource myConnectionSource = myConnector.getConnectionSource();
				
				Connection dbConn = myConnectionSource.getDatabaseConnectionNoTimeout();
				String updateUploadedQuery = "UPDATE `UploadToken` SET `framesAborted` = `framesAborted` + ?, `framesRemaining` = `framesRemaining` - ?, `lastAltered` = CURRENT_TIMESTAMP WHERE `UploadToken`.`username` = ? AND `UploadToken`.`token` = ? AND `UploadToken`.`adminEmail` = ? AND `UploadToken`.`event` = ?";
				PreparedStatement toUpdate = dbConn.prepareStatement(updateUploadedQuery);
				
				toUpdate.setLong(1, remainingSize);
				toUpdate.setLong(2, remainingSize);
				toUpdate.setString(3, username);
				toUpdate.setString(4, token);
				toUpdate.setString(5, admin);
				toUpdate.setString(6, event);
			}
			catch(Exception e2)
			{
				e2.printStackTrace();
			}
			
			HashMap outputMap = new HashMap();
			outputMap.put("result", "nokay");
			outputMap.put("problem", "insert issue");
			String toWrite = gson.toJson(outputMap);
			try {
				session.getBasicRemote().sendText(toWrite);
			} catch (IOException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
			e.printStackTrace();
			return;
		}
		finally
		{
            try { if (rset != null) rset.close(); } catch(Exception e) { }
            try { if (stmt != null) stmt.close(); } catch(Exception e) { }
            try { if (conn != null) conn.close(); } catch(Exception e) { }
        }
		
		System.out.println(new Date());
		//System.out.println("Done: " + fromJSON.get("totalDone") + "/" + fromJSON.get("totalToDo"));
		
		
		HashMap outputMap = new HashMap();
		outputMap.put("result", "ok");
		String toWrite = gson.toJson(outputMap);
		try {
			session.getBasicRemote().sendText(toWrite);
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		
		/*
		try
		{
			session.getBasicRemote().sendText("Hello Client " + session.getId() + "!");
			//session.close();
		}
		catch (IOException e)
		{
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		*/
	}
	
	public long insertInto(String table, Map fromJSON, Connection dbConn, String username, String eventname, String adminemail) throws Exception
	{
		long toReturn = 0;
		if(fromJSON.containsKey(table) && ((List)fromJSON.get(table)).size() > 0)
		{
			List<Map> userList = (List) fromJSON.get(table);
			Map<String, Object> firstUser = (Map) userList.get(0);
			int listSize = userList.size();
			
			String headings = "(";
			String values = "(";
			boolean first = true;
			
			ConcurrentHashMap secureHeadingMap = new ConcurrentHashMap();
			String columnNamesQuery = "SELECT `COLUMN_NAME` FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE `TABLE_SCHEMA`='openDataCollectionServer' AND `TABLE_NAME`=?";
			PreparedStatement columnNamesStatement = dbConn.prepareStatement(columnNamesQuery);
			columnNamesStatement.setString(1, table);
			ResultSet colNameSet = columnNamesStatement.executeQuery();
			while(colNameSet.next())
			{
				secureHeadingMap.put(colNameSet.getString(1), "");
			}
			columnNamesStatement.close();
			
			Set<String> masterKeySet = firstUser.keySet();
			for(String heading : masterKeySet)
			{
				if(!secureHeadingMap.containsKey(heading))
				{
					System.out.println("No such column in " + table + ": " + heading);
					masterKeySet.remove(heading);
					continue;
				}
				if(first)
				{
					
				}
				else
				{
					values += ", ";
					headings += ", ";
				}
				values += "?";
				headings += heading;
				first = false;
			}
			values += ")";
			headings += ")";
			
			String userInsert = "INSERT IGNORE INTO `" + table + "` " + headings + " VALUES ";
			StringBuilder totalQuery = new StringBuilder();
			totalQuery.append(userInsert);
			first = true;
			for(int x=0; x<listSize; x++)
			{
				if(first)
				{
					
				}
				else
				{
					totalQuery.append(", ");
				}
				totalQuery.append(values);
				first = false;
			}
			userInsert = totalQuery.toString();
			//System.out.println(userInsert);
			//System.out.println(userList);
			
			PreparedStatement insertStatement = dbConn.prepareStatement(userInsert);
			
			int curEnt = 1;
			for(Map entry : userList)
			{
				if(!entry.get("username").equals(username))
				{
					System.out.println("Invalid username: " + entry.get("username") + ", " + username);
					return 0;
				}
				if(!entry.get("event").equals(eventname))
				{
					System.out.println("Invalid event: " + entry.get("event") + ", " + username);
					return 0;
				}
				if(!entry.get("adminEmail").equals(adminemail))
				{
					System.out.println("Invalid adminEmail: " + entry.get("adminEmail") + ", " + username);
					return 0;
				}
				toReturn++;
				for(String key : masterKeySet)
				{
					//System.out.println(entry.get(key).getClass());
					if(key.equals("screenshot"))
					{
						String toDecode = (String) entry.get(key);
						byte[] decoded = Base64.getDecoder().decode(toDecode);
						insertStatement.setBytes(curEnt, decoded);
					}
					else
					{
						insertStatement.setString(curEnt, "" + entry.get(key));
					}
					curEnt++;
				}
			}
			
			insertStatement.execute();
			insertStatement.close();
			//dbConn.close();
		}
		return toReturn;
	}
	
	@OnError
	public void onError(Throwable t) throws Throwable
	{
		t.printStackTrace();
	}
}
