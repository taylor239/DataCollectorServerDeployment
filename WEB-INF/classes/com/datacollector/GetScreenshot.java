package com.datacollector;

import java.awt.Image;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Servlet implementation class GetScreenshot
 */
@WebServlet("/getClosestScreenshot.jpg")
public class GetScreenshot extends HttpServlet
{
	//private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public GetScreenshot()
    {
        super();
        
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		response.setContentType("image/jpg");
		HttpSession session = request.getSession(true);
		DatabaseConnector myConnector=(DatabaseConnector)session.getAttribute("connector");
		if(myConnector==null)
		{
			myConnector=new DatabaseConnector(getServletContext());
			session.setAttribute("connector", myConnector);
		}
		//response.getWriter().append("Served at: ").append(request.getContextPath());
		String username = request.getParameter("username");
		String timestamp = request.getParameter("timestamp");
		//response.getWriter().append(username + "\n" + timestamp);
		byte[] toWrite = myConnector.getScreenshot(username, timestamp);
		response.setContentLength(toWrite.length);
		OutputStream myOutput = response.getOutputStream();
		myOutput.write(toWrite);
		myOutput.close();
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
		doGet(request, response);
	}

}
