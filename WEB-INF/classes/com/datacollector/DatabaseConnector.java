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
	//Yeah, the OCR library produced garbage results.  Looks like
	//if we want OCR we are going to need to do a lot more integration
	//work or build our own, the wrappers for open source OCR are
	//not great in Java.  Oh, these variables are deprecated BTW.
	private static OCRProcessor ocrProc = null;
	private int numOcrThreads = 2;
	
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
	
	private String keyboardQuery = "SELECT *, UNIX_TIMESTAMP(`inputTime`) AS `indexMS`, 'keyboard' AS `fromInput` FROM `openDataCollectionServer`.`KeyboardInput`\n" + 
			"WHERE `event` = ? AND `adminEmail` = ?\n" + 
			"ORDER BY `inputTime` ASC";
	
	private String keyboardQueryBounds = "SELECT `KeyboardInput`.`username`, `KeyboardInput`.`session`, UNIX_TIMESTAMP(MIN(`KeyboardInput`.`inputTime`)) AS `mintimeMS`, UNIX_TIMESTAMP(MAX(`KeyboardInput`.`inputTime`)) AS `maxtimeMS`, MIN(`KeyboardInput`.`inputTime`) AS `mintime`, MAX(`KeyboardInput`.`inputTime`) AS `maxtime`, COUNT(*) AS `totalEntries` FROM `openDataCollectionServer`.`KeyboardInput`\n" + 
			"WHERE `event` = ? AND `adminEmail` = ?\n" + 
			"GROUP BY `KeyboardInput`.`session`, `KeyboardInput`.`username`, `KeyboardInput`.`event`, `KeyboardInput`.`adminEmail`";
	
	private String mouseQuery = "SELECT *, UNIX_TIMESTAMP(`inputTime`) AS `indexMS`, 'mouse' AS `fromInput` FROM `openDataCollectionServer`.`MouseInput`\n" + 
			"WHERE `event` = ? AND `adminEmail` = ?\n" + 
			"ORDER BY `inputTime` ASC";
	
	private String mouseQueryBounds = "SELECT `MouseInput`.`username`, `MouseInput`.`session`, UNIX_TIMESTAMP(MIN(`MouseInput`.`inputTime`)) AS `mintimeMS`, UNIX_TIMESTAMP(MAX(`MouseInput`.`inputTime`)) AS `maxtimeMS`, MIN(`MouseInput`.`inputTime`) AS `mintime`, MAX(`MouseInput`.`inputTime`) AS `maxtime`, COUNT(*) AS `totalEntries` FROM `openDataCollectionServer`.`MouseInput`\n" + 
			"WHERE `event` = ? AND `adminEmail` = ?\n" + 
			"GROUP BY `MouseInput`.`session`, `MouseInput`.`username`, `MouseInput`.`event`, `MouseInput`.`adminEmail`";
	
	private String taskQuery = "SELECT *, UNIX_TIMESTAMP(`TaskEvent`.`eventTime`) AS `indexMS` FROM `openDataCollectionServer`.`Task` LEFT JOIN `TaskEvent` ON `Task`.`username` = `TaskEvent`.`username` AND `Task`.`session` = `TaskEvent`.`session` AND `Task`.`event` = `TaskEvent`.`event` AND `Task`.`adminEmail` = `TaskEvent`.`adminEmail` AND `Task`.`taskName` = `TaskEvent`.`taskName`  AND `Task`.`startTimestamp` = `TaskEvent`.`startTimestamp` WHERE `Task`.`event` = ? AND `Task`.`adminEmail` = ? ORDER BY `TaskEvent`.`eventTime` ASC";
	private String taskTagQuery = "SELECT * FROM `openDataCollectionServer`.`Task` INNER JOIN `TaskTags` ON `Task`.`username` = `TaskTags`.`username` AND `Task`.`session` = `TaskTags`.`session` AND `Task`.`event` = `TaskTags`.`event` AND `Task`.`adminEmail` = `TaskTags`.`adminEmail` AND `Task`.`taskName` = `TaskTags`.`taskName` AND `Task`.`startTimestamp` = `TaskTags`.`startTimestamp` WHERE `Task`.`event` = ? AND `Task`.`adminEmail` = ?";
	private String taskQueryBounds = "SELECT `TaskEvent`.`username`, UNIX_TIMESTAMP(MIN(`TaskEvent`.`eventTime`)) AS `mintimeMS`, UNIX_TIMESTAMP(MAX(`TaskEvent`.`eventTime`)) AS `maxtimeMS`, `TaskEvent`.`session`, MIN(`TaskEvent`.`eventTime`) AS `mintime`, MAX(`TaskEvent`.`eventTime`) AS `maxtime`, COUNT(*) AS `totalEntries` FROM `openDataCollectionServer`.`Task` LEFT JOIN `TaskEvent` ON `Task`.`username` = `TaskEvent`.`username` AND `Task`.`session` = `TaskEvent`.`session` AND `Task`.`event` = `TaskEvent`.`event` AND `Task`.`adminEmail` = `TaskEvent`.`adminEmail` AND `Task`.`taskName` = `TaskEvent`.`taskName` WHERE `Task`.`event` = ? AND `Task`.`adminEmail` = ? GROUP BY `TaskEvent`.`adminEmail`, `TaskEvent`.`event`, `TaskEvent`.`username`, `TaskEvent`.`session`";
	private String taskQueryTags = "SELECT DISTINCT(`tag`) FROM `TaskTags` WHERE `TaskTags`.`event` = ? AND `TaskTags`.`adminEmail` = ? UNION SELECT `tag` FROM `TaskTagsPublic`";
	
	
	private String imageQuery = "SELECT *, UNIX_TIMESTAMP(`taken`) AS `indexMS` FROM `openDataCollectionServer`.`Screenshot` WHERE `username` = ? AND `session` = ? AND `event` = ? AND `adminEmail` = ? ORDER BY abs(? - (UNIX_TIMESTAMP(`taken`) * 1000)) LIMIT 1";
	private String imageQueryExact = "SELECT *, UNIX_TIMESTAMP(`taken`) AS `indexMS` FROM `openDataCollectionServer`.`Screenshot` WHERE `username` = ? AND `session` = ? AND `event` = ? AND `adminEmail` = ? AND (UNIX_TIMESTAMP(`taken`) * 1000) = ?";
	//" AND (UNIX_TIMESTAMP(`taken`) * 1000) > ?" - after time
	//" AND (UNIX_TIMESTAMP(`taken`) * 1000) < ?" - before time
	private String allImageQuery = "SELECT *, UNIX_TIMESTAMP(`taken`) AS `indexMS` FROM `openDataCollectionServer`.`Screenshot` WHERE `event` = ? AND `adminEmail` = ? ORDER BY `taken` ASC";
	
	private String allImageQueryBounds = "SELECT `Screenshot`.`username`, `Screenshot`.`session`, UNIX_TIMESTAMP(MIN(`Screenshot`.`taken`)) AS `mintimeMS`, UNIX_TIMESTAMP(MAX(`Screenshot`.`taken`)) AS `maxtimeMS`, MIN(`Screenshot`.`taken`) AS `mintime`, MAX(`Screenshot`.`taken`) AS `maxtime`, COUNT(*) AS `totalEntries` FROM `openDataCollectionServer`.`Screenshot` WHERE `event` = ? AND `adminEmail` = ?\n" + 
			"GROUP BY `Screenshot`.`session`, `Screenshot`.`username`, `Screenshot`.`event`, `Screenshot`.`adminEmail`";
	
	
	private String filterQuery = "SELECT * FROM `openDataCollectionServer`.`VisualizationFilters` WHERE `VisualizationFilters`.`event` = ? AND `VisualizationFilters`.`adminEmail` = ? ORDER BY `VisualizationFilters`.`saveName`, `VisualizationFilters`.`filterNum` ASC";
	
	//private String allProcessQueryOld = "SELECT * FROM `Process` LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start` WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ? ORDER BY `ProcessAttributes`.`insertTimestamp` ASC";
	
	private String allProcessQuery = "SELECT *, UNIX_TIMESTAMP(`ProcessAttributes`.`timestamp`) AS `indexMS` FROM `Process` LEFT JOIN \n" + 
			"(\n" + 
			"SELECT `event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, GROUP_CONCAT(`arg` ORDER BY `numbered` ASC SEPARATOR ' ') AS `arguments` FROM `ProcessArgs` GROUP BY `ProcessArgs`.`event`, `ProcessArgs`.`adminEmail`, `ProcessArgs`.`username`, `ProcessArgs`.`session`, `ProcessArgs`.`user`, `ProcessArgs`.`pid`, `ProcessArgs`.`start`\n" + 
			") a\n" + 
			"USING (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`)\n" + 
			"LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start`\n" + 
			"WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ? ORDER BY `ProcessAttributes`.`timestamp` ASC";
	
	private String summaryProcessQuery = "SELECT `Process`.*, a.*, MAX(`ProcessAttributes`.`cpu`) AS `maxcpu`, MAX(`ProcessAttributes`.`mem`) AS `maxmem`, UNIX_TIMESTAMP(MIN(`ProcessAttributes`.`timestamp`)) AS `mintimeMS`, UNIX_TIMESTAMP(MAX(`ProcessAttributes`.`timestamp`)) AS `maxtimeMS`, MAX(`ProcessAttributes`.`timestamp`) AS `maxtime`, MIN(`ProcessAttributes`.`timestamp`) AS `mintime` FROM `Process` LEFT JOIN \n" + 
			"(\n" + 
			"SELECT `event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, GROUP_CONCAT(`arg` ORDER BY `numbered` ASC SEPARATOR ' ') AS `arguments` FROM `ProcessArgs` GROUP BY `ProcessArgs`.`event`, `ProcessArgs`.`adminEmail`, `ProcessArgs`.`username`, `ProcessArgs`.`session`, `ProcessArgs`.`user`, `ProcessArgs`.`pid`, `ProcessArgs`.`start`\n" + 
			") a\n" + 
			"USING (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`)\n" + 
			"LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start`\n" + 
			"WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ?\n" + 
			"GROUP BY `Process`.`event`, `Process`.`adminEmail`, `Process`.`username`, `Process`.`session`, `Process`.`user`, `Process`.`pid`, `Process`.`start`\n" + 
			"ORDER BY `mintime` ASC";
	
	private String summaryProcessQueryLimited = "SELECT `Process`.*, a.* FROM `Process` LEFT JOIN \n" + 
			"(\n" + 
			"SELECT `event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, GROUP_CONCAT(`arg` ORDER BY `numbered` ASC SEPARATOR ' ') AS `arguments` FROM `ProcessArgs` GROUP BY `ProcessArgs`.`event`, `ProcessArgs`.`adminEmail`, `ProcessArgs`.`username`, `ProcessArgs`.`session`, `ProcessArgs`.`user`, `ProcessArgs`.`pid`, `ProcessArgs`.`start`\n" + 
			") a\n" + 
			"USING (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`)\n" + 
			"WHERE `Process`.`event` = ? AND `Process`.`adminEmail` = ?\n";
	
	private String allProcessQueryFix = "SELECT * FROM `Process` LEFT JOIN \n" + 
			"(\n" + 
			"SELECT `event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, GROUP_CONCAT(`arg` ORDER BY `numbered` ASC SEPARATOR ' ') AS `arguments` FROM `ProcessArgs` GROUP BY `ProcessArgs`.`event`, `ProcessArgs`.`adminEmail`, `ProcessArgs`.`username`, `ProcessArgs`.`session`, `ProcessArgs`.`user`, `ProcessArgs`.`pid`, `ProcessArgs`.`start`\n" + 
			") a\n" + 
			"USING (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`)\n" + 
			"LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start`\n" + 
			"WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ? ORDER BY `ProcessAttributes`.`timestamp` ASC";
	
	//private String allProcessQuery = "SELECT * FROM\n" + 
	//		"(\n" + 
	//		"\n" + 
	//		"SELECT `Process`.`command`, `Process`.`parentpid`, `Process`.`parentuser`, `Process`.`parentstart`, a.`arguments`, `ProcessAttributes`.*, @prev_username AS 'prev_username', @prev_username := `Process`.`username`, @prev_session AS 'prev_session', @prev_session := `Process`.`session`, @prev_user AS 'prev_user', @prev_user := `Process`.`user`, @prev_pid AS 'prev_pid', @prev_pid := `Process`.`pid`, @prev_start AS 'prev_start', @prev_start := `Process`.`start`, @prev_cpu AS 'prev_cpu', @prev_cpu := `ProcessAttributes`.`cpu`, @prev_mem AS 'prev_mem', @prev_mem := `ProcessAttributes`.`mem` FROM `Process` LEFT JOIN \n" + 
	//		"\n" + 
	//		"(\n" + 
	//		"	SELECT `event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, GROUP_CONCAT(`arg` ORDER BY `numbered` ASC SEPARATOR ' ') AS `arguments` FROM `ProcessArgs` GROUP BY `ProcessArgs`.`event`, `ProcessArgs`.`adminEmail`, `ProcessArgs`.`username`, `ProcessArgs`.`session`, `ProcessArgs`.`user`, `ProcessArgs`.`pid`, `ProcessArgs`.`start`\n" + 
	//		") a\n" + 
	//		"\n" + 
	//		"USING (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`)\n" + 
	//		"\n" + 
	//		"LEFT JOIN `ProcessAttributes` ON `Process`.`event` = `ProcessAttributes`.`event` AND `Process`.`adminEmail` = `ProcessAttributes`.`adminEmail` AND `Process`.`username` = `ProcessAttributes`.`username` AND `Process`.`session` = `ProcessAttributes`.`session` AND `Process`.`user` = `ProcessAttributes`.`user` AND `Process`.`pid` = `ProcessAttributes`.`pid` AND `Process`.`start` = `ProcessAttributes`.`start`\n" + 
	//		"\n" + 
	//		"WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ?\n" + 
	//		"\n" + 
	//		"ORDER BY `ProcessAttributes`.`event`, `ProcessAttributes`.`adminEmail`, `ProcessAttributes`.`username`, `ProcessAttributes`.`session`, `ProcessAttributes`.`user`, `ProcessAttributes`.`pid`, `ProcessAttributes`.`start`, `ProcessAttributes`.`timestamp` ASC\n" + 
	//		"\n" + 
	//		") qu\n" + 
	//		"\n" + 
	//		"WHERE `prev_username` != `qu`.`username` OR `prev_session` != `qu`.`session` OR `prev_user` != `qu`.`user` OR `prev_pid` != `qu`.`pid` OR `prev_start` != `qu`.`start` OR `prev_cpu` != `qu`.`cpu` OR `prev_mem` != `qu`.`mem`\n" + 
	//		"\n" + 
	//		"ORDER BY `qu`.`timestamp` ASC";
	
	private String allProcessQueryBounds = "SELECT `ProcessAttributes`.`username`, `ProcessAttributes`.`session`, UNIX_TIMESTAMP(MIN(`ProcessAttributes`.`timestamp`)) AS `mintimeMS`, UNIX_TIMESTAMP(MAX(`ProcessAttributes`.`timestamp`)) AS `maxtimeMS`, MIN(`ProcessAttributes`.`timestamp`) AS `mintime`, MAX(`ProcessAttributes`.`timestamp`) AS `maxtime`, COUNT(*) AS `totalEntries` FROM `ProcessAttributes` WHERE `ProcessAttributes`.`event` = ? AND `ProcessAttributes`.`adminEmail` = ? GROUP BY `ProcessAttributes`.`session`, `ProcessAttributes`.`username`, `ProcessAttributes`.`event`, `ProcessAttributes`.`adminEmail`";
	
	private String allWindowQuery = "SELECT *, UNIX_TIMESTAMP(`WindowDetails`.`timeChanged`) AS `indexMS` FROM `Window` LEFT JOIN `WindowDetails`ON `Window`.`event` = `WindowDetails`.`event` AND `Window`.`adminEmail` = `WindowDetails`.`adminEmail` AND `Window`.`username` = `WindowDetails`.`username` AND `Window`.`session` = `WindowDetails`.`session` AND `Window`.`user` = `WindowDetails`.`user` AND `Window`.`pid` = `WindowDetails`.`pid` AND `Window`.`start` = `WindowDetails`.`start` AND `Window`.`xid` = `WindowDetails`.`xid` WHERE `WindowDetails`.`event` = ? AND `WindowDetails`.`adminEmail` = ? ORDER BY `WindowDetails`.`timeChanged` ASC";
	private String allWindowQueryBounds = "SELECT `WindowDetails`.`username`, `WindowDetails`.`session`, UNIX_TIMESTAMP(MIN(`WindowDetails`.`timeChanged`)) AS `mintimeMS`, UNIX_TIMESTAMP(MAX(`WindowDetails`.`timeChanged`)) AS `maxtimeMS`, MIN(`WindowDetails`.`timeChanged`) AS `mintime`, MAX(`WindowDetails`.`timeChanged`) AS `maxtime`, COUNT(*) AS `totalEntries` FROM `Window` LEFT JOIN `WindowDetails`ON `Window`.`event` = `WindowDetails`.`event` AND `Window`.`adminEmail` = `WindowDetails`.`adminEmail` AND `Window`.`username` = `WindowDetails`.`username` AND `Window`.`session` = `WindowDetails`.`session` AND `Window`.`user` = `WindowDetails`.`user` AND `Window`.`pid` = `WindowDetails`.`pid` AND `Window`.`start` = `WindowDetails`.`start` AND `Window`.`xid` = `WindowDetails`.`xid` WHERE `WindowDetails`.`event` = ? AND `WindowDetails`.`adminEmail` = ? GROUP BY `WindowDetails`.`adminEmail`, `WindowDetails`.`event`, `WindowDetails`.`username`, `WindowDetails`.`session`";
	
	private String insertFilter = "INSERT INTO `VisualizationFilters`(`event`, `adminEmail`, `level`, `field`, `value`, `server`, `saveName`, `filterNum`) VALUES ";
	private String insertFilterValues = "(?,?,?,?,?,?,?,?)";
	
	private String deleteFilter = "DELETE FROM `VisualizationFilters` WHERE `event` = ? AND `adminEmail` = ? AND `saveName` = ?";
	
	private String setNote = "UPDATE `User` SET `notes`= ? WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ?";
	
	private String insertTask = "INSERT INTO `Task`(`event`, `adminEmail`, `username`, `session`, `taskName`, `completion`, `startTimestamp`, `goal`, `note`) VALUES (?,?,?,?,?,?, FROM_UNIXTIME(? / 1000), ?, ?)";
	private String insertTaskEvent = "INSERT INTO `TaskEvent`(`event`, `adminEmail`, `username`, `session`, `taskName`, `eventTime`, `eventDescription`, `startTimestamp`, `source`) VALUES (?,?,?,?,?,FROM_UNIXTIME(? / 1000),?,FROM_UNIXTIME(? / 1000),?)";
	private String insertTaskTag = "INSERT INTO `TaskTags`(`event`, `adminEmail`, `username`, `session`, `taskName`, `startTimestamp`, `tag`) VALUES (?,?,?,?,?, FROM_UNIXTIME(? / 1000), ?)";
	
	private String deleteTaskEvents = "DELETE `Task` FROM `Task` "
			+ "INNER JOIN `TaskEvent` ON `Task`.`event` = `TaskEvent`.`event` AND `Task`.`adminEmail` = `TaskEvent`.`adminEmail` AND `Task`.`username` = `TaskEvent`.`username` AND `Task`.`session` = `TaskEvent`.`session` AND `Task`.`taskName` = `TaskEvent`.`taskName` AND `Task`.`startTimestamp` = `TaskEvent`.`startTimestamp` "
			+ "WHERE `TaskEvent`.`event` = ? AND `TaskEvent`.`adminEmail` = ? AND `TaskEvent`.`username` = ? AND `TaskEvent`.`session` = ? AND `TaskEvent`.`taskName` = ? AND `TaskEvent`.`source` = ? AND `TaskEvent`.`startTimestamp` = FROM_UNIXTIME(? / 1000)";
	
	private String selectTaskEvents = "SELECT *, UNIX_TIMESTAMP(`eventTime`) AS `indexMS` FROM `TaskEvent` WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `startTimestamp` = FROM_UNIXTIME(? / 1000)";
	
	private String deleteTask = "DELETE FROM `Task` WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `startTimestamp` = FROM_UNIXTIME(? / 1000)";
	
	private String sessionDetailsQuery = "SELECT * FROM `openDataCollectionServer`.`User` WHERE `event` = ? AND `adminEmail` = ? ORDER BY `insertTimestamp` ASC";
	
	private String limiter = " LIMIT ?, ?";
	
	private String checkPerms = "SELECT * FROM `EventPassword` WHERE `event` = ? AND `adminEmail` = ? AND `password` = ?";
	
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
	
	public ConcurrentHashMap getCachedBounds(String adminEmail, String eventName)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		String cachedQuery = "SELECT b.*, UNIX_TIMESTAMP(b.`startDate`) AS `startDateMS`, UNIX_TIMESTAMP(b.`endDate`) AS `endDateMS` FROM `BoundsHistory` b RIGHT JOIN\n" + 
				"(\n" + 
				"    SELECT MAX(a.`snapTime`) AS `snapTime`, a.`adminEmail`, a.`event`, a.`username`, a.`session`, a.`dataType` FROM `BoundsHistory` a WHERE a.`adminEmail` = ? AND a.`event` = ? AND a.`isCurrent` = 1 GROUP BY a.`adminEmail`, a.`event`, a.`username`, a.`session`, a.`dataType`\n" + 
				") c\n" + 
				"ON c.`event` = b.`event` AND c.`adminEmail` = b.`adminEmail` AND c.`username` = b.`username` AND c.`session` = b.`session` AND c.`snapTime` = b.`snapTime`";
		
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		PreparedStatement myStmt = null;
		ResultSet myResults = null;
		
		try
		{
			myStmt = myConnector.prepareStatement(cachedQuery);
			myStmt.setString(1, adminEmail);
			myStmt.setString(2, eventName);
			System.out.println(myStmt);
			myResults = myStmt.executeQuery();
			
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				ConcurrentHashMap nextNextRow = new ConcurrentHashMap();
				
				String userName = myResults.getString("username");
				String sessionName = myResults.getString("session");
				String dataType = myResults.getString("dataType");
				
				nextRow.put("Index", myResults.getTimestamp("startDate", cal));
				nextRow.put("Index MS", myResults.getDouble("startDateMS") * 1000);
				nextRow.put("SnapDate", myResults.getTimestamp("snapTime", cal));
				nextRow.put("TotalEntries", myResults.getString("count"));
				nextNextRow.put("Index", myResults.getTimestamp("endDate", cal));
				nextNextRow.put("Index MS", myResults.getDouble("endDateMS") * 1000);
				
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
				
				if(!sessionMap.containsKey(dataType + "bounds"))
				{
					sessionMap.put(dataType + "bounds", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get(dataType + "bounds");
				
				eventList.add(nextRow);
				eventList.add(nextNextRow);
			}
			
			
			myResults.close();
			
			myStmt.close();
			
			myConnector.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			try
			{
				if(myResults != null)
				{
					myResults.close();
				}
				if(myStmt != null)
				{
					myStmt.close();
				}
				if(myConnector != null)
				{
					myConnector.close();
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}
		
		cachedQuery = "SELECT b.* FROM `ActiveHistory` b RIGHT JOIN\n" + 
				"(\n" + 
				"    SELECT MAX(a.`snapTime`) AS `snapTime`, a.`adminEmail`, a.`event`, a.`username`, a.`session` FROM `ActiveHistory` a WHERE a.`adminEmail` = ? AND a.`event` = ? AND a.`isCurrent` = 1 GROUP BY a.`adminEmail`, a.`event`, a.`username`, a.`session`\n" + 
				") c\n" + 
				"ON c.`event` = b.`event` AND c.`adminEmail` = b.`adminEmail` AND c.`username` = b.`username` AND c.`session` = b.`session` AND c.`snapTime` = b.`snapTime`";
		
		
		myConnector = mySource.getDatabaseConnectionNoTimeout();
		myStmt = null;
		myResults = null;
		
		try
		{
			myStmt = myConnector.prepareStatement(cachedQuery);
			myStmt.setString(1, adminEmail);
			myStmt.setString(2, eventName);
			myResults = myStmt.executeQuery();
			
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				String userName = myResults.getString("username");
				String sessionName = myResults.getString("session");
				String dataType = "activetime";
				
				nextRow.put("SnapDate", myResults.getTimestamp("snapTime", cal));
				nextRow.put("ActiveTime", myResults.getString("minutesActive"));
				nextRow.put("Resolution", myResults.getString("resolution"));
				
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
				
				if(!sessionMap.containsKey(dataType))
				{
					sessionMap.put(dataType, new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get(dataType);
				
				eventList.add(nextRow);
				
			}
			
			
			myResults.close();
			
			myStmt.close();
			
			myConnector.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			try
			{
				if(myResults != null)
				{
					myResults.close();
				}
				if(myStmt != null)
				{
					myStmt.close();
				}
				if(myConnector != null)
				{
					myConnector.close();
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}
		
		
		return myReturn;
	}
	
	public void cacheBounds(String adminEmail, String eventName, String username, String session, String count, double startDate, double endDate, String dataType, DatabaseUpdateConsumer myConsumer)
	{
		String deactivateOld = "UPDATE `BoundsHistory` SET `isCurrent`=0 WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `dataType` = ?";
		String insertQuery = "INSERT INTO `BoundsHistory`(`event`, `adminEmail`, `username`, `session`, `count`, `startDate`, `endDate`, `dataType`) VALUES (?, ?, ?, ?, ?, FROM_UNIXTIME(? / 1000), FROM_UNIXTIME(? / 1000), ?)";
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		PreparedStatement myStmt = null;
		
		try
		{
			myStmt = myConnector.prepareStatement(deactivateOld);
			myStmt.setString(1, eventName);
			myStmt.setString(2, adminEmail);
			myStmt.setString(3, username);
			myStmt.setString(4, session);
			myStmt.setString(5, dataType);
			myStmt.execute();
			
			myStmt.close();
			
			myStmt = myConnector.prepareStatement(insertQuery);
			myStmt.setString(1, eventName);
			myStmt.setString(2, adminEmail);
			myStmt.setString(3, username);
			myStmt.setString(4, session);
			myStmt.setString(5, count);
			//myStmt.setTimestamp(6, startDate, cal);
			//myStmt.setTimestamp(7, endDate, cal);
			myStmt.setDouble(6, startDate);
			myStmt.setDouble(7, endDate);
			myStmt.setString(8, dataType);
			myStmt.execute();
			
			myStmt.close();
			
			myConnector.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			try
			{
				if(myStmt != null)
				{
					myStmt.close();
				}
				if(myConnector != null)
				{
					myConnector.close();
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}
		
		myConsumer.consumeUpdate(dataType + " : " + username + " : " + session + " : " + count + " : " + startDate + " : " + endDate);
	}
	
	public void cacheActive(String adminEmail, String eventName, ConcurrentHashMap eventMap, DatabaseUpdateConsumer myConsumer, int resolution)
	{
		Iterator myIterator = eventMap.entrySet().iterator();
		while(myIterator.hasNext())
		{
			Entry curUser = (Entry) myIterator.next();
			String userName = (String) curUser.getKey();
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) curUser.getValue();
			Iterator sessionIterator = sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Entry curSession = (Entry) sessionIterator.next();
				String sessionName = (String) curSession.getKey();
				ConcurrentHashMap boundsMap = (ConcurrentHashMap) curSession.getValue();
				Iterator boundsIter = boundsMap.entrySet().iterator();
				while(boundsIter.hasNext())
				{
					Entry boundsEntry = (Entry) boundsIter.next();
					String boundsType = (String) boundsEntry.getKey();
					ArrayList bounds = (ArrayList) boundsEntry.getValue();
					ConcurrentHashMap minMap = (ConcurrentHashMap) bounds.get(0);
					int total = (int) minMap.get("minutesActive");
					cacheActive(adminEmail, eventName, userName, sessionName, total, myConsumer, resolution);
				}
			}
		}
	}
	
	public void cacheActive(String adminEmail, String eventName, String username, String session, int minutes, DatabaseUpdateConsumer myConsumer, int resolution)
	{
		System.out.println("Caching active for " + adminEmail + " : " + eventName + " : " + username + " : " + minutes);
		String deactivateOld = "UPDATE `ActiveHistory` SET `isCurrent`=0 WHERE `event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ?";
		String insertQuery = "INSERT INTO `ActiveHistory`(`event`, `adminEmail`, `username`, `session`, `minutesActive`, `resolution`) VALUES (?, ?, ?, ?, ?, ?)";
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		PreparedStatement myStmt = null;
		
		try
		{
			myStmt = myConnector.prepareStatement(deactivateOld);
			myStmt.setString(1, eventName);
			myStmt.setString(2, adminEmail);
			myStmt.setString(3, username);
			myStmt.setString(4, session);
			myStmt.execute();
			
			myStmt.close();
			
			myStmt = myConnector.prepareStatement(insertQuery);
			myStmt.setString(1, eventName);
			myStmt.setString(2, adminEmail);
			myStmt.setString(3, username);
			myStmt.setString(4, session);
			myStmt.setInt(5, minutes);
			myStmt.setInt(6, resolution);
			myStmt.execute();
			
			myStmt.close();
			
			myConnector.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			try
			{
				if(myStmt != null)
				{
					myStmt.close();
				}
				if(myConnector != null)
				{
					myConnector.close();
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}
		
		myConsumer.consumeUpdate("minutesactive" + " : " + username + " : " + session + " : " + minutes);
	}
	
	public void cacheBounds(String adminEmail, String eventName, ConcurrentHashMap eventMap, DatabaseUpdateConsumer myConsumer)
	{
		Iterator myIterator = eventMap.entrySet().iterator();
		while(myIterator.hasNext())
		{
			Entry curUser = (Entry) myIterator.next();
			String userName = (String) curUser.getKey();
			ConcurrentHashMap sessionMap = (ConcurrentHashMap) curUser.getValue();
			Iterator sessionIterator = sessionMap.entrySet().iterator();
			while(sessionIterator.hasNext())
			{
				Entry curSession = (Entry) sessionIterator.next();
				String sessionName = (String) curSession.getKey();
				ConcurrentHashMap boundsMap = (ConcurrentHashMap) curSession.getValue();
				Iterator boundsIter = boundsMap.entrySet().iterator();
				while(boundsIter.hasNext())
				{
					Entry boundsEntry = (Entry) boundsIter.next();
					String boundsType = (String) boundsEntry.getKey();
					boundsType = boundsType.replaceAll("bounds", "");
					ArrayList bounds = (ArrayList) boundsEntry.getValue();
					ConcurrentHashMap minMap = (ConcurrentHashMap) bounds.get(0);
					ConcurrentHashMap maxMap = (ConcurrentHashMap) bounds.get(1);
					String total = (String) minMap.get("TotalEntries");
					//Timestamp min = (Timestamp) minMap.get("Index");
					//Timestamp max = (Timestamp) maxMap.get("Index");
					double min = (double) minMap.get("Index MS");
					double max = (double) maxMap.get("Index MS");
					cacheBounds(adminEmail, eventName, userName, sessionName, total, min, max, boundsType, myConsumer);
				}
			}
		}
	}
	
	public ConcurrentHashMap getActiveMinutes(String adminEmail, String eventName, int minutesChunk)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		String query = "SELECT COUNT(DISTINCT(FROM_UNIXTIME(`theTimestamp` * (60 * ?)))) AS `timecount`, `adminEmail`, `event`, `username`, `session` FROM\n" + 
				"(\n" + 
				"SELECT COUNT(*), ROUND(ABS(UNIX_TIMESTAMP(`inputTime`)) / (60 * ?)) AS `theTimestamp`, `adminEmail`, `event`, `username`, `session` FROM `KeyboardInput`\n" + 
				"WHERE `adminEmail` = ? AND `event` = ?\n" + 
				"GROUP BY ROUND(ABS(UNIX_TIMESTAMP(`inputTime`)) / (60 * ?)), `adminEmail`, `event`, `username`, `session`\n" + 
				"UNION\n" + 
				"SELECT COUNT(*), ROUND(ABS(UNIX_TIMESTAMP(`inputTime`)) / (60 * ?)) AS `theTimetamp`, `adminEmail`, `event`, `username`, `session` FROM `MouseInput`\n" + 
				"WHERE `adminEmail` = ? AND `event` = ?\n" + 
				"GROUP BY ROUND(ABS(UNIX_TIMESTAMP(`inputTime`)) / (60 * ?)), `adminEmail`, `event`, `username`, `session`\n" + 
				")\n" + 
				"a GROUP BY `adminEmail`, `event`, `username`, `session`";
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		PreparedStatement myStmt = null;
		ResultSet myResults = null;
		
		try
		{
			myStmt = myConnector.prepareStatement(query);
			myStmt.setInt(1, minutesChunk);
			myStmt.setInt(2, minutesChunk);
			myStmt.setString(3, adminEmail);
			myStmt.setString(4, eventName);
			myStmt.setInt(5, minutesChunk);
			myStmt.setInt(6, minutesChunk);
			myStmt.setString(7, adminEmail);
			myStmt.setString(8, eventName);
			myStmt.setInt(9, minutesChunk);
			
			//System.out.println(myStmt);
			
			myResults = myStmt.executeQuery();
			
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				String userName = myResults.getString("username");
				String sessionName = myResults.getString("session");
				String dataType = "activetime";
				
				int totalCount = myResults.getInt("timecount");
				
				nextRow.put("minutesActive", totalCount * minutesChunk);
				
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
				
				if(!sessionMap.containsKey(dataType))
				{
					sessionMap.put(dataType, new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get(dataType);
				
				eventList.add(nextRow);
				
			}
			
			
			myResults.close();
			
			myStmt.close();
			
			myConnector.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			try
			{
				if(myResults != null)
				{
					myResults.close();
				}
				if(myStmt != null)
				{
					myStmt.close();
				}
				if(myConnector != null)
				{
					myConnector.close();
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}
		
		//System.out.println(myReturn);
		
		return myReturn;
	}
	
	public void cacheBounds(String eventName, String adminEmail, DatabaseUpdateConsumer myConsumer)
	{
		ConcurrentHashMap eventMap = new ConcurrentHashMap();
		
		eventMap = getProcessDataHierarchyBounds(eventName, adminEmail);
		cacheBounds(adminEmail, eventName, eventMap, myConsumer);
		myConsumer.consumeUpdate("Done caching processes");
		
		eventMap = getTasksHierarchyBounds(eventName, adminEmail);
		cacheBounds(adminEmail, eventName, eventMap, myConsumer);
		myConsumer.consumeUpdate("Done caching tasks");
		
		eventMap = getWindowDataHierarchyBounds(eventName, adminEmail);
		cacheBounds(adminEmail, eventName, eventMap, myConsumer);
		myConsumer.consumeUpdate("Done caching windows");
		
		eventMap = getKeystrokesHierarchyBounds(eventName, adminEmail);
		cacheBounds(adminEmail, eventName, eventMap, myConsumer);
		myConsumer.consumeUpdate("Done caching keystrokes");
		
		eventMap = getMouseHierarchyBounds(eventName, adminEmail);
		cacheBounds(adminEmail, eventName, eventMap, myConsumer);
		myConsumer.consumeUpdate("Done caching mouse");
		
		eventMap = getScreenshotsHierarchyBounds(eventName, adminEmail);
		cacheBounds(adminEmail, eventName, eventMap, myConsumer);
		myConsumer.consumeUpdate("Done caching screenshots");
		
		int timeResolution = 5;
		eventMap = getActiveMinutes(adminEmail, eventName, timeResolution);
		cacheActive(adminEmail, eventName, eventMap, myConsumer, timeResolution);
		myConsumer.consumeUpdate("Done caching active minutes");
		
		myConsumer.consumeUpdate("Finished!");
		
		myConsumer.consumeUpdate(getCachedBounds(adminEmail, eventName));
		
		myConsumer.endConsumption();
	}
	
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
								String entryMS = fieldEntry.getKey() + " MS";
								//System.out.println("Date: " + fieldEntry.getKey());
								if(curData.containsKey(entryMS) && !(curData.get(entryMS) instanceof Long))
								{
									if(curData.get(entryMS) instanceof Double)
									{
										curData.put(entryMS, (long)((double)curData.get(entryMS)));
									}
									else
									{
										curData.put(entryMS, Long.parseLong(curData.get(entryMS).toString()));
									}
								}
								else
								{
									System.out.println("Needs native time long: "  + dataEntry.getKey());
									curData.put(entryMS, ((Date) fieldEntry.getValue()).getTime());
								}
								
								//System.out.println("Converted");
								//System.out.println(curData.get(entryMS).getClass());
								long thisTime = (long) curData.get(entryMS);
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
	
	public ConcurrentHashMap getPermissionDetails(String eventName, String eventAdmin, String password)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
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
				myReturn.put("adminemail", myResults.getString("adminEmail"));
				String tagger = myResults.getString("tagger");
				if(tagger != null)
				{
					myReturn.put("tagger", tagger);
				}
				myReturn.put("anon", myResults.getInt("anon") > 0);
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
	
	
	
	public ConcurrentHashMap addTask(String event, String user, String session, String admin, long start, long end, String taskName, String[] tags, String tagger, String goal, String note)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			//String curStatement = insertFilter;
			String curStatement = insertTask;
			PreparedStatement myStatement = myConnector.prepareStatement(curStatement);
			//`event`, `adminEmail`, `username`, `session`, `taskName`, `completion`, `startTimestamp`
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, user);
			myStatement.setString(4, session);
			myStatement.setString(5, taskName);
			myStatement.setString(6, "1");
			myStatement.setLong(7, start);
			myStatement.setString(8, goal);
			myStatement.setString(9, note);
			
			//System.out.println(myStatement);
			
			myStatement.execute();
			myStatement.close();
			
			for(int x=0; tags != null && x < tags.length; x++)
			{
				if(tags[x].isEmpty())
				{
					continue;
				}
				curStatement = insertTaskTag;
				myStatement = myConnector.prepareStatement(curStatement);
				//`event`, `adminEmail`, `username`, `session`, `taskName`, `completion`, `startTimestamp`
				myStatement.setString(1, event);
				myStatement.setString(2, admin);
				myStatement.setString(3, user);
				myStatement.setString(4, session);
				myStatement.setString(5, taskName);
				myStatement.setLong(6, start);
				myStatement.setString(7, tags[x]);
				
				//System.out.println(myStatement);
				
				myStatement.execute();
				myStatement.close();
			}
			
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
			myStatement.setString(9, tagger);
			
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
			myStatement.setString(9, tagger);
			
			myStatement.execute();
			
			
			stmt = myStatement;
			
			stmt.close();
			conn.close();
			myReturn.put("result", "okay");
			
			//ArrayList thisUser = new ArrayList();
			//thisUser.add(user);
			//ArrayList thisSession = new ArrayList();
			//thisUser.add(session);
			
			//myReturn.put("newEvents", normalizeAllTime(getTasksHierarchy(event, admin, thisUser, thisSession, "", "")));
			
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
	
	public ConcurrentHashMap setNote(String event, String user, String session, String admin, String note, String tagger)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		try
		{
			//String curStatement = insertFilter;
			String curStatement = setNote;
			PreparedStatement myStatement = myConnector.prepareStatement(curStatement);
			//`event`, `adminEmail`, `username`, `session`, `taskName`, `completion`, `startTimestamp`
			myStatement.setString(1, note);
			myStatement.setString(2, event);
			myStatement.setString(3, admin);
			myStatement.setString(4, user);
			myStatement.setString(5, session);
			
			//System.out.println(myStatement);
			
			myStatement.execute();
			myStatement.close();
			
			stmt = myStatement;
			
			stmt.close();
			conn.close();
			myReturn.put("result", "okay");
			
			//ArrayList thisUser = new ArrayList();
			//thisUser.add(user);
			//ArrayList thisSession = new ArrayList();
			//thisUser.add(session);
			
			//myReturn.put("newEvents", normalizeAllTime(getTasksHierarchy(event, admin, thisUser, thisSession, "", "")));
			
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
			//System.out.println(curStatement);
			//`event` = ? AND `adminEmail` = ? AND `username` = ? AND `session` = ? AND `taskName` = ? AND `source` = ?
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			myStatement.setString(3, user);
			myStatement.setString(4, session);
			myStatement.setString(5, taskName);
			myStatement.setString(6, source);
			myStatement.setLong(7, startTime);
			
			//System.out.println(myStatement);
			
			myStatement.execute();
			myStatement.close();
			/*
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
			*/
			
			stmt = myStatement;
			
			stmt.close();
			conn.close();
			myReturn.put("result", "okay");
			
			//ArrayList thisUser = new ArrayList();
			//thisUser.add(user);
			
			//ArrayList thisSession = new ArrayList();
			//thisUser.add(session);
			
			//myReturn.put("newEvents", normalizeAllTime(getTasksHierarchy(event, admin, thisUser, thisSession, "", "")));
			
			
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
				nextRow.put("Note", myResults.getString("note"));
				nextRow.put("Source", myResults.getString("source"));
				nextRow.put("TaskName", myResults.getString("taskName"));
				nextRow.put("Completion", myResults.getString("completion"));
				nextRow.put("Goal", myResults.getString("goal"));
				nextRow.put("EventTime", myResults.getTimestamp("eventTime", cal));
				nextRow.put("StartTime", myResults.getTimestamp("startTimestamp", cal));
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				nextRow.put("Index", myResults.getTimestamp("eventTime", cal));
				nextRow.put("Index MS", myResults.getDouble("indexMS") * 1000);
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
		
		if(myReturn != null)
		{
			System.out.println("Trying to get task tags");
			ConcurrentHashMap eventTagMap = getTaskTagsHierarchyMap(event, admin, usersToSelect, sessionsToSelect, start, end);
			//if(true)
			//{
			//	System.out.println(eventTagMap);
			//	return myReturn;
			//}
			
			Iterator userIterator = eventTagMap.entrySet().iterator();
			while(userIterator.hasNext())
			{
				Map.Entry userEntry = (Entry) userIterator.next();
				String userName = (String) userEntry.getKey();
				System.out.println(userName);
				ConcurrentHashMap sessionMap = (ConcurrentHashMap) userEntry.getValue();
				Iterator sessionIterator = sessionMap.entrySet().iterator();
				while(sessionIterator.hasNext())
				{
					Map.Entry sessionEntry = (Entry) sessionIterator.next();
					String sessionName = (String) sessionEntry.getKey();
					//System.out.println(sessionName);
					ConcurrentHashMap eventTags = (ConcurrentHashMap) sessionEntry.getValue();
					
					//System.out.println(myReturn);
					ArrayList eventList = (ArrayList) ((ConcurrentHashMap)((ConcurrentHashMap) myReturn.get(userName)).get(sessionName)).get("events");
					
					//System.out.println(eventList);
					
					for(int x = 0; x < eventList.size(); x++)
					{
						ConcurrentHashMap curEvent = (ConcurrentHashMap) eventList.get(x);
						if(eventTags.containsKey(curEvent.get("TaskName")))
						{
							ConcurrentHashMap nameMap = (ConcurrentHashMap) eventTags.get(curEvent.get("TaskName"));
							if(nameMap.containsKey(curEvent.get("StartTime")))
							{
								ArrayList tagList = (ArrayList) nameMap.get(curEvent.get("StartTime"));
								curEvent.put("Tags", tagList);
							}
						}
					}
				}
			}
		}
		
		
		
		return myReturn;
	}
	
	public ConcurrentHashMap getTaskTagsHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String taskQuery = this.taskTagQuery;
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
				nextRow.put("TaskName", myResults.getString("taskName"));
				nextRow.put("Completion", myResults.getString("completion"));
				nextRow.put("StartTime", myResults.getTimestamp("startTimestamp", cal));
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				//nextRow.put("Event", myResults.getString("event"));
				
				nextRow.put("Tag", myResults.getString("tag"));
				
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
				
				if(!sessionMap.containsKey("eventtags"))
				{
					sessionMap.put("eventtags", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("eventtags");
				
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
	
	public ConcurrentHashMap getTaskTagsHierarchyMap(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String taskQuery = this.taskTagQuery;
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
				//ConcurrentHashMap nextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				String taskName = myResults.getString("taskName");
				//nextRow.put("Completion", myResults.getString("completion"));
				Timestamp startTime = myResults.getTimestamp("startTimestamp", cal);
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				//nextRow.put("Event", myResults.getString("event"));
				
				String tag = myResults.getString("tag");
				
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
				
				if(!sessionMap.containsKey(taskName))
				{
					sessionMap.put(taskName, new ConcurrentHashMap());
				}
				ConcurrentHashMap nameMap = (ConcurrentHashMap) sessionMap.get(taskName);
				
				if(!nameMap.containsKey(startTime))
				{
					nameMap.put(startTime, new ArrayList());
				}
				ArrayList tagList = (ArrayList) nameMap.get(startTime);
				
				tagList.add(tag);
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
	
	public ConcurrentHashMap getTasksHierarchyBounds(String event, String admin)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String taskQuery = this.taskQueryBounds;
		String userSelectString = "";
		
		
		String sessionSelectString = "";
		
		
		
		
		try
		{
			System.out.println(taskQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(taskQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			int sessionOffset = 0;
			
			
			int secondSessionOffset = 0;
			
			
			
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				ConcurrentHashMap nextNextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				//nextNextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				//nextNextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				//nextRow.put("Source", myResults.getString("source"));
				//nextRow.put("TaskName", myResults.getString("taskName"));
				//nextRow.put("Completion", myResults.getString("completion"));
				//nextRow.put("EventTime", myResults.getTimestamp("eventTime", cal));
				//nextRow.put("StartTime", myResults.getTimestamp("startTimestamp", cal));
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				nextRow.put("Index", myResults.getTimestamp("mintime", cal)); nextRow.put("Index MS", myResults.getDouble("mintimeMS") * 1000);
				nextRow.put("TotalEntries", myResults.getString("totalEntries"));
				nextNextRow.put("Index", myResults.getTimestamp("maxtime", cal)); nextNextRow.put("Index MS", myResults.getDouble("maxtimeMS") * 1000);
				//nextRow.put("Event", myResults.getString("event"));
				
				//nextRow.put("Description", myResults.getString("eventDescription"));
				
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
				
				if(!sessionMap.containsKey("eventbounds"))
				{
					sessionMap.put("eventbounds", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("eventbounds");
				
				eventList.add(nextRow);
				eventList.add(nextNextRow);
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
	
	public ArrayList getTaskTags(String event, String admin)
	{
		ArrayList myReturn = new ArrayList();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String taskQuery = this.taskQueryTags;
		String userSelectString = "";
		
		
		String sessionSelectString = "";
		
		
		
		
		try
		{
			System.out.println(taskQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(taskQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				myReturn.add(myResults.getString("tag"));
				
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
				nextRow.put("Notes", myResults.getString("notes"));
				
				
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
				nextRow.put("Index MS", myResults.getDouble("indexMS") * 1000);
				
				nextRow.put("Text", myResults.getString("ocrtext"));
				
				byte[] image = myResults.getBytes("screenshot");
				nextRow.put("Size", image.length);
				
				
				/*
				if(myResults.getInt("doneocr") <= 0)
				{
					if(ocrProc == null)
					{
						ocrProc = new OCRProcessor(numOcrThreads);
					}
					ConcurrentHashMap toProcessImage = new ConcurrentHashMap();
					toProcessImage.put("AdminEmail", admin);
					toProcessImage.put("Event", event);
					toProcessImage.put("Username", userName);
					toProcessImage.put("Session", sessionName);
					toProcessImage.put("Taken", nextRow.get("Taken"));
					toProcessImage.put("image", image);
					toProcessImage.put("Connector", this);
					ocrProc.queueImage(toProcessImage);
				}
				*/
				
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
	
	public ConcurrentHashMap getScreenshotsHierarchyBounds(String event, String admin)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
        String allImageQuery = this.allImageQueryBounds;
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		String userSelectString = "";
		
		
		String sessionSelectString = "";
		
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(allImageQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			
			
			int secondSessionOffset = 0;
			
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				ConcurrentHashMap nextNextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				//nextRow.put("Index", myResults.getTimestamp("taken", cal));
				nextRow.put("Index", myResults.getTimestamp("mintime", cal)); nextRow.put("Index MS", myResults.getDouble("mintimeMS") * 1000);
				nextRow.put("TotalEntries", myResults.getString("totalEntries"));
				nextNextRow.put("Index", myResults.getTimestamp("maxtime", cal)); nextNextRow.put("Index MS", myResults.getDouble("maxtimeMS") * 1000);
				
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
				
				if(!sessionMap.containsKey("screenshotsbounds"))
				{
					sessionMap.put("screenshotsbounds", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("screenshotsbounds");
				
				eventList.add(nextRow);
				eventList.add(nextNextRow);
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
				nextRow.put("Index MS", myResults.getDouble("indexMS") * 1000);
				
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
				nextRow.put("Index MS", myResults.getDouble("indexMS") * 1000);
				
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
	
	public ConcurrentHashMap getProcessSummaryHierarchy(String event, String admin, ArrayList usersToSelect, ArrayList sessionsToSelect, String start, String end)
	{
		ConcurrentHashMap lastMap = new ConcurrentHashMap();
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String allProcessQuery = this.summaryProcessQueryLimited;
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
			//System.out.println(allProcessQuery);
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
				
				//Timestamp minTimeString = myResults.getTimestamp("mintime", cal);
				//Timestamp maxTimeString = myResults.getTimestamp("maxtime", cal);
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
				
				//if(minTimeString.toString().contains("0000-00-00"))
				//{
				//	nextRow.put("MinTime", new Timestamp(0));
				//}
				//else
				//{
				//	nextRow.put("MinTime", myResults.getTimestamp("mintime", cal));
				//}
				//if(maxTimeString.toString().contains("0000-00-00"))
				//{
				//	nextRow.put("MaxTime", new Timestamp(0));
				//}
				//else
				//{
				//	nextRow.put("MaxTime", myResults.getTimestamp("maxtime", cal));
				//}
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				//nextRow.put("Index", nextRow.get("MinTime"));
				
				
				//nextRow.put("MaxCPU", myResults.getString("maxcpu"));
				//nextRow.put("MaxMem", myResults.getString("maxmem"));
				
				
				
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
				
				if(!sessionMap.containsKey("processsummary"))
				{
					sessionMap.put("processsummary", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("processsummary");
				
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
	
	public ConcurrentHashMap getProcessDataHierarchyBounds(String event, String admin)
	{
		ConcurrentHashMap lastMap = new ConcurrentHashMap();
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String allProcessQuery = this.allProcessQueryBounds;
		String userSelectString = "";
		
		
		String sessionSelectString = "";
		
		
		
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(allProcessQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			System.out.println(myStatement);
			
			int sessionOffset = 0;
			
			
			int secondSessionOffset = 0;
			
			
			
			
			//System.out.println(myStatement);
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				ConcurrentHashMap nextNextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				//Timestamp timeString = myResults.getTimestamp("timestamp", cal);
				//System.out.println(timeString);
				
				//nextRow.put("User", myResults.getString("user"));
				//nextRow.put("PID", myResults.getString("pid"));
				//nextRow.put("Start", myResults.getString("start"));
				//nextRow.put("Command", myResults.getString("command"));
				
				
				//if(myResults.getObject("arguments") != null)
				//{
				//	nextRow.put("Arguments", myResults.getString("arguments"));
				//}
				
				//ConcurrentHashMap rowKey = new ConcurrentHashMap(nextRow);
				
				//rowKey.put("Username", userName);
				//rowKey.put("Session", sessionName);
				//if(lastMap.containsKey(rowKey))
				//{
				//	nextRow.put("Prev", lastMap.get(rowKey));
				//	((ConcurrentHashMap)lastMap.get(rowKey)).put("Next", nextRow);
				//}
				//lastMap.put(rowKey, nextRow);
				
				//if(timeString.toString().contains("0000-00-00"))
				//{
				//	nextRow.put("SnapTime", new Timestamp(0));
				//}
				//else
				//{
				//	nextRow.put("SnapTime", myResults.getTimestamp("timestamp", cal));
				//}
				//nextRow.put("InsertTime", myResults.getTimestamp("insertTimestamp"));
				nextRow.put("Index", myResults.getTimestamp("mintime", cal)); nextRow.put("Index MS", myResults.getDouble("mintimeMS") * 1000);
				nextRow.put("TotalEntries", myResults.getString("totalEntries"));
				nextNextRow.put("Index", myResults.getTimestamp("maxtime", cal)); nextNextRow.put("Index MS", myResults.getDouble("maxtimeMS") * 1000);
				
				
				//nextRow.put("CPU", myResults.getString("cpu"));
				//nextRow.put("Mem", myResults.getString("mem"));
				//nextRow.put("VSZ", myResults.getString("vsz"));
				//nextRow.put("RSS", myResults.getString("rss"));
				//nextRow.put("TTY", myResults.getString("tty"));
				//nextRow.put("Stat", myResults.getString("stat"));
				//nextRow.put("Time", myResults.getString("time"));
				
				
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
				
				if(!sessionMap.containsKey("processbounds"))
				{
					sessionMap.put("processbounds", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("processbounds");
				
				eventList.add(nextRow);
				eventList.add(nextNextRow);
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
			System.out.println("Query ready");
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
				nextRow.put("Index MS", myResults.getDouble("indexMS") * 1000);
				
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
	
	public ConcurrentHashMap getKeystrokesHierarchyBounds(String event, String admin)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String keyboardQuery = this.keyboardQueryBounds;
		String userSelectString = "";
		
		
		String sessionSelectString = "";
		
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(keyboardQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			
			
			int secondSessionOffset = 0;
			
			
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				ConcurrentHashMap nextNextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				nextRow.put("Index", myResults.getTimestamp("mintime", cal)); nextRow.put("Index MS", myResults.getDouble("mintimeMS") * 1000);
				nextRow.put("TotalEntries", myResults.getString("totalEntries"));
				nextNextRow.put("Index", myResults.getTimestamp("maxtime", cal)); nextNextRow.put("Index MS", myResults.getDouble("maxtimeMS") * 1000);
				
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
				
				if(!sessionMap.containsKey("keystrokesbounds"))
				{
					sessionMap.put("keystrokesbounds", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("keystrokesbounds");
				
				eventList.add(nextRow);
				eventList.add(nextNextRow);
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
			System.out.println("Getting mouse query:");
			System.out.println(mouseQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(mouseQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			for(int x=0; x < sessionsToSelect.size(); x++)
			{
				System.out.println(sessionsToSelect.get(x));
				myStatement.setString(3 + x, (String) sessionsToSelect.get(x));
				sessionOffset = x + 1;
			}
			
			int secondSessionOffset = 0;
			for(int x=0; x < usersToSelect.size(); x++)
			{
				System.out.println(usersToSelect.get(x));
				myStatement.setString(3 + sessionOffset + x, (String) usersToSelect.get(x));
				secondSessionOffset = x + 1;
			}
			
			if(!start.isEmpty() && !end.isEmpty())
			{
				System.out.println(start + ", " + end);
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
				nextRow.put("Index MS", myResults.getDouble("indexMS") * 1000);
				
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
	
	public ConcurrentHashMap getMouseHierarchyBounds(String event, String admin)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String mouseQuery = this.mouseQueryBounds;
		String userSelectString = "";
		
		
		String sessionSelectString = "";
		
		
		
		try
		{
			PreparedStatement myStatement = myConnector.prepareStatement(mouseQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			
			
			int secondSessionOffset = 0;
			
			
			
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				ConcurrentHashMap nextNextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				//nextRow.put("Index", myResults.getTimestamp("inputTime", cal));
				nextRow.put("Index", myResults.getTimestamp("mintime", cal)); nextRow.put("Index MS", myResults.getDouble("mintimeMS") * 1000);
				nextRow.put("TotalEntries", myResults.getString("totalEntries"));
				nextNextRow.put("Index", myResults.getTimestamp("maxtime", cal)); nextNextRow.put("Index MS", myResults.getDouble("maxtimeMS") * 1000);
				
				
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
				
				if(!sessionMap.containsKey("mousebounds"))
				{
					sessionMap.put("mousebounds", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("mousebounds");
				
				eventList.add(nextRow);
				eventList.add(nextNextRow);
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
				nextRow.put("Index MS", myResults.getDouble("indexMS") * 1000);
				
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
	
	public ConcurrentHashMap getWindowDataHierarchyBounds(String event, String admin)
	{
		ConcurrentHashMap myReturn = new ConcurrentHashMap();
		
		Connection conn = null;
        Statement stmt = null;
        ResultSet rset = null;
		
		Connection myConnector = mySource.getDatabaseConnectionNoTimeout();
		conn = myConnector;
		
		String allWindowQuery = this.allWindowQueryBounds;
		String userSelectString = "";
		
		
		String sessionSelectString = "";
		
		
		
		
		try
		{
			System.out.println(allWindowQuery);
			PreparedStatement myStatement = myConnector.prepareStatement(allWindowQuery);
			myStatement.setString(1, event);
			myStatement.setString(2, admin);
			
			int sessionOffset = 0;
			int secondSessionOffset = 0;
			
			
			
			
			
			
			ResultSet myResults = myStatement.executeQuery();
			while(myResults.next())
			{
				ConcurrentHashMap nextRow = new ConcurrentHashMap();
				ConcurrentHashMap nextNextRow = new ConcurrentHashMap();
				
				//nextRow.put("Username", myResults.getString("username"));
				String userName = myResults.getString("username");
				//nextRow.put("Session", myResults.getString("session"));
				String sessionName = myResults.getString("session");
				
				//nextRow.put("ChangeTime", myResults.getTimestamp("timeChanged", cal));
				nextRow.put("Index", myResults.getTimestamp("mintime", cal)); nextRow.put("Index MS", myResults.getDouble("mintimeMS") * 1000);
				nextRow.put("TotalEntries", myResults.getString("totalEntries"));
				nextNextRow.put("Index", myResults.getTimestamp("maxtime", cal)); nextNextRow.put("Index MS", myResults.getDouble("maxtimeMS") * 1000);
				
				/*
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
				*/
				
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
				
				if(!sessionMap.containsKey("windowbounds"))
				{
					sessionMap.put("windowbounds", new ArrayList());
				}
				ArrayList eventList = (ArrayList) sessionMap.get("windowbounds");
				
				eventList.add(nextRow);
				eventList.add(nextNextRow);
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
