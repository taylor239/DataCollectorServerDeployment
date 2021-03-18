package com.datacollector;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import javax.sql.DataSource;

import org.apache.commons.pool2.ObjectPool;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.apache.commons.dbcp2.ConnectionFactory;
import org.apache.commons.dbcp2.PoolableConnection;
import org.apache.commons.dbcp2.PoolingDataSource;
import org.apache.commons.dbcp2.PoolableConnectionFactory;
import org.apache.commons.dbcp2.DriverManagerConnectionFactory;

import java.sql.Connection;

public class TestingConnectionSource implements Runnable
{
	private Connection myConnection;
	
	
	String userName = "dataCollectorServer";
	String password = "uBgiDDGhndviQeEZ";
	String address = "jdbc:mysql://localhost:3306/openDataCollectionServer?autoReconnect=true";
	static DataSource singletonDataSource = null;
	static ConcurrentHashMap<Object, Object> toClose, nextClose;
	static Thread closeThread;
	static boolean running = true;
	
	private static int minTimeout = 60000;
	
	//public TestingConnectionSource()
	//{
		/*
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
		}
		catch (ClassNotFoundException e)
		{
			e.printStackTrace();
		}
		*/
	//}
	
	public TestingConnectionSource(String theUser, String thePwd, String theAddr)
	{
		userName = theUser;
		password = thePwd;
		address = theAddr;
		/*
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
		}
		catch (ClassNotFoundException e)
		{
			e.printStackTrace();
		}
		*/
	}
	
	public synchronized Connection getDatabaseConnection()
	{
		if(closeThread == null || !(closeThread.isAlive()))
		{
			closeThread = new Thread(this);
			closeThread.start();
		}
		//if(myConnection != null)
		//{
		//	return myConnection;
		//}
		if(nextClose == null)
		{
			nextClose = new ConcurrentHashMap();
		}
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
			//System.out.println(address);
			if(singletonDataSource == null)
			{
				singletonDataSource = setupDataSource(address, userName, password);
			}
			Connection toReturn = singletonDataSource.getConnection();
			//toReturn.set
			if(!nextClose.containsKey(toReturn))
			{
				nextClose.put(toReturn, true);
			}
			return toReturn;
			//Connection newConnection = DriverManager.getConnection(address, userName, password);
			//return newConnection;
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		return null;
	}
	
	public synchronized Connection getDatabaseConnectionNoTimeout()
	{
		
		if(closeThread == null || !(closeThread.isAlive()))
		{
			closeThread = new Thread(this);
			closeThread.start();
		}
		//if(myConnection != null)
		//{
		//	return myConnection;
		//}
		if(nextClose == null)
		{
			nextClose = new ConcurrentHashMap();
		}
		try
		{
			Class.forName("com.mysql.jdbc.Driver");
			
			
			if(singletonDataSource == null)
			{
				
				singletonDataSource = setupDataSource(address, userName, password);
			}
			
			
			Connection toReturn = null; // = singletonDataSource.getConnection();
			while(toReturn == null || toReturn.isClosed() == true)
			{
				if(toReturn != null)
				{
					//toReturn.
				}
				
				toReturn = singletonDataSource.getConnection();
				if(toReturn == null || toReturn.isClosed() == true)
				{
					System.out.println("Problem getting connection: " + toReturn);
				}
			}
			//toReturn.set
			//if(!nextClose.containsKey(toReturn))
			//{
			//	nextClose.put(toReturn, true);
			//}
			return toReturn;
			//Connection newConnection = DriverManager.getConnection(address, userName, password);
			//return newConnection;
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		return null;
	}
	
	public void returnConnection(Connection toReturn)
	{
		myConnection = toReturn;
		//try
		//{
		//	toReturn.close();
		//}
		//catch (SQLException e)
		//{
		//	e.printStackTrace();
		//}
	}
	
	public static DataSource setupDataSource(String connectURI, String myUsername, String myPassword) {
        //
        // First, we'll create a ConnectionFactory that the
        // pool will use to create Connections.
        // We'll use the DriverManagerConnectionFactory,
        // using the connect string passed in the command line
        // arguments.
        //
		Properties properties = new Properties();
		properties.setProperty("user", myUsername);
		properties.setProperty("password", myPassword);
		properties.setProperty("maxTotal", "50");
        ConnectionFactory connectionFactory =
            new DriverManagerConnectionFactory(connectURI, properties);
        
        //
        // Next we'll create the PoolableConnectionFactory, which wraps
        // the "real" Connections created by the ConnectionFactory with
        // the classes that implement the pooling functionality.
        //
        PoolableConnectionFactory poolableConnectionFactory =
            new PoolableConnectionFactory(connectionFactory, null);
        poolableConnectionFactory.setMaxConnLifetimeMillis(minTimeout * 2);
        
        //poolableConnectionFactory.setMaxConnLifetimeMillis(1000);
        //
        // Now we'll need a ObjectPool that serves as the
        // actual pool of connections.
        //
        // We'll use a GenericObjectPool instance, although
        // any ObjectPool implementation will suffice.
        //
        ObjectPool<PoolableConnection> connectionPool =
                new GenericObjectPool<>(poolableConnectionFactory);
        
        // Set the factory's pool property to the owning pool
        poolableConnectionFactory.setPool(connectionPool);
        
        //
        // Finally, we create the PoolingDriver itself,
        // passing in the object pool we created.
        //
        PoolingDataSource<PoolableConnection> dataSource =
                new PoolingDataSource<>(connectionPool);
        
        //return null;
        return dataSource;
    }

	@Override
	public void run()
	{
		while(running)
		{
			try
			{
				Thread.sleep(minTimeout);
				if(toClose != null)
				{
					for(Map.Entry<Object,Object> entry : toClose.entrySet())
					{
						Connection curConnection = ((Connection)entry.getKey());
						if(curConnection != null && !curConnection.isClosed())
						{
							((Connection)entry.getKey()).close();
						}
					}
				}
				toClose = nextClose;
				nextClose = new ConcurrentHashMap();
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
		}
	}

}