//This code builds and visualizes petri nets from selected tasks.

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

async function petriToGraph(analyzedTasks)
{
	var toReturn = {};
	toReturn["nodes"] = [];
	toReturn["links"] = [];
	
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

async function analyzeTaskMap(curTask)
{
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
	console.log("Analyzing:");
	console.log(curParent["TaskName"]);
	//For all children except the first, their predecessor is the
	//first child before them that is not concurrent to them.
	
	//If there is no previous child, then the predecessor is
	//the predecessor for the parent.  We will assign this at
	//the end from this list.
	var predlessChildren = [];
	
	//We also keep track of children that have been used as
	//predecessors so that at the end we can determine which
	//ones are not used and thus are predecessor to the parent.
	var usedChildren = {};
	
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
				if(curConcurrent.indexOf(curChildren[y]) == -1)
				{
					//The previous child is not concurrent to the
					//current child we are getting pred for.  We
					//assign it as pred and continue.
					curChild["Predecessor"] = [curChildren[y]];
					usedChildren[curChildren[y]] = true;
					foundPred = true;
					break;
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
	console.log("Predless children:");
	console.log(predlessChildren);
	for(entry in predlessChildren)
	{
		predlessChildren[entry]["Predecessor"] = curTask["Predecessor"];
	}
	
	//The predecessor to the parent task are all of the children that are
	//not predecessor to anything else.
	newPredList = [];
	for(entry in curChildren)
	{
		if(usedChildren[curChildren[entry]])
		{
			
		}
		else
		{
			newPredList.push(curChildren[entry]);
		}
	}
	console.log("Pred list for parent:");
	console.log(newPredList);
	if(newPredList.length > 0)
	{
		curTask["Predecessor"] = newPredList;
	}
	
	//Now we run this same algorithm on all children.
	for(var x = curChildren.length - 1; x >= 0; x--)
	{
		var curChild = curChildren[x];
		analyzeTaskMap(curChild);
	}
	
	console.log("Returning task:")
	console.log(curTask)
	
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
		var alreadyIn = false;
		var curSession = sessionTasks[sessions[entry]];
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

	for(var entry in finalAttackGraphs)
	{
		for(place in finalAttackGraphs[entry]["nodes"])
		{
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
	
	var link = petriG.append("g")
		.selectAll("line")
		.data(finalNodesEdges.links)
		.enter()
		.append("line")
		.attr("stroke", "Black")
		.attr("stroke-width", "2")
		.attr("marker-end", "url(#end)");
	
	var node = petriG.append("g")
		.selectAll("circle")
		.data(finalNodesEdges.nodes)
		.enter();
	
	function dragged(d) {
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
	var transitions = node.filter(d => d.type === "Transition")
		.append("rect")
		.attr("width", transitionWidth)
		.attr("height", transitionHeight)
		.attr("fill", "blue");

	var labels = node.filter(d => d.type === "Place")
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
	.text(function(d)
			{
				return d["Place"]["TaskName"];
			});
	
	node = transitions.merge(places).merge(labels);
	
	simulation.on("tick", () => {
		link
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