<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, com.datacollector.*, java.sql.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Catalyst Endpoint Data Collection</title>
</head>
<body>
<div align="center">
<h1>Sign Up</h1>
<table width="60%">
<form action="home.jsp">
<tr>
<td style="text-align:center;">
<h2>Email</h2>
</td>
</tr>
<tr>
<td style="text-align:center;">
<input type="email" id="email" name="email">
</td>
</tr>
<tr>
<td style="text-align:center;">
<h2>Name</h2>
</td>
</tr>
<tr>
<td style="text-align:center;">
<input type="text" id="name" name="name">
</td>
</tr>
<tr>
<td style="text-align:center;">
<h2>Password</h2>
</td>
</tr>
<tr>
<td style="text-align:center;">
<input type="password" id="password" name="password">
</td>
</tr>
<tr>
<td style="text-align:center;">
<input type="submit" value="Submit">
</td>
</tr>
</form>
</table>
</div>
</body>
</html>