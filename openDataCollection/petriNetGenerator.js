//This code builds and visualizes petri nets from selected tasks.

const curve = d3.line().curve(d3.curveNatural);

var attackGraphs = [];

function rebuildPetriMenu()
{
	//console.log(d3.select("#petriNets"));
	d3.select("#petriNets").selectAll("option").remove();
	d3.select("#petriNets")
		.selectAll("option")
		.data(attackGraphs)
		.enter()
		.append("option")
		.attr("value", function(d, i)
		{
			return i;
		})
		.html(function(d, i)
		{
			return d["nodes"][0]["Place"]["TaskName"];
		})
}

async function buildTaskMapTop(user, session, task, onlySession, colissionMap)
{
	var curGraph = await buildTaskMap(user, session, task, onlySession, colissionMap)
	
	console.log(curGraph);
	
	curGraph = getNestingLevel(curGraph);
	
	var toReturn = await analyzeTaskMap(curGraph)
	toReturn = toNodeMap(toReturn);
	
	console.log(toReturn);
	
	toReturn = await petriToGraph(toReturn);
	
	console.log(toReturn);
	
	attackGraphs.push(toReturn);
	console.log(attackGraphs)
	rebuildPetriMenu();
	return toReturn;
}

function getNestingLevel(toReturn)
{
	if(toReturn["Nesting Level"])
	{
		return;
	}
	//console.log("Getting nesting level")
	//console.log(toReturn);
	toReturn["Nesting Level"] = 1;
	
	if(toReturn["Child Tasks"] && toReturn["Child Tasks"].length > 0)
	{
		var maxNest = 0;
		for(var entry in toReturn["Child Tasks"])
		{
			getNestingLevel(toReturn["Child Tasks"][entry]);
			if(toReturn["Child Tasks"][entry]["Nesting Level"] > maxNest)
			{
				maxNest = toReturn["Child Tasks"][entry]["Nesting Level"];
			}
		}
		toReturn["Nesting Level"] = maxNest + 1;
	}
	
	toReturn["Parent Task"]["Nesting Level"] = toReturn["Nesting Level"];
	toReturn["Parent Task"]["Mouse Input"] = toReturn["Mouse Input"];
	toReturn["Parent Task"]["Key Input"] = toReturn["Key Input"];
	
	return toReturn;
}

async function petriToGraph(analyzedTasks)
{
	var toReturn = {};
	toReturn["nodes"] = [];
	toReturn["links"] = [];
	
	var nodeSourceCounts = {};
	
	var transitionNum = 0;
	
	for(var entry in analyzedTasks)
	{
		var curPlace = analyzedTasks[entry];
		var placeNode = {};
		placeNode["type"] = "Place";
		placeNode["id"] = entry + "_place";
		placeNode["Place"] = curPlace["Result"];
		toReturn["nodes"].push(placeNode);
		
		if(entry != "-1")
		{
			var transitionNode = {};
			transitionNode["id"] = curPlace["Result"]["Task Hash"] + "_transition";
			//transitionNode["label"] = curPlace["Result"]["Goal"];
			transitionNode["label"] = curPlace["Result"]["TaskName"];
			transitionNum++;
			transitionNode["type"] = "Transition";
			transitionNode["Target Place"] = curPlace["Result"];
			
			for(source in curPlace["Transitions"])
			{
				//transitionNode["id"] = curTransition[source]["Result"]["Task Hash"] + "_" + transitionNode["id"];
				var prevPlaceLink = {};
				prevPlaceLink["target"] = transitionNode["id"];
				prevPlaceLink["source"] = curPlace["Transitions"][source]["Result"]["Task Hash"] + "_place";
				
				
				toReturn["links"].push(prevPlaceLink);
			}
			
			
			var nextPlaceLink = {};
			nextPlaceLink["source"] = transitionNode["id"];
			nextPlaceLink["target"] = placeNode["id"];
			toReturn["links"].push(nextPlaceLink);
			toReturn["nodes"].push(transitionNode);
		}
	}
	return toReturn;
}

