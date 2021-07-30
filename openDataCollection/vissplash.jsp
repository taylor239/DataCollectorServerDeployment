<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" import="java.util.ArrayList, java.util.HashMap, com.datacollector.*, java.sql.*"%>
<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" type="text/css" href="Design.css">
<script src="./sha_func.js"></script>
<script src="./clonedeep.js"></script>
<script src="./pathFunctions.js"></script>
<script src="./d3.v4.min.js"></script>
<script src="./d3-scale-chromatic.v0.3.min.js"></script>
<meta charset="UTF-8">
<title>Data Collection Visualization</title>
</head>
<%
Class.forName("com.mysql.jdbc.Driver");
DatabaseConnector myConnector=(DatabaseConnector)session.getAttribute("connector");
if(myConnector==null)
{
	myConnector=new DatabaseConnector(getServletContext());
	session.setAttribute("connector", myConnector);
}
TestingConnectionSource myConnectionSource = myConnector.getConnectionSource();

String eventName = request.getParameter("event");

String eventPassword = request.getParameter("eventPassword");

if(eventPassword != null)
{
	session.setAttribute("eventPassword", eventPassword);
}

String eventAdmin = request.getParameter("eventAdmin");

if(eventAdmin != null)
{
	session.setAttribute("eventAdmin", eventAdmin);
}


