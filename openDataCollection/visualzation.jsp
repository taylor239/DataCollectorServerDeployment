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
<table width="100%" style="border:0">
	<tr>
		<td class="layoutTableSide" style="border:0">
		<div align="left">
			<span style="cursor: pointer" onclick="toggleLeft();">⊟</span>
		</div>
		</td>
		<td class="layoutTableCenter" style="border:0">
		
		</td>
		<td class="layoutTableSide" style="border:0">
		
		</td>
	</tr>
</table>
<table id="bodyTable">
	<tr>
		<td class="layoutTableSide leftCol">
			<table id="optionFilterTable" width="100%" height="100%">
					<tr>
						<td colspan="5">
								<div align="center">
									Options
								</div>
						</td>
					</tr>
					<tr>
						<td colspan="5">
									Playback Speed
						</td>
					</tr>
					<tr>
						<td colspan="5">
									<input type="text" size="4" id="playbackSpeed" name="playbackSpeed" value="10">x
						</td>
					</tr>
					
					<tr>
						<td colspan="5">
									Timeline Zoom
						</td>
					</tr>
					<tr>
						<td colspan="3">
									<input type="text" size="4" id="timelineZoom" name="timelineZoom" value="1">x
						</td>
						<td colspan="2">
									<button type="button" onclick="start(true)">Apply</button>
						</td>
					</tr>
					<tr id="filterTitle1">
						<td colspan="5">
							<div align="center">
									Filters
							</div>
						</td>
					</tr>
					<tr>
						<td colspan="2">
						<div align="center">
						<button type="button" onclick="saveFilters()">Save</button>
						</div>
						</td>
						<td colspan="3">
						<div align="center">
						<input type="text" size="15" id="saveFilter" name="saveFilter" value="Name">
						</div>
						</td>
					</tr>
					<tr>
						<td colspan="5">
						<div align="center">
						<button type="button" onclick="loadFilter(true)">Load</button>
						<button type="button" onclick="loadFilter(false)">Append</button>
						<button type="button" onclick="deleteFilter()">Delete</button>
						</div>
						</td>
					</tr>
					<tr>
						<td colspan="5">
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
						<td width="20%">
						Field
						</td>
						<td width="40%">
						Value
						</td>
						<td width="20%">
						Server
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
						<td>
						
						</td>
						<td id = "filter_add_add" class="clickableHover" onclick="addFilter()">
						<div align="center">
						+
						</div>
						</td>
					</tr>
					
					
			</table>
		</td>
		<td class="layoutTableCenter centerCol" id="mainVisContainer">
			<table style="overflow-x:auto" id="visTable">
			<tr><td>
			<div align="center" id="title">User Timelines for <%=eventName %></div>
			</td></tr>
			<tr><td id="visRow">
			<div align="center" id="mainVisualization">
			</div>
			</td></tr>
			</table>
		</td>
		<td class="layoutTableSide rightCol">
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
		<td class="layoutTableSide leftCol">
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
		<td class="layoutTableCenter centerCol">
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
		<td class="layoutTableSide rightCol">
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
	var showLeft = true;
	function toggleLeft()
	{
		showLeft = !(showLeft);
		toDisplay = "none";
		if(showLeft)
		{
			toDisplay = "";
			d3.selectAll(".leftCol").style("display", toDisplay);
			visWidthParent -= d3.select(".leftCol").node().offsetWidth;
		}
		else
		{
			visWidthParent += d3.select(".leftCol").node().offsetWidth;
			d3.selectAll(".leftCol").style("display", toDisplay);
		}
		start(true);
	}
	
	var filters = [];
	var filtersTitle = [];
	var startFilters = 0;
	
	var firstFilter = {}
	firstFilter["Level"] = 1;
	firstFilter["Field"] = "";
	firstFilter["Value"] = "== 'Aggregated'";
	//firstFilter["id"] = "filter_0"
	filters.push(firstFilter);
	
	
	
	
	
	var containingTableRow = document.getElementById("mainVisContainer");
	var visTable = document.getElementById("visTable");
	var visRow = document.getElementById("visRow");
	
	var windowWidth = window.innerWidth;
	var windowHeight = window.innerHeight;
	
	console.log(windowHeight + ", " + windowWidth);
	
	var visPadding = 20;
	
	var visWidth = containingTableRow.offsetWidth - visPadding;
	var visWidthParent = containingTableRow.offsetWidth - visPadding;
	var visHeight = windowHeight * .5;
	var bottomVisHeight = windowHeight * .25;
	var sidePadding = 24;
	
	var barHeight = visHeight / 10;
	var xAxisPadding = 3 * barHeight;
	//var xAxisPadding = .2 * visWidth;
	
	var eventName = "<%=eventName %>";
	var adminName = "<%=request.getParameter("email") %>";
	
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
	
	var userSessionAxisY = {};
	
	var legendWidth = 25;
	var legendHeight = visHeight / 25;
	
	var timeMode = "Session";
	
	var highlightMap = {};
	highlightMap["TaskName"] = true;
	highlightMap["FirstClass"] = true;
	
	function deleteFilter()
	{
		var toDelete = document.getElementById("savedFilters").value;
		var urlToPost = "deleteFilter.json?event=" + eventName + "&deleteName=" + toDelete;
		d3.json(urlToPost, function(error, data)
				{
					if(data["result"] == "okay")
					{
						savedFilters = document.getElementById("savedFilters");
						savedFilters.remove(savedFilters.selectedIndex);
					}
					else
					{
						showLightbox("<tr><td><div width=\"100%\">Error deleting filter set.</div></td></tr>");
					}
				});
	}
	
	function loadFilter(removeOld)
	{
		if(removeOld)
		{
			filters = [];
		}
		var toLoad = document.getElementById("savedFilters").value;
		var filtersToLoad = savedFilters[toLoad];
		for(toAdd in filtersToLoad)
		{
			var filterToAdd = {}
			filterToAdd["Level"] = filtersToLoad[toAdd]["Level"];
			filterToAdd["Field"] = filtersToLoad[toAdd]["Field"];
			filterToAdd["Value"] = filtersToLoad[toAdd]["Value"];
			//firstFilter["id"] = "filter_0"
			filters.push(filterToAdd);
		}
		rebuildFilters();
		start(true);
	}
	
	function saveFilters()
	{
		
		var saveAs = document.getElementById("saveFilter").value;
		var urlToPost = "addFilters.json?event=" + eventName + "&saveName=" + saveAs;
		var x=0;
		for(entry in filters)
		{
			//console.log(filters[entry]);
			urlToPost += "&filterLevel" + x + "=" + filters[entry]["Level"];
			urlToPost += "&filterValue" + x + "=" + filters[entry]["Value"];
			urlToPost += "&filterField" + x + "=" + filters[entry]["Field"];
			x++;
		}
		d3.json(urlToPost, function(error, data)
				{
					if(data["result"] == "okay")
					{
						newOption = new Option(saveAs, saveAs);
						document.getElementById("savedFilters").add(newOption,undefined);
					}
					else
					{
						showLightbox("<tr><td><div width=\"100%\">Error saving filter set.</div></td></tr>");
					}
					//console.log(data);
				});
	}
	
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
						+"<div align=\"center\">"
						+"<input type=\"checkbox\" id=\"filter_server_" + (i - startFilters) + "\" name=\"filter_server_" + (i - startFilters) + "\" value=\"filter_server_" + (i - startFilters) + "\">"
						+"</div>"
						+"</td>"
						+"<td class=\"clickableHover\" id = \"filter_" + (i - startFilters) + "_remove\">"
						+"<div align=\"center\" onclick=\"removeFilter(" + (i - startFilters) + ")\">"
						+"X"
						+"</div>"
						+"</td>";
					});
	}
	
	//rebuildFilters();
	
	
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
			//console.log(dataToModify);
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
					//dataToModify[user][session]["screenshots"][entry]["Screenshot"] = getScreenshotData;
					//dataToModify[user][session]["screenshots"][entry]["HasScreenshot"] = hasScreenshot;
				}
				downloadImages(user, session, dataToModify[user][session]["screenshots"], 0);
				
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
		return dataToModify;
	}
	
	var summaryProcStats = {};
	var summaryProcStatsArray = [];
	var measureBy = "session";
	function filter(dataToFilter, filters)
	{
		summaryProcStats = {};
		summaryProcStatsArray = [];
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
			var userProcFound = {};
			
			toFilter = filterMap[0];
			if(toFilter)
			{
				for(curFilter in toFilter)
				{
					if(!(eval(("'" + user + "'" + toFilter[curFilter]["Value"]))))
					{
						delete dataToFilter[user];
					}
				}
			}
			for(session in dataToFilter[user])
			{
				if(measureBy = "session")
				{
					var userProcFound = {};
				}
				//console.log(session);
				toFilter = filterMap[1];
				if(toFilter)
				{
					for(curFilter in toFilter)
					{
						if(!(eval("'" + session + "'" + toFilter[curFilter]["Value"])))
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
							if(!(eval("'" + data + "'" + toFilter[curFilter]["Value"])))
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
						var filteredOut = false;
						if(toFilter)
						{
							for(curFilter in toFilter)
							{
								if(toFilter[curFilter]["Field"] in dataToFilter[user][session][data][entry])
								{
									if(!(eval("'" + dataToFilter[user][session][data][entry][toFilter[curFilter]["Field"]] + "'" + toFilter[curFilter]["Value"])))
									{
										//console.log(dataToFilter[user][session][data][entry]);
										dataToFilter[user][session][data].splice(entry, 1);
										entry--;
										curLength = dataToFilter[user][session][data].length;
										//console.log(entry);
										//toSplice.push(entry);
										filteredOut = true;
										break;
									}
								}
							}
						}
						if(!filteredOut)
						{
							if(data == "processes")
							{
								if(!(dataToFilter[user][session][data][entry]["Command"] in userProcFound))
								{
									if(dataToFilter[user][session][data][entry]["Command"] in summaryProcStats)
									{
										summaryProcStats[dataToFilter[user][session][data][entry]["Command"]]["count"]++;
									}
									else
									{
										procStatMap = {};
										procStatMap["Command"] = dataToFilter[user][session][data][entry]["Command"];
										procStatMap["count"] = 1;
										summaryProcStats[dataToFilter[user][session][data][entry]["Command"]] = procStatMap;
									}
									userProcFound[dataToFilter[user][session][data][entry]["Command"]] = 0
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
			
		var minProc = Number.POSITIVE_INFINITY;
		var maxProc = 0;
		summaryProcStatsArray = Object.values(summaryProcStats).sort(function(a, b)
				{
					if(a["count"] > maxProc)
					{
						maxProc = a["count"];
					}
					if(a["count"] < minProc)
					{
						minProc = a["count"];
					}
					if(b["count"] > maxProc)
					{
						maxProc = b["count"];
					}
					if(b["count"] < minProc)
					{
						minProc = b["count"];
					}
					return b["count"] - a["count"];
				});
		summaryProcStats["Max"] = maxProc;
		summaryProcStats["Min"] = minProc;
		//console.log(summaryProcStatsArray);
		return dataToFilter;
	}
	
	var theNormData;
	var theNormDataClone;
	var theNormDataDone = false;
	var origTitle = d3.select("#title").text();
	
	var savedFilters = {};
	d3.json("Filters.json?event=" + eventName, function(error, data)
			{
				saveNames = [];
				
				for(entry in data)
				{
					curEntry = {};
					if(!(data[entry]["SaveName"] in savedFilters))
					{
						savedFilters[data[entry]["SaveName"]] = [];
						saveNames.push(data[entry]["SaveName"]);
					}
					curEntry["Level"] = data[entry]["Level"];
					curEntry["Field"] = data[entry]["Field"];
					curEntry["Value"] = data[entry]["Value"];
					curEntry["Server"] = data[entry]["Server"];
					savedFilters[data[entry]["SaveName"]].push(curEntry);
				}
				
				
				d3.select("#savedFilters")
					.selectAll("option")
					.remove();
				d3.select("#savedFilters")
					.selectAll("option")
					.data(saveNames)
					.enter()
					.append("option")
					.attr("value", function(d, i)
							{
								console.log(d);
								return d;
							})
					.html(function(d, i)
							{
								return d;
							});
					
				d3.select("#optionFilterTable")
				.selectAll("tr")
				.each(function(d, i)
						{
							//console.log(d);
							//console.log(this);
							filtersTitle.push(this);
							startFilters = i;
						});
				rebuildFilters();
				downloadData();
			})
	
			
	var db;
	var objectStore;
	
	async function persistData(key, value)
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
	
	async function getScreenshotData()
	{
		//console.log("Getting screenshot:");
		var hashVal = this["ImageHash"];
		//console.log(hashVal);
		var toReturn = (await retrieveData(hashVal));
		//console.log(toReturn)
		return toReturn.value;
	}
	
	async function hasScreenshot(entry)
	{
		//console.log("Getting screenshot:");
		var hashVal = entry["ImageHash"];
		//console.log(hashVal);
		var toReturn = (await hasData(hashVal));
		return toReturn;
	}
	
	var downloadedImageSize = 0;
	var downloadedSize = 0;
	
	async function downloadData()
	{
		var needsUpdate = false;
		d3.select("body").style("cursor", "wait");
		lastEvent = (await retrieveData("event").value)
		//if(eventName != lastEvent)
		if(true)
		{
			persistData("event", eventName);
			persistData("time", new Date());
			needsUpdate = true;
		}
		lastTime = (await retrieveData("time").value)
		origTitle += ", last visit on " + lastTime;
		
		d3.select("#title")
			.html(origTitle);
		
		
		if(needsUpdate)
		{
			d3.select("#title")
				.html(origTitle + "<br />Starting download...");
			d3.json("logExport.json?event=" + eventName + "&datasources=keystrokes,mouse,processes,windows,events,environment,screenshotindices&normalize=none", async function(error, data)
				{
					theNormData = preprocess(data);
					try
					{
						await persistData("data", theNormData);
					}
					catch(err)
					{
						console.log(err);
					}
					//theNormDataClone = JSON.parse(JSON.stringify(theNormData));
					//try
					//{
					//	theNormDataClone = (await retrieveData("data")).value;
					//}
					//catch(err)
					//{
					//	console.log(err);
					//}
					theNormDataDone = true;
					
					d3.select("#title")
						.html(origTitle + "<br />Index data: <b>" + downloadedSize + "</b> bytes; new image data: <b>" + downloadedImageSize + "</b> bytes, finished " + downloadedSessions + " of " + totalSessions + " sessions.")
					
					
					d3.select("body").style("cursor", "");
					start(true);
				})
				.on("progress", function(d, i)
						{
							downloadedSize = d["loaded"];
							d3.select("#title")
									.html(origTitle + "<br />Data Size: <b>" + d["loaded"] + "</b> bytes")
							//console.log(d);
						});
		}
		else
		{
			theNormDataDone = true;
			d3.select("body").style("cursor", "");
			start(true);
		}
	}
	
	var chunkSize = 50;
	
	var downloadedSessions = 0;
	var totalSessions = 0;
	
	async function downloadImages(userName, sessionName, imageArray, nextCount)
	{
		var curCount = nextCount;
		
		while(curCount < imageArray.length)
		{
			var entry = curCount;
			var curScreenshot = (await hasScreenshot(imageArray[entry]));
			//console.log(entry + ": " + curScreenshot)
			if(curScreenshot)
			{
				curCount = entry + 1;
				//break;
			}
			else
			{
				break;
			}
		}
		if(curCount < imageArray.length)
		{
			//console.log("Fetching screenshots from " + userName + ", " + sessionName + ": " + curCount + " : " + chunkSize);
			//console.log(imageArray);
			var curSelect = "&users=" + userName + "&sessions=" + sessionName + "&first=" + curCount + "&count=" + chunkSize;
			await d3.json("logExport.json?event=" + eventName + "&datasources=screenshots&normalize=none" + curSelect, async function(error, data)
			{
				for(user in data)
				{
					for(session in data[user])
					{
						
						var curScreenshotList = data[user][session]["screenshots"];
						
						for(screenshot in curScreenshotList)
						{
							var hashVal = SHA256(user + session + curScreenshotList[screenshot]["Index MS"]);
							//console.log(imageArray[screenshot]);
							try
							{
								await persistData(hashVal, curScreenshotList[screenshot]["Screenshot"]);
							}
							catch(err)
							{
								console.log(err);
							}
							curCount++;
						}
					}
				}
				
				d3.select("#title")
					.html(origTitle + "<br />Index data: <b>" + downloadedSize + "</b> bytes; new image data: <b>" + downloadedImageSize + "</b> bytes, finished " + downloadedSessions + " of " + totalSessions + " sessions.")
				
				
				if(curCount < imageArray.length)
				{
					console.log("Continuing screenshots from " + userName + ", " + sessionName + ": " + curCount + " : " + chunkSize + " of " + imageArray.length);
					downloadImages(userName, sessionName, imageArray, curCount);
				}
				else
				{
					downloadedSessions++;
					d3.select("#title")
					.html(origTitle + "<br />Index data: <b>" + downloadedSize + "</b> bytes; new image data: <b>" + downloadedImageSize + "</b> bytes, finished " + downloadedSessions + " of " + totalSessions + " sessions.")
				}
				
			})
			.on("progress", async function(d, i)
					{
						//downloadedSize = d["loaded"];
						downloadedImageSize += d["loaded"];
						d3.select("#title")
						.html(origTitle + "<br />Index data: <b>" + downloadedSize + "</b> bytes; image data: <b>" + downloadedImageSize + "</b> bytes, finished " + downloadedSessions + " of " + totalSessions + " sessions.");
					});
		}
		else
		{
			downloadedSessions++;
			d3.select("#title")
			.html(origTitle + "<br />Index data: <b>" + downloadedSize + "</b> bytes; new image data: <b>" + downloadedImageSize + "</b> bytes, finished " + downloadedSessions + " of " + totalSessions + " sessions.")
		}
	}
	
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
	
	
	var visWidthParent = (containingTableRow.offsetWidth - visPadding);
	async function start(needsUpdate)
	{
		d3.select(visRow).style("max-width", (visWidthParent + visPadding) + "px");
		d3.select(visTable).style("max-width", (visWidthParent + visPadding) + "px");
		
		var timelineZoom = Number(document.getElementById("timelineZoom").value);
		visWidth = (visWidthParent) * timelineZoom;
		
		if(needsUpdate)
		{
			d3.select("#mainVisualization").selectAll("*").remove();
			//d3.select("#mainVisualization").html("");
			d3.select("#legend").selectAll("*").remove();
			//d3.select("#legend").html("");
			clearWindow();
			theNormData = ((await retrieveData("data")).value);
			theNormData = filter(theNormData, filters);
			showDefault();
		}
		console.log("Starting Main Vis")
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
				minTimeUserAbsolute = Number.POSITIVE_INFINITY;
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
							if(dataType == "screenshots")
							{
								thisData[x]["Hash"] = SHA256(user + session + thisData[x]["Index MS"]);
								thisData[x]["Screenshot"] = getScreenshotData;
							}
							
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
						showDefault();
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
				.style("pointer-events", "none")
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
		
		var filterButtonsUser = svg.append("g")
		.selectAll("rect")
		.data(userOrderArray)
		.enter()
		.append("rect")
		.attr("x", visWidth - (xAxisPadding / 2 - xAxisPadding / 20))
		.attr("width", xAxisPadding / 2 - xAxisPadding / 20)
		.attr("height", barHeight - (xAxisPadding / 25))
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
					return("filterbuttonuser_" + SHA256(userOrderMap[d]));
				})
		.on("click", function(d, i)
				{
					addFilterDirect(0, "", "!= '" + userOrderMap[d] + "'");
				});
		
		
		var filterLabelsUser = svg.append("g")
		.selectAll("text")
		.data(userOrderArray)
		.enter()
		.append("text")
		.attr("x", visWidth - (xAxisPadding / 2 - xAxisPadding / 20) + xAxisPadding / 4 - xAxisPadding / 40)
		.attr("width", xAxisPadding / 2)
		.attr("height", barHeight - 2 * (xAxisPadding / 25))
		.attr("y", function(d, i)
				{
					if(i == 0)
					{
						curSessionCount = 0;
					}
					numSessions = Object.keys(theNormData[userOrderMap[d]]["Session Ordering"]["Order List"]).length;
					toReturn = barHeight * i + barHeight * 2 * curSessionCount + barHeight / 2 - (xAxisPadding / 50);
					curSessionCount += numSessions;
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
					return("filterbuttonuser_label_" + SHA256(userOrderMap[d]));
				})
		.classed("clickableBar", true);
		
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
					return colorScale(windowColorNumber[d["FirstClass"]]);
				})
		.attr("initFill", function(d, i)
				{
					return colorScale(windowColorNumber[d["FirstClass"]]);
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
						showDefault();
						return;
					}
					
					d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					d3.select(this).attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
					curStroke = this;
					showWindow(d["Owning User"], d["Owning Session"], "Windows", d["Index MS"]);
				})
		.attr("class", function(d)
			{
				processToWindow[SHA256(d["User"] + d["Start"] + d["PID"])] = SHA256(d["FirstClass"]);
				if(!(SHA256(d["FirstClass"]) in windowToProcess))
				{
					windowToProcess[SHA256(d["FirstClass"])] = [];
				}
				windowToProcess[SHA256(d["FirstClass"])].push(SHA256(d["User"] + d["Start"] + d["PID"]));
				return "clickableBar " + "select_" + SHA256(d["FirstClass"]) + " " + "window_process_" + SHA256(d["User"] + d["Start"] + d["PID"]);
			})
		
		//.classed("clickableBar", true)
		.attr("z", 2);
		
		var foregroundTextG = svg.append("g");
		
		/*
		var foregroundText = foregroundTextG
		.selectAll("text")
		.data(windowTimeline)
		.enter()
		.append("text")
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
		.attr("y", function(d, i)
				{
					
					return d["Session Order"] * barHeight * 2 + d["User Order"] * barHeight + barHeight + xAxisPadding / 50;
				})
		.attr("fill", function(d, i)
				{
					if(windowColorNumber[d["FirstClass"]] % 2 == 1)
					{
						return "Black"
					}
					return "White"
				})
		.attr("textLength", function(d, i)
				{
					if(timeMode == "Session")
					{
						return d["Time Scale Session"](d["End MS Session"] - d["Index MS Session"]) + "px";
					}
					else if(timeMode == "User")
					{
						return d["Time Scale User"](d["End MS User"] - d["Index MS User"]) + "px";
					}
					else if(timeMode == "Universal")
					{
						return d["Time Scale Universal"](d["End MS Universal"] - d["Index MS Universal"]) + "px";
					}
					return (timeScale(d["End Time MS"] - d["Start Time MS"]) -1) + "px";
				})
		.attr("font-size", barHeight / 4)
		.attr("dominant-baseline", "hanging")
		.style("pointer-events", "none")
		.attr("clip-path", function(d, i)
				{
					return "url(#ellipse-clip)";
				})
		.attr("opacity", 1)
		.text(function(d, i)
				{
					return d["Name"];
				});
		*/
		
		var eventTimeline;
		var eventTypeNumbers = {};
		var eventTypeArray = [];
		var taskRects = svg.append("g")
		.selectAll("rect")
		.data(function()
				{
					function binarySearchArray(items, value){
					    var firstIndex  = 0,
					        lastIndex   = items.length - 1,
					        middleIndex = Math.floor((lastIndex + firstIndex)/2);
		
					    while(items[middleIndex] != value && firstIndex < lastIndex)
					    {
					       if (value < items[middleIndex])
					        {
					            lastIndex = middleIndex - 1;
					        } 
					      else if (value > items[middleIndex])
					        {
					            firstIndex = middleIndex + 1;
					        }
					        middleIndex = Math.floor((lastIndex + firstIndex)/2);
					    }
		
					 return middleIndex;
					}
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
							var openSpots = [];
							openSpots.push(0);
							
							//console.log("New session");
							var maxNumActive = 1;
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
								
								if(!(eventsList[z]["Source"] in eventTypeNumbers))
								{
									var eventType = {};
									eventType["Source"] = eventsList[z]["Source"];
									eventType["Number"] = Object.keys(eventTypeNumbers).length % 8;
									eventTypeNumbers[eventType["Source"]] = eventType;
									eventTypeArray.push(eventType);
								}
								
								if(eventsList[z]["Description"] == "start" || !(eventsList[z]["TaskName"] in curActiveMap))
								{
									//var placeholder = {};
									//placeholder["Index MS Session"] = theNormData[theUser][curSession]["Index MS Session Max"];
									//placeholder["Index MS User"] = theNormData[theUser]["Index MS User Max"];
									
									//eventsList[z]["Next"] = placeholder;
									//if(openSpots.length == 0)
									//{
									//	eventsList[z]["Active Row"] = Object.keys(curActiveMap).length;
									//}
									//else
									//{
									if(eventsList[z]["Description"] == "start")
									{
										//console.log("Got new start");
										//console.log(openSpots);
										//console.log("Cur active " + Object.keys(curActiveMap).length);
									}
									if(openSpots.length == 0)
									{
										openSpots.push(Object.keys(curActiveMap).length)
										if(Object.keys(curActiveMap).length + 1 > maxNumActive)
										{
											maxNumActive = Object.keys(curActiveMap).length + 1;
										}
									}
									eventsList[z]["Active Row"] = openSpots.shift();
									//}
									if(!(eventsList[z]["Description"] == "start"))
									{
										//maxNumActive++;
										//eventsList[z]["Active Row"] = maxNumActive;
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
									//if(Object.keys(curActiveMap).length > maxNumActive)
									//{
									//	maxNumActive = Object.keys(curActiveMap).length;
									//}
								}
								else
								{
									eventsList[z]["Active Row"] = curActiveMap[eventsList[z]["TaskName"]]["Active Row"];
									curActiveMap[eventsList[z]["TaskName"]]["Next"] = eventsList[z];
									curActiveMap[eventsList[z]["TaskName"]] = eventsList[z];
									if(eventsList[z]["Description"] == "end")
									{
										delete curActiveMap[eventsList[z]["TaskName"]];
										openRow = eventsList[z]["Active Row"];
										//console.log("Returning " + openRow)
										if(openSpots.length == 0)
										{
											openSpots.push(openRow);
										}
										else
										{
											closestVal = binarySearchArray(openSpots, openRow)
											if(openSpots[closestVal] > openRow)
											{
												openSpots.splice(closestVal - 1, 0, openRow);
											}
											else
											{
												openSpots.splice(closestVal, 0, openRow);
											}
										}
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
					return colorScaleAccent(eventTypeNumbers[d["Source"]]["Number"]);
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
						clearWindow(); curStroke = null;
						showDefault();
						return;
					}
					d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					d3.select(this).attr("stroke", "#ffff00").attr("stroke-width", xAxisPadding / 50);
					curStroke = this;
					showWindow(d["Owning User"], d["Owning Session"], "Events", d["Index MS"]);
				})
		.classed("clickableBar", true)
		.attr("z", 3);
		
		var taskText = svg.append("g")
		.selectAll("text")
		.data(eventTimeline)
		.enter()
		.append("text")
		.style("pointer-events", "none")
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
		.attr("y", function(d, i)
				{
					var totalHeight =  (barHeight - xAxisPadding / 25) / d["Max Active"];
					//totalHeight = totalHeight * 2;
					return d["Session Order"] * barHeight * 2 + d["User Order"] * barHeight + barHeight * 2 + d["Active Row"] * totalHeight + (totalHeight * .5) + xAxisPadding / 100;
				})
		.attr("dominant-baseline", "middle")
		.style("font-size", function(d, i)
				{
					var totalWidth = 0;
					if(timeMode == "Session")
					{
						totalWidth = .75 * (d["Time Scale Session"](d["Next"]["Index MS Session"] - d["Index MS Session"]));
					}
					else if(timeMode == "User")
					{
						totalWidth = .75 * (d["Time Scale User"](d["Next"]["Index MS User"] - d["Index MS User"]));
					}
					else if(timeMode == "Universal")
					{
						totalWidth = .75 * (d["Time Scale Universal"](d["Next"]["Index MS Universal"] - d["Index MS Universal"]));
					}
					else
					{
						totalWidth = .75 *  (timeScale(d["End Time MS"] - d["Start Time MS"]) -1);
					}
					var totalHeight =  (barHeight - xAxisPadding / 25) / d["Max Active"];
					if(totalHeight < totalWidth)
					{
						return totalHeight;
					}
					return totalWidth;
				})
		.text(function(d, i)
				{
					return d["TaskName"];
				});
		
		var sessionLabelFontSize = (barHeight - xAxisPadding / 25) / 5;
		var sessionLabelFontWidth = sessionLabelFontSize *.6;
		//var sessionList;
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
						showDefault();
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
		.attr("height", barHeight - 2 * (xAxisPadding / 25) - (xAxisPadding / 50))
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i + barHeight + (xAxisPadding / 25) + (xAxisPadding / 50);
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
						showDefault();
						return;
					}
					//d3.select(this).attr("initStrokeWidth", d3.select(this).attr("stroke-width"));d3.select(this).attr("initStroke", d3.select(this).attr("stroke"));
					//d3.select(this).attr("stroke", "#ff0000").attr("stroke-width", xAxisPadding / 50);
					//curStroke = this;
					showSession(d["User"], d["Session"]);
					
					//curPlayButton = d3.select(("#playbutton_" + SHA256(d["User"] + d["Session"]))).attr("fill", "red");
					//curPlayLabel = d3.select(("#playbutton_label_" + SHA256(d["User"] + d["Session"]))).text("Pause");
					playAnimation(d["User"], d["Session"]);
				});
		
		var filterButtons = svg.append("g")
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.attr("x", 0)
		.attr("width", xAxisPadding / 2 - xAxisPadding / 20)
		.attr("height", barHeight - 2 * (xAxisPadding / 25) - (xAxisPadding / 50))
		.attr("y", function(d, i)
				{
					toReturn = d["User Number"] * barHeight + barHeight;
					toReturn += barHeight * 2 * i + barHeight + (xAxisPadding / 25) + (xAxisPadding / 50);
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
					toReturn += barHeight * 2 * i + (1.5 * barHeight) + (xAxisPadding / 50);
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
					toReturn += barHeight * 2 * i + (1.5 * barHeight) + (xAxisPadding / 50);
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
		
		var screenshotTimeline;
		var sessionList = [];
		var screenshotRects = svg.append("g")
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
							var windowList = theNormData[theUser][curSession]["screenshots"];
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
									lookupTable[theUser][curSession]["Screenshots"] = {};
								}
								if(!("Screenshots" in lookupTable[theUser][curSession]))
								{
									lookupTable[theUser][curSession]["Screenshots"] = {};
								}
								lookupTable[theUser][curSession]["Screenshots"][windowList[z]["Index MS"]] = windowList[z];
							}
							toReturn[toReturn.length - 1]["End MS Session"] = theNormData[theUser][curSession]["Index MS Session Max"];
							toReturn[toReturn.length - 1]["End MS User"] = theNormData[theUser][curSession]["Index MS Session Max"] + theNormData[theUser][curSession]["Index MS User Session Min"];
							toReturn[toReturn.length - 1]["End MS Universal"] = theNormData[theUser][curSession]["Index MS Session Max"] + theNormData[theUser][curSession]["Index MS User Session Min"] + theNormData[theUser]["Index MS Universal Min"];
							sessionNum++;
						}
						userNum++;
					}
					screenshotTimeline = toReturn;
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
					
					return d["Session Order"] * barHeight * 2 + d["User Order"] * barHeight + barHeight + barHeight / 2;
				})
		.attr("height", barHeight / 2)
		.attr("stroke", "black")
		.attr("stroke-width", xAxisPadding / 100)
		.attr("fill", function(d, i)
				{
					return colorScale(i % 20);
				})
		.attr("initFill", function(d, i)
				{
					return colorScale(i % 20);
				})
		.attr("id", function(d, i)
				{
					return "screenshot_" + d["Hash"];
				})
		.attr("opacity", .9);
		
		
		//Tick for animation
		var timelineTick = svg.append("rect").style("pointer-events", "none");
		var timelineText = svg.append("text")
			.style("fill", "Crimson")
			.style("pointer-events", "none")
			.style("font-size", barHeight / 4)
			.style("dominant-baseline", "hanging");
		
		var axisBars = svg.append("g")
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.attr("x", xAxisPadding)
		.attr("width", visWidth - xAxisPadding)
		.attr("height", barHeight / 2)
		.attr("y", function(d, i)
				{
					if(!(d["User"] in userSessionAxisY))
					{
						userSessionAxisY[d["User"]] = {}
					}
					if(!(d["Session"] in userSessionAxisY[d["User"]]))
					{
						userSessionAxisY[d["User"]][d["Session"]] = {};
					}
					//console.log(userSessionAxisY);
					toReturn = d["User Number"] * barHeight;
					toReturn += barHeight * 2 * i;
					toReturn -= barHeight / 2;
					toReturn += barHeight * 2;
					
					userSessionAxisY[d["User"]][d["Session"]]["y"] = toReturn;
					
					return toReturn;
				})
		.attr("fill", "#FFF")
		.attr("opacity", ".75")
		.attr("z", 2)
		.on("mousemove", async function(d, i)
				{
					var curX = d3.mouse(this)[0];
					var curY = d3.mouse(this)[1];
					//console.log(curX + ", " + curY);
					//console.log(this);
					timelineTick.attr("x", curX)
								.attr("y", function()
										{
											return userSessionAxisY[d["User"]][d["Session"]]["y"];
										})
								.attr("height", barHeight / 4)
								.attr("width",  xAxisPadding / 50);
					timelineTick.raise();
					timelineText.attr("x", curX + xAxisPadding / 50)
							.attr("y", function()
							{
								return userSessionAxisY[d["User"]][d["Session"]]["y"];
							})
							.text(function()
									{
										userName = d["User"];
										sessionName = d["Session"];
										//var scale = theNormData[userName][sessionName]["Time Scale"];
										maxSession = Number(theNormData[userName][sessionName]["Index MS Session Max"]);
										minSession = theNormData[userName]["Index MS User Min Absolute"] + theNormData[userName][sessionName]["Index MS User Session Min"];
										scale = d3.scaleLinear();
										scale.range([0, maxSession / 60000]);
										scale.domain([xAxisPadding, visWidth]);
										d3.select("#screenshotDiv")
												.selectAll("*")
												.remove();
										async function updateScreenshot()
										{
											d3.select("#screenshotDiv")
												.append("img")
												.attr("width", "100%")
												.attr("src", "data:image/jpg;base64," + (await getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Screenshot"]()))
												//.attr("src", "./getScreenshot.jpg?username=" + userName + "&timestamp=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Index MS"] + "&session=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Original Session"] + "&event=" + eventName)
												.attr("style", "cursor:pointer;")
												.on("click", async function()
														{
															//showLightbox("<tr><td><div width=\"100%\"><img src=\"./getScreenshot.jpg?username=" + userName + "&timestamp=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Index MS"] + "&session=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Original Session"] + "&event=" + eventName + "\" style=\"width: 100%;\"></div></td></tr>");
															showLightbox("<tr><td><div width=\"100%\"><img src=\""+ "data:image/jpg;base64," + (await getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Screenshot"]()) + "\" style=\"width: 100%;\"></div></td></tr>");
														});
										}
										updateScreenshot();
										//showLightbox("<tr><td><div width=\"100%\"><img src=\"./getScreenshot.jpg?username=" + userName + "&timestamp=" + getScreenshot(userName, sessionName, screenshotIndex)["Index MS"] + "&session=" + sessionName + "&event=" + eventName + "\" style=\"width: 100%;\"></div></td></tr>");
										//console.log(minSession + (scale(curX) * 60000));
										return scale(curX)
									});
					timelineText.raise();
				});
		
		var axisUnits = svg.append("g")
		.selectAll("text")
		.data(sessionList)
		.enter()
		.append("text")
		.style("pointer-events", "none")
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
					toReturn += barHeight * 2;
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("opacity", "1")
		.text("Minutes")
		.attr("z", 2);
		
		var screenshotLabel = svg.append("g")
		.selectAll("text")
		.data(sessionList)
		.enter()
		.append("text")
		.style("pointer-events", "none")
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
					toReturn += barHeight * 2;
					toReturn -= barHeight / 4;
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("opacity", "1")
		.text("Screenshots")
		.attr("z", 2);
		
		var windowLabel = svg.append("g")
		.selectAll("text")
		.data(sessionList)
		.enter()
		.append("text")
		.style("pointer-events", "none")
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
					toReturn += barHeight * 2;
					toReturn -= barHeight / 2;
					return toReturn;
				})
		.attr("fill", "#000")
		.attr("opacity", "1")
		.text("Active Window")
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
					//toReturn += barHeight;
					toReturn -= (xAxisPadding / 25);
					return toReturn;
				})
		.attr("fill", "#FFF")
		.attr("z", 2)
		.style("pointer-events", "none")
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
					d3.selectAll(this).select("*").style("pointer-events", "none");
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
					//sessionName += "Fr:"
					//sessionName += '\n';
					sessionName += minDate;
					sessionName += '\nTo\n';
					//sessionName += "To:"
					//sessionName += '\n';
					sessionName += maxDate;
					if(sessionList[sess]["Session"] != "Aggregated")
					{
						sessionName += '\n';
						sessionName += normEntry["environment"][0]["Environment"].substring(0, 20) + "...";
						sessionName += '\n';
						sessionName += 'Up:';
						sessionName += normEntry["environment"][0]["UploadTime"];
					}
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
		.style("pointer-events", "none")
		//.attr("font-weight", "bolder")
		.text("Task Annotation Source:");

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
		.style("pointer-events", "none")
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
					return d["Source"];
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
				.style("pointer-events", "none")
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
								showDefault();
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
		//d3.select("#mainVisualization").select("svg")
		//.attr("height", (visHeight) + "px")
		//.style("height", (visHeight) + "px");
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
			//showDefault();
		}
	}
	
	async function showDefault()
	{
		
		var addTaskRow = d3.select("#infoTable").append("tr").append("td")
		.attr("width", visWidthParent + "px")
		.html("<td><div align=\"center\">Process Occurances in Sessions</div></td>");
	
		var newSVG = d3.select("#infoTable").append("tr").append("td").append("div").style("max-width", visWidthParent + "px").style("overflow-x", "scroll").append("svg")
			.attr("width", ((visWidthParent / 15) * summaryProcStatsArray.length)  + "px")
			.attr("height", bottomVisHeight  + "px")
			.append("g");
		
		var processTooltip = newSVG.append("g")
		.append("text")
		.attr("y", "0px")
		.attr("x", "0px")
		.attr("font-size", xAxisPadding / 10)
		//.attr("width", xAxisPadding + "px")
		//.attr("height", bottomVisHeight + "px")
		.attr("alignment-baseline", "auto")
		.attr("dominant-baseline", "auto")
		.attr("text-anchor", "left")
		.style("font-weight", "bold")
		.text("");
		
		var barRects = newSVG.append("g").selectAll("rect")
			.data(summaryProcStatsArray)
			.enter()
			.append("rect")
					.attr("x", function(d, i)
							{
								return i * (visWidthParent / 15) + (visWidthParent / 60);
							})
					.attr("width", function(d, i)
							{
								return (visWidthParent / 20);
							})
					.attr("y", function(d, i)
							{
								return bottomVisHeight - d["count"] / summaryProcStats["Max"] * bottomVisHeight + (xAxisPadding / 10);
							})
					.attr("height", function(d, i)
							{
								return d["count"] / summaryProcStats["Max"] * bottomVisHeight - (xAxisPadding / 10);
							})
					.attr("stroke", "none")
					.attr("fill", function(d, i)
							{
								return colorScale(i % 20);
							})
					.on("mouseenter", function(d, i)
					{
						processTooltip.text(d["Command"] + ": " + d["count"])
								.attr("y", (bottomVisHeight - d["count"] / summaryProcStats["Max"] * bottomVisHeight + (xAxisPadding / 10)) + "px")
								.attr("x", i * (visWidthParent / 15) + (visWidthParent / 60) + "px");
					});
					
		
		var barLabels = newSVG.append("g").selectAll("text")
		.data(summaryProcStatsArray)
		.enter()
		.append("text")
				.attr("x", function(d, i)
						{
							return i * (visWidthParent / 15) + (visWidthParent / 60) + (visWidthParent / 40);
						})
				.attr("y", function(d, i)
						{
							return bottomVisHeight - d["count"] / summaryProcStats["Max"] * bottomVisHeight + (xAxisPadding / 10) + (bottomVisHeight / 40);
						})
				.text(function(d, i)
						{
							charsAllowed = ((d["count"] / summaryProcStats["Max"] * bottomVisHeight) - ((xAxisPadding / 10) + (bottomVisHeight / 40))) / ((bottomVisHeight) / 40);
							return d["Command"].substring(0, Math.round(charsAllowed));
						})
				.style("font-size", bottomVisHeight / 20)
				.attr("text-anchor", "start")
				.attr("dominant-baseline", "auto")
				.attr("stroke", "none")
				.style("writing-mode", "vertical-lr")
				.attr("fill", function(d, i)
						{
							if(i % 2 == 1)
							{
								return "black";
							}
							return "white";
						});
			
		var barNames = newSVG.append("g").selectAll("text")
		.data(summaryProcStatsArray)
		.enter()
		.append("text")
				.attr("x", function(d, i)
						{
							return i * (visWidthParent / 15) + (visWidthParent / 60) + (visWidthParent / 40);
						})
				.attr("y", function(d, i)
						{
							return bottomVisHeight - (xAxisPadding / 25);
						})
				.text(function(d, i)
						{
							return d["count"];
						})
				.attr("text-anchor", "middle")
				.attr("dominant-baseline", "auto")
				.attr("stroke", "none")
				.attr("fill", function(d, i)
						{
							if(i % 2 == 1)
							{
								return "black";
							}
							return "white";
						});
		
		
	}
	
	var animationTimeout;
	
	var degradeCoefficient = 60000;
	
	function playAnimation(owningUser, owningSession)
	{
		showLightbox("<tr><td id=\"animationRow\"><div id=\"animationDiv\" width=\"100%\" height=\"100%\"></div></td></tr>");
		
		var playing = true;
		
		var playbackSpeedMultiplier = Number(document.getElementById("playbackSpeed").value);
		
		var aniRow = d3.select("#animationRow");
		var aniDiv = d3.select("#animationDiv");
		
		var divBounds = aniRow.node().getBoundingClientRect();
		
		
		var screenshots = theNormData[owningUser][owningSession]["screenshots"];
		var keystrokes = theNormData[owningUser][owningSession]["keystrokes"];
		var mouse = theNormData[owningUser][owningSession]["mouse"];
		var windows = theNormData[owningUser][owningSession]["windows"];
		
		
		//console.log(divBounds);
		
		var garbageToRemove = [];
		
		var animationSvg = aniDiv.append("svg")
			.attr("width", divBounds["width"])
			.attr("height", divBounds["height"]);
		
		var backgroundG = animationSvg.append("g");
		
		var animationAxisG = animationSvg.append("g");
		
		
		var animationG = animationSvg.append("g");
		
		var curScreenshot = backgroundG.append("image")
			.attr("width", divBounds["width"])
			.attr("height", divBounds["height"])
			//.attr("preserveAspectRatio", "xMidYMid meet");
			.attr("preserveAspectRatio", "none");
		
			
		var lastScreenshot;
		
		var maxSessionAnimation = theNormData[owningUser][owningSession]["Index MS Session Max"];
		var timeScaleAnimation = d3.scaleLinear();
		timeScaleAnimation.domain
					(
						[0, maxSessionAnimation]
					)
		timeScaleAnimation.range
					(
						[0, animationSvg.attr("width")]
					);
		
		var timeScaleAnimationLookup = d3.scaleLinear();
		timeScaleAnimationLookup.range
					(
						[0, maxSessionAnimation]
					)
		timeScaleAnimationLookup.domain
					(
						[0, animationSvg.attr("width")]
					);
		
		
		var animationAxis = d3.axisBottom().scale(timeScaleAnimation);
		animationAxisG.call(animationAxis);
		animationAxisG.attr("transform", "translate(" + 0 + "," + (divBounds["height"] * .8) + ")")
		var textPadding = animationAxisG.node().getBBox()["height"];
		
		var curTimer = 0;
		var screenshotIndex = 0;
		var keystrokesIndex = 0;
		var mouseIndex = 0;
		var windowsIndex = 0;
		
		var seekBarG = animationSvg.append("g");
		var seekBar = seekBarG.append("rect")
				.attr("x", 0)
				.attr("y", (divBounds["height"] * .8))
				.attr("height", textPadding)
				.attr("width", animationSvg.attr("width"))
				.attr("style", "cursor:crosshair;")
				.style("stroke", "Chartreuse")
				.style("fill-opacity", ".1")
				.style("fill", "Chartreuse");
		
		var axisLabelG = animationSvg.append("g");
		var axisLabel = axisLabelG.append("text")
				.attr("x", 0)
				.attr("y", (divBounds["height"] * .8) + textPadding)
				.style("pointer-events", "none")
				.text("MS");
		
		var axisTickG = animationSvg.append("g");
		var axisTick = axisTickG.append("rect")
				.style("pointer-events", "none")
				.attr("width", divBounds["width"]/400)
				.attr("height", textPadding)
				.attr("stroke", "crimson")
				.attr("x", 0)
				.attr("y", (divBounds["height"] * .8));
		
		var playPauseG = animationSvg.append("g");
		var playPause = playPauseG.append("rect")
				.attr("width", divBounds["width"] / 9)
				.attr("height", (divBounds["height"] * .05))
				.attr("fill", "Chartreuse")
				.attr("stroke", "Black")
				.attr("x", (4 * divBounds["width"]) / 9)
				.attr("y", (divBounds["height"] * .8) + textPadding);
		var playPauseLabel = playPauseG.append("text")
				.style("pointer-events", "none")
				.attr("text-anchor", "middle")
				.attr("dominant-baseline", "middle")
				.attr("font-weight", "bolder")
				.attr("textLength", divBounds["width"] / 9)
				.attr("fill", "Black")
				.attr("stroke", "Black")
				.attr("font-size", (divBounds["height"] * .05))
				.text("⏸")
				.attr("x", divBounds["width"] / 2)
				.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .025));
		var activeWindowTitle = playPauseG.append("text")
				.style("pointer-events", "none")
				.attr("text-anchor", "middle")
				.attr("dominant-baseline", "middle")
				.attr("textLength", (divBounds["width"]) / 9)
				.attr("fill", "Black")
				.attr("stroke", "Black")
				.attr("font-size", (divBounds["height"] * .025))
				//.style("font-weight", "bold")
				.text("Active Window:")
				.attr("x", divBounds["width"] / 2)
				.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .075));
		var activeWindowNameBg = playPauseG.append("rect")
				.style("pointer-events", "none")
				.attr("fill", "White")
				.attr("opacity", ".8")
				.attr("x", (divBounds["width"] / 2) - ((2 * divBounds["width"]) / 9))
				.attr("width", (4 * divBounds["width"]) / 9)
				.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .125))
				.attr("height", (divBounds["height"] * .025));
		var activeWindow = playPauseG.append("text")
				.style("pointer-events", "none")
				.attr("text-anchor", "middle")
				.attr("dominant-baseline", "middle")
				.attr("textLength", (2 * divBounds["width"]) / 9)
				.attr("fill", "Black")
				.attr("stroke", "Black")
				.attr("font-size", (divBounds["height"] * .025))
				//.style("font-weight", "bold")
				.text("...")
				.attr("x", divBounds["width"] / 2)
				.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .1));
		var activeWindowName = playPauseG.append("text")
				.style("pointer-events", "none")
				.attr("text-anchor", "middle")
				.attr("dominant-baseline", "middle")
				.attr("textLength", (4 * divBounds["width"]) / 9)
				.attr("fill", "Black")
				.attr("stroke", "Black")
				.attr("font-size", (divBounds["height"] * .025))
				//.style("font-weight", "bold")
				.text("...")
				.attr("x", divBounds["width"] / 2)
				.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .125));
		
		
		
		
		function nextFrame()
		{
			var screenshotTime = Infinity;
			if(screenshots && screenshotIndex < screenshots.length)
			{
				screenshotTime = Number(screenshots[screenshotIndex]["Index MS Session"]);
			}
			var keystrokesTime = Infinity;
			if(keystrokes && keystrokesIndex < keystrokes.length)
			{
				keystrokesTime = Number(keystrokes[keystrokesIndex]["Index MS Session"]);
			}
			var mouseTime = Infinity;
			if(mouse && mouseIndex < mouse.length)
			{
				mouseTime = Number(mouse[mouseIndex]["Index MS Session"]);
			}
			var windowsTime = Infinity;
			if(windows && windowsIndex < windows.length)
			{
				windowsTime = Number(windows[windowsIndex]["Index MS Session"]);
			}
			
			if(screenshotTime < keystrokesTime)
			{
				if(screenshotTime < mouseTime)
				{
					if(screenshotTime < windowsTime)
					{
						screenshotIndex++;
						return screenshots[screenshotIndex - 1];
					}
					else
					{
						windowsIndex++;
						return windows[windowsIndex - 1];
					}
				}
				else
				{
					if(mouseTime < windowsTime)
					{
						mouseIndex++;
						return mouse[mouseIndex - 1];
					}
					else
					{
						windowsIndex++;
						return windows[windowsIndex - 1];
					}
				}
			}
			else if(mouseTime < keystrokesTime)
			{
				if(mouseTime < windowsTime)
				{
					mouseIndex++;
					return mouse[mouseIndex - 1];
				}
				else
				{
					windowsIndex++;
					return windows[windowsIndex - 1];
				}
			}
			else
			{
				if(keystrokesTime < windowsTime)
				{
					keystrokesIndex++;
					return keystrokes[keystrokesIndex - 1];
				}
				else
				{
					windowsIndex++;
					return windows[windowsIndex - 1];
				}
			}
		}
		
		var lastFrame;
		var lastImg = new Image();
		
		var lastMouseClicks = [];
		
		var keyboardInputs = [];
		
		var curKeyInput = animationG.append("text").attr("x", 0)
							.attr("y", 0)
							.text("")
							.attr("text", "")
							.attr("font-size", 0);
		
		keyboardInputs.unshift(curKeyInput);
		//var typedText = animationG.selectAll("text").data(keyboardInputs).append("text");
		
		//var curLine = "";
		
		
		var typedText;
			
		var textHeight = 0;
		
		var startY = 0;
		
		var prevLastScreenshot;
		
		async function runAnimation()
		{
			var curFrame = nextFrame();
			//console.log(curFrame);
			
			if(curFrame)
			{
				axisTick .attr("x", timeScaleAnimation(curFrame["Index MS Session"]));
				
				for(entry in lastMouseClicks)
				{
					//if(entry != lastMouseClicks.length)
					{
						var sessionTime = Number(lastMouseClicks[entry].attr("indexTime"));
						var curType = lastMouseClicks[entry].attr("Type");
						//console.log(sessionTime);
						var timeDiff = Number(curFrame["Index MS Session"]) - sessionTime;
						//console.log(timeDiff);
						if(timeDiff > degradeCoefficient)
						{
							lastMouseClicks[entry].remove();
							lastMouseClicks.splice(entry, 1);
							entry--;
							continue;
						}
						else
						{
							lastMouseClicks[entry].attr("opacity", ((1 - (timeDiff / degradeCoefficient)) * .5));
							nextColor = "Grey";
							if(curType == "Down")
							{
								nextColor = "Green"
							}
							lastMouseClicks[entry].attr("stroke", nextColor);
						}
						
					}
				}
			}
			
			if(curFrame && curFrame["Screenshot"])
			{
				curScreenshot = backgroundG.append("image")
				.attr("width", divBounds["width"])
				.attr("height", divBounds["height"])
				//.attr("preserveAspectRatio", "xMidYMid meet");
				.attr("preserveAspectRatio", "none");
				
				lastImg.src = "data:image/jpg;base64," + (await curFrame["Screenshot"]());
				
				var xRatio = divBounds["width"] / lastImg["width"];
				var yRatio = (divBounds["height"] * .8) / lastImg["height"];
				var finalRatio = xRatio;
				if(xRatio > yRatio)
				{
					finalRatio = yRatio;
				}
				
				var finalWidth = finalRatio * lastImg["width"];
				var finalX = (divBounds["width"] - finalWidth) / 2;
				
				curScreenshot.attr("href", "data:image/jpg;base64," + (await curFrame["Screenshot"]()))
							.attr("width", finalWidth)
							.attr("x", finalX)
							.attr("onload", function()
									{
										
									})
							.attr("height", finalRatio * lastImg["height"]);
				
				textHeight = curScreenshot.attr("width") / 50;
				
				startY = finalRatio * lastImg["height"];
				
				if(!typedText)
				{
					typedText = animationG.append("text").attr("x", 0)
						.attr("y", startY + textHeight + textPadding)
						.text("Input:")
						.attr("font-size", textHeight);
				}
				
				if(prevLastScreenshot)
				{
					//prevLastScreenshot.remove();
					garbageToRemove.push(prevLastScreenshot);
				}
				if(lastScreenshot)
				{
					prevLastScreenshot = lastScreenshot;
					//lastScreenshot.remove();
				}
				lastScreenshot = curScreenshot;
				for(toRemove in garbageToRemove)
				{
					if(curFrame["Index MS Session"] - garbageToRemove[toRemove]["Index MS Session"] > 10000)
					{
						garbageToRemove[toRemove].remove();
					}
				}
			}
			
			if(curFrame && curFrame["FirstClass"])
			{
				activeWindow.text(curFrame["FirstClass"]);
				activeWindowName.text(curFrame["Name"]);
			}
			
			if(curFrame && curFrame["XLoc"])
			{
				var xLoc = Number(curFrame["XLoc"]);
				//console.log(xLoc);
				xLoc = xLoc / lastImg["width"];
				//console.log(xLoc);
				xLoc = xLoc * curScreenshot.attr("width");
				xLoc = xLoc + Number(curScreenshot.attr("x"));
				//console.log(xLoc);
				var yLoc = Number(curFrame["YLoc"]) / lastImg["height"];
				yLoc = yLoc * curScreenshot.attr("height");
				var centerColor = "Black";
				var outerColor = "Blue"
				if(curFrame["Type"] == "down")
				{
					outerColor = "Red"
				}
				var nextMouse = animationG.append("circle")
					.attr("indexTime", curFrame["Index MS Session"])
					.attr("mouseType", curFrame["Type"])
					.attr("cx", xLoc)
					.attr("cy", yLoc)
					.attr("r", curScreenshot.attr("width") / 200)
					.attr("fill", centerColor)
					.attr("stroke", outerColor)
					.attr("stroke-width", curScreenshot.attr("width") / 400)
					.attr("opacity", ".9");
				
				lastMouseClicks.push(nextMouse);
			}
			
			if(curFrame && curFrame["Button"] && (curFrame["Type"] == "press"))// || curFrame["Type"] == "type"))
			{
				buttonToType = curFrame["Button"];
				if(buttonToType == "Up")
				{
					buttonToType = "⇧";
				}
				else if(buttonToType == "Down")
				{
					buttonToType = "⇩";
				}
				else if(buttonToType == "Left")
				{
					buttonToType = "⇦";
				}
				else if(buttonToType == "Right")
				{
					buttonToType = "⇨";
				}
				else if(buttonToType == "Space")
				{
					buttonToType = " ";
				}
				else if(buttonToType == "Period")
				{
					buttonToType = ".";
				}
				else if(buttonToType == "Backspace")
				{
					buttonToType = "⌫";
				}
				else if(buttonToType == "Shift")
				{
					buttonToType = "⇯";
				}
				else if(buttonToType == "Minus")
				{
					buttonToType = "-";
				}
				else if(buttonToType == "Backslash")
				{
					buttonToType = "\\";
				}
				else if(buttonToType == "Forwardslash")
				{
					buttonToType = "/";
				}
				else if(buttonToType == "Enter")
				{
					//keyboardInputs.shift();
					//keyboardInputs.unshift(curLine);
					curKeyInput = animationG.append("text").attr("x", 0)
					.attr("y", startY  + textPadding)
					.text("⏎")
					.attr("text", "⏎")
					.attr("font-size", textHeight);
					
					keyboardInputs.unshift(curKeyInput);
				}
				else if(buttonToType.length > 1)
				{
					buttonToType = "[" + buttonToType + "]";
				}
				
				if(buttonToType != "Enter")
				{
					if(curKeyInput.node().getBBox()["width"] + textHeight > (3.5 * divBounds["width"]) / 9)
					{
						//keyboardInputs.shift();
						//keyboardInputs.unshift(curLine);
						curKeyInput = animationG.append("text").attr("x", 0)
						.attr("y", startY  + textPadding)
						.text("⏎")
						.attr("text", "")
						.attr("font-size", textHeight);
						
						keyboardInputs.unshift(curKeyInput);
					}
					curKeyInput.attr("text", curKeyInput.attr("text") + buttonToType);
					curKeyInput.text(curKeyInput.attr("text"));
					//keyboardInputs.shift();
					//keyboardInputs.unshift(curLine);
					
				}
				
				//console.log(keyboardInputs);
				
				
				
			}
			
			for(entry in keyboardInputs)
			{
				keyboardInputs[entry].attr("y", startY  + textPadding + ((Number(entry) + 2) * textHeight))
									.attr("font-size", textHeight);
			}
			
			
			if(playing && curFrame && (!(lastFrame)))
			{
				axisTick .style("transition", (Number(curFrame["Index MS Session"]) / playbackSpeedMultiplier) + "ms linear");
				animationTimeout = setTimeout(runAnimation, Number(curFrame["Index MS Session"]) / playbackSpeedMultiplier);
			}
			else if(playing && curFrame)
			{
				axisTick .style("transition", ((Number(curFrame["Index MS Session"]) - Number(lastFrame["Index MS Session"])) / playbackSpeedMultiplier) + "ms linear");
				animationTimeout = setTimeout(runAnimation, (Number(curFrame["Index MS Session"]) - Number(lastFrame["Index MS Session"])) / playbackSpeedMultiplier);
			}
			lastFrame = curFrame;
		}
		
		animationTimeout = setTimeout(runAnimation, 0);
		
		playPause.on("click", function(d, i)
				{
					d3.event.stopPropagation();
					if(playing)
					{
						clearTimeout(animationTimeout);
						playPause.attr("fill", "Crimson");
						playPauseLabel.text("▶");
						seekBar.style("fill", "Crimson").style("stroke", "Crimson");
						playing = false;
					}
					else
					{
						playPause.attr("fill", "Chartreuse");
						playPauseLabel.text("⏸");
						seekBar.style("fill", "Chartreuse").style("stroke", "Chartreuse");
						playing = true;
						animationTimeout = setTimeout(runAnimation, 0);
					}
				})
		
		seekBar.on("click", function(d, i)
				{
					clearTimeout(animationTimeout);
					var curX = d3.mouse(this)[0];
					var curY = d3.mouse(this)[1];
					var selectTime = timeScaleAnimationLookup(curX);
					//console.log(selectTime);
					var curDiff = Infinity;
					if(screenshots)
					{
						screenshotIndex = closestIndexMSBinarySession(screenshots, selectTime);
						var curScreenshot = screenshots[screenshotIndex];
						//console.log(curScreenshot);
					}
					if(keystrokes)
					{
						keystrokesIndex = closestIndexMSBinarySession(keystrokes, selectTime);
						var curKeystrokes = keystrokes[keystrokesIndex];
						//console.log(curKeystrokes);
					}
					if(mouse)
					{
						mouseIndex = closestIndexMSBinarySession(mouse, selectTime);
						var curMouse = mouse[mouseIndex];
						//console.log(curMouse);
					}
					if(windows)
					{
						windowsIndex = closestIndexMSBinarySession(windows, selectTime);
						var curWindows = windows[windowsIndex];
						//console.log(curMouse);
					}
					
					var selectedEntry;
					if(screenshots && curScreenshot)
					{
						selectedEntry = curScreenshot;
						curDiff = Math.abs(Number(curScreenshot["Index MS Session"]) - selectTime);
					}
					if(keystrokes && curKeystrokes && curDiff > Math.abs(Number(curKeystrokes["Index MS Session"]) - selectTime))
					{
						selectedEntry = curKeystrokes;
						curDiff = Math.abs(Number(curKeystrokes["Index MS Session"]) - selectTime);
					}
					if(mouse && curMouse && curDiff > Math.abs(Number(curMouse["Index MS Session"]) - selectTime))
					{
						selectedEntry = curMouse;
						curDiff = Math.abs(Number(curMouse["Index MS Session"]) - selectTime);
					}
					if(windows && curWindows && curDiff > Math.abs(Number(curWindows["Index MS Session"]) - selectTime))
					{
						selectedEntry = curWindows;
						curDiff = Math.abs(Number(curWindows["Index MS Session"]) - selectTime);
					}
					
					while(screenshots && screenshotIndex < screenshots.length && Number(screenshots[screenshotIndex]["Index MS Session"]) < Number(selectedEntry["Index MS Session"]))
					{
						screenshotIndex++;
					}
					while(keystrokes && keystrokesIndex < keystrokes.length && Number(keystrokes[keystrokesIndex]["Index MS Session"]) < Number(selectedEntry["Index MS Session"]))
					{
						keystrokesIndex++;
					}
					while(mouse && mouseIndex < mouse.length && Number(mouse[mouseIndex]["Index MS Session"]) < Number(selectedEntry["Index MS Session"]))
					{
						mouseIndex++;
					}
					while(windows && windowsIndex < windows.length && Number(windows[windowsIndex]["Index MS Session"]) < Number(selectedEntry["Index MS Session"]))
					{
						windowsIndex++;
					}
					//console.log(selectedEntry);
					//console.log(nextFrame());
					d3.event.stopPropagation();
					lastFrame = selectedEntry;
					axisTick.style("transition", "none");
					axisTick .attr("x", timeScaleAnimation(selectedEntry["Index MS Session"]));
					
					curKeyInput = animationG.append("text").attr("x", 0)
					.attr("y", startY  + textPadding)
					.text("⏯")
					.attr("text", "")
					.attr("font-size", textHeight);
					
					keyboardInputs.unshift(curKeyInput);
					
					activeWindow.text("...");
					activeWindowName.text("...");
					
					for(entry in lastMouseClicks)
					{
						
							lastMouseClicks[entry].remove();
							lastMouseClicks.splice(entry, 1);
							entry--;
							continue;
						
					}
					if(playing)
					{
						seekBar.attr("fill", "Chartreuse").attr("stroke", "Chartreuse");
						animationTimeout = setTimeout(runAnimation, 0);
					}
					else
					{
						seekBar.attr("fill", "Crimson").attr("stroke", "Crimson");
						runAnimation();
					}
				})
		
		
	}
	
	var processTooltip;
	var processTooltipRect;
	var lastMouseOver;
	var lastMouseHash;
	
	var curSelectUser = "";
	var curSelectSession = "";
	
	function addTask(userName, sessionName)
	{
		var startTask = Number(document.getElementById("addTaskStart").value) + theNormData[userName]["Index MS User Min Absolute"] + theNormData[userName][sessionName]["Index MS User Session Min"];
		var endTask = Number(document.getElementById("addTaskEnd").value) + theNormData[userName]["Index MS User Min Absolute"] + theNormData[userName][sessionName]["Index MS User Session Min"];
		var taskName = document.getElementById("addTaskName").value;
		
		var taskUrl = "addTask.json?event=" + eventName + "&userName=" + userName + "&sessionName=" + sessionName + "&start=" + startTask + "&end=" + endTask + "&taskName=" + taskName;
		
		d3.json(taskUrl, function(error, data)
					{
						//console.log(data);
						if(data["result"] == "okay")
						{
							
							var sessEvents = theNormData[userName][sessionName]["events"];
							var aggEvents = theNormData[userName]["Aggregated"]["events"];
							
							var userSessDiff = theNormData[userName][sessionName]["Index MS User Session Min"];
							var absUserDiff = theNormData[userName]["Index MS User Min Absolute"];
							
							var newEvents = data["newEvents"][userName][sessionName]["events"];
							
							function binarySearchEvents(items, value){
							    var firstIndex  = 0,
							        lastIndex   = items.length - 1,
							        middleIndex = Math.floor((lastIndex + firstIndex)/2);

							    while(items[middleIndex]["Index MS"] != value && firstIndex < lastIndex)
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
							
							//newEvents = theNormDataClone[userName][sessionName]["events"];
							
							var aggEventList = theNormData[userName]["Aggregated"]["events"];
							
							for(entry in newEvents)
							{
								newEvents[entry]["Original Session"] = sessionName;
								newEvents[entry]["Index MS Session"] = newEvents[entry]["Index MS"] - absUserDiff - userSessDiff;
								newEvents[entry]["Index MS User"] = newEvents[entry]["Index MS"] - absUserDiff;
								if(newEvents[entry]["TaskName"] == taskName)
								{
									aggEntry = binarySearchEvents(aggEventList, newEvents[entry]["Index MS"]);
									newEntryClone = JSON.parse(JSON.stringify(newEvents[entry]));
									newEntryClone["Owning Session"] = "Aggregated";
									if(aggEventList[aggEntry]["Index MS"] < newEvents[entry]["Index MS"])
									{
										aggEventList.splice(aggEntry, 0, newEntryClone);
									}
									else
									{
										aggEventList.splice(aggEntry - 1, 0, newEntryClone);
									}
								}
							}
							//console.log(newEvents);
							theNormData[userName][sessionName]["events"] = newEvents;
							
							
							
							//var lastAggIndex = 0;
							//for(newEntry in newEvents)
							//{
							//	var curEntry = newEvents[newEntry];
							//	var curIndex = newEntry["Index MS"];
							//	if(curEntry["TaskName"] != taskName)
							//	{
							//		continue;
							//	}
							//	if(lastAggIndex >= aggEventList.length)
							//	{
							//		aggEventList.push(curEntry);
							//		lastAggIndex++;
							//		continue;
							//	}
							//	while(lastAggIndex < aggEventList.length)
							//	{
							//		if(aggEventList[lastAggIndex]["Index MS"] <= curIndex)
							//		{
							//			aggEventList.splice(lastAggIndex - 1, 0, curEntry);
							//			break;
							//		}
							//		lastAggIndex++;
							//	}
							//}
							//preprocess();
							start(true);
						}
						
					});
	}
	
	async function showSession(owningUser, owningSession)
	{
		//console.log(d3.select("#mainVisContainer").style("height",  "300px").attr("height",  "300px"));
		
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
		.attr("src", "data:image/jpg;base64," + (await (theNormData[owningUser][owningSession]["screenshots"][0]["Screenshot"]())))
		//.attr("src", "./getScreenshot.jpg?username=" + owningUser + "&timestamp=" + getScreenshot(owningUser, screenshotSession, screenshotIndex)["Index MS"] + "&session=" + screenshotSession + "&event=" + eventName)
		.attr("style", "cursor:pointer;")
		.on("click", function()
				{
					//showLightbox("<tr><td><div width=\"100%\"><img src=\"./getScreenshot.jpg?username=" + owningUser + "&timestamp=" + getScreenshot(owningUser, screenshotSession, screenshotIndex)["Index MS"] + "&session=" + screenshotSession + "&event=" + eventName + "\" style=\"width: 100%;\"></div></td></tr>");
					showLightbox("<tr><td><div width=\"100%\"><img src=\"data:image/jpg;base64," + (await (theNormData[owningUser][owningSession]["screenshots"][0]["Screenshot"]())) + "\" style=\"width: 100%;\"></div></td></tr>");
				});
		
		
		curProcessMap = processMap[owningUser][owningSession];
		
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
		
		var addTaskRow = d3.select("#infoTable").append("tr").append("td")
			.attr("width", visWidthParent + "px")
			.html("<td><div align=\"center\">Add Task</div></td>");
		
		var addTaskRow = d3.select("#infoTable").append("tr").append("td")
		.attr("width", visWidthParent + "px")
				.append("table").attr("width", visWidthParent + "px").append("tr").attr("width", visWidthParent + "px")
					.html("<td width=\"25%\"><div align=\"center\"><input type=\"text\" id=\"addTaskStart\" name=\"addTaskStart\" value=\"Start (MS Session Time)\"></div></td>" +
							"<td width=\"25%\"><div align=\"center\"><input type=\"text\" id=\"addTaskEnd\" name=\"addTaskEnd\" value=\"End (MS Session Time)\"></div></td>" +
							"<td width=\"25%\"><div align=\"center\"><input type=\"text\" id=\"addTaskName\" name=\"addTaskName\" value=\"Task Name\"></div></td>" +
							"<td width=\"25%\"><div align=\"center\"><button type=\"button\" onclick=\"addTask('" + owningUser + "', '" + owningSession + "')\">Submit</button></div></td>");
		
		var newAxis = d3.axisTop(timeScale);
		
		var initX = 0;
		
		var dragAddTask = d3.drag()
			.on("drag", dragmoveAddTask)
			.on("start", function(d)
					{
						initX = d3.event.x;
						if(initX < xAxisPadding)
						{
							initX = xAxisPadding;
						}
						selectRect.attr("x", initX);
						selectRect.attr("width", 0);
						document.getElementById("addTaskStart").value = "Start (MS Session Time)";
						document.getElementById("addTaskEnd").value = "End (MS Session Time)";
					});
		
		function dragmoveAddTask(d)
		{
			var x = d3.event.x;
			var y = d3.event.y;
			var startPoint = 0;
			var endPoint = 0;
			if(x < initX)
			{
				selectRect.attr("x", x);
				selectRect.attr("width", initX - x);
				startPoint = timeScale.invert(x - xAxisPadding);
				endPoint = timeScale.invert(initX - xAxisPadding);
			}
			else
			{
				selectRect.attr("x", initX);
				selectRect.attr("width", x - initX);
				startPoint = timeScale.invert(initX - xAxisPadding);
				endPoint = timeScale.invert(x - xAxisPadding);
			}
			document.getElementById("addTaskStart").value = startPoint;
			document.getElementById("addTaskEnd").value = endPoint;
		}
		
		var addTaskAxisSVG = d3.select("#infoTable").append("tr").append("td").append("svg")
				.attr("class", "clickableBar")
				.attr("width", visWidthParent + "px")
				.attr("height", (barHeight / 1.75) + "px")
				//.on("mousedown", function(d)
				//		{
				//			console.log(d);
				//		})
				.call(dragAddTask);
		
		var selectRect = addTaskAxisSVG.append("g")
				.append("rect")
				.attr("x", 0)
				.attr("y", 0)
				.attr("width", 0)
				.attr("height", barHeight / 1.75)
				.attr("fill", "cyan")
				.attr("pointer-events", "none");
		
		var addTableAxis = addTaskAxisSVG.append("g")
				.attr("transform", "translate(" + xAxisPadding + "," + (barHeight / 2) + ")")
				.attr("pointer-events", "none")
				.call(newAxis);
		var addTableAxisLabel = addTaskAxisSVG.append("g")
				.append("text")
				.attr("x", xAxisPadding / 2)
				.attr("y", barHeight / 3.5)
				.attr("text-anchor", "middle")
				.attr("dominant-baseline", "middle")
				.attr("font-size", bottomVizFontSize * 2)
				.text("Select Time:")
				.attr("pointer-events", "none");
		
		
		
		var newSVG = d3.select("#infoTable").append("tr").append("td").append("svg")
			.attr("width", visWidthParent + "px")
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
						
						if(processTooltipRect.attr("x") > visWidthParent / 2)
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
		.style("pointer-events", "none")
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
		.style("pointer-events", "none")
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
	
	function closestIndexMSBinary(items, value){
	    var firstIndex  = 0,
	        lastIndex   = items.length - 1,
	        middleIndex = Math.floor((lastIndex + firstIndex)/2);

	    while(items[middleIndex]["Index MS"] != value && firstIndex < lastIndex)
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
	
	var prevScreenshot;
	
	function getScreenshot(userName, sessionName, indexMS)
	{
		var screenshotIndexArray = theNormData[userName][sessionName]["screenshots"];
		var finalScreenshot = screenshotIndexArray[closestIndexMSBinary(screenshotIndexArray, indexMS)];
		//console.log(finalScreenshot);
		var curHash = SHA256(userName + sessionName + finalScreenshot["Index MS"])
		var nextScreenshot = d3.select("#" + "screenshot_" + curHash);
		if(prevScreenshot)
		{
			if(prevScreenshot.attr("id") == nextScreenshot.attr("id"))
			{
				return finalScreenshot;
			}
			prevScreenshot.attr("fill", prevScreenshot.attr("initFill"));
			prevScreenshot.attr("stroke", "Black");
		}
		nextScreenshot.attr("stroke", "Crimson");
		nextScreenshot.attr("fill", "Black");
		prevScreenshot = nextScreenshot;
		return finalScreenshot;
	}
	
	function deleteTask(userName, sessionName, taskName, startTime)
	{
		var taskUrl = "deleteTask.json?event=" + eventName + "&userName=" + userName + "&sessionName=" + sessionName + "&taskName=" + taskName + "&startTime=" + startTime;
		d3.json(taskUrl, function(error, data)
				{
					//console.log(data);
					if(data["result"] == "okay")
					{
						var sessEvents = theNormData[userName][sessionName]["events"];
						var aggEvents = theNormData[userName]["Aggregated"]["events"];
						
						var userSessDiff = theNormData[userName][sessionName]["Index MS User Session Min"];
						var absUserDiff = theNormData[userName]["Index MS User Min Absolute"];
						
						var newEvents = data["newEvents"][userName][sessionName]["events"];
						
						function binarySearchEvents(items, value){
						    var firstIndex  = 0,
						        lastIndex   = items.length - 1,
						        middleIndex = Math.floor((lastIndex + firstIndex)/2);

						    while(items[middleIndex]["Index MS"] != value && firstIndex < lastIndex)
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
						
						//newEvents = theNormDataClone[userName][sessionName]["events"];
						
						var aggEventList = theNormData[userName]["Aggregated"]["events"];
						
						for(entry in newEvents)
						{
							newEvents[entry]["Original Session"] = sessionName;
							newEvents[entry]["Index MS Session"] = newEvents[entry]["Index MS"] - absUserDiff - userSessDiff;
							newEvents[entry]["Index MS User"] = newEvents[entry]["Index MS"] - absUserDiff;
							if(newEvents[entry]["TaskName"] == taskName)
							{
								aggEntry = binarySearchEvents(aggEventList, newEvents[entry]["Index MS"]);
								newEntryClone = JSON.parse(JSON.stringify(newEvents[entry]));
								newEntryClone["Owning Session"] = "Aggregated";
								if(aggEventList[aggEntry]["Index MS"] < newEvents[entry]["Index MS"])
								{
									aggEventList.splice(aggEntry, 0, newEntryClone);
								}
								else
								{
									aggEventList.splice(aggEntry - 1, 0, newEntryClone);
								}
							}
						}
						//console.log(newEvents);
						theNormData[userName][sessionName]["events"] = newEvents;
						
						
						start(true);
						//curEvents = theNormDataClone[userName][sessionName]["events"];
						//for(element in curEvents)
						//{
						//	if(curEvents[element]["TaskName"] == taskName && curEvents[element]["Source"] == adminName)
						//	{
						//		curEvents.splice(element, 1);
						//		element--;
						//	}
						//}
					}
				});
	}
	
	var curSelectProcess;
	var curSelElements = [];
	
	async function showWindow(username, session, type, timestamp)
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
		
		if(type == "Events")
		{
			if(curSlot["Original Session"] != "User")
			{
				d3.select("#extraInfoTable")
					.append("tr")
					.html("<td colspan=\"4\"><button type=\"button\" onclick=\"deleteTask('cgtboy1988', '" + curSlot["Original Session"] + "', '" + curSlot["TaskName"] + "', '" + curSlot["Index MS"] + "')\">Delete</button></td>");
			}
		}
		
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
							return "<td width=\"12.5%\" style=\" max-width:" + (.125 * visWidthParent) + "px\">" + d["key1"] + "</td>" + "<td width=\"37.5%\" style=\" max-width:" + (.375 * visWidthParent) + "px; overflow-x:auto;\">" + d["value1"] + "</td>" + "<td width=\"12.5%\" style=\" max-width:" + (.125 * visWidthParent) + "px\">" + d["key2"] + "</td>" + "<td width=\"37.5%\" style=\" max-width:" + (.375 * visWidthParent) + "px; overflow-x:auto;\">" + d["value2"] + "</td>";
						});
		
		//console.log(curSlot);
		
		//console.log(curSlot["Start Time"]);
		
		d3.select("#screenshotDiv")
				.selectAll("*")
				.remove();
		
		d3.select("#screenshotDiv")
				.append("img")
				.attr("width", "100%")
				.attr("src", "data:image/jpg;base64," + (await (getScreenshot(curSlot["Owning User"], curSlot["Original Session"], curSlot["Index MS"])["Screenshot"]())))
				//.attr("src", "./getScreenshot.jpg?username=" + curSlot["Owning User"] + "&timestamp=" + getScreenshot(curSlot["Owning User"], curSlot["Original Session"], curSlot["Index MS"])["Index MS"] + "&session=" + curSlot["Original Session"] + "&event=" + eventName)
				.attr("style", "cursor:pointer;")
				.on("click", function()
						{
							showLightbox("<tr><td><div width=\"100%\"><img src=\"data:image/jpg;base64," + (await (getScreenshot(curSlot["Owning User"], curSlot["Original Session"], curSlot["Index MS"])["Screenshot"]())) + "\" style=\"width: 100%;\"></div></td></tr>");
							//showLightbox("<tr><td><div width=\"100%\"><img src=\"./getScreenshot.jpg?username=" + curSlot["Owning User"] + "&timestamp=" + getScreenshot(curSlot["Owning User"], curSlot["Original Session"], curSlot["Index MS"])["Index MS"] + "&session=" + curSlot["Original Session"] + "&event=" + eventName + "\" style=\"width: 100%;\"></div></td></tr>");
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