async function analyzeTaskMap(curTask, nodeMap)
{
	if(!nodeMap)
	{
		nodeMap = {};
	}
	
	if(nodeMap[curTask["Parent Task"]["Task Hash"]])
	{
		curTask = nodeMap[curTask["Parent Task"]["Task Hash"]];
		return curTask;
	}
	
	//If the current task does not have a predecessor, give it
	//the default start node as a predecessor.
	if(!curTask["Predecessor"])
	{
		var defPred = {}
		defPred["Child Tasks"] = [];
		defPred["Concurrent Tasks"] = [];
		defParent = {};
		defPred["Parent Task"] = {};
		defPred["Parent Task"]["TaskName"] = "_StartNode_";
		defPred["Parent Task"]["Task Hash"] = "-1";
		curTask["Predecessor"] = [defPred];
	}
	
	var curParent = curTask["Parent Task"];
	var curChildren = curTask["Child Tasks"];
	
	//For all children except the first, their predecessor is the
	//first child before them that is not concurrent to them.
	
	//If there is no previous child, then the predecessor is
	//the predecessor for the parent.  We will assign this at
	//the end from this list.
	var predlessChildren = [];
	
	//We also keep track of children that have been used as
	//predecessors so that at the end we can determine which
	//ones are not used and thus are predecessor to the parent.
	
	//After this is all done, we will recursively call this on
	//the children.
	for(var x = curChildren.length - 1; x >= 0; x--)
	{
		//Get the current child
		var curChild = curChildren[x];
		var curChildChildren = curChild["Child Tasks"];
		var curConcurrent = curChild["Concurrent Tasks"];
		var curChildParent = curChild["Parent Task"];
		
		var foundPred = false;
		if(x >= 1)
		{
			//Iterate through children before this child,
			//looking for one that is not concurrent.
			for(var y = x - 1; y >= 0; y--)
			{
				var isConcurrent = false;
				for(entry in curConcurrent)
				{
					if(curConcurrent[entry]["Parent Task"]["Task Hash"] == curChildren[y]["Parent Task"]["Task Hash"])
					{
						isConcurrent = true;
					}
				}
				if(!isConcurrent)
				{
					//The previous child is not concurrent to the
					//current child we are getting pred for.  We
					//assign it as pred and continue.
					curChild["Predecessor"] = [curChildren[y]];
					curChildren[y]["UsedPred"] = true;
					foundPred = true;
					y = -1;
				}
			}
		}
		if(!foundPred)
		{
			//There was no previous child that was not concurrent
			//to the current child, so we set it aside.
			predlessChildren.push(curChild)
		}
	}
	
	//Now, for each child without a pred, we assign the pred for
	//the parent.
	for(entry in predlessChildren)
	{
		predlessChildren[entry]["Predecessor"] = curTask["Predecessor"];
	}
	
	//The predecessor to the parent task are all of the children that are
	//not predecessor to anything else.
	var newPredList = [];
	for(entry in curChildren)
	{
		if(curChildren[entry]["UsedPred"])
		{
			
		}
		else
		{
			newPredList.push(curChildren[entry]);
		}
	}
	
	if(newPredList.length > 0)
	{
		curTask["Predecessor"] = newPredList;
	}
	
	nodeMap[curTask["Parent Task"]["Task Hash"]] = curTask;
	//Now we run this same algorithm on all children.
	for(var x = curChildren.length - 1; x >= 0; x--)
	{
		var curChild = curChildren[x];
		analyzeTaskMap(curChild, nodeMap);
	}
	
	
	return curTask;
}

function toNodeMap(curTask, nodeMap, targetNode)
{
	if(!nodeMap)
	{
		nodeMap = {};
	}
	
	var curNode;
	
	if(nodeMap[curTask["Parent Task"]["Task Hash"]])
	{
		curNode = nodeMap[curTask["Parent Task"]["Task Hash"]];
	}
	else
	{
		curNode = {};
		curNode["Result"] = curTask["Parent Task"];
		curNode["Transitions"] = [];
		nodeMap[curNode["Result"]["Task Hash"]] = curNode;
	}
	
	if(targetNode)
	{
		targetNode["Transitions"].push(curNode);
	}
	
	
	for(entry in curTask["Predecessor"])
	{
		nodeMap = toNodeMap(curTask["Predecessor"][entry], nodeMap, curNode);
	}
	
	if(curNode["Transitions"].length == 0)
	{
		curNode["Transitions"].push(curNode);
	}
	
	return nodeMap;
}

