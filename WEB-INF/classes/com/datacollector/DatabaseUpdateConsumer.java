package com.datacollector;

public interface DatabaseUpdateConsumer
{
	public void consumeUpdate(Object update);
	public void endConsumption();
}