if(request.getParameter("email") != null)
{
	session.removeAttribute("admin");
	session.removeAttribute("adminName");
	String adminEmail = request.getParameter("email");
	if(request.getParameter("password") != null)
	{
		String password = request.getParameter("password");
		
		String loginQuery = "SELECT * FROM `openDataCollectionServer`.`Admin` WHERE `adminEmail` = ? AND `adminPassword` = ?";
		
		Connection dbConn = myConnectionSource.getDatabaseConnection();
		try
		{
			PreparedStatement queryStmt = dbConn.prepareStatement(loginQuery);
			queryStmt.setString(1, adminEmail);
			queryStmt.setString(2, password);
			ResultSet myResults = queryStmt.executeQuery();
			if(myResults.next())
			{
				session.setAttribute("admin", myResults.getString("adminEmail"));
				session.setAttribute("adminName", myResults.getString("name"));
			}
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	}
}

%>
<body>
<table id="bodyTable">
	<tr>
		<td class="layoutTableCenter centerCol" id="mainVisContainer">
			<table style="overflow-x:auto" id="visTable">
				<tr>
					<td>
						<div align="center" id="title">User and Session Selection for <%=eventName %> Visualization</div>
					</td>
				</tr>
				<tr>
					<td id="visRow">
						<div align="center" id="mainVisualization">
						<table id="searchTable">
							<tr>
								<td colspan="11">
									<div align="center">User and Session Search Table</div>
								</td>
							</tr>
							<tr>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> <b>User Name</b>
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> <b>Session Name</b>
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> Start Date
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> End Date
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> Tasks
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> Active Windows
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> Processes
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> Screenshot Text
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> Environment
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> Notes
								</td>
								<td class="searchCol">
									Select
								</td>
							</tr>
							<tr>
								<td colspan="11">
									<div align="center"><input type="button" value="Refresh Search" onclick="refreshSearch()"><input type="button" value="Visualize Selected" onclick="visualize()"></div>
								</td>
							</tr>
							<tr>
								<td>
									<input class="searchField" type="text" id="userField">
								</td>
								<td>
									<input class="searchField" type="text" id="sessionField">
								</td>
								<td>
									<input class="searchField" type="text" id="startDateField">
								</td>
								<td>
									<input class="searchField" type="text" id="endDateField">
								</td>
								<td>
									<input class="searchField" type="text" id="tasksField">
								</td>
								<td>
									<input class="searchField" type="text" id="windowField">
								</td>
								<td>
									<input class="searchField" type="text" id="processField">
								</td>
								<td>
									<input class="searchField" type="text" id="screenshotField">
								</td>
								<td>
									<input class="searchField" type="text" id="environmentField">
								</td>
								<td>
									<input class="searchField" type="text" id="noteField">
								</td>
								<td>
									
								</td>
							</tr>
						</table>
						</div>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
</body>


<style>

.searchCol
{
	width: 9.1%
}
.searchField
{
	width: 100%
}

.expandPlus
{
	cursor:pointer;
}

.expandPlus:hover
{
	color: blue;
	text-shadow:0px 0px 5px blue;
	-moz-transition: all 0.2s ease-in;
	-o-transition: all 0.2s ease-in;
	-webkit-transition: all 0.2s ease-in;
	transition: all 0.2s ease-in;
}

.popimage
{
	
}

.black_overlay
{
	transition:300ms linear;
	display: none;
	position: absolute;
	top: 0%;
	left: 0%;
	width: 100%;
	height: 100%;
	background-color: black;
	z-index:1001;
	opacity:0;
	cursor:pointer;
}

.black_highlight
{
	transition:300ms linear;
	position: absolute;
	top: 0%;
	left: 0%;
	width: 100%;
	height: 100%;
	z-index:1001;
	cursor:pointer;
}
 
.white_content
{
	transition:300ms linear;
	border-radius:10px;
	display: none;
	position: absolute;
	top: 2.5%;
	left: 5%;
	width: 90%;
	height: 95%;
	max-height:95%;
	padding: 2px;
	border: 4px solid #000;
	background-color: white;
	z-index:1002;
	overflow: auto;
	text-align:center;
	opacity:0;
	vertical-align:middle;
}

.white_dim
{
	transition:300ms linear;
	border-radius:10px;
	display: block;
	padding: 2px;
	border: 4px solid #000;
	background-color: white;
	z-index:1002;
	overflow: auto;
	text-align:justify;
	cursor:pointer;
	opacity:0;
	vertical-align:middle;
}

.white_content td
{
	text-align:center;
	vertical-align:middle;
}

</style>

<script>

var curToggledCol;

var defaultNumCols;

function toggleCol(colToExpand)
{
	let curTable = document.getElementById("searchTable");
	let curRows = curTable.rows;
	
	if(!defaultNumCols)
	{
		defaultNumCols = curRows[0].cells[0].colSpan;
	}
	
	if(curToggledCol)
	{
		curToggledCol.innerHTML = "➕";
	}
	if(curToggledCol == colToExpand)
	{
		
		curToggledCol = undefined;
	}
	else
	{
		curToggledCol = colToExpand;
		curToggledCol.innerHTML = "➖";
	}
	
	var cols = document.getElementsByClassName("searchCol");
	for(var i = 0; i < cols.length; i++)
	{
		let curCol = cols.item(i);
		if(curToggledCol && curCol == curToggledCol.parentElement)
		{
			curCol.style.width = "100%";
			curCol.style.display = "";
		}
		else
		{
			if(curToggledCol)
			{
				curCol.style.width = "0%";
				curCol.style.display = "none";
			}
			else
			{
				curCol.style.width = "";
				curCol.style.display = "";
			}
		}
	}
	
	
	if(curToggledCol)
	{
		let toggledColNum = curToggledCol.parentElement.cellIndex;
		
		curRows[0].cells[0].colSpan = 1;
		curRows[2].cells[0].colSpan = 1;
		
		for(var x = 3; x < curRows.length; x++)
		{
			let curCells = curRows[x].cells;
			for(var y = 0; y < curCells.length; y++)
			{
				if(y != toggledColNum)
				{
					curCells[y].style.width = "0%";
					curCells[y].style.display = "none";
				}
				else
				{
					curCells[y].style.width = "100%";
					curCells[y].style.display = "";
				}
			}
		}
	}
	else
	{
		curRows[0].cells[0].colSpan = defaultNumCols;
		curRows[2].cells[0].colSpan = defaultNumCols;
		
		for(var x = 3; x < curRows.length; x++)
		{
			let curCells = curRows[x].cells;
			for(var y = 0; y < curCells.length; y++)
			{
				curCells[y].style.width = "";
				curCells[y].style.display = "";
			}
		}
	}
	
}

function getFullWidth() {
	  return Math.max(
		document.body.scrollWidth,
		document.documentElement.scrollWidth,
		document.body.offsetWidth,
		document.documentElement.offsetWidth,
		document.documentElement.clientWidth
	  );
	}

	function getFullHeight() {
	  return Math.max(
		document.body.scrollHeight,
		document.documentElement.scrollHeight,
		document.body.offsetHeight,
		document.documentElement.offsetHeight,
		document.documentElement.clientHeight
	  );
	}



function dimBackground(toHighlight, captionText, nextFunction)
{
	
	curFunction = nextFunction;
	
	var totalWidth = getFullWidth();
	var totalHeight = getFullHeight();
	
	
	var eleX = Math.round(toHighlight.getBoundingClientRect()["x"]);
	var eleY = Math.round(toHighlight.getBoundingClientRect()["y"]);
	var eleWidth = Math.round(toHighlight.getBoundingClientRect()["width"]);
	var eleHeight = Math.round(toHighlight.getBoundingClientRect()["height"]);
	
	var surroundingRects = [];
	
	var leftRect = {x: 0, y: 0, width: eleX, height: totalHeight};
	var topRect = {x: eleX, y:0, width: eleWidth, height: eleY};
	var bottomRect = {x: eleX, y: eleY + eleHeight, width: eleWidth, height: totalHeight - (eleY + eleHeight)};
	var rightRect = {x: eleX + eleWidth, y: 0, width: totalWidth - (eleX + eleWidth), height: totalHeight};
	surroundingRects.push(leftRect);
	surroundingRects.push(topRect);
	surroundingRects.push(bottomRect);
	surroundingRects.push(rightRect);
	
	
	var newBlackDiv=document.createElement('div');
	newBlackDiv.className="black_highlight";
	//newBlackDiv.style.position = "absolute";
	//newBlackDiv.style.display = "block";
	//newBlackDiv.style.width = totalWidth + "px";
	//newBlackDiv.style.height = totalHeight + "px";
	newBlackDiv.id="fade";
	document.body.appendChild(newBlackDiv);
	newBlackDiv.onclick=undimBackground;
	newBlackDiv.style.opacity=0;
	
	var dimSVG = d3.select(newBlackDiv).append("svg")
	dimSVG.attr("width", "100%")
		.attr("height", "100%")
		.selectAll("rect")
		.data(surroundingRects)
		.enter()
		.append("rect")
		.attr("x", function(d, i)
				{
					return d["x"];
				})
		.attr("y", function(d, i)
				{
					return d["y"];
				})
		.attr("width", function(d, i)
				{
					return d["width"];
				})
		.attr("height", function(d, i)
				{
					return d["height"];
				})
		.attr("fill", "Black")
		.attr("opacity", ".8")
		.on("click", "undimBackground()");
	
	dimSVG.append("text")
		.attr("fill", "white")
		.text("Click anywhere to continue.")
		.attr("alignment-baseline", "hanging")
		.attr("dominant-baseline", "hanging")
		.attr("text-anchor", "middle")
		.attr("x", "50%")
		.attr("y", "1%");
	
	var minWidth = totalWidth * .15;
	if(eleWidth > minWidth)
	{
		minWidth = eleWidth;
	}
	
	if(captionText)
	{
		var box = document.createElement('span');
		box.style.position = 'absolute'; 
		box.style.left = eleX + "px";
		box.style.right = (totalWidth - (eleX + minWidth)) + "px";
		if((eleY + eleHeight) > (totalHeight * .75))
		{
			
			box.style.bottom = (totalHeight - eleY) + "px";
		}
		else
		{
			box.style.top = (eleY + eleHeight) + "px";
			
		}
		box.className="white_dim";
		box.id="light";
		box.onclick=undimBackground;
		box.innerHTML=captionText;
		document.body.appendChild(box);
	}
	
	dimTimeout=setTimeout("fadeInDim();", 1);
}

function fadeInDim()
{
	var oldBlackDiv=document.getElementById('fade');
	oldBlackDiv.style.opacity=.8;
	var oldWhiteDiv=document.getElementById('light');
	oldWhiteDiv.style.opacity=1;
}

function undimBackground()
{
	clearTimeout(lightBoxTimeout);
	
	var oldBlackDiv=document.getElementById('fade');
	oldBlackDiv.style.opacity=0;
	var oldWhiteDiv=document.getElementById('light');
	if(oldWhiteDiv)
	{
		oldWhiteDiv.style.opacity=0;
	}
	
	lightBoxTimeout=setTimeout("fadeOutDim();", 300);
}

function fadeOutDim()
{
	var oldBlackDiv=document.getElementById('fade');
	oldBlackDiv.display="none";
	
	var oldWhiteDiv=document.getElementById('light');
	if(oldWhiteDiv)
	{
		oldWhiteDiv.display="none";
		document.body.removeChild(oldWhiteDiv);
	}
	
	document.body.removeChild(oldBlackDiv);
	
	if(curFunction)
	{
		curFunction();
	}
}

var lightBoxTimeout;

async function showLightbox(theHTML)
{
	clearTimeout(lightBoxTimeout);
	
	var newWhiteDiv=document.createElement('table');
	newWhiteDiv.className="white_content";
	newWhiteDiv.id="light";
	newWhiteDiv.innerHTML=theHTML;
	
	var newBlackDiv=document.createElement('table');
	newBlackDiv.className="black_overlay";
	newBlackDiv.id="fade";
	
	document.body.appendChild(newWhiteDiv);
	document.body.appendChild(newBlackDiv);
	
	newWhiteDiv.style.display='table';
	newBlackDiv.style.display='table';
	
	//newWhiteDiv.onclick=unshowLightbox;
	newBlackDiv.onclick=unshowLightbox;
	
	newWhiteDiv.style.opacity=0;
	newBlackDiv.style.opacity=0;
	lightBoxTimeout=setTimeout("fadeInLightbox();", 1);
}

function fadeInLightbox()
{
	var oldWhiteDiv=document.getElementById('light');
	oldWhiteDiv.style.opacity=1;
	
	var oldBlackDiv=document.getElementById('fade');
	oldBlackDiv.style.opacity=.8;
}

function unshowLightbox()
{
	clearTimeout(animationTimeout);
	clearTimeout(lightBoxTimeout);
	
	var oldWhiteDiv=document.getElementById('light');
	oldWhiteDiv.style.opacity=0;
	
	var oldBlackDiv=document.getElementById('fade');
	oldBlackDiv.style.opacity=0;
	
	lightBoxTimeout=setTimeout("fadeOutLightbox();", 300);
}

function fadeOutLightbox()
{
	var oldWhiteDiv=document.getElementById('light');
	oldWhiteDiv.display="none";
	
	var oldBlackDiv=document.getElementById('fade');
	oldBlackDiv.display="none";
	
	document.body.removeChild(oldWhiteDiv);
	document.body.removeChild(oldBlackDiv);
}

</script>


<script>

	var visWidth = window.innerWidth;
	var visHeight = window.innerHeight;
	var barHeight = visHeight / 10;
	var xAxisPadding = 3 * barHeight;
	
	var eventName = "<%=eventName %>";
	var adminName = "<%=request.getParameter("email") %>";
	var eventAdmin = "<%=eventAdmin %>";
	
	var lookupTable = {};
	var windowColorNumber = {};
	var curWindowNum = 0;
	var windowLegend = [];
	
	async function preprocess(dataToModify)
	{
		processMap = {};
		lookupTable = {};
		userOrderMap = {};
		
		totalSessions = 0;
		for(user in dataToModify)
		{
			aggregateSession = {}
			listsToAdd = {}
			newSession = {}
			for(session in dataToModify[user])
			{
				if(Object.keys(dataToModify[user][session]).length < 3)
				{
					delete dataToModify[user][session];
					continue;
				}
				
				totalSessions++;
				
				for(entry in dataToModify[user][session]["screenshots"])
				{
					var hashVal = SHA256(user + session + dataToModify[user][session]["screenshots"][entry]["Index MS"]);
					dataToModify[user][session]["screenshots"][entry]["ImageHash"] = hashVal;
				}
				
				var hashValDownload = SHA256(user + session + "_download");
				
				if(dataToModify[user][session]["windows"])
				{
					var activeWindows = [];
					for(curWindow in dataToModify[user][session]["windows"])
					{
						
						if(dataToModify[user][session]["windows"][curWindow]["Active"] == "1")
						{
							activeWindows.push(dataToModify[user][session]["windows"][curWindow]);
						}
					}
					dataToModify[user][session]["allWindows"] = dataToModify[user][session]["windows"];
					dataToModify[user][session]["windows"] = activeWindows;
				}
				
				for(data in dataToModify[user][session])
				{
					if(!(data in listsToAdd))
					{
						listsToAdd[data] = [];
					}
					listsToAdd[data].push(dataToModify[user][session][data]);
					for(entry in dataToModify[user][session][data])
					{
						dataToModify[user][session][data][entry]["Original Session"] = session;
					}
				}
			}
			listsToAdd = JSON.parse(JSON.stringify(listsToAdd));
			for(data in listsToAdd)
			{
				newDataList = [];
				if(listsToAdd[data] == null)
				{
					listsToAdd[data] = [];
				}
				listsToAdd[data] = listsToAdd[data].sort(function(a, b)
							{
								return a[0]["Index MS User"] - b[0]["Index MS User"];
							});
				for(curList in listsToAdd[data])
				{
					newDataList = newDataList.concat(listsToAdd[data][curList]);
				}
				newDataList = newDataList.sort(function(a, b)
						{
							return a["Index MS User"] - b["Index MS User"];
						});
				for(element in newDataList)
				{
					newDataList[element]["Index MS Session"] = newDataList[element]["Index MS User"];
				}
				newSession[data] = newDataList;
			}
			dataToModify[user]["Aggregated"] = newSession;
		}
		
		var theNormData = dataToModify;
		
		for(user in theNormData)
		{
			sessionOrderMap = {};
			maxTimeUser = 0;
			minTimeUser = Number.POSITIVE_INFINITY;
			minTimeUserAbsolute = Number.POSITIVE_INFINITY;
			maxTimeUserDate = "";
			minTimeUserDate = "";
			minTimeUserUniversal = Number.POSITIVE_INFINITY;
			for(session in theNormData[user])
			{
				//console.log("Doing session " + session);
				maxTimeSession = 0;
				minTimeSession = Number.POSITIVE_INFINITY;
				minTimeUserSession = Number.POSITIVE_INFINITY;
				maxTimeSessionDate = "";
				minTimeSessionDate = "";
				theCurData = theNormData[user][session];
				for(dataType in theCurData)
				{
					//console.log("Doing data: " + dataType);
					thisData = theCurData[dataType];
					
					if(!(user in lookupTable))
					{
						//console.log("Adding to lookup table: " + user)
						lookupTable[user] = {};
					}
					if(!(session in lookupTable[user]))
					{
						//console.log("Adding to lookup table: " + session)
						lookupTable[user][session] = {};
					}
					
					var isAsync = false;
					
					if(thisData["data"] && (typeof thisData["data"]) == "function")
					{
						thisData = (await thisData["getfiltered"]());
						if(!thisData)
						{
							console.log("No data for " + user + ":" + session + ":" + dataType)
							continue;
						}
						thisData = thisData.value;
						isAsync = true;
					}
					
					if(!thisData)
					{
						console.log("No data for " + user + ":" + session + ":" + dataType)
						continue;
					}
					
					var curUserSessionMap;
					if(dataType == "processes")
					{
						var curLookupTable = {};
						if(!("Processes" in lookupTable[user][session]))
						{
							lookupTable[user][session]["Processes"] = {};
							lookupTable[user][session]["Processes"]["data"] = getProcessLookupData;
							lookupTable[user][session]["Processes"]["storedata"] = storeProcessDataLookup;
							await lookupTable[user][session]["Processes"]["storedata"](curLookupTable);
						}
						curLookupTable = (await (lookupTable[user][session]["Processes"]["data"]())).value;
						
						if(!(user in processMap))
						{
							processMap[user] = {};
						}
						//console.log("Checking proc map for " + session);
						if(!(session in processMap[user]))
						{
							//console.log("Adding proc map for " + session);
							//processMap[user][session] = {};
							var processMapDataObject = {};
							processMapDataObject["user"] = user;
							processMapDataObject["session"] = session;
							processMapDataObject["data"] = getProcessMapData;
							processMapDataObject["storedata"] = storeProcessDataMap;
							//console.log("Storing")
							//console.log(processMapDataObject)
							//console.log(processMap);
							await processMapDataObject["storedata"]({});
							processMap[user][session] = processMapDataObject;
						}
						//console.log("Getting proc map");
						curUserSessionMap = (await (processMap[user][session]["data"]())).value;
						//console.log("Got");
						//console.log(curUserSessionMap);
					}
					
					for(x=0; x<thisData.length; x++)
					{
						
						if(dataType == "windows")
						{
							if(!(thisData[x]["FirstClass"] in windowColorNumber))
							{
								windowColorNumber[thisData[x]["FirstClass"]] = curWindowNum % 20;
								curWindowNum++;
								windowLegend.push(thisData[x]["FirstClass"])
							}
						}
						
						if(dataType == "processes")
						{
							
							
							thisData[x]["Owning User"] = user;
							thisData[x]["Owning Session"] = session;
							thisData[x]["Hash"] = SHA256(thisData[x]["User"] + thisData[x]["Start"] + thisData[x]["PID"])
							
							
							curLookupTable[thisData[x]["Hash"]] = thisData[x];
							//lookupTable[user][session]["Processes"][thisData[x]["Hash"]] = thisData[x];
							
							
							
							
							curPid = thisData[x]["PID"]
							curOSUser = thisData[x]["User"]
							curStart = thisData[x]["Start"]
							thisData[x]["CPU"] = Number(thisData[x]["CPU"])
							curCPU = thisData[x]["CPU"]
							thisData[x]["Mem"] = Number(thisData[x]["Mem"])
							curMem = thisData[x]["Mem"]
							
							if(!(curOSUser in curUserSessionMap))
							{
								curUserSessionMap[curOSUser] = {};
							}
							if(!(curStart in curUserSessionMap[curOSUser]))
							{
								curUserSessionMap[curOSUser][curStart] = {};
							}
							if(!(curPid in curUserSessionMap[curOSUser][curStart]))
							{
								thisData[x]["Aggregate CPU"] = curCPU
								thisData[x]["Aggregate Mem"] = curMem
								curUserSessionMap[curOSUser][curStart][curPid] = [];
								curUserSessionMap[curOSUser][curStart][curPid].push(thisData[x]);
							}
							else
							{
								curList = curUserSessionMap[curOSUser][curStart][curPid];
								thisData[x]["Aggregate CPU"] = curCPU + curList[curList.length - 1]["Aggregate CPU"]
								thisData[x]["Aggregate Mem"] = curMem + curList[curList.length - 1]["Aggregate Mem"]
								thisData[x]["Prev"] = curList[curList.length - 1];
								curList[curList.length - 1]["Next"] = thisData[x];
								curList.push(thisData[x]);
							}
							
						}
						
						thisData[x]["Index MS Universal"] = Number(thisData[x]["Index MS Universal"]);
						thisData[x]["Index MS"] = Number(thisData[x]["Index MS"]);
						thisData[x]["Index MS User"] = Number(thisData[x]["Index MS User"]);
						thisData[x]["Index MS Session"] = Number(thisData[x]["Index MS Session"]);
					}
					
					if(dataType == "processes")
					{
						if(curUserSessionMap)
						{
							console.log(user + ": " + session);
							console.log(curUserSessionMap);
							await processMap[user][session]["storedata"](curUserSessionMap);
						}
						await lookupTable[user][session]["Processes"]["storedata"](curLookupTable);
					}
					
					if(thisData.length > 0 && !(dataType == "environment"))
					{
						lastTimeSession = thisData[thisData.length - 1]["Index MS Session"];
						lastTimeUser = thisData[thisData.length - 1]["Index MS User"];
						lastTimeDate = thisData[thisData.length - 1]["Index"];
						firstTimeSession = thisData[0]["Index MS Session"];
						firstTimeUser = thisData[0]["Index MS User"];
						firstTimeUserAbsolute = thisData[0]["Index MS"];
						firstTimeDate = thisData[0]["Index"];
						
						if(lastTimeSession > maxTimeSession)
						{
							maxTimeSession = lastTimeSession;
							maxTimeSessionDate = lastTimeDate;
						}
						if(firstTimeSession < minTimeSession)
						{
							minTimeSession = firstTimeSession;
							minTimeSessionDate = firstTimeDate;
						}
						if(firstTimeUser < minTimeUserSession)
						{
							minTimeUserSession = firstTimeUser;
						}
						if(lastTimeUser > maxTimeUser)
						{
							maxTimeUser = lastTimeUser;
							maxTimeUserDate = lastTimeDate;
						}
						if(firstTimeUser < minTimeUser)
						{
							minTimeUser = firstTimeUser;
							minTimeUserAbsolute = firstTimeUserAbsolute;
							minTimeUserDate = firstTimeDate;
							
						}
						firstTimeUniversal = thisData[0]["Index MS Universal"];
						if(firstTimeUniversal < minTimeUserUniversal)
						{
							minTimeUserUniversal = firstTimeUniversal;
						}
					}
					
					if(isAsync)
					{
						await theCurData[dataType]["storefiltered"](thisData);
					}
					
				}
				theCurData["Index MS Session Max"] = maxTimeSession;
				theCurData["Index MS Session Min"] = minTimeSession;
				theCurData["Index MS Session Max Date"] = maxTimeSessionDate;
				theCurData["Index MS Session Min Date"] = minTimeSessionDate;
				
				theCurData["Index MS User Session Min"] = minTimeUserSession;
				
				theCurData["Time Adjustment"] = 0;
				if(session == "Aggregated")
				{
					theCurData["Time Adjustment"] = theCurData["Time Adjustment"] - 1;
					minTimeUserSession = -1;
				}
				while(minTimeUserSession in sessionOrderMap)
				{
					if(session == "Aggregated")
					{
						theCurData["Time Adjustment"] = theCurData["Time Adjustment"] - 1;
						minTimeUserSession--;
					}
					else
					{
						theCurData["Time Adjustment"] = theCurData["Time Adjustment"] + 1;
						minTimeUserSession++;
					}
				}
				
				sessionOrderMap[minTimeUserSession] = session;
				
				timeScale = d3.scaleLinear();
				timeScale.domain
							(
								[0, maxTimeSession]
							)
				timeScale.range
							(
								[0, visWidth - xAxisPadding]
							);
				theCurData["Time Scale"] = timeScale;
			}
			
			theNormData[user]["Index MS Universal Min"] = minTimeUserUniversal;
			userOrderMap[minTimeUserUniversal] = user;
			
			sessionOrderArray = Object.keys(sessionOrderMap).sort(function(a, b) {return a - b;});
			sessionOrderMap["Order List"] = sessionOrderArray;
			theNormData[user]["Session Ordering"] = sessionOrderMap;
			
			theNormData[user]["Index MS User Max"] = maxTimeUser;
			theNormData[user]["Index MS User Min"] = minTimeUser;
			theNormData[user]["Index MS User Max Date"] = maxTimeUserDate;
			theNormData[user]["Index MS User Min Date"] = minTimeUserDate;
			theNormData[user]["Index MS User Min Absolute"] = minTimeUserAbsolute;
			
			timeScale = d3.scaleLinear();
			timeScale.domain
						(
							[0, maxTimeUser]
						)
			timeScale.range
						(
							[0, visWidth - xAxisPadding]
						);
			theNormData[user]["Time Scale"] = timeScale;
		}
		userOrderArray = Object.keys(userOrderMap).sort(function(a, b) {return a - b;});
		userOrderMap["Order List"] = userOrderArray;
		
		return dataToModify;
	}
	
	
	
	var theNormData;
	var theNormDataClone;
	var theNormDataDone = false;
	var origTitle = d3.select("#title").text();
	
			
	var db;
	var objectStore;
	
	var curQueue = [];
	
	var persistWriting = false;
	
	
	
	async function persistData(key, value)
	{
		var args = {};
		args["key"] = key;
		args["value"] = value;
		//console.log(args);
		curQueue.push(args);
		//console.log(curQueue);
		if(!persistWriting)
		{
			writePersist();
		}
		return new Promise(async function (resolve, reject)
		{
			resolve(true);
		})
	}
	
	async function writePersist()
	{
		var myReturn = false;
		persistWriting = true;
		console.log("Starting write worker");
		curWrite = curQueue.pop();
		while(curWrite)
		{
			d3.select("body").style("cursor", "wait");
			//console.log(curWrite);
			myReturn = await wrappedPersistData(curWrite["key"], curWrite["value"]);
			curWrite = curQueue.pop();
		}
		persistWriting = false;
		d3.select("body").style("cursor", "");
		return(myReturn);
	}
	
	function sleep(ms)
	{
		return new Promise(resolve => setTimeout(resolve, ms));
	}
	
	async function persistDataAndWait(key, value)
	{
		var args = {};
		args["key"] = key;
		args["value"] = value;
		//console.log(args);
		curQueue.push(args);
		//console.log(curQueue);
		var myReturn = await writePersist();
		
		
		//if(curQueue.length > 0)
		//{
		//	console.log("Waiting on write...")
		//	console.log(curQueue.length);
		//	console.log(curQueue[0]);
		//	await sleep(150000);
		//}
		return new Promise(async function (resolve, reject)
		{
			resolve(myReturn);
		})
	}
	
	Function.prototype.clone = function() {
	var that = this;
	var temp = function temporary() { return that.apply(this, arguments); };
	for(var key in this) {
		if (this.hasOwnProperty(key)) {
			temp[key] = this[key];
		}
	}
	return temp;
	};
	
	var blockingPersist = false;
	//async function persistData(key, value)
	//{
	//	return await toClonePersistData.clone()(key, value);
	//}
	
	async function wrappedPersistData(key, value)
	{
		// In the following line, you should include the prefixes of implementations you want to test.
		window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
		// DON'T use "var indexedDB = ..." if you're not in a function.
		// Moreover, you may need references to some window.IDB* objects:
		window.IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || window.msIDBTransaction || {READ_WRITE: "readwrite"}; // This line should only be needed if it is needed to support the object's constants for older browsers
		window.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange || window.msIDBKeyRange;
		
		return new Promise(async function (resolve, reject)
		{
			if(!db)
			{
				var request = window.indexedDB.open("LocalStore", 4);
				request.onerror = function(event)
				{
					// Do something with request.errorCode!
					console.log(request.errorCode);
					return;
				};
				request.onupgradeneeded = function(event)
				{
					db = event.target.result;
					if (!db.objectStoreNames.contains("objects"))
					{
						objectStore = db.createObjectStore("objects", { keyPath: "key" });
					}
				};
				request.onsuccess = async function(event)
				{
					db = event.target.result;
					try
					{
						var theReturn = await (nestedStoreData(key, value));
						resolve(theReturn);
					}
					catch(err)
					{
						console.log(err);
						reject(err);
					}
				}
			}
			else
			{
				try
				{
					var theReturn = await (nestedStoreData(key, value));
					resolve(theReturn);
				}
				catch(err)
				{
					reject(err);
				}
			}
		})
	}
	async function nestedStoreData(key, value)
	{
		return new Promise(function (resolve, reject)
		{
			var transaction = db.transaction(["objects"], "readwrite");
			transaction.oncomplete = function(event)
			{
				//console.log("All done!");
				resolve(true);
			};
	
			transaction.onerror = function(event)
			{
				reject(event);
			};
			objectStore = transaction.objectStore("objects");
			
			var toPersist = {};
			toPersist["key"] = key;
			toPersist["value"] = value;
			//console.log("Storing " + key);
			//console.log(value);
			var request = objectStore.put(toPersist);
		})
	}
	
	async function retrieveData(key)
	{
		d3.select("body").style("cursor", "wait");
		var toReturn = await retrieveDataWrapper(key);
		d3.select("body").style("cursor", "");
		return toReturn;
	}
	
	async function hasData(key)
	{
		d3.select("body").style("cursor", "wait");
		var toReturn = await nestedCountData(key);
		//console.log("Count " + toReturn);
		d3.select("body").style("cursor", "");
		if(toReturn > 0)
		{
			return true;
		}
		return false;
	}
	
	async function retrieveDataWrapper(key)
	{
		try
		{
			var value = await nestedRetrieveData(key);
			//console.log(value);
			
			return await value;
		}
		catch (err)
		{
			console.log(err);
		}
	}
	
	async function nestedRetrieveData(key)
	{
		// In the following line, you should include the prefixes of implementations you want to test.
		window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
		// DON'T use "var indexedDB = ..." if you're not in a function.
		// Moreover, you may need references to some window.IDB* objects:
		window.IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || window.msIDBTransaction || {READ_WRITE: "readwrite"}; // This line should only be needed if it is needed to support the object's constants for older browsers
		window.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange || window.msIDBKeyRange;
		
		if(!db)
		{
			
		}
		else
		{
			return new Promise(function (resolve, reject)
			{
				var transaction = db.transaction(["objects"]);
				var objectStore = transaction.objectStore("objects");
				var request = objectStore.get(key);
				request.onerror = function(event)
				{
					reject(event);
				};
				request.onsuccess = function(event)
				{
					resolve(event.target.result);
				};
			})
			
		}
		
		
	}
	
	async function nestedCountData(key)
	{
		// In the following line, you should include the prefixes of implementations you want to test.
		window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
		// DON'T use "var indexedDB = ..." if you're not in a function.
		// Moreover, you may need references to some window.IDB* objects:
		window.IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || window.msIDBTransaction || {READ_WRITE: "readwrite"}; // This line should only be needed if it is needed to support the object's constants for older browsers
		window.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange || window.msIDBKeyRange;
		
		if(!db)
		{
			
		}
		else
		{
			return new Promise(function (resolve, reject)
			{
				var transaction = db.transaction(["objects"]);
				var objectStore = transaction.objectStore("objects");
				var request = objectStore.count(key);
				request.onerror = function(event)
				{
					reject(event);
				};
				request.onsuccess = function(event)
				{
					resolve(event.target.result);
				};
			})
			
		}
		
		
	}
	
	
	
	var usersToQuery = [];
	var sessionsToQuery = [];
	var autoDownload = false;
	
	function processParameters()
	{
		var theUrl = window.location.href;
		var url = new URL(theUrl);
		var usersString = url.searchParams.get("users");
		if(usersString)
		{
			usersToQuery = usersString.split(",");
		}
		var sessionsString = url.searchParams.get("sessions");
		if(sessionsString)
		{
			sessionsToQuery = sessionsString.split(",");
		}
		autoDownload = (url.searchParams.get("autodownload") == "true");
	}
	
	var searchTerms = [];
	
	async function downloadData()
	{
		d3.select("body").style("cursor", "wait");
		
		d3.select("#title")
			.html(origTitle);
		
		
		//if(needsUpdate)
		{
			d3.select("#title")
				.html(origTitle + "<br />Starting download...");
			d3.json("getTags.json?event=" + eventName, async function(error, data)
			{
				searchTerms = data;
			});
			
			processParameters();
			var userSessionFilter = "";
			
			if(usersToQuery && usersToQuery.length > 0)
			{
				var first = true;
				userSessionFilter += "&users=";
				for(userEntry in usersToQuery)
				{
					if(!first)
					{
						userSessionFilter += ",";
					}
					userSessionFilter += usersToQuery[userEntry];
					first = false;
				}
			}
			
			if(sessionsToQuery && sessionsToQuery.length > 0)
			{
				var first = true;
				userSessionFilter += "&sessions=";
				for(sessionEntry in sessionsToQuery)
				{
					if(!first)
					{
						userSessionFilter += ",";
					}
					userSessionFilter += sessionsToQuery[sessionEntry];
					first = false;
				}
			}
			
			
			d3.json("logExport.json?event=" + eventName + "&datasources=windows,events,environment,processsummary&normalize=none" + userSessionFilter, async function(error, data)
				{
					try
					{
						var isDone = false;
						while(!isDone)
						{
							isDone = await persistDataAndWait("indexdata", data);
						}
					}
					catch(err)
					{
						console.log(err);
					}
					theNormData = await preprocess(data);
					/*
					try
					{
						var isDone = false;
						while(!isDone)
						{
							isDone = await persistDataAndWait("data", theNormData);
						}
					}
					catch(err)
					{
						console.log(err);
					}
					*/
					theNormDataDone = true;
					
					d3.select("#title")
						.html(origTitle + "<br />Index data: <b>" + downloadedSize + "</b> bytes downloaded.")
					
					
					d3.select("body").style("cursor", "");
					buildTable();
					
				})
				.on("progress", function(d, i)
						{
							downloadedSize = d["loaded"];
							d3.select("#title")
									.html(origTitle + "<br />Data Size: <b>" + d["loaded"] + "</b> bytes")
							//console.log(d);
						});
		}
		//else
		{
			theNormDataDone = true;
			d3.select("body").style("cursor", "");
		}
		
	}
	
	function buildTable()
	{
		var tbodyRef = document.getElementById('searchTable').getElementsByTagName('tbody')[0];
		for(user in theNormData)
		{
			for(session in theNormData[user]["Session Ordering"]["Order List"])
			{
				let sessionName = theNormData[user]["Session Ordering"][theNormData[user]["Session Ordering"]["Order List"][session]];
				//console.log("Searching " + user + ": " + sessionName);
				var newRow = tbodyRef.insertRow();
				newRow.style.wordBreak = "break-all";
				newRow.id = SHA256(user+sessionName);
				var newCell = newRow.insertCell();
				newCell.innerHTML = user;
				newCell = newRow.insertCell();
				newCell.innerHTML = sessionName;
				
				newCell = newRow.insertCell();
				newCell.innerHTML = theNormData[user][sessionName]["Index MS Session Min Date"];
				
				newCell = newRow.insertCell();
				newCell.innerHTML = theNormData[user][sessionName]["Index MS Session Max Date"];
				
				newCell = newRow.insertCell();
				var newCellHTML = "<select style=\"width:100%\" multiple name='" + SHA256(user+sessionName + "_tasks") + "' id='" + SHA256(user+sessionName + "_tasks") + "'>";
				for(entry in theNormData[user][sessionName]["events"])
				{
					var curEvent = theNormData[user][sessionName]["events"][entry];
					if(curEvent["Description"] == "start")
					{
						var curOption = "<option value=" + curEvent["TaskName"] + ">" + curEvent["TaskName"] + "</option>";
						newCellHTML += curOption;
					}
				}
				newCellHTML += "</select>"
				newCell.innerHTML = newCellHTML;
				
				newCell = newRow.insertCell();
				var newCellHTML = "<select style=\"width:100%\" multiple name='" + SHA256(user+sessionName + "_windows") + "' id='" + SHA256(user+sessionName + "_windows") + "'>";
				var doneMap = {};
				for(entry in theNormData[user][sessionName]["windows"])
				{
					var curEvent = theNormData[user][sessionName]["windows"][entry];
					if(curEvent["Name"] in doneMap)
					{
						
					}
					else
					{
						doneMap[curWindow["Name"]] = true;
						var curOption = "<option value=" + curEvent["FirstClass"] + "_" + curEvent["Name"] + ">" + curEvent["FirstClass"] + ": " + curEvent["Name"] + "</option>";
						newCellHTML += curOption;
					}
				}
				newCellHTML += "</select>"
				newCell.innerHTML = newCellHTML;
				
				newCell = newRow.insertCell();
				var newCellHTML = "<select style=\"width:100%\" multiple name='" + SHA256(user+sessionName + "_processsummary") + "' id='" + SHA256(user+sessionName + "_processsummary") + "'>";
				for(entry in theNormData[user][sessionName]["processsummary"])
				{
					var curEvent = theNormData[user][sessionName]["processsummary"][entry];
					
					var curOption = "<option value=" + curEvent["Command"] + "_" + curEvent["Arguments"] + ">" + curEvent["Command"] + ": " + curEvent["Arguments"] + "</option>";
					newCellHTML += curOption;
					
				}
				newCellHTML += "</select>"
				newCell.innerHTML = newCellHTML;
				
				newCell = newRow.insertCell();
				var newCellHTML = "<select style=\"width:100%\" multiple name='" + SHA256(user+sessionName + "_screenshots") + "' id='" + SHA256(user+sessionName + "_screenshots") + "'>";
				for(entry in theNormData[user][sessionName]["screenshots"])
				{
					var curEvent = theNormData[user][sessionName]["screenshots"][entry];
					
					//var curOption = "<option value=" + curEvent["Command"] + "_" + curEvent["Arguments"] + ">" + curEvent["Command"] + ": " + curEvent["Arguments"] + "</option>";
					//newCellHTML += curOption;
					
				}
				var curOption = "<option value=" + "soon" + ">" + "Coming Soon" + "</option>";
				newCellHTML += curOption;
				newCellHTML += "</select>"
				newCell.innerHTML = newCellHTML;
				
				newCell = newRow.insertCell();
				var envLines = theNormData[user][sessionName]["environment"][0]["Environment"].split(/\n/);
				var newCellHTML = "<select style=\"width:100%\" multiple name='" + SHA256(user+sessionName + "_environment") + "' id='" + SHA256(user+sessionName + "_environment") + "'>";
				for(entry in envLines)
				{
					var curOption = "<option value=" + envLines[entry] + ">" + envLines[entry] + "</option>";
					newCellHTML += curOption;
					
				}
				newCellHTML += "</select>"
				newCell.innerHTML = newCellHTML;
				
				newCell = newRow.insertCell();
				
				if(sessionName != "Aggregated")
				{
					newCell.innerHTML = "<textarea style=\"width:100%\" multiple name='" + SHA256(user+sessionName + "_notes") + "' id='" + SHA256(user+sessionName + "_notes") + "'>" + theNormData[user][sessionName]["environment"][0]["Notes"] + "</textarea>" +
					"<input type=\"button\" value=\"Save\" onclick=\"setNote('" + user + "', '" + sessionName + "')\">";
				}
				
				newCell = newRow.insertCell();
				var onclickAddition = "";
				if(sessionName == "Aggregated")
				{
					onclickAddition = " onclick=\"selectAll('" + user + "')\"";
				}
				newCell.innerHTML = "<input type=\"checkbox\" id=\"session_" + user + "_" + sessionName + "\" name=\"session_" + sessionName + "\" value=\"" + sessionName + "\"" + onclickAddition + ">";
				
			}
		}
	}
	
	var toTest;
	function setNote(user, session)
	{
		var theNote = document.getElementById(SHA256(user+session + "_notes")).value;
		var noteUrl = "setNote.json?event=" + eventName + "&userName=" + user + "&sessionName=" + session + "&note=" + theNote;
		
		d3.json(noteUrl, function(error, data)
					{
						if(data["result"] == "okay")
						{
							
						}
						else
						{
							document.getElementById(SHA256(user+session + "_notes")).value = "Error: " + data + "\n" + error;
						}
					});
	}
	
	function visualize()
	{
		var baseURL = "visualzation.jsp?event=" + eventName + "&eventAdmin=" + eventAdmin + "&autodownload=true&sessions=";
		var sessionArgs = "";
		var usersArgs = "";
		var usersUsed = {};
		for(user in theNormData)
		{
			for(session in theNormData[user])
			{
				var curCheck = document.getElementById("session_" + user + "_" + session);
				if(curCheck && curCheck.checked)
				{
					if(session == "Aggregated")
					{
						continue;
					}
					if(sessionArgs != "")
					{
						sessionArgs += "," + session;
					}
					else
					{
						sessionArgs += session;
					}
					if(!usersUsed[user])
					{
						usersUsed[user] = true;
						if(usersArgs != "")
						{
							usersArgs += "," + user;
						}
						else
						{
							usersArgs += user;
						}
					}
				}
			}
		}
		baseURL += sessionArgs + "&users=" + usersArgs;
		window.location.replace(baseURL);
	}
	
	
	
	function sleep(seconds)
	{
		var e = new Date().getTime + (seconds * 1000);
		while(new Date().getTime() < e) {}
	}
	
	
	function selectAll(userName)
	{
		var toCheck = document.getElementById("session_" + userName + "_Aggregated").checked;
		for(session in theNormData[userName])
		{
			var curCheck = document.getElementById("session_" + userName + "_" + session);
			if(curCheck)
			{
				curCheck.checked = toCheck;
			}
		}
	}
	
	function refreshSearch()
	{
		var userSearch = document.getElementById("userField").value;
		var sessionSearch = document.getElementById("sessionField").value;
		var startSearch = document.getElementById("startDateField").value;
		var endSearch = document.getElementById("endDateField").value;
		var tasksSearch = document.getElementById("tasksField").value;
		var windowSearch = document.getElementById("windowField").value;
		var processSearch = document.getElementById("processField").value;
		var screenshotSearch = document.getElementById("screenshotField").value;
		var environmentSearch = document.getElementById("environmentField").value;
		var noteSearch = document.getElementById("noteField").value;
		
		
		for(user in theNormData)
		{
			for(session in theNormData[user])
			{
				var curHash = SHA256(user+session)
				var curRow = document.getElementById(curHash)
				if(curRow)
				{
					curRow.style.display = "";
					if(!(user.includes(userSearch)))
					{
						curRow.style.display = "none";
					}
					if(!(session.includes(sessionSearch)))
					{
						curRow.style.display = "none";
					}
					if(!(theNormData[user][session]["Index MS Session Min Date"].includes(startSearch)))
					{
						curRow.style.display = "none";
					}
					if(!(theNormData[user][session]["Index MS Session Max Date"].includes(endSearch)))
					{
						curRow.style.display = "none";
					}
					
					var hasTask = false;
					for(entry in theNormData[user][session]["events"])
					{
						var curEvent = theNormData[user][session]["events"][entry];
						if(curEvent["Description"] == "start")
						{
							var curOption = curEvent["TaskName"];
							if(curOption.includes(tasksSearch))
							{
								hasTask = true;
								break;
							}
						}
					}
					if(!hasTask)
					{
						curRow.style.display = "none";
					}
					
					var hasTask = false;
					for(entry in theNormData[user][session]["windows"])
					{
						var curEvent = theNormData[user][session]["windows"][entry];
						var curOption = curEvent["FirstClass"] + ": " + curEvent["Name"];
						if(curOption.includes(windowSearch))
						{
							hasTask = true;
						}
					}
					if(!hasTask)
					{
						curRow.style.display = "none";
					}
					
					var hasTask = false;
					for(entry in theNormData[user][session]["processsummary"])
					{
						var curEvent = theNormData[user][session]["processsummary"][entry];
						var curOption = curEvent["Command"] + ": " + curEvent["Arguments"];
						if(curOption.includes(processSearch))
						{
							hasTask = true;
						}
					}
					if(!hasTask)
					{
						curRow.style.display = "none";
					}
					
					if(!(theNormData[user][session]["environment"][0]["Environment"].includes(environmentSearch)))
					{
						curRow.style.display = "none";
					}
					
					if(!(theNormData[user][session]["environment"][0]["Notes"].includes(noteSearch)))
					{
						curRow.style.display = "none";
					}
				}
			}
		}
	}
	
	downloadData();

</script>
</html>
