<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, com.datacollector.*"%>
<%
	DatabaseConnector myConnector = new DatabaseConnector();
	ArrayList results = myConnector.getCollectedData();
	results = myConnector.getStartNodes(results);
	out.print(myConnector.toJSON(results));
	
%>