/*
async function analyzeTaskMap(taskMap, nodeCache)
{
	if(!nodeCache)
	{
		nodeCache = {};
	}
	//We will build a petri net from the task map.
	var curTask = taskMap;
	//The current parent is the result, the goal.
	var curParent = taskMap["Parent Task"];
	//Child tasks can run concurrently.  Each concurrent running
	//child task with no subsequent task is a requirement for
	//transition to the result.  Each child task with no children
	//requires the collected data from its time and its
	//predecessor child to fire.
	var curChildren = curTask["Child Tasks"];
	var childHashes = {};
	
	console.log("Analyzing node:")
	console.log(curParent)
	
	for(entry in curChildren)
	{
		childHashes[curChildren[entry]["Parent Task"]["Task Hash"]] = true;
	}
	
	if(curTask)
	{
		var curNode = {};
		if(nodeCache[curParent["Task Hash"]])
		{
			console.log("Cur node is cached");
			curNode = nodeCache[curParent["Task Hash"]];
		}
		else
		{
			curNode["Result"] = curParent;
			curNode["Transitions"] = [];
			nodeCache[curParent["Task Hash"]] = curNode;
		}
		
		var curTransition = [];
		
		if(curChildren.length == 0)
		{
			console.log("No node children")
			
			if(!curTask["Predecessor"])
			{
				console.log("Does not have predecessor")
				
				var defPred = {}
				defPred["Child Tasks"] = [];
				defPred["Concurrent Tasks"] = [];
				defParent = {};
				defPred["Parent Task"] = {};
				defPred["Parent Task"]["TaskName"] = "_StartNode_";
				defPred["Parent Task"]["Task Hash"] = "-1";
				curTask["Predecessor"] = defPred;
			}
			
			console.log("Has predecessor, adjusting:")
			console.log(curTask["Predecessor"]["Parent Task"])
			
			var nextPredNode = {};
			if(nodeCache[curTask["Predecessor"]["Parent Task"]["Task Hash"]])
			{
				nextPredNode = nodeCache[curTask["Predecessor"]["Parent Task"]["Task Hash"]];
			}
			else
			{
				nextPredNode["Result"] = curTask["Predecessor"]["Parent Task"];
				nextPredNode["Transitions"] = [];
				nodeCache[curTask["Predecessor"]["Parent Task"]["Task Hash"]] = nextPredNode;
				analyzeTaskMap(curTask["Predecessor"], nodeCache);
			}
			curTransition.push(nextPredNode);
		}
		
		for(var x = curChildren.length - 1; x >= 0; x--)
		{
			for(var y = x - 1; y >= 0; y--)
			{
				if(curChildren[x]["Concurrent Tasks"].indexOf(curChildren[y]) == -1)
				{
					curChildren[x]["Predecessor"] = curChildren[y];
					break;
				}
				else
				{
					
				}
			}
			if(!curChildren[x]["Predecessor"])
			{
				//defPred = JSON.parse(JSON.stringify(curTask));
				var defPred = {}
				defPred["Child Tasks"] = [];
				defPred["Concurrent Tasks"] = [];
				defParent = {};
				defPred["Parent Task"] = {};
				defPred["Parent Task"]["TaskName"] = "_StartNode_";
				defPred["Parent Task"]["Task Hash"] = "-1";
				//JSON.parse(JSON.stringify(defParent["Parent Task"]));
				//defPred["Parent Task"]["Next"] = defPred["Parent Task"];
				//defPred["Parent Task"]["TaskName"] = "Begin " + defPred["Parent Task"]["TaskName"];
				if(!curChildren[x]["Predecessor"])
				{
					curChildren[x]["Predecessor"] = defPred;
					defPred["Successor"] = curChildren[x];
					var nextSuccessor = curChildren[x]["Successor"];
					while(nextSuccessor)
					{
						nextSuccessor["Predecessor"] = defPred;
						nextSuccessor = nextSuccessor["Successor"];
					}
				}
			}
		}

		for(var x = curChildren.length - 1; x >= 0; x--)
		{
			//Take the last child and last concurrent children.
			//If the last child has a concurrent task and that task
			//is also a child then it is also a requirement and
			//in the transition.
			
			console.log("Looking at child:")
			console.log(curChildren[x]["Parent Task"]);
			
			if(x == curChildren.length - 1)
			{
				console.log("Last child")
				//curTransition.push(curChildren[x]["Parent Task"])
				var nextNode = {};
				if(nodeCache[curChildren[x]["Parent Task"]["Task Hash"]])
				{
					nextNode = nodeCache[curChildren[x]["Parent Task"]["Task Hash"]];
				}
				else
				{
					nextNode["Result"] = curChildren[x]["Parent Task"];
					nextNode["Transitions"] = [];
					nodeCache[curChildren[x]["Parent Task"]["Task Hash"]] = nextNode;
					if(curTask["Predecessor"])
					{
						if(curChildren[x]["Predecessor"])
						{
							
						}
						else
						{
							curChildren[x]["Predecessor"] = curTask["Predecessor"];
						}
					}
					analyzeTaskMap(curChildren[x], nodeCache);
				}
				curTransition.push(nextNode);
				for(entry in curChildren[x]["Concurrent Tasks"])
				{
					var taskToCheck = curChildren[x]["Concurrent Tasks"][entry];
					if(taskToCheck["Parent Task"]["Task Hash"] in childHashes)
					{
						var nextConNode = {};
						if(nodeCache[taskToCheck["Parent Task"]["Task Hash"]])
						{
							nextConNode = nodeCache[taskToCheck["Parent Task"]["Task Hash"]];
						}
						else
						{
							nextConNode["Result"] = taskToCheck["Parent Task"];
							nextConNode["Transitions"] = [];
							nodeCache[taskToCheck["Parent Task"]["Task Hash"]] = nextConNode;
							//console.log(taskToCheck);
							analyzeTaskMap(taskToCheck, nodeCache);
						}
						curTransition.push(nextConNode);
					}
				}
			}
			else
			{
				console.log("This is before the last node, we dont care?")
			}
		}
		curNode["Transitions"].push(curTransition);
		
		nodeCache[curParent["Task Hash"]] = curNode;
	}

	return nodeCache;
}
*/


