<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, com.datacollector.*"%>
<%
	DatabaseConnector myConnector = new DatabaseConnector();
	ArrayList results = myConnector.getCollectedData();
	//System.out.println(results);
	results = myConnector.getStartNodes(results);
	results = myConnector.normalizeTime(results);
	out.print(myConnector.toJSON(results));
	
%>