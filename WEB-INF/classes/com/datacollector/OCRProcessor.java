package com.datacollector;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

import javax.imageio.ImageIO;

import net.sourceforge.tess4j.Tesseract;

import net.sourceforge.tess4j.TesseractException;


public class OCRProcessor implements Runnable
{
	private ArrayList curThreads = new ArrayList();
	
	private ConcurrentLinkedQueue imagesToProcess = new ConcurrentLinkedQueue();
	
	private ConcurrentHashMap processKeys = new ConcurrentHashMap();
	
	private boolean running = true;
	
	public OCRProcessor(int numThreads)
	{
		for(int x = 0; x < numThreads; x++)
		{
			Thread newThread = new Thread(this);
			newThread.start();
			curThreads.add(newThread);
		}
	}
	
	public void addThreads(int numThreads)
	{
		for(int x = 0; x < numThreads; x++)
		{
			Thread newThread = new Thread(this);
			newThread.start();
			curThreads.add(newThread);
		}
	}
	
	public void stop()
	{
		running = false;
	}
	
	
	public void queueImage(ConcurrentHashMap toQueue)
	{
		toQueue.put("key", (String)toQueue.get("AdminEmail") + (String)toQueue.get("Event") + (String)toQueue.get("Username") + (String)toQueue.get("Session") + toQueue.get("Taken"));
		if(processKeys.containsKey((String)toQueue.get("key")))
		{
			
		}
		else
		{
			processKeys.put((String)toQueue.get("key"), true);
			imagesToProcess.add(toQueue);
		}
	}
	
	
	@Override
	public void run()
	{
		Tesseract myTess = new Tesseract();
		myTess.setDatapath("/usr/share/tesseract-ocr/4.00/");
		while(running)
		{
			if(imagesToProcess.size() <= 0)
			{
				try
				{
					Thread.currentThread().sleep(1000);
				}
				catch(InterruptedException e)
				{
					e.printStackTrace();
				}
				continue;
			}
			ConcurrentHashMap nextImage = (ConcurrentHashMap) imagesToProcess.poll();
			System.out.println("Next image:");
			System.out.println(nextImage);
			//BufferedImage toProcess
			ByteArrayInputStream bis = new ByteArrayInputStream((byte[]) nextImage.get("image"));
			try
			{
				BufferedImage toProcess = ImageIO.read(bis);
				String result = myTess.doOCR(toProcess);
				System.out.println("Read OCR:");
				System.out.println(result);
			}
			catch(TesseractException | IOException e)
			{
				e.printStackTrace();
			}
			processKeys.remove(nextImage.get("key"));
		}
	}

}