async function buildTaskMap(user, session, task, onlySession, colissionMap)
{

	if(task.constructor.name == "String")
	{
		task = objectCacheMap[task];
	}

	
	if(!colissionMap)
	{
		colissionMap = {};
	}
	
	var thisHash = SHA256(task["User"] + task["Original Session"] + task["TaskName"]);
	
	task["Task Hash"] = thisHash;
	
	if(colissionMap[thisHash])
	{
		return colissionMap[thisHash];
	}
	var concurrentTasks = [];
	var childTasks = [];
	
	var toReturn = {};
	toReturn["Mouse Input"] = 0;
	toReturn["Key Input"] = 0;
	colissionMap[thisHash] = toReturn;
	toReturn["Parent Task"] = task;
	toReturn["Concurrent Tasks"] = concurrentTasks;
	toReturn["Child Tasks"] = childTasks
	
	if(!(task["Next"]))
	{
		return toReturn;
	}
	
	var sessions = [];
	var sessionTasks = {};
	var sessionCurIndices = {};
	//First we select all of the task arrays.

	if(onlySession)
	{
		sessions.push(session);
		sessionTasks[session] = theNormData[user][session]["events"];
	}
	else
	{
		for(entry in theNormData[user]["Session Ordering"]["Order List"])
		{
			if(theNormData[user]["Session Ordering"]["Order List"][entry] == -1)
			{
				continue;
			}
			else
			{
				var curSession = theNormData[user]["Session Ordering"][theNormData[user]["Session Ordering"]["Order List"][entry]];

				
				if(theNormData[user][curSession]["events"])
				{
					//if(Number(theNormData[user][curSession]["events"][0]["Index MS"]) < Number(task["Next"]["Index MS"]) || theNormData[user][curSession]["events"][theNormData[user][curSession]["events"].length - 1]["Index MS"] > task["Index MS"])
					{
						sessions.push(curSession);
						sessionTasks[curSession] = theNormData[user][curSession]["events"];
					}
				}
			}
		}
	}

	
	var sessionsIncluded = [];
	//Next we find the start and end indices in each session based.
	//on the parent task start and end.  All task events we look
	//at will be in between these indices.
	for(entry in sessions)
	{
		var curSession = sessionTasks[sessions[entry]];
		
		//Get keyboard and mouse indices to calculate IO during task
		var getKeyValue = (await theNormData[user][sessions[entry]]["keystrokes"]["getfiltered"]())
		var keystrokes;
		if(getKeyValue)
		{
			keystrokes = getKeyValue.value;
			var startNode = binarySearch(keystrokes, task["Index MS"]);
			if(startNode >= 0)
			{
				while(keystrokes[startNode] && Number(keystrokes[startNode]["Index MS"]) < Number(task["Index MS"]))
				{
					startNode++;
				}
				
				var endNode = binarySearch(keystrokes, task["Next"]["Index MS"]);
				while(keystrokes[endNode] && Number(keystrokes[endNode]["Index MS"]) > Number(task["Next"]["Index MS"]))
				{
					endNode--;
				}
				
				if(endNode > startNode)
				{
					toReturn["Key Input"] += (endNode - startNode);
				}
			}
		}
		else
		{
			
		}
		var getMouseValue = (await theNormData[user][sessions[entry]]["mouse"]["getfiltered"]())
		var mouse;
		if(getMouseValue)
		{
			mouse = getMouseValue.value;
			var startNode = binarySearch(mouse, task["Index MS"]);
			if(startNode >= 0)
			{
				while(mouse[startNode] && Number(mouse[startNode]["Index MS"]) < Number(task["Index MS"]))
				{
					startNode++;
				}
				
				var endNode = binarySearch(mouse, task["Next"]["Index MS"]);
				while(mouse[endNode] && Number(mouse[endNode]["Index MS"]) > Number(task["Next"]["Index MS"]))
				{
					endNode--;
				}
				
				if(endNode > startNode)
				{
					toReturn["Mouse Input"] += (endNode - startNode);
				}
			}
		}
		else
		{
			
		}
		
		
		var alreadyIn = false;
		var startNode = binarySearch(curSession, task["Index MS"]);
		var endNode = binarySearch(curSession, task["Next"]["Index MS"]);
		//console.log(curSession[startNode]);
		//console.log(curSession[startNode]["Index MS"]);
		//console.log(task);
		//console.log(task["Index MS"]);
		while((curSession[startNode]["Index MS"] < task["Index MS"] || curSession[startNode] == task) && startNode < curSession.length)
		{
			//console.log(task["Next"]);
			//console.log(task["Next"]["Index MS"]);
			if(curSession[startNode]["Index MS"] > task["Next"]["Index MS"])
			{
				//return toReturn;
				break;
			}
			if(startNode == endNode)
			{
				//break;
				//return toReturn;
			}
			startNode++;
		}
		if(curSession[startNode]["Index MS"] > task["Next"]["Index MS"])
		{
			break;
			//return toReturn;
		}
		else
		{
			alreadyIn = true;
			sessionCurIndices["start_" + sessions[entry]] = startNode;
			sessionsIncluded.push(sessions[entry]);
		}
		
		sessionCurIndices["start_" + sessions[entry]] = startNode;
		
		while((curSession[endNode]["Index MS"] > task["Next"]["Index MS"] || curSession[endNode] == task["Next"]) && endNode > 0)
		{
			if(curSession[endNode]["Index MS"] < task["Index MS"])
			{
				break;
				//return toReturn;
			}
			if(startNode == endNode)
			{
				//break;
				//return toReturn;
			}
			endNode--;
		}
		if(curSession[endNode]["Index MS"] < task["Index MS"])
		{
			break;
			//return toReturn;
		}
		else
		{
			sessionCurIndices["end_" + sessions[entry]] = endNode;
			if(!alreadyIn)
			{
				sessionsIncluded.push(sessions[entry]);
			}
		}

	}

	//This helper function returns the next task from all session
	//lists.
	if(sessionsIncluded.length == 0)
	{
		return toReturn;
	}
	
	function nextTask()
	{
		var toReturn;
		var minEvent = Infinity;
		var finalSession = "";
		for(entry in sessionsIncluded)
		{
			var curSession = sessionTasks[sessionsIncluded[entry]];
			var curStart = sessionCurIndices["start_" + sessionsIncluded[entry]];
			var curEnd = sessionCurIndices["end_" + sessionsIncluded[entry]];

			if(curStart <= curEnd)
			{
				if(curSession[curStart]["Index MS"] < minEvent)
				{
					minEvent = curSession[curStart]["Index MS"];
					toReturn = curSession[curStart];
					finalSession = sessionsIncluded[entry];
				}
			}
		}
		sessionCurIndices["start_" + finalSession] = sessionCurIndices["start_" + finalSession] + 1;
		return toReturn;
	}

	//Iterate through tasks.  If the task starts or ends during
	//this task but not both, it is a concurrent task.  Add it to
	//list of concurrencies.  If the task starts and ends during
	//this task then it is a child/subtask.  Recursively call
	//this function to build children/concurrencies in the child/
	//subtask.  With child concurrencies, if they are encompassed
	//within the parent then delete and add as another child and
	//call the same recursive function.  Else add the task as a
	//concurrence to the parent.  Continue iteration after this
	//subtask.
	
	var hasTask = {};
	
	var theTask = nextTask();
	var curEnd;
	while(theTask)
	{
		var taskHash = SHA256(theTask["User"] + theTask["Original Session"] + theTask["TaskName"]);
		
		theTask["Task Hash"] = taskHash;
		if(taskHash in hasTask)
		{
			
		}
		else
		{
			hasTask[taskHash] = true;
			if(theTask["Description"] == "end" || !(theTask["Next"]) || theTask["Next"]["Index MS"] > task["Next"]["Index MS"])
			{
				var builtTask = await buildTaskMap(user, session, theTask, onlySession, colissionMap)
				concurrentTasks.push(builtTask);
			}
			else
			{
				if(!(curEnd) || theTask["Next"]["Index MS"] > curEnd["Next"]["Index MS"])
				{
					var builtTask = await buildTaskMap(user, session, theTask, onlySession, colissionMap)
					childTasks.push(builtTask);
					curEnd = theTask;
				}
			}
		}
		
		theTask = nextTask();
	}
	
	return toReturn;
	
}

