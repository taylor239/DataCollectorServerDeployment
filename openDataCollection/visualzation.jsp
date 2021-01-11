<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.ArrayList, java.util.HashMap, com.datacollector.*, java.sql.*"%>
<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" type="text/css" href="Design.css">
<script src="./sha_func.js"></script>
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

Connection dbConn = myConnectionSource.getDatabaseConnection();

String eventName = request.getParameter("event");

if(request.getParameter("email") != null)
{
	session.removeAttribute("admin");
	session.removeAttribute("adminName");
	String adminEmail = request.getParameter("email");
	if(request.getParameter("password") != null)
	{
		String password = request.getParameter("password");
		
		String loginQuery = "SELECT * FROM `openDataCollectionServer`.`Admin` WHERE `adminEmail` = ? AND `adminPassword` = ?";
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
		<td class="layoutTableSide">
			<table id="optionFilterTable" width="100%" height="100%">
					<tr>
						<td colspan="4">
								<div align="center">
									Options
								</div>
						</td>
					</tr>
					<tr>
						<td colspan="4">
									Playback Speed
						</td>
					</tr>
					<tr>
						<td colspan="4">
									<input type="text" size="4" id="playbackSpeed" name="playbackSpeed" value="10">x
						</td>
					</tr>
					<tr id="filterTitle1">
						<td colspan="4">
							<div align="center">
									Filters
							</div>
						</td>
					</tr>
					<tr>
						<td colspan="2">
						<div align="center">
						<button type="button">Save</button>
						</div>
						</td>
						<td colspan="2">
						<div align="center">
						<input type="text" size="15" id="saveFilter" name="saveFilter" value="Name">
						</div>
						</td>
					</tr>
					<tr>
						<td colspan="1">
						<div align="center">
						<button type="button">Load</button>
						</div>
						</td>
						<td colspan="1">
						<div align="center">
						<button type="button">Append</button>
						</div>
						</td>
						<td colspan="2">
						<div align="center">
						<select name="savedFilters" id="savedFilters">
							<option value="default">Default</option>
						</select>
						</div>
						</td>
					</tr>
					<tr id="filterTitle2">
						<td width="20%">
						Level
						</td>
						<td width="30%">
						Field
						</td>
						<td width="50%">
						Value
						</td>
						<td>
						
						</td>
					</tr>
					<tr id = "filter_add">
						<td id = "filter_add_level">
						<input type="text" size="2" id="filter_add_level_field" name="filter_add_level_field" value="3">
						</td>
						<td id = "filter_add_field">
						<input type="text" size="6" id="filter_add_field_field" name="filter_add_field_field" value="FirstClass">
						</td>
						<td id = "filter_add_value">
						<input type="text" size="11" id="filter_add_value_field" name="filter_add_value_field" value="!= 'com-datacollectorloc'">
						</td>
						<td id = "filter_add_add" class="clickableHover" onclick="addFilter()">
						<div align="center">
						+
						</div>
						</td>
					</tr>
					
					
			</table>
		</td>
		<td class="layoutTableCenter" id="mainVisContainer">
			<table>
			<tr><td>
			<div align="center" id="title">User Timelines for <%=eventName %></div>
			</td></tr>
			<tr><td>
			<div align="center" id="mainVisualization">
			</div>
			</td></tr>
			</table>
		</td>
		<td class="layoutTableSide">
			<table width="100%" height="100%">
					<tr>
						<td>
							<div align="center">Legend</div>
						</td>
					</tr>
					<tr>
						<td>
							<div align="left" id="legend">
							
							</div>
						</td>
					</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td class="layoutTableSide">
			<table id="screenshotTable" width="100%" class="dataTable">
				<tr>
					<td colspan=1>
					<div align="center">Screenshot</div>
					</td>
				</tr>
				<tr>
					<td colspan=1>
							<div align="center" id="screenshotDiv">
							
							</div>
					</td>
				</tr>
			</table>
		</td>
		<td class="layoutTableCenter">
			<table id="graphTable" width="100%" class="dataTable">
				<tr>
					<td>
					<div align="center">Details</div>
					</td>
				</tr>
			</table>
			<table id="infoTable" width="100%" class="dataTable">
				
			</table>
			<table id="extraInfoTable" width="100%" class="dataTable">
				
			</table>
		</td>
			</div>	
		</td>
		<td class="layoutTableSide">
			<table id="highlightTable" width="100%" class="dataTable" style="overflow-y: scroll">
				<tr>
					<td colspan=1>
					<div align="center">Highlights</div>
					</td>
				</tr>
				<tr height="100%">
					<td colspan=1>
							<div align="center" id="highlightDiv">
							
							</div>
					</td>
				</tr>
				<tr>
					<td colspan=1>
							<div align="center" id="extraHighlightDiv">
							
							</div>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
</body>


<style>

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
 
.white_content
{
	transition:300ms linear;
	border-radius:10px;
	display: none;
	position: absolute;
	top: 6.75%;
	left: 12.5%;
	width: 75%;
	height: 75%;
	max-height:75%;
	padding: 2px;
	border: 4px solid #000;
	background-color: white;
	z-index:1002;
	overflow: auto;
	text-align:center;
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

var lightBoxTimeout;

function showLightbox(theHTML)
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
	
	newWhiteDiv.onclick=unshowLightbox;
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
	
	var filters = [];
	var filtersTitle = [];
	var startFilters = 0;
	d3.select("#optionFilterTable")
	.selectAll("tr")
	.each(function(d, i)
			{
				//console.log(d);
				//console.log(this);
				filtersTitle.push(this);
				startFilters = i;
			});
	var firstFilter = {}
	firstFilter["Level"] = 1;
	firstFilter["Field"] = "";
	firstFilter["Value"] = "== 'Aggregated'";
	//firstFilter["id"] = "filter_0"
	filters.push(firstFilter);
	
	
	
	
	
	var containingTableRow = document.getElementById("mainVisContainer");
	
	var windowWidth = window.innerWidth;
	var windowHeight = window.innerHeight;
	
	console.log(windowHeight + ", " + windowWidth);
	
	var visPadding = 20;
	
	var visWidth = containingTableRow.offsetWidth - visPadding;
	var visHeight = windowHeight * .6;
	var bottomVisHeight = windowHeight * .25;
	var sidePadding = 24;
	
	var barHeight = visHeight / 10;
	var xAxisPadding = 3 * barHeight;
	//var xAxisPadding = .2 * visWidth;
	
	var eventName = "<%=eventName %>";
	
	var svg;
	var userOrdering;
	
	var keySlots = 200;
	var keyMap;
	
	var overlayText = true;
	
	var lookupTable;
	
	var processMap;
	
	var curStroke;
	var sessionStroke;
	var curHighlight = [];
	
	var curPlayButton;
	var curPlayLabel;
	
	var tickWidth = 4;
	
	var legendWidth = 25;
	var legendHeight = visHeight / 25;
	
	var timeMode = "Session";
	
	var highlightMap = {};
	highlightMap["TaskName"] = true;
	highlightMap["SecondClass"] = true;
	
	function rebuildFilters()
	{
		var tableData = filtersTitle.concat(filters);
		//console.log(tableData);
		d3.select("#optionFilterTable")
			.selectAll("tr")
			//.data(tableData)
			//.exit()
			.remove();
		d3.select("#optionFilterTable")
			.selectAll("tr")
			.data(tableData)
			.enter()
			.append("tr")
			.style("height", function(d, i)
					{
						if(i <= startFilters)
						{
							return legendHeight + "px";
						}
						return 3 * legendHeight + "px";
					})
			.html(function(d, i)
					{
						if(i <= startFilters)
						{
							return d.innerHTML;
						}
						d["id"] = "filter_" + (i - startFilters)
						return "<td id = \"filter_" + (i - startFilters) + "_level\">"
						+d["Level"]
						+"</td>"
						+"<td id = \"filter_" + (i - startFilters) + "_field\">"
						+d["Field"]
						+"</td>"
						+"<td style=\"overflow-x:auto; overflow-y:auto; word-break:break-all; display:block; height:100%;\" id = \"filter_" + (i - startFilters) + "_value\">"
						+d["Value"]
						+"</td>"
						+"<td class=\"clickableHover\" id = \"filter_" + (i - startFilters) + "_remove\">"
						+"<div align=\"center\" onclick=\"removeFilter(" + (i - startFilters) + ")\">"
						+"X"
						+"</div>"
						+"</td>";
					});
	}
	
	rebuildFilters();
	
	
	function removeFilter(filterNum)
	{
		
		filters.splice(filterNum - 1, 1);
		rebuildFilters();
		start(true);
	}
	function addFilter()
	{
		levelVal = document.getElementById("filter_add_level_field").value;
		fieldVal = document.getElementById("filter_add_field_field").value;
		valueVal = document.getElementById("filter_add_value_field").value;
		var newFilter = {}
		newFilter["Level"] = Number(levelVal);
		newFilter["Field"] = fieldVal;
		newFilter["Value"] = valueVal;
		filters.push(newFilter);
		
		rebuildFilters();
		start(true);
	}
	
	function addFilterDirect(levelVal, fieldVal, valueVal)
	{
		//levelVal = document.getElementById("filter_add_level_field").value;
		//fieldVal = document.getElementById("filter_add_field_field").value;
		//valueVal = document.getElementById("filter_add_value_field").value;
		var newFilter = {}
		newFilter["Level"] = Number(levelVal);
		newFilter["Field"] = fieldVal;
		newFilter["Value"] = valueVal;
		filters.push(newFilter);
		
		rebuildFilters();
		start(true);
	}
	
	function preprocess(dataToModify)
	{
		for(user in dataToModify)
		{
			aggregateSession = {}
			listsToAdd = {}
			newSession = {}
			for(session in dataToModify[user])
			{
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
		return dataToModify;
	}
	
	function filter(dataToFilter, filters)
	{
		var filterMap = {};
		for(entry in filters)
		{
			if(!(filters[entry]["Level"] in filterMap))
			{
				filterMap[filters[entry]["Level"]] = [];
			}
			filterMap[filters[entry]["Level"]].push(filters[entry]);
		}
		
		console.log(filterMap);
		
		for(user in dataToFilter)
		{
			toFilter = filterMap[0];
			if(toFilter)
			{
				for(curFilter in toFilter)
				{
					if(!(eval(("'" + user + "' " + toFilter[curFilter]["Value"]))))
					{
						delete dataToFilter[user];
					}
				}
			}
			for(session in dataToFilter[user])
			{
				//console.log(session);
				toFilter = filterMap[1];
				if(toFilter)
				{
					for(curFilter in toFilter)
					{
						if(!(eval("'" + session + "' " + toFilter[curFilter]["Value"])))
						{
							delete dataToFilter[user][session];
						}
					}
				}
				
				for(data in dataToFilter[user][session])
				{
					toFilter = filterMap[2];
					if(toFilter)
					{
						for(curFilter in toFilter)
						{
							if(!(eval("'" + data + "' " + toFilter[curFilter]["Value"])))
							{
								dataToFilter[user][session][data] = [];
							}
						}
					}
					toSplice = [];
					//console.log(dataToFilter[user][session][data]);
					entry = 0;
					curLength = dataToFilter[user][session][data].length;
					while(entry < curLength)
					//for(entry in dataToFilter[user][session][data])
					{
						toFilter = filterMap[3];
						if(toFilter)
						{
							for(curFilter in toFilter)
							{
								if(toFilter[curFilter]["Field"] in dataToFilter[user][session][data][entry])
								{
									if(!(eval("'" + dataToFilter[user][session][data][entry][toFilter[curFilter]["Field"]] + "' " + toFilter[curFilter]["Value"])))
									{
										//console.log(dataToFilter[user][session][data][entry]);
										dataToFilter[user][session][data].splice(entry, 1);
										entry--;
										curLength = dataToFilter[user][session][data].length;
										//console.log(entry);
										//toSplice.push(entry);
										break;
									}
								}
							}
						}
						entry++;
					}
					//toSplice.reverse();
					
					//console.log("Removing");
					//console.log(dataToFilter[user][session][data]);
					//console.log(toSplice);
					//console.log(dataToFilter[user][session][data]);
					//for(reEntry in toSplice)
					//{
						//console.log(reEntry);
						//console.log(dataToFilter[user][session][data][reEntry]);
						//dataToFilter[user][session][data].splice(entry, 1);
						//console.log(dataToFilter[user][session][data]);
						
					//}
				}
			}
			}
			
		
		return dataToFilter;
	}
	
	var theNormData;
	var theNormDataClone;
	var theNormDataDone = false;
	var origTitle = d3.select("#title").text();
	d3.json("logExport.json?event=" + eventName + "&datasources=keystrokes,mouse,processes,windows,events,screenshotindices&normalize=none", function(error, data)
			{
				theNormData = preprocess(data);
				theNormDataClone = JSON.parse(JSON.stringify(theNormData));
				theNormDataDone = true;
				start(true);
			})
			.on("progress", function(d, i)
					{
						d3.select("#title")
								.html(origTitle + "<br />Data Size: <b>" + d["loaded"] + "</b> bytes")
						//console.log(d);
					});
	
	
	
	function sleep(seconds)
	{
		var e = new Date().getTime + (seconds * 1000);
		while(new Date().getTime() < e) {}
	}
	
	
	
	function setTimeScale(type)
	{
		timeMode = type;
		if(theNormDataDone)
		{
			start(false);
		}
	}
	
	var colorScale = d3.scaleOrdinal(d3.schemeCategory20);
	var colorScaleAccent = d3.scaleOrdinal(d3["schemeAccent"]);
	
	var processToWindow = {};
	var windowToProcess = {};
	
	function start(needsUpdate)
	{
		if(needsUpdate)
		{
			d3.select("#mainVisualization").selectAll("*").remove();
			//d3.select("#mainVisualization").html("");
			d3.select("#legend").selectAll("*").remove();
			//d3.select("#legend").html("");
			clearWindow();
			theNormData = JSON.parse(JSON.stringify(theNormDataClone));
			theNormData = filter(theNormData, filters);
		}
		lookupTable = {};
		//Prepare data with sorting and finding mins, maxes
		
		var curWindowNum = 0;
		var windowColorNumber = {};
		var windowLegend = [];
		
		if(needsUpdate)
		{
			processMap = {};
			lookupTable = {};
			userOrderMap = {};
			for(user in theNormData)
			{
				sessionOrderMap = {};
				maxTimeUser = 0;
				minTimeUser = Number.POSITIVE_INFINITY;
				maxTimeUserDate = "";
				minTimeUserDate = "";
				minTimeUserUniversal = Number.POSITIVE_INFINITY;
				for(session in theNormData[user])
				{
					maxTimeSession = 0;
					minTimeSession = Number.POSITIVE_INFINITY;
					minTimeUserSession = Number.POSITIVE_INFINITY;
					maxTimeSessionDate = "";
					minTimeSessionDate = "";
					theCurData = theNormData[user][session];
					for(dataType in theCurData)
					{
						thisData = theCurData[dataType];
						
						for(x=0; x<thisData.length; x++)
						{
							if(dataType == "windows")
							{
								if(!(thisData[x]["SecondClass"] in windowColorNumber))
								{
									windowColorNumber[thisData[x]["SecondClass"]] = curWindowNum % 20;
									curWindowNum++;
									windowLegend.push(thisData[x]["SecondClass"])
								}
							}
							
							if(dataType == "processes")
							{
								if(!(user in lookupTable))
								{
									lookupTable[user] = {};
								}
								if(!(session in lookupTable[user]))
								{
									lookupTable[user][session] = {};
								}
								if(!("Processes" in lookupTable[user][session]))
								{
									lookupTable[user][session]["Processes"] = {};
								}
								
								thisData[x]["Owning User"] = user;
								thisData[x]["Owning Session"] = session;
								thisData[x]["Hash"] = SHA256(thisData[x]["User"] + thisData[x]["Start"] + thisData[x]["PID"])
								lookupTable[user][session]["Processes"][thisData[x]["Hash"]] = thisData[x];
								
								if(!(user in processMap))
								{
									processMap[user] = {};
								}
								if(!(session in processMap[user]))
								{
									processMap[user][session] = {};
								}
								curUserSessionMap = processMap[user][session];
								
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
						
						if(thisData.length > 0)
						{
							lastTimeSession = thisData[thisData.length - 1]["Index MS Session"];
							lastTimeUser = thisData[thisData.length - 1]["Index MS User"];
							lastTimeDate = thisData[thisData.length - 1]["Index"];
							firstTimeSession = thisData[0]["Index MS Session"];
							firstTimeUser = thisData[0]["Index MS User"];
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
								minTimeUserDate = firstTimeDate;
							}
							firstTimeUniversal = thisData[0]["Index MS Universal"];
							if(firstTimeUniversal < minTimeUserUniversal)
							{
								minTimeUserUniversal = firstTimeUniversal;
							}
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
		}
		
		console.log(theNormData);
		
		//Paint legend
		var legendSVG = d3.selectAll("#legend")
				.append("svg")
				.attr("width", "100%")
				.attr("height", visHeight)
				.attr("class", "svg")
				.style('overflow', 'scroll');
		
		legendSVG = legendSVG.append("g");
		
		var legendTitle = legendSVG.append("text")
				.attr("x", "50%")
				.attr("y", .5 * legendHeight)
				.attr("alignment-baseline", "central")
				.attr("dominant-baseline", "middle")
				.attr("text-anchor", "middle")
				//.attr("font-weight", "bolder")
				.text("Active Windows:");
		
		var legend = legendSVG.append("g")
				.selectAll("rect")
				.data(windowLegend)
				.enter()
				.append("rect")
				.attr("x", 0)
				.attr("width", "100%")
				//.attr("width", legendWidth)
				.attr("y", function(d, i)
						{
							return legendHeight * (i + 1);
						})
				.attr("height", legendHeight)
				.attr("stroke", "black")
				.attr("stroke-width", 0)
				.attr("fill", function(d, i)
						{
							return colorScale(windowColorNumber[d]);
						})
				.attr("initFill", function(d, i)
						{
							return colorScale(windowColorNumber[d]);
						})
				.attr("id", function(d, i)
						{
							return "legend_" + SHA256(d);
						})
				.attr("initStrokeWidth", 0)
				.on("click", function(d, i)
				{
					if(curStroke)
					{
						d3.select(curStroke).attr("stroke", "black").attr("stroke-width", d3.select(curStroke).attr("initStrokeWidth"));d3.select(curStroke).attr("stroke", "black").attr("stroke", d3.select(curStroke).attr("initStroke"));
					}
					if(curStroke == this)
					{
						d3.select(curStroke).attr("stroke-width", 0)
						clearWindow(); curStroke = null;
						return;
					}
					d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					d3.select(this).attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
					curStroke = this;
					highlightItems("select_" + SHA256(d));
				})
		.classed("clickableBar", true);
		
		
		var legendText = legendSVG.append("g")
				.selectAll("text")
				.data(windowLegend)
				.enter()
				.append("text")
				//.attr("font-size", 11)
				.attr("x", 0)
				.attr("y", function(d, i)
						{
							//return legendHeight * (i + 1);
							//return legendHeight * (i) + legendHeight;
							return legendHeight * (i + 1) + legendHeight * .5;
						})
				.attr("height", legendHeight * .75)
				.text(function(d, i)
						{
							return d;
						})
				.attr("fill", function(d, i)
						{
							if(i % 2 == 0)
							{
								return "#FFF";
							}
							else
							{
								return "#000";
							}
						})
				.attr("font-weight", "bolder")
				.attr("dominant-baseline", "middle")
				.attr("stroke", function(d, i)
						{
							if(i % 2 == 0)
							{
								return "none";
							}
							else
							{
								return "none";
							}
						});
		
		//Get the SVG for the main viz timeline
		svg = d3.selectAll("#mainVisualization")
		.style("height", visHeight + "px")
		.style('overflow-y', 'scroll')
		.append("svg")
		.attr("width", visWidth)
		.attr("height", visHeight)
		.attr("class", "svg");
		
		origSvg = svg;
		svg = svg.append("g");
		
		var finalTimelineHeight = 0;
		//Paint main vis timeline
		var curSessionCount = 0;
		backgroundG = svg.append("g")
		var backgroundRects = backgroundG
		.selectAll("rect")
		.data(userOrderArray)
		.enter()
		.append("rect")
		.attr("x",  0)
		.attr("y", function(d, i)
				{
					if(i == 0)
					{
						curSessionCount = 0;
					}
					numSessions = Object.keys(theNormData[userOrderMap[d]]["Session Ordering"]["Order List"]).length;
					toReturn = barHeight * i + barHeight * 2 * curSessionCount;
					curSessionCount += numSessions;
					return toReturn;
				})
		.attr("width", visWidth)
		.attr("height", function(d, i)
				{
					if(i == 0)
					{
						finalTimelineHeight = 0;
					}
					numSessions = Object.keys(theNormData[userOrderMap[d]]["Session Ordering"]["Order List"]).length;
					finalTimelineHeight += barHeight * 2 * numSessions + barHeight;
					return barHeight * 2 * numSessions + barHeight;
				})
		.attr("stroke", "#000000")
		.attr("fill", function(d, i)
				{
					if(i % 2 == 1)
					{
						return "#ffffff"
					}
					else
					{
						return "#b7d2ff"
					}
				})
		.attr("opacity", 0.2)
		.attr("z", 1);
		
		origSvg.attr("height", finalTimelineHeight);
		
		var timelineStarts = svg.append("g")
		.selectAll("rect")
		.data(userOrderArray)
		.enter()
		.append("rect")
		.attr("x",  xAxisPadding - xAxisPadding / 25)
		.attr("y", function(d, i)
				{
					if(i == 0)
					{
						curSessionCount = 0;
					}
					numSessions = Object.keys(theNormData[userOrderMap[d]]["Session Ordering"]["Order List"]).length;
					toReturn = barHeight * i + barHeight * 2 * curSessionCount;
					curSessionCount += numSessions;
					return toReturn + barHeight;
				})
		.attr("width", xAxisPadding / 25)
		.attr("height", function(d, i)
				{
					numSessions = Object.keys(theNormData[userOrderMap[d]]["Session Ordering"]["Order List"]).length;
					return barHeight * 2 * numSessions;
				})
		.attr("stroke", "#000000")
		.attr("fill", function(d)
				{
					return "#000000"
				})
		.attr("opacity", 1)
		.attr("z", 2);
		
		
		var userLabels = svg.append("g")
		.selectAll("text")
		.data(userOrderArray)
		.enter()
		.append("text")
		.attr("x",  0)
		.attr("y", function(d, i)
				{
					if(i == 0)
					{
						curSessionCount = 0;
					}
					numSessions = Object.keys(theNormData[userOrderMap[d]]["Session Ordering"]["Order List"]).length;
					toReturn = barHeight * i + barHeight * 2 * curSessionCount + barHeight / 4;
					curSessionCount += numSessions;
					return toReturn;
				})
		.attr("width", visWidth - 2)
		.attr("height", function(d, i)
				{
					return barHeight;
				})
		.attr("stroke", "none")
		.attr("fill", function(d)
				{
					return "#000000";
				})
		.attr("opacity", 1)
		.attr("z", 2)
		.attr("font-weight", "bolder")
		.attr("dominant-baseline", "middle")		
		.text(function(d, i)
				{
					return userOrderMap[d] + ": " + theNormData[userOrderMap[d]]["Index MS User Min Date"] + " to " + theNormData[userOrderMap[d]]["Index MS User Max Date"];
				})
		.style("font-size", barHeight/4 + "px");
		
		var windowTimeline;
		var sessionList = [];
		var foregroundRects = svg.append("g")
		.selectAll("rect")
		.data(function()
				{
					var toReturn = [];
					var userNum = 0;
					var sessionNum = 0;
					for(var x of userOrderArray)
					{
						var theUser = userOrderMap[x];
						var userSessionOrdering = theNormData[theUser]["Session Ordering"]
						var userSessionList = userSessionOrdering["Order List"];
						for(var y in userSessionList)
						{
							var curSession = userSessionOrdering[userSessionList[y]];
							var userSession = {}
							userSession["User"] = theUser;
							userSession["User Number"] = userNum;
							userSession["Session"] = curSession;
							sessionList.push(userSession);
							var windowList = theNormData[theUser][curSession]["windows"];
							var firstEntry = true;
							for(var z in windowList)
							{
								windowList[z]["User Order"] = userNum;
								windowList[z]["Session Order"] = sessionNum;
								windowList[z]["Owning User"] = theUser;
								windowList[z]["Owning Session"] = curSession;
								if(!firstEntry)
								{
									toReturn[toReturn.length - 1]["End MS Universal"] = windowList[z]["Index MS Universal"];
									toReturn[toReturn.length - 1]["End MS User"] = windowList[z]["Index MS User"];
									toReturn[toReturn.length - 1]["End MS Session"] = windowList[z]["Index MS Session"];
									toReturn[toReturn.length - 1]["Next"] = windowList[z];
								}
								firstEntry = false;
								if(timeMode == "Session")
								{
									windowList[z]["Time Scale Session"] = theNormData[theUser][curSession]["Time Scale"];
								}
								else if(timeMode == "User")
								{
									windowList[z]["Time Scale User"] = theNormData[theUser]["Time Scale"];
								}
								else if(timeMode == "Universal")
								{
									windowList[z]["Time Scale Universal"] = theNormData["Time Scale"];
								}
								toReturn.push(windowList[z]);
								if(!(theUser in lookupTable))
								{
									lookupTable[theUser] = {};
								}
								if(!(curSession in lookupTable[theUser]))
								{
									lookupTable[theUser][curSession] = {};
									lookupTable[theUser][curSession]["Windows"] = {};
								}
								if(!("Windows" in lookupTable[theUser][curSession]))
								{
									lookupTable[theUser][curSession]["Windows"] = {};
								}
								lookupTable[theUser][curSession]["Windows"][windowList[z]["Index MS"]] = windowList[z];
							}
							toReturn[toReturn.length - 1]["End MS Session"] = theNormData[theUser][curSession]["Index MS Session Max"];
							toReturn[toReturn.length - 1]["End MS User"] = theNormData[theUser][curSession]["Index MS Session Max"] + theNormData[theUser][curSession]["Index MS User Session Min"];
							toReturn[toReturn.length - 1]["End MS Universal"] = theNormData[theUser][curSession]["Index MS Session Max"] + theNormData[theUser][curSession]["Index MS User Session Min"] + theNormData[theUser]["Index MS Universal Min"];							sessionNum++;
						}
						userNum++;
					}
					windowTimeline = toReturn;
					return toReturn;
				})
		.enter()
		.append("rect")
		.attr("x", function(d, i)
				{
					if(timeMode == "Session")
					{
						return d["Time Scale Session"](d["Index MS Session"]) + xAxisPadding;
					}
					else if(timeMode == "User")
					{
						return d["Time Scale User"](d["Index MS User"]) + xAxisPadding;
					}
					else if(timeMode == "Universal")
					{
						return d["Time Scale Universal"](d["Index MS Universal"]) + xAxisPadding;
					}
					return 0;
				})
		.attr("width", function(d, i)
				{
					if(timeMode == "Session")
					{
						return d["Time Scale Session"](d["End MS Session"] - d["Index MS Session"]);
					}
					else if(timeMode == "User")
					{
						return d["Time Scale User"](d["End MS User"] - d["Index MS User"]);
					}
					else if(timeMode == "Universal")
					{
						return d["Time Scale Universal"](d["End MS Universal"] - d["Index MS Universal"]);
					}
					return timeScale(d["End Time MS"] - d["Start Time MS"]) -1;
				})
		.attr("y", function(d, i)
				{
					
					return d["Session Order"] * barHeight * 2 + d["User Order"] * barHeight + barHeight;
				})
		.attr("height", barHeight)
		.attr("stroke", "black")
		.attr("stroke-width", xAxisPadding / 100)
		.attr("fill", function(d, i)
				{
					return colorScale(windowColorNumber[d["SecondClass"]]);
				})
		.attr("initFill", function(d, i)
				{
					return colorScale(windowColorNumber[d["SecondClass"]]);
				})
		.attr("opacity", 1)
		.on("click", function(d, i)
				{
					var backgroundRect = d3.select("#background_rect_" + SHA256(d["Owning User"] + d["Owning Session"]));
					if(!sessionStroke || sessionStroke.node() != backgroundRect.node())
					{
						var e = document.createEvent('UIEvents');
						e.initUIEvent('click', true, true, /* ... */);
						backgroundRect.node().dispatchEvent(e);
					}
					
					if(curStroke)
					{
						d3.select(curStroke).attr("stroke", "black").attr("stroke-width", d3.select(curStroke).attr("initStrokeWidth"));d3.select(curStroke).attr("stroke", "black").attr("stroke", d3.select(curStroke).attr("initStroke"));
					}
					if(curStroke == this)
					{
						if(sessionStroke)
						{
							sessionStroke.attr("stroke", "black").attr("stroke-width", sessionStroke.attr("initStrokeWidth"));sessionStroke.attr("stroke", "black").attr("stroke", sessionStroke.attr("initStroke"));
						}
						clearWindow(); curStroke = null; sessionStroke = null;
						return;
					}
					
					d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					d3.select(this).attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
					curStroke = this;
					showWindow(d["Owning User"], d["Owning Session"], "Windows", d["Index MS"]);
				})
		.attr("class", function(d)
			{
				processToWindow[SHA256(d["User"] + d["Start"] + d["PID"])] = SHA256(d["SecondClass"]);
				if(!(SHA256(d["SecondClass"]) in windowToProcess))
				{
					windowToProcess[SHA256(d["SecondClass"])] = [];
				}
				windowToProcess[SHA256(d["SecondClass"])].push(SHA256(d["User"] + d["Start"] + d["PID"]));
				return "clickableBar " + "select_" + SHA256(d["SecondClass"]) + " " + "window_process_" + SHA256(d["User"] + d["Start"] + d["PID"]);
			})
		
		//.classed("clickableBar", true)
		.attr("z", 2);
		
		var eventTimeline;
		var eventTypeNumbers = {};
		var eventTypeArray = [];
		var taskRects = svg.append("g")
		.selectAll("rect")
		.data(function()
				{
					var toReturn = [];
					var userNum = 0;
					var sessionNum = 0;
					for(var x of userOrderArray)
					{
						var theUser = userOrderMap[x];
						var userSessionOrdering = theNormData[theUser]["Session Ordering"]
						var userSessionList = userSessionOrdering["Order List"];
						for(var y in userSessionList)
						{
							var maxNumActive = 0;
							var curSession = userSessionOrdering[userSessionList[y]];
							var userSession = {}
							userSession["User"] = theUser;
							userSession["User Number"] = userNum;
							userSession["Session"] = curSession;
							
							//sessionList.push(userSession);
							var eventsList = theNormData[theUser][curSession]["events"];
							
							
							var curActiveMap = {};
							var curSessionList = [];
							
							for(var z in eventsList)
							{
								if(timeMode == "Session")
								{
									eventsList[z]["Time Scale Session"] = theNormData[theUser][curSession]["Time Scale"];
								}
								else if(timeMode == "User")
								{
									eventsList[z]["Time Scale User"] = theNormData[theUser]["Time Scale"];
								}
								else if(timeMode == "Universal")
								{
									eventsList[z]["Time Scale Universal"] = theNormData["Time Scale"];
								}
								eventsList[z]["User Order"] = userNum;
								eventsList[z]["Session Order"] = sessionNum;
								
								if(!(eventsList[z]["Description"] in eventTypeNumbers))
								{
									var eventType = {};
									eventType["Description"] = eventsList[z]["Description"];
									eventType["Number"] = Object.keys(eventTypeNumbers).length % 8;
									eventTypeNumbers[eventType["Description"]] = eventType;
									eventTypeArray.push(eventType);
								}
								
								if(eventsList[z]["Description"] == "start" || !(eventsList[z]["TaskName"] in curActiveMap))
								{
									eventsList[z]["Active Row"] = Object.keys(curActiveMap).length;
									if(!(eventsList[z]["Description"] == "start"))
									{
										maxNumActive++;
										eventsList[z]["Active Row"] = maxNumActive;
										var cloned = JSON.parse(JSON.stringify(eventsList[z]));
										cloned["Time Scale Session"] = eventsList[z]["Time Scale Session"];
										cloned["Description"] = "Default";
										cloned["Next"] = eventsList[z];
										if(!(cloned["Description"] in eventTypeNumbers))
										{
											var eventType = {};
											eventType["Description"] = cloned["Description"];
											eventType["Number"] = Object.keys(eventTypeNumbers).length % 8;
											eventTypeNumbers[eventType["Description"]] = eventType;
											eventTypeArray.push(eventType);
										}
										toReturn.push(cloned);
										
										if(!(theUser in lookupTable))
										{
											lookupTable[theUser] = {};
										}
										if(!(curSession in lookupTable[theUser]))
										{
											lookupTable[theUser][curSession] = {};
											lookupTable[theUser][curSession]["Events"] = {};
										}
										if(!("Events" in lookupTable[theUser][curSession]))
										{
											lookupTable[theUser][curSession]["Events"] = {};
										}
										cloned["Owning User"] = theUser;
										cloned["Owning Session"] = curSession;
										lookupTable[theUser][curSession]["Events"][cloned["Index MS"]] = cloned;
										
										curSessionList.unshift(cloned);
									}
									if(!(eventsList[z]["Description"] == "end"))
									{
										curActiveMap[eventsList[z]["TaskName"]] = eventsList[z];
									}
									if(Object.keys(curActiveMap).length > maxNumActive)
									{
										maxNumActive = Object.keys(curActiveMap).length;
									}
								}
								else
								{
									eventsList[z]["Active Row"] = curActiveMap[eventsList[z]["TaskName"]]["Active Row"];
									curActiveMap[eventsList[z]["TaskName"]]["Next"] = eventsList[z];
									curActiveMap[eventsList[z]["TaskName"]] = eventsList[z];
									if(eventsList[z]["Description"] == "end")
									{
										delete curActiveMap[eventsList[z]["TaskName"]];
									}
								}
								
								if(eventsList[z]["Description"] != "end")
								{
									toReturn.push(eventsList[z]);
									
									if(!(theUser in lookupTable))
									{
										lookupTable[theUser] = {};
									}
									if(!(curSession in lookupTable[theUser]))
									{
										lookupTable[theUser][curSession] = {};
										lookupTable[theUser][curSession]["Events"] = {};
									}
									if(!("Events" in lookupTable[theUser][curSession]))
									{
										lookupTable[theUser][curSession]["Events"] = {};
									}
									eventsList[z]["Owning User"] = theUser;
									eventsList[z]["Owning Session"] = curSession;
									lookupTable[theUser][curSession]["Events"][eventsList[z]["Index MS"]] = eventsList[z];
									
									curSessionList.push(eventsList[z]);
								}
							}
							for(z in curSessionList)
							{
								curSessionList[z]["Max Active"] = maxNumActive;
								if(!("Next" in curSessionList[z]))
								{
									var cloned = JSON.parse(JSON.stringify(curSessionList[z]));
									cloned["Description"] = "Default";
									cloned["Index MS Session"] = theNormData[theUser][curSession]["Index MS Session Max"];
									cloned["Index MS User"] = theNormData[theUser][curSession]["Index MS Session Max"] + theNormData[theUser][curSession]["Index MS User Session Min"];
									cloned["Index MS Universal"] = theNormData[theUser][curSession]["Index MS Session Max"] + theNormData[theUser][curSession]["Index MS User Session Min"] + theNormData[theUser]["Index MS Universal Min"];
									curSessionList[z]["Next"] = cloned;
								}
							}
							sessionNum++;
						}
						userNum++;
					}
					eventTimeline = toReturn;
					return toReturn;
				})
		.enter()
		.append("rect")
		.attr("x", function(d, i)
				{
					if(timeMode == "Session")
					{
						return d["Time Scale Session"](d["Index MS Session"]) + xAxisPadding;
					}
					else if(timeMode == "User")
					{
						return d["Time Scale User"](d["Index MS User"]) + xAxisPadding;
					}
					else if(timeMode == "Universal")
					{
						return d["Time Scale Universal"](d["Index MS Universal"]) + xAxisPadding;
					}
					return 0;
				})
		.attr("width", function(d, i)
				{
					if(timeMode == "Session")
					{
						return d["Time Scale Session"](d["Next"]["Index MS Session"] - d["Index MS Session"]);
					}
					else if(timeMode == "User")
					{
						return d["Time Scale User"](d["Next"]["Index MS User"] - d["Index MS User"]);
					}
					else if(timeMode == "Universal")
					{
						return d["Time Scale Universal"](d["Next"]["Index MS Universal"] - d["Index MS Universal"]);
					}
					return timeScale(d["End Time MS"] - d["Start Time MS"]) -1;
				})
		.attr("y", function(d, i)
				{
					var totalHeight =  (barHeight - xAxisPadding / 25) / d["Max Active"];
					return d["Session Order"] * barHeight * 2 + d["User Order"] * barHeight + barHeight * 2 + d["Active Row"] * totalHeight;
				})
		.attr("height", function(d, i)
				{
					var totalHeight =  (barHeight - xAxisPadding / 25) / d["Max Active"];
					return totalHeight;
				})
		.attr("stroke", "black")
		.attr("stroke-width", xAxisPadding / 100)
		.attr("fill", function(d, i)
				{
					return colorScaleAccent(eventTypeNumbers[d["Description"]]["Number"]);
				})
		.attr("opacity", 1)
		.on("click", function(d, i)
				{
					if(curStroke)
					{
						d3.select(curStroke).attr("stroke", "black").attr("stroke-width", d3.select(curStroke).attr("initStrokeWidth"));d3.select(curStroke).attr("stroke", "black").attr("stroke", d3.select(curStroke).attr("initStroke"));
					}
					if(curStroke == this)
					{
						clearWindow(); curStroke = null;
						return;
					}
					d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					d3.select(this).attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
					curStroke = this;
					showWindow(d["Owning User"], d["Owning Session"], "Events", d["Index MS"]);
				})
		.classed("clickableBar", true)
		.attr("z", 3);
		
		var sessionLabelFontSize = (barHeight - xAxisPadding / 25) / 5;
		var sessionLabelFontWidth = sessionLabelFontSize *.6;
		var sessionList;
		var sessionBarG = svg.append("g")
		var sessionBars = sessionBarG
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.attr("x", "0")
		.attr("width", visWidth)
		.attr("height", xAxisPadding / 25)
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i;
					toReturn -= (xAxisPadding / 25);
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("z", 3);
		
		var sessionBackgroundBars = svg.append("g").lower()
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.attr("x", "0")
		.attr("width", visWidth)
		.attr("height", barHeight * 2 - xAxisPadding / 25)
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i;
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("fill-opacity", function(d, i)
				{
					if(i % 2 == 0)
					{
						return ".2";
					}
					return "0";
				})
		.attr("stroke-opacity", ".75")
		.attr("z", 0)
		.attr("stroke", "black")
		.attr("stroke-width", xAxisPadding / 100)
		.classed("clickableBarHelp", true)
		.attr("id", function(d, i)
				{
					return "background_rect_" + SHA256(d["User"] + d["Session"]);
				})
		.on("click", function(d, i)
				{
					
					if(curStroke)
					{
						d3.select(curStroke).attr("stroke", "black").attr("stroke-width", d3.select(curStroke).attr("initStrokeWidth"));d3.select(curStroke).attr("stroke", "black").attr("stroke", d3.select(curStroke).attr("initStroke"));
					}
					if(sessionStroke)
					{
						sessionStroke.attr("stroke", "black").attr("stroke-width", sessionStroke.attr("initStrokeWidth"));sessionStroke.attr("stroke", "black").attr("stroke", sessionStroke.attr("initStroke"));
					}
					if(sessionStroke && sessionStroke.node() == d3.select(this).node())
					{
						clearWindow(); curStroke = null; sessionStroke = null;
						return;
					}
					d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					d3.select(this).attr("stroke", "#ff0000").attr("stroke-width", xAxisPadding / 50);
					sessionStroke = d3.select(this);
					showSession(d["User"], d["Session"]);
				});
		
		var playButtons = svg.append("g")
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.attr("x", xAxisPadding / 2)
		.attr("width", xAxisPadding / 2 - xAxisPadding / 20)
		.attr("height", barHeight - 2 * (xAxisPadding / 25))
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i + barHeight + (xAxisPadding / 25);
					return toReturn;
				})
		.attr("fill", "Chartreuse")
		.attr("initFill", "Chartreuse")
		.attr("stroke", "black")
		.attr("initStroke", "black")
		.attr("stroke-width", "0")
		.attr("initStrokeWidth", "0")
		.attr("z", 2)
		.classed("clickableBar", true)
		.attr("id", function(d, i)
				{
					return("playbutton_" + SHA256(d["User"] + d["Session"]));
				})
		.on("click", function(d, i)
				{
					if(curStroke)
					{
						d3.select(curStroke).attr("stroke", "black").attr("stroke-width", d3.select(curStroke).attr("initStrokeWidth"));d3.select(curStroke).attr("stroke", "black").attr("stroke", d3.select(curStroke).attr("initStroke"));
					}
					if(curStroke == this)
					{
						clearWindow(); curStroke = null;
						return;
					}
					d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					d3.select(this).attr("stroke", "#ff0000").attr("stroke-width", xAxisPadding / 50);
					curStroke = this;
					showSession(d["User"], d["Session"]);
					
					curPlayButton = d3.select(("#playbutton_" + SHA256(d["User"] + d["Session"]))).attr("fill", "red");
					curPlayLabel = d3.select(("#playbutton_label_" + SHA256(d["User"] + d["Session"]))).text("Pause");
					playAnimation(d["User"], d["Session"]);
				});
		
		var filterButtons = svg.append("g")
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.attr("x", 0)
		.attr("width", xAxisPadding / 2 - xAxisPadding / 20)
		.attr("height", barHeight - 2 * (xAxisPadding / 25))
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i + barHeight + (xAxisPadding / 25);
					return toReturn;
				})
		.attr("fill", "Crimson")
		.attr("initFill", "Crimson")
		.attr("stroke", "black")
		.attr("initStroke", "black")
		.attr("stroke-width", "0")
		.attr("initStrokeWidth", "0")
		.attr("z", 2)
		.classed("clickableBar", true)
		.attr("id", function(d, i)
				{
					return("filterbutton_" + SHA256(d["User"] + d["Session"]));
				})
		.on("click", function(d, i)
				{
					addFilterDirect(1, "", "!= '" + d["Session"] + "'");
				});
		
		var playLabels = svg.append("g")
		.selectAll("text")
		.data(sessionList)
		.enter()
		.append("text")
		.attr("x", 3 * xAxisPadding / 4 - xAxisPadding / 40)
		.attr("width", xAxisPadding / 2)
		.attr("height", barHeight - 2 * (xAxisPadding / 25))
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i + 1.5 * barHeight;
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("z", 2)
		.attr("font-weight", "bolder")
		.attr("font-family", "monospace")
		.attr("alignment-baseline", "central")
		.attr("dominant-baseline", "middle")
		.attr("text-anchor", "middle")
		.text("Play")
		.attr("initText", "Play")
		.style("pointer-events", "none")
		.attr("id", function(d, i)
				{
					return("playbutton_label_" + SHA256(d["User"] + d["Session"]));
				})
		.classed("clickableBar", true);
		
		var filterLabels = svg.append("g")
		.selectAll("text")
		.data(sessionList)
		.enter()
		.append("text")
		.attr("x", xAxisPadding / 4 - xAxisPadding / 40)
		.attr("width", xAxisPadding / 2)
		.attr("height", barHeight - 2 * (xAxisPadding / 25))
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i + 1.5 * barHeight;
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("z", 2)
		.attr("font-weight", "bolder")
		.attr("font-family", "monospace")
		.attr("alignment-baseline", "central")
		.attr("dominant-baseline", "middle")
		.attr("text-anchor", "middle")
		.text("Filter")
		.attr("initText", "Filter")
		.style("pointer-events", "none")
		.attr("id", function(d, i)
				{
					return("filterbutton_label_" + SHA256(d["User"] + d["Session"]));
				})
		.classed("clickableBar", true);
		
		
		var axisBars = svg.append("g")
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.attr("x", xAxisPadding)
		.attr("width", visWidth - xAxisPadding)
		.attr("height", barHeight / 4)
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight;
					toReturn += barHeight * 2 * i;
					toReturn -= barHeight / 4;
					return toReturn;
				})
		.attr("fill", "#FFF")
		.attr("opacity", ".85")
		.attr("z", 2);
		
		var axisUnits = svg.append("g")
		.selectAll("text")
		.data(sessionList)
		.enter()
		.append("text")
		.style("font-size", (barHeight / 8) + "px")
		.style("font-weight", "bolder")
		.attr("font-size", (barHeight / 8) + "px")
		.attr("dominant-baseline", "middle")
		.attr("x", xAxisPadding + xAxisPadding / 25)
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight;
					toReturn += barHeight * 2 * i;
					toReturn -= barHeight / 16;
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("opacity", "1")
		.text("Minutes")
		.attr("z", 2);
		
		var sessionAxes = svg.append("g")
		.selectAll("g")
		.data(sessionList)
		.enter()
		.append("g")
		.style("font-size", (barHeight / 8) + "px")
		.attr("font-size", (barHeight / 8) + "px")
		.attr("x", xAxisPadding)
		.attr("width", visWidth - xAxisPadding)
		.attr("height", xAxisPadding / 25)
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight;
					toReturn += barHeight * 2 * i;
					toReturn -= (xAxisPadding / 25);
					return toReturn;
				})
		.attr("fill", "#FFF")
		.attr("z", 2)
		.attr("transform", function(d, i)
				{
					toReturn = d["User Number"] * barHeight;
					toReturn += barHeight * 2 * (i + 1);
					return "translate("+ xAxisPadding + ", " + toReturn + ")";
				})
		.each(function(d, i)
				{
					userName = d["User"];
					sessionName = d["Session"];
					//var scale = theNormData[userName][sessionName]["Time Scale"];
					maxSession = Number(theNormData[userName][sessionName]["Index MS Session Max"]);
					scale = d3.scaleLinear();
					scale.domain([0, maxSession / 60000]);
					scale.range([0, visWidth - xAxisPadding]);
					
					axis = d3.axisTop()
						.scale(scale).tickSize(barHeight / 16);
					
					axis(d3.select(this));
				});
		
		var sessionLabels = svg.append("g")
		.selectAll("text")
		.data(function()
			{
				var myReturn = [];
				
				var fontWidth = sessionLabelFontWidth;
				var areaWidth = xAxisPadding - xAxisPadding / 25;
				
				sessNum = 0;
				for(sess in sessionList)
				{
					var normEntry = theNormData[sessionList[sess]["User"]][sessionList[sess]["Session"]]
					var minDate = normEntry["Index MS Session Min Date"];
					var maxDate = normEntry["Index MS Session Max Date"];
					var sessionName = sessionList[sess]["Session"];
					
					sessionName += '\n';
					sessionName += "From:"
					sessionName += '\n';
					sessionName += minDate;
					sessionName += '\n';
					sessionName += "To:"
					sessionName += '\n';
					sessionName += maxDate;
					
					var line = 0;
					var position = 0;
					for(var i = 0; i < sessionName.length; i++)
					{
						if(sessionName[i] == '\n')
						{
							line++;
							position = 0;
							continue;
						}
						var nextEntry = {}
						nextEntry["User Number"] = sessionList[sess]["User Number"]
						nextEntry["Session Number"] = sessNum;
						nextEntry["Char"] = sessionName[i];
						nextEntry["Line"] = line;
						nextEntry["Position"] = position;
						position++;
						if(position * fontWidth + fontWidth > areaWidth)
						{
							line++;
							position = 0;
						}
						myReturn.push(nextEntry);
					}
					sessNum++;
				}
				return myReturn;
			}	
		)
		.enter()
		.append("text")
		.attr("x", function(d, i)
				{
					return d["Position"] * sessionLabelFontWidth;
				})
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * d["Session Number"];
					toReturn += sessionLabelFontSize/2;
					toReturn += d["Line"] * sessionLabelFontSize;
					return toReturn;
				})
		.attr("width", sessionLabelFontWidth)
		.attr("height", function(d, i)
				{
					return sessionLabelFontSize;
				})
		.attr("stroke", "none")
		.attr("fill", function(d)
				{
					return "#000000";
				})
		.attr("opacity", 1)
		.attr("z", 2)
		.attr("font-weight", "bolder")
		.attr("font-family", "monospace")
		.attr("dominant-baseline", "middle")		
		.text(function(d, i)
				{
					return d["Char"];
				})
		.style("font-size", sessionLabelFontSize + "px");
		
		var eventLegendBaseline = (windowLegend.length + 1) * legendHeight
		var legendTitleEvents = legendSVG.append("text")
		.attr("x", "50%")
		.attr("y", .5 * legendHeight + eventLegendBaseline)
		.attr("alignment-baseline", "central")
		.attr("dominant-baseline", "middle")
		.attr("text-anchor", "middle")
		//.attr("font-weight", "bolder")
		.text("Task Events:");

		var legendEvents = legendSVG.append("g")
		.selectAll("rect")
		.data(eventTypeArray)
		.enter()
		.append("rect")
		.attr("x", 0)
		.attr("width", "100%")
		//.attr("width", legendWidth)
		.attr("y", function(d, i)
				{
					return legendHeight * (i + 1) + eventLegendBaseline;
				})
		.attr("height", legendHeight)
		.attr("stroke", "none")
		.attr("fill", function(d, i)
				{
					return colorScaleAccent(d["Number"]);
				});


		var legendTextEvents = legendSVG.append("g")
		.selectAll("text")
		.data(eventTypeArray)
		.enter()
		.append("text")
		//.attr("font-size", 11)
		.attr("x", 0)
		.attr("y", function(d, i)
				{
					//return legendHeight * (i + 1);
					//return legendHeight * (i) + legendHeight;
					return legendHeight * (i + 1) + legendHeight * .5 + eventLegendBaseline;
				})
		.attr("height", legendHeight * .75)
		.text(function(d, i)
				{
					return d["Description"];
				})
		.attr("fill", function(d, i)
				{
					return "#000";
				})
		.attr("font-weight", "bolder")
		.attr("dominant-baseline", "middle")
		.attr("stroke", function(d, i)
				{
					if(i % 2 == 0)
					{
						return "none";
					}
					else
					{
						return "none";
					}
				});

		sessionBarG.lower();
		backgroundG.lower();
	}
	
	function startOld()
	{
		if(!usersDone || !theNormDataDone || !totalDataDone || !theDataDone || !collectedDataNormDone || !taskDataDone)
		{
			return;
		}
		svg = d3.selectAll("#mainVisualization")
				.append("svg")
				.attr("width", visWidth-1)
				.attr("height", visHeight)
				.attr("class", "svg");
		//console.log(users);
		theNormData[x]["Start Time MS"]
		theNormData[x]["Username"]
		
		lookupTable = {};
		for(x=0; x<theNormData.length; x++)
		{
			if(!(theNormData[x]["Username"] in lookupTable))
			{
				lookupTable[theNormData[x]["Username"]] = {};
			}
			lookupTable[theNormData[x]["Username"]][theNormData[x]["Start Time MS"]] = theNormData[x];
		}
		
		var timeMax = d3.max(totalNormData, function(d){ return d["Input Time MS"]; });
		var keyTime = timeMax / keySlots;
		keyMap = {};
		
		for(x=0; x<totalNormData.length; x++)
		{
			
			if(!(totalNormData[x]["Username"] in keyMap))
			{
				keyMap[totalNormData[x]["Username"]] = {};
				keyMap[totalNormData[x]["Username"]]["max"] = 0;
			}
			var curSlot = Math.round(totalNormData[x]["Input Time MS"] / keyTime) * keyTime;
			
			if(curSlot in keyMap[totalNormData[x]["Username"]])
			{
				keyMap[totalNormData[x]["Username"]][curSlot]++;
			}
			else
			{
				keyMap[totalNormData[x]["Username"]][curSlot] = 1;
			}
			if(keyMap[totalNormData[x]["Username"]][curSlot] > keyMap[totalNormData[x]["Username"]]["max"])
			{
				keyMap[totalNormData[x]["Username"]]["max"] = keyMap[totalNormData[x]["Username"]][curSlot];
			}
		}
		
		timeScale = d3.scaleLinear();
		timeScale.domain
					(
						[0,
						timeMax]
					)
		timeScale.range([0, visWidth - xAxisPadding]);
		
		userOrdering = {};
		for(x=0; x<users.length; x++)
		{
			userOrdering[users[x]] = x;
		}
		
		
		barHeight = visHeight / (users.length * 2);
		
		var backgroundRects = svg.append("g")
				.selectAll("rect")
				.data(users)
				.enter()
				.append("rect")
				.attr("x",  1)
				.attr("y", function(d, i)
						{
							//console.log(d);
							return barHeight * 2 * userOrdering[d];
						})
				.attr("width", visWidth - 2)
				.attr("height", barHeight * 2)
				.attr("stroke", "#000000")
				.attr("fill", function(d)
						{
							if(userOrdering[d] % 2 == 0)
							{
								return "#ffffff"
							}
							else
							{
								return "#b7d2ff"
							}
						})
				.attr("opacity", 0.2)
				.attr("z", 0);
		
		
		var colorScale = d3.scaleOrdinal(d3.schemeCategory20);
		var colorNumberMap = {};
		var count = 0;
		var numberCount = 0;
		
		var finalLegendArray = [];
		
		for(x=0; x<theNormData.length; x++)
		{
			if(x > 0 && theNormData[x]["Username"] != theNormData[x - 1]["Username"])
			{
				numberCount = 0;
			}
			theNormData[x]["Number"] = numberCount;
			numberCount ++;
			if(!(theNormData[x]["Window Class 2"] in colorNumberMap))
			{
				colorNumberMap[theNormData[x]["Window Class 2"]] = count;
				
				count++;
			}
		}
		
		for(key in colorNumberMap)
		{
			//console.log(key);
			//console.log(colorNumberMap[key]);
			finalLegendArray[colorNumberMap[key]] = key;
		}
		//console.log(finalLegendArray);
		
		//console.log(colorNumberMap);
		var legendSVG = d3.selectAll("#legend")
				.append("svg")
				.attr("width", "100%")
				.attr("height", visHeight)
				.attr("class", "svg");
		
		var legend = legendSVG.append("g")
				.selectAll("rect")
				.data(finalLegendArray)
				.enter()
				.append("rect")
				.attr("x", 0)
				.attr("width", legendWidth)
				.attr("y", function(d, i)
						{
							return legendHeight * (i);
						})
				.attr("height", legendHeight)
				.attr("stroke", "none")
				.attr("fill", function(d, i)
						{
							//console.log(d);
							return colorScale(d);
						});
		
		var legendText = legendSVG.append("g")
				.selectAll("text")
				.data(finalLegendArray)
				.enter()
				.append("text")
				.attr("font-size", 11)
				.attr("x", legendWidth)
				.attr("y", function(d, i)
						{
							return legendHeight * (i + .5);
						})
				.text(function(d, i)
						{
							return d;
						});
		
		var foregroundWindowRects = svg.append("g")
				.selectAll("rect")
				.data(theNormData)
				.enter()
				.append("rect")
				.attr("x", function(d, i)
						{
							return timeScale(d["Start Time MS"]) + xAxisPadding;
						})
				.attr("width", function(d, i)
						{
							return timeScale(d["End Time MS"] - d["Start Time MS"]) -1;
						})
				.attr("y", function(d, i)
						{
							return userOrdering[d["Username"]] * barHeight * 2 + .25 * barHeight;
						})
				.attr("height", .75 * barHeight)
				.attr("stroke", "black")
				.attr("stroke-width", 3)
				.attr("fill", function(d, i)
						{
							return colorScale(d["Window Class 2"]);
						})
				.attr("opacity", 1)
				.on("click", function(d, i)
						{
							d3.select(curStroke).attr("stroke", "none");
							if(curStroke == this)
							{
								clearWindow(); curStroke = null;
								return;
							}
							d3.select(this).attr("stroke", "#ffff00");
							curStroke = this;
							showWindow(d["Username"], d["Start Time MS"]);
						})
				.classed("clickableBar", true)
				.attr("z", 2);
		
		var foregroundWindowRectText = svg.append("g")
			.selectAll("text")
			.data(theNormData)
			.enter()
			.append("text")
			.text(function(d)
					{
						return d["Window Class 2"]
					})
			.attr("x", function(d, i)
						{
							return timeScale((d["End Time MS"] + d["Start Time MS"])/2) + xAxisPadding;
						})
			.attr("y", function(d, i)
						{
							var toAdd = 0;
							if(d["Number"] % 2 == 1)
							{
								toAdd += 12;
							}
							return userOrdering[d["Username"]] * barHeight * 2 + .25 * barHeight - 2 + toAdd;
						})
			.attr("font-size", 11)
			.attr("text-anchor", "middle")
			.attr("class", function(d, i)
						{
							if(d["Number"] % 2 == 1)
							{
								return "textShadow";
							}
							else
							{
								return "none";
							}
						})
			.attr("fill", function(d, i)
						{
							if(d["Number"] % 2 == 1)
							{
								return "#fff";
							}
							return "#000";
						})
			.attr("opacity", function(d, i)
						{
							if(overlayText)
							{
								return 1;
							}
							return 0;
						});
			
		
		var yAxisLabels = svg.append("g")
				.selectAll("text")
				.data(users)
				.enter()
				.append("text")
				.text(function(d)
						{
							return d;
						})
				.attr("x", function(d)
						{
							return xAxisPadding / 2;
						})
				.attr("y", function(d)
						{
							return barHeight * 2 * userOrdering[d] + barHeight;
						})
				.attr("font-size", 14)
				.attr("text-anchor", "middle");
		
		var taskRects = svg.append("g")
				.selectAll("rect")
				.data(taskData)
				.enter()
				.append("rect")
				.attr("x", function(d, i)
						{
							return timeScale(d["Event Time MS"]) + xAxisPadding - tickWidth/2;
						})
				.attr("width", function(d, i)
						{
							return tickWidth;
						})
				.attr("y", function(d, i)
						{
							return userOrdering[d["Username"]] * barHeight * 2 + barHeight;
						})
				.attr("height", .75 * barHeight)
				.attr("stroke", "none")
				.attr("fill", function(d, i)
						{
							if(d["Event"] == "end")
							{
								return "#0011ff";
							}
							if(d["Event"] == "start")
							{
								return "#ff0010";
							}
							return "#000";
						})
				.attr("opacity", 1)
				.attr("z", 2);
		
		var taskRects = svg.append("g")
				.selectAll("text")
				.data(taskData)
				.enter()
				.append("text")
				.attr("x", function(d, i)
						{
							return timeScale(d["Event Time MS"]) + xAxisPadding + tickWidth/2;
						})
				.attr("y", function(d, i)
						{
							if(d["Event"] == "end")
							{
								return userOrdering[d["Username"]] * barHeight * 2 + 1.75 * barHeight;
							}
							return userOrdering[d["Username"]] * barHeight * 2 + 1.25 * barHeight;
						})
				.text(function(d)
						{
							if(d["Event"] == "end")
							{
								return d["Event"] + ": " + d["Completion"];
							}
							if(d["Event"] == "start")
							{
								return d["Event"] + ": " + d["Task Name"];
							}
							return d["Event"];
						})
				.attr("font-size", 14)
				.attr("text-anchor", "left")
				.attr("opacity", 1)
				.attr("class", "textShadowWhite")
				.attr("z", 6);
		
		
		
		
		for(x=0; x<users.length; x++)
		{
			var current = keyMap[users[x]];
			var maxClicks = current["max"];
			var currentArray = [];
			var count = 0;
			for(var key in current)
			{
				if(current.hasOwnProperty(key) && key != "max")
				{
					var newObj = {};
					newObj["slot"] = parseInt(key);
					newObj["value"] = current[key];
					currentArray[count] = newObj;
					count++;
				}
			}
			
			var clickGraph = svg.append("g")
					.selectAll("rect")
					.data(currentArray)
					.enter()
					.append("rect")
					.attr("x", function(d, i)
							{
								return timeScale(d["slot"] - (keyTime / 4)) + xAxisPadding;
							})
					.attr("width", function(d, i)
							{
								return timeScale(keyTime) -1;
							})
					.attr("y", function(d, i)
							{
								return userOrdering[users[x]] * barHeight * 2 + barHeight - .375 * barHeight * (d["value"] / maxClicks);
							})
					.attr("height", function(d, i)
							{
								return .375 * barHeight * (d["value"] / maxClicks);
							})
					.attr("stroke", "none")
					.attr("fill", function(d, i)
							{
								return "#000000";
							})
					.attr("opacity", .75)
					.attr("z", 2);
		}
		
	}
	
	var lastHighlighted;
	
	function highlightItems(className)
	{
		clearWindow();
		lastHighlighted = className;
		d3.selectAll("." + className)
			.attr("initStrokeWidth", function()
					{
						return this.getAttribute("stroke-width")
					})
			.attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
	}
	
	function clearWindow()
	{
		if(curPlayButton)
		{
			curPlayButton.attr("fill", curPlayButton.attr("initFill"));
			curPlayLabel.text(curPlayLabel.attr("initText"));
		}
		curPlayButton = null;
		curPlayLabel = null;
		
		for(selection in curSelElements)
		{
			if(curSelElements[selection] && !(curSelElements[selection].empty()) && curSelElements[selection].attr("initFill"))
			{
				//curSelElements[selection].attr("fill", curSelElements[selection].attr("initFill"));
				curSelElements[selection].attr("fill", function(){ return this.getAttribute("initFill"); });
			}
		}
		curSelElements = [];
		
		if(curSelectProcess && curSelectProcess != null)
		{
			curLabel = d3.select("#process_legend_" + curSelectProcess[0]["Hash"])
			curLabel.attr("fill", curLabel.attr("initFill"));
		}
		curSelectProcess = null;
		
		if(lastHighlighted)
		{
			d3.selectAll("." + lastHighlighted)
			.attr("stroke-width", function()
					{
						return this.getAttribute("initStrokeWidth")
					})
			.attr("stroke", "black");
		}
		lastHighlighted = null;
		d3.select("#extraInfoTable")
			.selectAll("tr")
			.remove();
		d3.select("#infoTable")
			.selectAll("tr")
			.remove();
		d3.select("#screenshotDiv")
			.selectAll("*")
			.remove();
		d3.select("#highlightDiv")
			.selectAll("*")
			.remove();
		d3.select("#highlightDiv").style('overflow-y', 'auto').style("height", "auto")
		d3.select("#extraHighlightDiv")
			.selectAll("*")
			.remove();
		d3.select("#extraHighlightDiv").style('overflow-y', 'auto').style("height", "auto")
		//d3.select("#infoTable").append("tr").html("<td colspan=4><div align=\"center\">Details</div></td>");
		
		for(element in curHighlight)
		{
			curHighlight[element].attr("stroke-width", 0);
		}
		curHighlight = [];
		
		if(theNormDataDone)
		{
			showDefault();
		}
	}
	
	function showDefault()
	{
		
	}
	
	function playAnimation(owningUser, owningSession)
	{
		
	}
	
	var processTooltip;
	var processTooltipRect;
	var lastMouseOver;
	var lastMouseHash;
	
	var curSelectUser = "";
	var curSelectSession = "";
	
	function showSession(owningUser, owningSession)
	{
		curSelectUser = owningUser;
		curSelectSession = owningSession;
		bottomVizFontSize = bottomVisHeight / 25;
		clearWindow();
		
		curSessionMap = theNormData[owningUser][owningSession];
		
		d3.select("#screenshotDiv")
		.selectAll("*")
		.remove();
		
		screenshotIndex = theNormData[owningUser][owningSession]["screenshots"][0]["Index MS"];
		screenshotSession = theNormData[owningUser][owningSession]["screenshots"][0]["Original Session"];
		
		
		d3.select("#screenshotDiv")
		.append("img")
		.attr("width", "100%")
		.attr("src", "./getClosestScreenshot.jpg?username=" + owningUser + "&timestamp=" + screenshotIndex + "&session=" + screenshotSession + "&event=" + eventName)
		.attr("style", "cursor:pointer;")
		.on("click", function()
				{
					showLightbox("<tr><td><div width=\"100%\"><img src=\"./getClosestScreenshot.jpg?username=" + owningUser + "&timestamp=" + screenshotIndex + "&session=" + screenshotSession + "&event=" + eventName + "\" style=\"width: 100%;\"></div></td></tr>");
				});
		
		
		curProcessMap = processMap[owningUser][owningSession];
		
		var newSVG = d3.select("#infoTable").append("tr").append("td").append("svg")
			.attr("width", visWidth + "px")
			.attr("height", bottomVisHeight + "px")
			.append("g");
		
		
		cpuSortedList = [];
		var maxCPU = 0;
		for(osUser in curProcessMap)
		{
			for(started in curProcessMap[osUser])
			{
				for(pid in curProcessMap[osUser][started])
				{
					curProcList = curProcessMap[osUser][started][pid]
					totalAverage = curProcList[curProcList.length-1]["Aggregate CPU"] / curProcList.length;
					curProcList[0]["Average CPU"] = totalAverage;
					for(entry in curProcList)
					{
						if(curProcList[entry]["CPU"] > maxCPU)
						{
							maxCPU = curProcList[entry]["CPU"];
						}
						curProcList[entry]["Hash"] = SHA256(osUser + started + pid);
					}
					cpuSortedList.push(curProcList);
				}
			}
		}
		
		
		cpuSortedList.sort(function(a, b)
		{
			if(a[0]["Average CPU"] > b[0]["Average CPU"]) { return -1; }
			if(a[0]["Average CPU"] < b[0]["Average CPU"]) { return 1; }
			return 0;
		})
		
		
		var cpuScale = d3.scaleLinear();
		cpuScale.domain([0, maxCPU]);
		cpuScale.range([bottomVisHeight, 0]);
		
		var timeScale;
		if(timeMode == "Universal")
		{
			timeScale = theNormData["Time Scale"];
		}
		else if(timeMode == "User")
		{
			timeScale = theNormData[owningUser]["Time Scale"];
		}
		else
		{
			timeScale = theNormData[owningUser][owningSession]["Time Scale"];
		}
		
		var finalProcList = [];
		
		var lineFormattedData = []
		
		
		for(entry in cpuSortedList)
		{
			for(subEntry in cpuSortedList[entry])
			{
				cpuSortedList[entry][subEntry]["Process Order"] = entry;
			}
			
			name = cpuSortedList[entry][0]["User"] + cpuSortedList[entry][0]["Start"] + cpuSortedList[entry][0]["PID"];
			value = cpuSortedList[entry];
			lineEntry = {};
			lineEntry["name"] = name;
			lineEntry["values"] = value;
			lineFormattedData.push(lineEntry);
			
			finalProcList = finalProcList.concat(cpuSortedList[entry]);
		}
		
		cpuSortedList = cpuSortedList.reverse();
		
		finalProcList = finalProcList.reverse();
		
		
		var procPoints = newSVG.selectAll("circle")
			.data(finalProcList)
			.enter()
			.append("circle")
			.attr("cx", function(d, i)
					{
						if(timeMode == "Universal")
						{
							return xAxisPadding +  timeScale(d["Index MS Universal"]);
						}
						else if(timeMode == "User")
						{
							return xAxisPadding + timeScale(d["Index MS User"]);
						}
						else
						{
							return xAxisPadding +  timeScale(d["Index MS Session"]);
						}
					})
			.attr("cy", function(d, i)
					{
						return cpuScale(d["CPU"]);
					})
			.attr("class", function(d, i)
					{
						return "clickableBarPreise process_" + d["Hash"];
					})
			.attr("r", bottomVisHeight / 50)
			.attr("initR", bottomVisHeight / 50)
			//.attr("r", 5)
			.attr("fill", function(d, i)
					{
						return colorScale(d["Process Order"] % 20);
					})
			.attr("initFill", function(d, i)
					{
						return colorScale(d["Process Order"] % 20);
					})
			.on("mouseenter", function(d, i)
					{
							if(lastMouseOver == d)
							{
								return;
							}
							lastMouseOver = d;
						showWindow(owningUser, owningSession, "Processes", d["Hash"]);
						x = 0;
						if(timeMode == "Universal")
						{
							x = xAxisPadding +  timeScale(d["Index MS Universal"]);
						}
						else if(timeMode == "User")
						{
							x = xAxisPadding + timeScale(d["Index MS User"]);
						}
						else
						{
							x = xAxisPadding +  timeScale(d["Index MS Session"]);
						}
						if(cpuScale(d["CPU"]) > bottomVisHeight / 2)
						{
							processTooltipRect.attr("x", x + bottomVisHeight / 50)
									.attr("y", cpuScale(d["CPU"]) - bottomVisHeight / 100);
							processTooltip.attr("x", x + bottomVisHeight / 50)
									.attr("y", cpuScale(d["CPU"]) - bottomVisHeight / 50 - bottomVizFontSize * 6 - ("Arguments" in d) * bottomVizFontSize)
									.attr("alignment-baseline", "auto")
									.attr("dominant-baseline", "auto")
									.text(d["Index"]);
						}
						else
						{
							processTooltipRect.attr("x", x + bottomVisHeight / 50)
									.attr("y", cpuScale(d["CPU"]) + bottomVisHeight / 100);
							processTooltip.attr("x", x + bottomVisHeight / 50)
									.attr("y", cpuScale(d["CPU"]) + bottomVisHeight / 50)
									.attr("alignment-baseline", "hanging")
									.attr("dominant-baseline", "hanging")
									.text(d["Index"]);
						}
						
						processTooltip.append("tspan")
									.attr("x", x + bottomVisHeight / 50)
									.attr("dy", bottomVizFontSize)
									.text(d["Command"]);
						if("Arguments" in d)
						{
							processTooltip.append("tspan")
									.attr("x", x + bottomVisHeight / 50)
									.attr("dy", bottomVizFontSize)
									.text(d["Arguments"].substring(0, 50));
						}
						processTooltip.append("tspan")
									.attr("x", x + bottomVisHeight / 50)
									.attr("dy", bottomVizFontSize)
									.text("User: " + d["User"]);
						processTooltip.append("tspan")
									.attr("x", x + bottomVisHeight / 50)
									.attr("dy", bottomVizFontSize)
									.text("Start: " +d["Start"] + ", Time: " +d["Time"] + ", Stat: " +d["Stat"]);
						processTooltip.append("tspan")
									.attr("x", x + bottomVisHeight / 50)
									.attr("dy", bottomVizFontSize)
									.text("PID: " +d["PID"]);
						processTooltip.append("tspan")
									.attr("x", x + bottomVisHeight / 50)
									.attr("dy", bottomVizFontSize)
									.text("CPU: " +d["CPU"]);
						processTooltip.append("tspan")
									.attr("x", x + bottomVisHeight / 50)
									.attr("dy", bottomVizFontSize)
									.text("Mem: " +d["Mem"] + ", RSS: " + d["RSS"] + ", VSZ: " +d["VSZ"]);
						
						if(cpuScale(d["CPU"]) > bottomVisHeight / 2)
						{
							processTooltipRect.attr("width", processTooltip.node().getBoundingClientRect().width)
									.attr("y", processTooltipRect.attr("y") - processTooltip.node().getBoundingClientRect().height)
									.attr("height", (processTooltip.node().getBoundingClientRect().height));
						}
						else
						{
							processTooltipRect.attr("width", processTooltip.node().getBoundingClientRect().width)
							.attr("height", (processTooltip.node().getBoundingClientRect().height));
						}
						
						if(processTooltipRect.attr("x") > visWidth / 2)
						{
							processTooltipRect.attr("x", processTooltipRect.attr("x") - (bottomVisHeight / 25) - (processTooltipRect.attr("width") + (0)));
							processTooltip.selectAll("*").attr("x", processTooltip.attr("x") - (bottomVisHeight / 25) - (processTooltipRect.attr("width") + (0)));
							processTooltip.attr("x", processTooltip.attr("x") - (bottomVisHeight / 25) - (processTooltipRect.attr("width") + (0)));
						}
						
						if(lastMouseHash == d["Hash"])
						{
							return;
						}
						lastMouseHash = d["Hash"]
						var e = document.createEvent('UIEvents');
						e.initUIEvent('click', true, true, /* ... */);
						g = d3.select("#process_legend_" + d["Hash"]);
						g.node().dispatchEvent(e);
						
					});
		
		
		
		var line = d3.line()
				.x
				(
					function(d, i)
					{
						if(timeMode == "Universal")
						{
							return xAxisPadding +  timeScale(d["Index MS Universal"]);
						}
						else if(timeMode == "User")
						{
							return xAxisPadding + timeScale(d["Index MS User"]);
						}
						else
						{
							return xAxisPadding +  timeScale(d["Index MS Session"]);
						}
					}
				)
				.y
				(
					function(d, i)
					{
						return cpuScale(d["CPU"]);
					}
				)
				.curve(d3.curveMonotoneX);
		
		var enterExit = [];
		
		
		var procLines = newSVG.selectAll("path")
				.data(lineFormattedData)
				.enter()
				.append("path")
				.attr('d', d => line(d.values))
				.attr("fill", "none")
				.attr("class", function(d, i)
						{
							return "clickableBarPreise processPaths process_" + colorScale(d["values"][0]["Hash"] % 20);
						})
				.style("stroke-width", bottomVisHeight / 100)
				.attr("initStrokeWidth", bottomVisHeight / 100)
				.style("stroke", function(d, i)
						{
							return colorScale(d["values"][0]["Process Order"] % 20);
						})
				.attr("initStroke", function(d, i)
						{
							return colorScale(d["values"][0]["Process Order"] % 20);
						})
				.each(function(d, i)
						{
							//console.log(this);
							//console.log(d);
							//var windowsToSelect = processToWindow[d["values"][0]["Hash"]];
							var windowsToSelect = d["values"][0]["Hash"];
							if(windowsToSelect)
							{
								var outerThis = this;
								var outerD = d;
								d3.selectAll(".window_process_" + windowsToSelect)
										.each(function(d, i)
												{
													if(d["Owning User"] != owningUser || d["Owning Session"] != owningSession)
													{
														
													}
													else
													{
													var newEntry = JSON.parse(JSON.stringify(d));
													if(d["Next"])
													{
														var newEntryNext = JSON.parse(JSON.stringify(d["Next"]));
														newEntryNext["Process Path"] = outerThis;
														newEntryNext["Process"] = outerD;
														newEntryNext["Type"] = "Unfocus";
														enterExit.push(newEntryNext)
													}
													newEntry["Process Path"] = outerThis;
													newEntry["Process"] = outerD;
													newEntry["Type"] = "Focus";
													
													enterExit.push(newEntry)
													}
												})
										
							}
						});
		
		
		var procPointsWindow = newSVG.append("g").selectAll("circle")
		.data(enterExit)
		.enter()
		.append("circle")
		.style("pointer-events", "none")
		.attr("cx", function(d, i)
				{
					if(timeMode == "Universal")
					{
						return xAxisPadding +  timeScale(d["Index MS Universal"]);
					}
					else if(timeMode == "User")
					{
						return xAxisPadding + timeScale(d["Index MS User"]);
					}
					else
					{
						return xAxisPadding +  timeScale(d["Index MS Session"]);
					}
				})
		.attr("cy", function(d, i)
				{
					var x = 0;
					if(timeMode == "Universal")
					{
						x = xAxisPadding +  timeScale(d["Index MS Universal"]);
					}
					else if(timeMode == "User")
					{
						x = xAxisPadding + timeScale(d["Index MS User"]);
					}
					else
					{
						x = xAxisPadding +  timeScale(d["Index MS Session"]);
					}
					return findY(d["Process Path"], x);
				})
		.attr("class", function(d, i)
				{
					return "clickableBarPreise process_" + d["Hash"];
				})
		.attr("r", (bottomVisHeight / 50) * 1.25)
		.attr("initR", (bottomVisHeight / 50) * 1.25)
		//.attr("r", 5)
		.attr("fill", function(d, i)
				{
					if(d["Type"] == "Focus")
					{
						return "green";
					}
					return "red";
					//return colorScale(d["Process Order"] % 20);
				})
		.attr("initFill", function(d, i)
				{
					if(d["Type"] == "Focus")
					{
						return "green";
					}
					return "red";
					//return colorScale(d["Process Order"] % 20);
				});
		
		
		var yAxis = d3.axisLeft().scale(cpuScale)
		
		var cpuAxis = newSVG.append("g")
				.attr("transform", "translate(" + xAxisPadding + ", 0)")
				.call(yAxis);
		
		
		var axisLabel = newSVG.append("g")
				.append("text")
				.attr("y", bottomVisHeight / 2 + "px")
				.attr("x", xAxisPadding / 2 + "px")
				//.attr("width", xAxisPadding + "px")
				//.attr("height", bottomVisHeight + "px")
				.attr("alignment-baseline", "central")
				.attr("dominant-baseline", "middle")
				.attr("font-size", bottomVizFontSize * 2)
				.attr("text-anchor", "middle")
				.text("% CPU");
		
		var visLabel = newSVG.append("g")
		.append("text")
		.attr("y", "0px")
		.attr("x", "0px")
		//.attr("width", xAxisPadding + "px")
		//.attr("height", bottomVisHeight + "px")
		.attr("font-size", bottomVizFontSize * 2)
		.attr("alignment-baseline", "hanging")
		.attr("dominant-baseline", "hanging")
		.attr("text-anchor", "left")
		.style("font-weight", "bolder")
		.text("Processes");
		
		processTooltipRect = newSVG.append("g")
		.append("rect")
		.attr("y", "0px")
		.attr("x", "0px")
		.attr("width", "0px")
		.attr("height", "0px")
		.attr("fill", "yellow")
		.attr("opacity", ".75");
		
		processTooltip = newSVG.append("g")
		.append("text")
		.attr("y", "0px")
		.attr("x", "0px")
		//.attr("width", xAxisPadding + "px")
		//.attr("height", bottomVisHeight + "px")
		.attr("font-size", bottomVizFontSize)
		.attr("alignment-baseline", "auto")
		.attr("dominant-baseline", "auto")
		.attr("text-anchor", "left")
		.style("font-weight", "bold")
		.text("");
		
		
		//var highlightTable = d3.select("#highlightDiv").style('overflow-y', 'scroll').style("height", bottomVisHeight + "px");
		var highlightTable = d3.select("#highlightDiv").style("height", bottomVisHeight + "px");

		var legendSVGProcess = highlightTable
				.append("svg")
				.attr("width", "100%")
				.attr("height", (legendHeight * cpuSortedList.length * 2 + legendHeight) + "px");
		
		
		
		legendSVGProcess = legendSVGProcess.append("g");
		
		var legendTitleProcess = legendSVGProcess.append("text")
				.attr("x", "50%")
				.attr("y", .5 * legendHeight)
				.attr("alignment-baseline", "central")
				.attr("dominant-baseline", "middle")
				.attr("text-anchor", "middle")
				//.attr("font-weight", "bolder")
				.text("Processes:");
		
		cpuSortedList = cpuSortedList.reverse();
		var legendProcess = legendSVGProcess.append("g")
				.selectAll("rect")
				.data(cpuSortedList)
				.enter()
				.append("rect")
				.attr("x", 0)
				.attr("width", "100%")
				//.attr("width", legendWidth)
				.attr("y", function(d, i)
						{
							return legendHeight * (2 * i + 1);
						})
				.attr("height", 2 * legendHeight)
				.attr("stroke", "black")
				.attr("stroke-width", 0)
				.attr("initStrokeWidth", 0)
				.attr("fill", function(d, i)
						{
							return colorScale(d[0]["Process Order"] % 20);
						})
				.attr("initFill", function(d, i)
						{
							return colorScale(d[0]["Process Order"] % 20);
						})
				.attr("id", function(d, i)
						{
							return "process_legend_" + d[0]["Hash"];
						})
				.on("click", function(d, i)
				{
					for(selection in curSelElements)
					{
						if(curSelElements[selection] && !(curSelElements[selection].empty()) && curSelElements[selection].attr("initFill"))
						{
							//curSelElements[selection].attr("fill", curSelElements[selection].attr("initFill"));
							curSelElements[selection].attr("fill", function(){ return this.getAttribute("initFill"); });
							curSelElements[selection].attr("r", function()
								{
									if(this.getAttribute("initR"))
									{
										return this.getAttribute("initR");
									}
									return 0;
								});
						}
					}
					curSelElements = [];
					
					if(curSelectProcess)
					{
						curLabel = d3.select("#process_legend_" + curSelectProcess[0]["Hash"])
						curLabel.attr("fill", curLabel.attr("initFill"));
					}
					
					if(curSelectProcess == d)
					{
						curSelectProcess = null;
						return;
					}
					
					curHash = d[0]["Hash"];
					
					windowBars = d3.selectAll(".window_process_" + d[0]["Hash"])
					windowLegendBars = d3.select("#legend_" + processToWindow[d[0]["Hash"]])
					legendBars = d3.selectAll(".legend_" + d[0]["Hash"]);
					processCircles = d3.selectAll(".process_" + d[0]["Hash"])
					curLabel = d3.select("#process_legend_" + d[0]["Hash"])
					
					highlightColor = "#ffff00";
					
					windowBars.attr("fill", highlightColor);
					windowLegendBars.attr("fill", highlightColor);
					legendBars.attr("fill", highlightColor);
					processCircles.attr("fill", highlightColor).attr("r", bottomVisHeight / 25);
					curLabel.attr("fill", highlightColor);
					
					curSelElements.push(windowBars);
					curSelElements.push(windowLegendBars);
					curSelElements.push(legendBars);
					curSelElements.push(processCircles);
					
					curSelectProcess = d;
				})
				.attr("class", "clickableBar")
				.attr("initStrokeWidth", 0);
		
		
		var legendTextProcess = legendSVGProcess.append("g")
		.selectAll("text")
		.data(cpuSortedList)
		.enter()
		.append("text")
		//.attr("font-size", 11)
		.attr("x", 0)
		.attr("y", function(d, i)
				{
					//return legendHeight * (i + 1);
					//return legendHeight * (i) + legendHeight;
					return legendHeight * (2 * i + 1) + legendHeight * .5;
				})
		.attr("height", legendHeight * .75)
		.text(function(d, i)
				{
					return d[0]["User"] + ":" + d[0]["Start"] + ":" + d[0]["PID"];
				})
		.attr("fill", function(d, i)
				{
					if(i % 2 == 0)
					{
						return "#FFF";
					}
					else
					{
						return "#000";
					}
				})
		.attr("font-weight", "bolder")
		.attr("dominant-baseline", "middle")
		.attr("stroke", function(d, i)
				{
					if(i % 2 == 0)
					{
						return "none";
					}
					else
					{
						return "none";
					}
				});
		
		
		var legendTextProcessCmd = legendSVGProcess.append("g")
		.selectAll("text")
		.data(cpuSortedList)
		.enter()
		.append("text")
		//.attr("font-size", 11)
		.attr("x", 0)
		.attr("y", function(d, i)
				{
					//return legendHeight * (i + 1);
					//return legendHeight * (i) + legendHeight;
					return legendHeight * (2 * i + 2) + legendHeight * .5;
				})
		.attr("height", legendHeight * .75)
		.text(function(d, i)
				{
					return d[0]["Command"];
				})
		.attr("fill", function(d, i)
				{
					if(i % 2 == 0)
					{
						return "#FFF";
					}
					else
					{
						return "#000";
					}
				})
		.attr("font-weight", "bolder")
		.attr("dominant-baseline", "middle")
		.attr("stroke", function(d, i)
				{
					if(i % 2 == 0)
					{
						return "none";
					}
					else
					{
						return "none";
					}
				});
		
		
	}
	
	var curSelectProcess;
	var curSelElements = [];
	
	function showWindow(username, session, type, timestamp)
	{
		if(username != curSelectUser || session != curSelectSession)
		{
			clearWindow();
		}
		var curSlot = lookupTable[username][session][type][timestamp];
		//console.log(curSlot);
		var formattedSlot = [];
		var finalFormattedSlot = [];
		
		var highlights = [];
		
		var count = 0;
		for(key in curSlot)
		{
			//console.log(key);
			//console.log(curSlot[key]);
			if(key == "Next" || key == "Prev")
			{
				formattedSlot[count] = {"key":"Next Index MS", "value":curSlot[key]["Index MS"]};
				count++;
				formattedSlot[count] = {"key":"Next Index", "value":curSlot[key]["Index"]};
			}
			else
			{
				formattedSlot[count] = {"key":key, "value":curSlot[key]};
			}
			count++;
		}
		
		//console.log(formattedSlot);
		formattedSlot = formattedSlot.sort(function(a, b)
		{
			if(a.key < b.key) { return -1; }
			if(a.key > b.key) { return 1; }
			return 0;
		})
		
		//console.log(formattedSlot);
		
		for(x=0; x<formattedSlot.length; x+=2)
		{
			if(formattedSlot[x]["key"] in highlightMap)
			{
				highlights.push({"key1":formattedSlot[x]["key"], "value1":formattedSlot[x]["value"]});
				
				var toHighlight = d3.select("#legend_" + SHA256(formattedSlot[x]["value"]));
				toHighlight.attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
				curHighlight.push(toHighlight);
			}
			if(x+1 >= formattedSlot.length)
			{
				finalFormattedSlot[x/2] = {"key1":formattedSlot[x]["key"], "value1":formattedSlot[x]["value"], "key2":"", "value2":""};
			}
			else
			{
				finalFormattedSlot[x/2] = {"key1":formattedSlot[x]["key"], "value1":formattedSlot[x]["value"], "key2":formattedSlot[x+1]["key"], "value2":formattedSlot[x+1]["value"]};
				if(formattedSlot[x + 1]["key"] in highlightMap)
				{
					highlights.push({"key1":formattedSlot[x + 1]["key"], "value1":formattedSlot[x + 1]["value"]});
					
					var toHighlight = d3.select("#legend_" + SHA256(formattedSlot[x + 1]["value"]));
					toHighlight.attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
					curHighlight.push(toHighlight);
				}
			}
		}
		
		//finalFormattedSlot.unshift("<td colspan=4><div align=\"center\">Details</div></td>");
		//console.log(finalFormattedSlot);
		d3.select("#extraInfoTable")
				.selectAll("tr")
				.remove();
		
		//d3.select("#infoTable").append("tr").html("<td colspan=4><div align=\"center\">Details</div></td>")
		
		
		d3.select("#extraInfoTable")
				.selectAll("tr")
				.data(finalFormattedSlot)
				.enter()
				.append("tr")
				.html(function(d, i)
						{
							//if(i == 0)
							//{
							//	return d;
							//}
							return "<td width=\"12.5%\" style=\" max-width:" + (.125 * visWidth) + "px\">" + d["key1"] + "</td>" + "<td width=\"37.5%\" style=\" max-width:" + (.375 * visWidth) + "px; overflow-x:auto;\">" + d["value1"] + "</td>" + "<td width=\"12.5%\" style=\" max-width:" + (.125 * visWidth) + "px\">" + d["key2"] + "</td>" + "<td width=\"37.5%\" style=\" max-width:" + (.375 * visWidth) + "px; overflow-x:auto;\">" + d["value2"] + "</td>";
						});
		
		//console.log(curSlot);
		
		//console.log(curSlot["Start Time"]);
		
		d3.select("#screenshotDiv")
				.selectAll("*")
				.remove();
		
		d3.select("#screenshotDiv")
				.append("img")
				.attr("width", "100%")
				.attr("src", "./getClosestScreenshot.jpg?username=" + curSlot["Owning User"] + "&timestamp=" + curSlot["Index MS"] + "&session=" + curSlot["Original Session"] + "&event=" + eventName)
				.attr("style", "cursor:pointer;")
				.on("click", function()
						{
							showLightbox("<tr><td><div width=\"100%\"><img src=\"./getClosestScreenshot.jpg?username=" + curSlot["Owning User"] + "&timestamp=" + curSlot["Index MS"] + "&session=" + curSlot["Original Session"] + "&event=" + eventName + "\" style=\"width: 100%;\"></div></td></tr>");
						});
		
		d3.select("#extraHighlightDiv")
			.selectAll("*")
			.remove();

		highlightTable = d3.select("#extraHighlightDiv")
			.selectAll("p")
			.data(highlights)
			.enter()
			.append("p")
			.html(function(d, i)
					{
						return "<b>" + d["key1"] + ":</b><br />" + d["value1"];
					});
		
	}
	
	//var curFocus;
	
	

</script>
</html>