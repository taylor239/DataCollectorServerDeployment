//This code searches through the sorted data for closest elements to a given time.

function closestIndexMSBinary(items, value)
{
	var firstIndex  = 0,
		lastIndex   = items.length - 1,
		middleIndex = Math.floor((lastIndex + firstIndex)/2);
	
	var unfound = true;
	if(middleIndex > lastIndex)
	{
		middleIndex = lastIndex;
		unfound = false;
	}
	if(middleIndex < 0)
	{
		middleIndex = 0;
		unfound = false;
	}
	
	while(unfound && items[middleIndex] && items[middleIndex]["Index MS"] != value && firstIndex < lastIndex)
	{
	   if (value < items[middleIndex]["Index MS"])
		{
			lastIndex = middleIndex - 1;
		} 
	  else if (value > items[middleIndex]["Index MS"])
		{
			firstIndex = middleIndex + 1;
		}
		middleIndex = Math.floor((lastIndex + firstIndex)/2);
	}
	
	if(middleIndex > lastIndex)
	{
		middleIndex = lastIndex;
		unfound = false;
	}
	if(middleIndex < 0)
	{
		middleIndex = 0;
		unfound = false;
	}
	
	var curDiff = Math.abs(value - items[middleIndex]["Index MS"]);
	var nextDiff = Infinity;
	var prevDiff = Infinity;
	
	if(items[middleIndex + 1])
	{
		nextDiff = Math.abs(value - items[middleIndex + 1]["Index MS"]);
	}
	if(items[middleIndex - 1])
	{
		prevDiff = Math.abs(value - items[middleIndex - 1]["Index MS"]);
	}
	if(curDiff > nextDiff)
	{
		if(nextDiff > prevDiff)
		{
			return middleIndex - 1;
		}
		return middleIndex + 1;
	}
	if(curDiff > prevDiff)
	{
		return middleIndex - 1;
	}
	
 return middleIndex;
}

function closestIndexMSBinarySession(items, value){
	var firstIndex  = 0,
		lastIndex   = items.length - 1,
		middleIndex = Math.floor((lastIndex + firstIndex)/2);
	if(!items[middleIndex])
	{
		console.log(items);
		console.log(middleIndex);
	}
	while(items[middleIndex]["Index MS Session"] != value && firstIndex < lastIndex)
	{
	   if (value < items[middleIndex]["Index MS Session"])
		{
			lastIndex = middleIndex - 1;
		} 
	  else if (value > items[middleIndex]["Index MS Session"])
		{
			firstIndex = middleIndex + 1;
		}
		middleIndex = Math.floor((lastIndex + firstIndex)/2);
	}
	var curDiff = Math.abs(value - items[middleIndex]["Index MS Session"]);
	var nextDiff = Infinity;
	var prevDiff = Infinity;
	
	if(items[middleIndex + 1])
	{
		nextDiff = Math.abs(value - items[middleIndex + 1]["Index MS Session"]);
	}
	if(items[middleIndex - 1])
	{
		prevDiff = Math.abs(value - items[middleIndex - 1]["Index MS Session"]);
	}
	if(curDiff > nextDiff)
	{
		if(nextDiff > prevDiff)
		{
			return middleIndex - 1;
		}
		return middleIndex + 1;
	}
	if(curDiff > prevDiff)
	{
		return middleIndex - 1;
	}
	
 return middleIndex;
}

function binarySearch(items, value)
{
	var firstIndex  = 0,
		lastIndex   = items.length - 1,
		middleIndex = Math.floor((lastIndex + firstIndex)/2);
	var unfound = true;
	if(middleIndex > lastIndex)
	{
		middleIndex = lastIndex;
		unfound = false;
	}
	if(middleIndex < 0)
	{
		middleIndex = 0;
		unfound = false;
	}
	while(unfound && items[middleIndex] && items[middleIndex]["Index MS"] != value && firstIndex < lastIndex)
	{
	   if (value < items[middleIndex]["Index MS"])
		{
			lastIndex = middleIndex - 1;
		} 
	  else if (value > items[middleIndex]["Index MS"])
		{
			firstIndex = middleIndex + 1;
		}
		middleIndex = Math.floor((lastIndex + firstIndex)/2);
	}
	return middleIndex;
}