function viewPetriNets()
{
	var fontSize = "12";
	
	showLightbox("<tr><td id=\"petriRow\"><div id=\"petriDiv\" width=\"100%\" height=\"100%\"></div></td></tr>");

	var graphArrows = svg.append("svg:defs").selectAll("marker")
    .data(["end"])      // Different link/path types can be defined here
	  .enter().append("svg:marker")    // This section adds in the arrows
	    .attr("id", String)
	    .attr("viewBox", "0 -5 10 10")
	    .attr("refX", 15)
	    .attr("refY", -1.5)
	    .attr("markerWidth", 6)
	    .attr("markerHeight", 6)
	    .attr("orient", "auto")
	  .append("svg:path")
	    .attr("d", "M0,-5L10,0L0,5");
	
	
	var petriRow = d3.select("#petriRow");
	var petriDiv = d3.select("#petriDiv");
	
	var divBounds = petriRow.node().getBoundingClientRect();

	var petriSvg = petriDiv.append("svg")
		.attr("width", divBounds["width"])
		.attr("height", divBounds["height"])
		.attr("viewBox", [-divBounds["width"] / 2, -divBounds["height"] / 2, divBounds["width"], divBounds["height"]]);
	
	var petriG = petriSvg.append("g");
	
	var finalNodesEdges = {};
	finalNodesEdges["links"] = [];
	finalNodesEdges["nodes"] = [];
	var usedPlaces = {};
	
	var numUnused = 0;
	
	var finalAttackGraphs = JSON.parse(JSON.stringify(attackGraphs));
	
	//In this loop we merge nodes and calculate min, max nesting level and time taken
	var minNestingLevel = 0;
	var maxNestingLevel = 0;
	var minInput = Infinity;
	var maxInput = 0;
	var minTimeTaken = Infinity;
	var maxTimeTaken = 0;
	
	
	for(var entry in finalAttackGraphs)
	{
		for(place in finalAttackGraphs[entry]["nodes"])
		{
			if(finalAttackGraphs[entry]["nodes"][place]["type"] == "Transition")
			{
				if(finalAttackGraphs[entry]["nodes"][place]["Target Place"]["Nesting Level"] > maxNestingLevel)
				{
					maxNestingLevel = finalAttackGraphs[entry]["nodes"][place]["Target Place"]["Nesting Level"];
				}
				var timeTaken = finalAttackGraphs[entry]["nodes"][place]["Target Place"]["Next"]["Index MS"] - finalAttackGraphs[entry]["nodes"][place]["Target Place"]["Index MS"];
				finalAttackGraphs[entry]["nodes"][place]["Time Taken"] = timeTaken;
				
				if(timeTaken < minTimeTaken)
				{
					minTimeTaken = timeTaken;
				}
				if(timeTaken > maxTimeTaken)
				{
					maxTimeTaken = timeTaken;
				}
				
				var totalInput = finalAttackGraphs[entry]["nodes"][place]["Target Place"]["Mouse Input"] + finalAttackGraphs[entry]["nodes"][place]["Target Place"]["Key Input"];
				if(totalInput < minInput)
				{
					minInput = totalInput;
				}
				if(totalInput > maxInput)
				{
					maxInput = totalInput;
				}
			}
			
			if(finalAttackGraphs[entry]["nodes"][place]["id"] in usedPlaces)
			{
				
			}
			else
			{
				usedPlaces[finalAttackGraphs[entry]["nodes"][place]["id"]] = true;
				finalNodesEdges["nodes"].push(finalAttackGraphs[entry]["nodes"][place]);
			}
		}
		finalNodesEdges["links"] = finalNodesEdges["links"].concat(JSON.parse(JSON.stringify(finalAttackGraphs[entry]["links"])));
	}
	
	//console.log("Max Nesting: " + maxNestingLevel);
	//console.log("Time Taken: " + minTimeTaken + " : " + maxTimeTaken);
	//The multiplier range on the transition rect glyph.
	var minTransition = 1;
	var maxTransition = 3;
	
	var inputScaleRange = ["#ba4f00", "#a470ff"];
	var inputScale = d3.scaleLinear().domain([minInput, maxInput]).range(inputScaleRange);
	var nestingSizeScale = d3.scaleLinear().domain([minNestingLevel, maxNestingLevel]).range([minTransition, maxTransition]);
	var timeTakenScaleRange = ["#ffcf3d", "#00ff1e", "#00315c"];
	var timeTakenScale = d3.scaleLinear().domain([minTimeTaken, (minTimeTaken + maxTimeTaken) / 2, maxTimeTaken]).range(timeTakenScaleRange);
	
	var legendWidth = divBounds["width"] / 8;
	var legendHeight = divBounds["height"] / 3
	
	function linspace(start, end, n)
	{
		var out = [];
		var delta = (end - start) / (n - 1);
		
		var i = 0;
		while(i < (n - 1)) {
		    out.push(start + (i * delta));
		    i++;
		}
		
		out.push(end);
		return out;
	}

	var inputLegend = petriG.append("g");
	var inputGradient = inputLegend.append('defs')
		.append('linearGradient')
		.attr('id', 'inputGradient')
		.attr('x1', '0%') // bottom
		.attr('y1', '100%')
		.attr('x2', '0%') // to top
		.attr('y2', '0%')
		.attr('spreadMethod', 'pad');
	var inputPct = linspace(0, 100, inputScaleRange.length).map(function(d)
		{
			return Math.round(d) + '%';
		});
	var inputColourPct = d3.zip(inputPct, inputScaleRange);
	inputColourPct.forEach(function(d)
	{
		inputGradient.append('stop')
			.attr('offset', d[0])
			.attr('stop-color', d[1])
			.attr('stop-opacity', 1);
	});
	inputLegend.append('rect')
		.attr('x', -divBounds["width"] / 2)
		.attr('y', -divBounds["height"] / 2)
		.attr('width', legendWidth / 4)
		.attr('height', legendHeight)
		.style('fill', 'url(#inputGradient)');
	var inputScaleLegend = d3.scaleLinear()
		.domain([minInput, maxInput])
		.range([legendHeight, 0]);
	var inputLegendAxis = d3.axisLeft()
		.scale(inputScaleLegend);
	var inputAxisG = inputLegend.append("g")
		.attr("class", "legend axis")
		.attr("transform", "translate(" + ((-divBounds["width"] / 2) + (legendWidth / 4)) + ", " + (-divBounds["height"] / 2) + ")")
		.call(inputLegendAxis);
	inputAxisG.selectAll("text").style("fill", "white");
	inputAxisG.selectAll("line").style("stroke", "white");
	var axisLabel = inputLegend.append("text")
		.attr('x', (-divBounds["width"] / 2) + (legendWidth / 4))
		.attr('y', (-divBounds["height"] / 2) + (legendHeight / 2))
		.style("dominant-baseline", "text-after-edge")
		.style("writing-mode", "tb")
		.style("text-orientation", "upright")
		.style("text-anchor", "middle")
		.text("User Input");
	
	
	
	var timeTakenLegend = petriG.append("g");
	var timeTakenGradient = timeTakenLegend.append('defs')
		.append('linearGradient')
		.attr('id', 'timeTakenGradient')
		.attr('x1', '0%') // bottom
		.attr('y1', '100%')
		.attr('x2', '0%') // to top
		.attr('y2', '0%')
		.attr('spreadMethod', 'pad');
	var timeTakenPct = linspace(0, 100, timeTakenScaleRange.length).map(function(d)
		{
			return Math.round(d) + '%';
		});
	var timeTakenColourPct = d3.zip(timeTakenPct, timeTakenScaleRange);
	timeTakenColourPct.forEach(function(d)
	{
		timeTakenGradient.append('stop')
			.attr('offset', d[0])
			.attr('stop-color', d[1])
			.attr('stop-opacity', 1);
	});
	timeTakenLegend.append('rect')
		.attr('x', -divBounds["width"] / 2)
		.attr('y', (-divBounds["height"] / 2) + ((2 * divBounds["height"]) / 3))
		.attr('width', legendWidth / 4)
		.attr('height', legendHeight)
		.style('fill', 'url(#timeTakenGradient)');
	var timeTakenScaleLegend = d3.scaleLinear()
		.domain([minTimeTaken / 60000, maxTimeTaken / 60000])
		.range([legendHeight, 0]);
	var timeTakenLegendAxis = d3.axisLeft()
		.scale(timeTakenScaleLegend);
	var timeTakenAxisG = timeTakenLegend.append("g")
		.attr("class", "legend axis")
		.attr("transform", "translate(" + ((-divBounds["width"] / 2) + (legendWidth / 4)) + ", " + ((-divBounds["height"] / 2) + ((2 * divBounds["height"]) / 3)) + ")")
		.call(timeTakenLegendAxis);
	timeTakenAxisG.selectAll("text").style("fill", "white");
	timeTakenAxisG.selectAll("line").style("stroke", "white");
	var axisLabel = timeTakenLegend.append("text")
		.attr('x', (-divBounds["width"] / 2) + (legendWidth / 4))
		.attr('y', (-divBounds["height"] / 2) + ((2 * divBounds["height"]) / 3) + (legendHeight / 2))
		.style("dominant-baseline", "text-after-edge")
		.style("writing-mode", "tb")
		.style("text-orientation", "upright")
		.style("text-anchor", "middle")
		.text("Minutes Taken");
	
	for(var entry in finalNodesEdges["links"])
	{
		usedPlaces[finalNodesEdges["links"][entry]["source"]["id"]] = false;
		usedPlaces[finalNodesEdges["links"][entry]["source"]] = false;
	}

	

	var simulation = d3.forceSimulation(finalNodesEdges.nodes)
		.force("link", d3.forceLink(finalNodesEdges.links).id(d => d.id))
		.force("charge", d3.forceManyBody().strength(-250))
		.force("x", d3.forceX())
		.force("y", d3.forceY());
	
	//var link = petriG.append("g")
	//	.selectAll("line")
	//	.data(finalNodesEdges.links)
	//	.enter()
	//	.append("line")
	//	.attr("stroke", "Black")
	//	.attr("stroke-width", "2")
	//	.attr("marker-end", "url(#end)");
	var tooltipG = petriG.append("g");
	var tooltip = tooltipG.append("text").attr("font-size", fontSize);
	var tooltipBg = tooltipG.append("rect");
	
	var curveLink = petriG.append("g")
		.selectAll("path")
		.data(finalNodesEdges.links)
		.enter()
		.append("path")
		.attr('fill', 'none')
		.attr("stroke", "Black")
		.attr("stroke-width", "2")
		.attr("marker-end", "url(#end)");
	
	var node = petriG.append("g")
		.selectAll("circle")
		.data(finalNodesEdges.nodes)
		.enter();
	
	function dragged(d) {
		tooltip.text("")
			.attr("x", 0)
			.attr("y", 0);
		tooltipBg
			.attr("x", 0)
			.attr("y", 0)
			.attr("height", 0)
			.attr("width", 0);
		  if(d["id"] == "-1_place")
		  {
		      return;
		  }
		  d.fx = d3.event.x;
		  d.fy = d3.event.y;
		}

		function dragended(d) {
		  if(d["id"] == "-1_place")
		  {
		      return;
		  }
		  d.fx = d3.event.x;
		  d.fy = d3.event.y;
		  d3.select("#_petriStartNode_")
			.attr("x", -divBounds["width"] / 2)
			.attr("y", 0)
			.attr("cx", -divBounds["width"] / 2)
			.attr("cy", 0);
		  simulation.alphaTarget(0.3).restart();
		}
		
	var curEndNode = 0;
	var numUnused = 0;
	var places = node.filter(d => d.type === "Place")
		.append("circle")
		.attr("r", "10")
		.attr("fill", "red")
		.attr("endpointNum", function(d)
				{
					if(usedPlaces[d["id"]] == true)
					{
						numUnused++;
						return numUnused;
					}
				})
		.attr("cx", function(d)
				{
					if(d["id"] == "-1_place")
					{
						return -divBounds["width"] / 2;
					}
					else if(usedPlaces[d["id"]] == true)
					{
						return divBounds["width"] / 2;
					}
					return 0;
				})
		.attr("cy", function(d)
				{
					if(d["id"] == "-1_place")
					{
						return -divBounds["height"] / 2;
					}
					return 0;
				})
		.attr("fx", function(d)
				{
					if(d["id"] == "-1_place")
					{
						return -divBounds["width"] / 2;
					}
					else if(usedPlaces[d["id"]] == true)
					{
						return divBounds["width"] / 2;
						numUnused++;
					}
					return undefined;
				})
		.attr("fy", function(d)
				{
					if(d["id"] == "-1_place")
					{
						return -divBounds["height"] / 2;
					}
					return undefined;
				})
		.attr("id", function(d)
				{
					if(d["id"] == "-1_place")
					{
						return "_petriStartNode_";
					}
					return undefined;
				})
		.call(d3.drag()
		   .on("drag", dragged)
		   .on("end", dragended));
	
	var transitionWidth = 10;
	var transitionHeight = 20;
	//nestingSizeScale
	var transitions = node.filter(d => d.type === "Transition")
		.append("rect")
		.attr("width", function(d)
				{
					return transitionWidth * nestingSizeScale(d["Target Place"]["Nesting Level"]);
				})
		.attr("height", function(d)
				{
					return transitionHeight * nestingSizeScale(d["Target Place"]["Nesting Level"]);
				})
		.attr("fill", function(d)
				{
					return timeTakenScale(d["Time Taken"]);
				})
		.style("cursor", "pointer")
		.attr("stroke-width", "3px")
		.attr("stroke", function(d)
				{
					return inputScale(d["Target Place"]["Mouse Input"] + d["Target Place"]["Key Input"]);
				})
		.on("mouseenter", function(d, i)
				{
					tooltip.text(d["Target Place"]["TaskName"])
						.attr("x", Number(d3.select(this).attr("x")) + Number(d3.select(this).attr("width")))
						.attr("y", d3.select(this).attr("y"))
						.style("pointer-events", "none")
						.attr("alignment-baseline", "hanging")
						.attr("dominant-baseline", "hanging");
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("User: " + d["Target Place"]["Owning User"]);
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("Session: " + d["Target Place"]["Owning Session"]);
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("Source: " + d["Target Place"]["Source"]);
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("Goal: " + d["Target Place"]["Goal"]);
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("Timestamp: " + d["Target Place"]["Index"]);
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("Key Input: " + d["Target Place"]["Key Input"]);
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("Mouse Input: " + d["Target Place"]["Mouse Input"]);
					
					tooltip.append("tspan")
						.attr("x", tooltip.attr("x"))
						.attr("dy", fontSize)
						.text("Time Taken (Minutes): " + ((d["Target Place"]["Next"]["Index MS"] - d["Target Place"]["Index MS"]) / 60000));
					
					if(d["Target Place"]["Tags"])
					{
						tooltip.append("tspan")
							.attr("x", tooltip.attr("x"))
							.attr("dy", fontSize)
							.text("Tags: " + d["Target Place"]["Tags"].join(", ").substring(0, 50));
					}
					
					tooltipBg.attr("fill", "Yellow")
						.style("pointer-events", "none")
						.attr("x", Number(d3.select(this).attr("x")) + Number(d3.select(this).attr("width")))
						.attr("y", d3.select(this).attr("y"))
						.attr("height", tooltip.node().getBoundingClientRect().height)
						.attr("width", tooltip.node().getBoundingClientRect().width);
					tooltip.raise();
					tooltipG.raise();
				})
		.on("mouseout", function(d, i)
				{
					tooltip.selectAll("*").remove();
					tooltip.text("")
						.attr("x", 0)
						.attr("y", 0);
					tooltipBg
						.attr("x", 0)
						.attr("y", 0)
						.attr("height", 0)
						.attr("width", 0);
				})
		.call(d3.drag()
		   .on("drag", dragged)
		   .on("end", dragended));

	var labels = node//.filter(d => d.type === "Place")
	.append("text")
	.attr("text-anchor", function(d)
			{
				if(d["id"] == "-1_place")
				{
					return "start";
				}
				else if(usedPlaces[d["id"]] == true)
				{
					return "end";
				}
				return "middle";
			})
	.style("text-shadow", "1px 0 0 white, 1px 0 0 white, -1px 0 0 white, -1px 0 0 white")
	.text(function(d)
			{
				if(d["type"] == "Place")
				{
					return d["Place"]["Goal"];
				}
				else
				{
					return d["label"];
				}
			});
	
	node = transitions.merge(places).merge(labels);
	
	simulation.on("tick", () => {
		//link
		//	.attr("x1", d => d.source.x)
		//	.attr("y1", d => d.source.y)
		//	.attr("x2", d => d.target.x)
		//	.attr("y2", d => d.target.y);
		
		curveLink
			.attr("d", function(d)
					{
						var toReturn = [];
						var startPoint = [d.source.x, d.source.y];
						toReturn.push(startPoint);
						
						//This may be handy later when combining multiple petri nets
						//var totalDistance = Math.sqrt(Math.pow((d.target.x - d.source.x), 2) + Math.pow((d.target.y - d.source.y), 2));
						//var finalDistance = .2 * totalDistance;
						//var finalDistance = 25;
						var finalDistance = 0;
						if(d.target.x - d.source.x < 0)
						{
							finalDistance = -finalDistance;
						}
						var xLen = ((d.target.x - d.source.x));
						var yLen = ((d.target.y - d.source.y));
						var yMod = -xLen / (Math.abs(xLen) + Math.abs(yLen));
						var xMod = yLen / (Math.abs(xLen) + Math.abs(yLen));
						if(d.target.y - d.source.y < 0)
						{
							finalDistance = -finalDistance;
						}
						var midPoint = [(finalDistance * xMod) + (d.source.x + d.target.x) / 2, (finalDistance * yMod) + (d.source.y + d.target.y) / 2];
						toReturn.push(midPoint);
						
						var endPoint = [d.target.x, d.target.y];
						toReturn.push(endPoint);
						
						return curve(toReturn);
					})
			.attr("x1", d => d.source.x)
			.attr("y1", d => d.source.y)
			.attr("x2", d => d.target.x)
			.attr("y2", d => d.target.y);

		places
			.attr("cx", d => d.x)
			.attr("fx", function(d)
					{
						if(d["id"] == "-1_place")
						{
							d.x = -divBounds["width"] / 2;
							return -divBounds["width"] / 2;
						}
						else if(usedPlaces[d["id"]] == true)
						{
							d.x = divBounds["width"] / 2;
							return divBounds["width"] / 2;
						}
					})
			.attr("fy", function(d)
					{
						if(d["id"] == "-1_place")
						{
							d.y = 0;
							return 0;
						}
						else if(usedPlaces[d["id"]] == true)
						{
							d.y = ((this.getAttribute("endpointNum") / (numUnused + 1)) * (divBounds["height"])) - (divBounds["height"] / 2);
							return d.y;
						}
					})
			.attr("cy", d => d.y);
		
		transitions
			.attr("x", d => d.x - (transitionWidth / 2))
			.attr("y", d => d.y - (transitionHeight / 2));
		
		labels
			.attr("x", d => d.x - (transitionWidth / 2))
			.attr("y", d => d.y - (transitionHeight / 2));
	});
	
	d3.select("#_petriStartNode_")
		.attr("fx", -divBounds["width"] / 2)
		.attr("cx", -divBounds["width"] / 2)
		.attr("fy", 0)
		.attr("cy", 0);
	
}