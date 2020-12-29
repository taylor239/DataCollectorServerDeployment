package com.datacollector;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;

import javax.imageio.ImageIO;

import org.bytedeco.ffmpeg.avcodec.AVCodec;
import org.bytedeco.ffmpeg.global.avcodec;
import org.bytedeco.javacv.FFmpegFrameRecorder;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;

public class BufferedImageVideoEncoder
{
	
	int framerate = 1;
	int maxWidth = 0;
	int maxHeight = 0;
	
	long curOffset = 0;
	
	ByteArrayOutputStream videoBytes;
	
	Frame lastFrame = null;
	
	boolean first = true;
	long lastTime = 0;
	BufferedImage lastImage = null;
	
	Java2DFrameConverter myConverter;
	FFmpegFrameRecorder myRecorder;
	
	public BufferedImageVideoEncoder()
	{
		myConverter = new Java2DFrameConverter();
		System.out.println("Instantiate up encoer");
	}
	
	public void setupEncoder(int width, int height)
	{
		System.out.println("Setting up encoder with " + width + ", " + height);
		if(width % 2 == 1)
		{
			width++;
		}
		if(height % 2 == 1)
		{
			height++;
		}
		videoBytes = new ByteArrayOutputStream();
		myRecorder = new FFmpegFrameRecorder(videoBytes, width, height);
		//myRecorder.setVideoCodec(avcodec.AV_CODEC_ID_H264);
		myRecorder.setFormat("matroska");
		myRecorder.setCloseOutputStream(false);
		myRecorder.setFrameRate(25);
		try {
			myRecorder.start();
		} catch (org.bytedeco.javacv.FrameRecorder.Exception e) {
			e.printStackTrace();
		}
	}
	
	public boolean addImage(ConcurrentHashMap toAdd)
	{
		System.out.println("Adding image to video");
		//imagesToEncode.add(toAdd);
		System.out.println("Getting image " + toAdd.get("Screenshot").getClass());
		byte[] imageData = (byte[]) toAdd.get("Screenshot");
		ByteArrayInputStream toImage = new ByteArrayInputStream(imageData);
		try
		{
			System.out.println("Converting bytes to image");
			BufferedImage toEncode = ImageIO.read((InputStream)toImage);
			int curWidth = toEncode.getWidth();
			int curHeight = toEncode.getHeight();
			
			System.out.println("Checking resolution");
			if((!first) && (curWidth != maxWidth || curHeight != maxHeight))
			{
				System.out.println("Resolution changed");
				first = true;
				myRecorder.flush();
				return false;
			}
			
			long curTime = Long.parseLong((toAdd.get("Index MS").toString()));
			//long sessionTime = Long.parseLong((toAdd.get("Index MS Session").toString()));
			long sessionTime = curTime;
			if(first)
			{
				first = false;
				maxWidth = curWidth;
				maxHeight = curHeight;
				setupEncoder(curWidth, curHeight);
				lastTime = curTime;
				curOffset = sessionTime;
			}
			
			long timeDiff = curTime - lastTime;
			
			Frame curFrame = myConverter.convert(toEncode);
			for(long x=0; x<timeDiff; x+=1000)
			{
				//System.out.println("Filler frame at " + (lastTime + x - curOffset));
				myRecorder.setTimestamp((lastTime + x - curOffset)*1000);
				if(x > timeDiff/2 || lastFrame == null)
				{
					myRecorder.record(curFrame);
				}
				else
				{
					myRecorder.record(lastFrame);
				}
			}
			
			System.out.println("Frame size: " + curFrame.imageWidth + ", " + curFrame.imageHeight);
			myRecorder.setTimestamp((sessionTime - curOffset)*1000);
			System.out.println("Adding frame at " + (sessionTime - curOffset));
			myRecorder.record(curFrame);
			
			lastTime = curTime;
			lastImage = toEncode;
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		return true;
	}
	
	public byte[] getVideoBytes()
	{
		try {
			//myRecorder.flush();
			myRecorder.stop();
			videoBytes.flush();
		} catch (IOException e) {
			e.printStackTrace();
		}
		byte[] toReturn = videoBytes.toByteArray();
		System.out.println("Video is " + toReturn.length +" bytes");
		return toReturn;
	}
}
