package com.datacollector;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

import com.zakgof.velvetvideo.ISeekableOutput;

public class SeekableByteStream implements ISeekableOutput
{
	long curPos = 0;
	byte[] master = null;
	ArrayList<byte[]> curBuffer;
	
	public SeekableByteStream()
	{
		curBuffer = new ArrayList();
	}

	@Override
	public void seek(long arg0)
	{
		updateMaster();
		curPos = arg0;
	}

	@Override
	public void close()
	{
		updateMaster();
	}
	
	private void updateMaster()
	{
		long curSize = 0;
		if(master != null)
		{
			curSize = master.length;
		}
		long toWriteSize = 0;
		for(int x=0; x < curBuffer.size(); x++)
		{
			toWriteSize += curBuffer.get(x).length;
		}
		long newArraySize = curSize - curPos + toWriteSize;
		ByteArrayOutputStream curStream = new ByteArrayOutputStream();
		curStream.write(master, 0, (int)curPos);
		for(int x=0; x < curBuffer.size(); x++)
		{
			curPos += curBuffer.get(x).length;
			curStream.write(curBuffer.get(x), 0, curBuffer.get(x).length);
		}
		if(curPos < master.length)
		{
			curStream.write(master, (int)curPos, master.length);
			curPos = master.length;
		}
		
		try {
			curStream.flush();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		master = curStream.toByteArray();
	}
	
	public byte[] toBytes()
	{
		return master;
	}

	@Override
	public void write(byte[] arg0)
	{
		curBuffer.add(arg0);
	}

}
