<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.security.*, java.net.*, java.util.*, java.io.*, java.nio.file.*, javax.xml.bind.*, com.google.gson.Gson"%>
<%
	String hash="";
	String sqlHash = "";
	String downloadURL="/currentVersion.jsp";
	String sqlVersion = "/dataCollection.sql";
	ServletContext sc=getServletContext();
	String jarPath=sc.getRealPath("/endpointSoftware/DataCollector.jar");
	String jarURLPath = "/DataCollectorServer/endpointSoftware/DataCollector.jar";
	String sqlPath=sc.getRealPath("/endpointSoftware/dataCollection.sql");
	String sqlURLPath = "/DataCollectorServer/endpointSoftware/dataCollection.sql";
	File jarFile = new File(jarPath);
	MessageDigest md = MessageDigest.getInstance("MD5");
	boolean error = false;
	try
	{
		byte[] b = Files.readAllBytes(Paths.get(jarPath));
		byte[] hashBytes = MessageDigest.getInstance("MD5").digest(b);
		hash = DatatypeConverter.printHexBinary(hashBytes);
		b = Files.readAllBytes(Paths.get(sqlPath));
		hashBytes = MessageDigest.getInstance("MD5").digest(b);
		sqlHash = DatatypeConverter.printHexBinary(hashBytes);
	}
	catch(Exception e)
	{
		error = true;
		//e.printStackTrace();
	}
	HashMap myJSONOut = new HashMap();
	if(error)
	{
		myJSONOut.put("status", "error");
	}
	else
	{
		myJSONOut.put("status", "ok");
		myJSONOut.put("currentVersion", hash);
		myJSONOut.put("downloadURL", jarURLPath);
		myJSONOut.put("currentSQLVersion", sqlHash);
		myJSONOut.put("sqlDownloadURL", sqlURLPath);
	}
	myJSONOut.put("serverTime", System.currentTimeMillis());
	Gson myGson = new Gson();
	String output = myGson.toJson(myJSONOut);
	out.print(output);
	//System.out.println("Send a response2");
%>