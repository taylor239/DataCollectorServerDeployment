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
<script src="./pageFunctions.js"></script>
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
<table width="100%" style="border:0">
	<tr>
		<td class="layoutTableSide" style="border:0">
		<div align="left">
			<span id="leftHide" style="cursor: pointer" onclick="toggleLeft();">⊟</span>
		</div>
		</td>
		<td class="layoutTableCenter" style="border:0">
		
		</td>
		<td class="layoutTableSide" style="border:0">
		<div align="right">
			Lost? <button type="button" onclick="tutorial()">Info</button><button type="button" onclick="back()">Back</button>
		</div>
		</td>
	</tr>
</table>
<table id="bodyTable">
	<tr>
		<td id="optionFilterCell" class="layoutTableSide leftCol" style="height:100%">
			<table id="optionFilterTable" width="100%" height="100%" style="display:block; overflow-y:scroll">
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
						<td colspan="5">
									<span width="50%"><input type="text" size="4" id="timelineZoom" name="timelineZoom" value="1">x horizontal</span>
									<span width="50%"><input type="text" size="4" id="timelineZoomVert" name="timelineZoomVert" value="1">x vertical</span>
						</td>
					</tr>
					<tr>
						<td colspan="5">
									<div align="center"><button type="button" onclick="start(true)">Apply</button></div>
						</td>
					</tr>
					<tr>
						<td colspan="5">
									<input type="checkbox" id="processAutoSelect" name="processAutoSelect">Process Tooltip Details
						</td>
					</tr>
					<tr>
						<td colspan="5">
									<input type="checkbox" id="loadProcessGraph" name="loadProcessGraph">Autoload Process Graph
						</td>
					</tr>
					<tr id="taskTitle1">
						<td colspan="5">
							<div align="center">
									Task Analysis
							</div>
						</td>
					</tr>
					<tr id="taskTitle1">
						<td colspan="5">
							<div align="center">
									<button type="button" onclick="viewPetriNets()">Petri Net View</button>
							</div>
						</td>
					</tr>
					<tr>
						<td colspan="5">
							<div align="center">
									Petri Nets to Visualize<br />
									<select style="width: 100%;" name="petriNets" id="petriNets" multiple>
									</select>
							</div>
						</td>
					</tr>
					<tr>
						<td colspan="5">
							<table id="innerFilterTable">
								<tr id="filterTitle1">
									<td colspan="6">
										<div align="center">
												Filters
										</div>
									</td>
								</tr>
								<tr>
									<td colspan="3">
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
									<td colspan="6">
									<div align="center">
									<button type="button" onclick="loadFilter(true)">Load</button>
									<button type="button" onclick="loadFilter(false)">Append</button>
									<button type="button" onclick="deleteFilter()">Delete</button>
									</div>
									</td>
								</tr>
								<tr>
									<td colspan="6">
									<div align="center">
									<select name="savedFilters" id="savedFilters">
										<option value="default">Default</option>
									</select>
									</div>
									</td>
								</tr>
								<tr id="filterTitle2">
									<td width="10%">
									Level
									</td>
									<td width="10%">
									Prefix
									</td>
									<td width="20%">
									Field
									</td>
									<td width="40%">
									Suffix
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
									<td id = "filter_add_prefix">
									<input type="text" size="2" id="filter_add_prefix_field" name="filter_add_prefix_field" value="">
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
		<td id="legendTable" class="layoutTableSide rightCol">
			<table width="100%" height="100%">
					<tr id="legendTitle">
						<td>
							<div align="center">Legend</div>
						</td>
					</tr>
					<tr>
						<td style="height:100%" id="legendCell">
							<div style="overflow-y: scroll; max-height: 100%" align="left" id="legend">
							
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
		<td class="layoutTableCenter centerCol", id="graphCell">
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

<script>
	var showLeft = true;
	function toggleLeft()
	{
		showLeft = !(showLeft);
		toDisplay = "none";
		if(showLeft)
		{
			document.getElementById("leftHide").innerHTML = "⊟";
			toDisplay = "";
			d3.selectAll(".leftCol").style("display", toDisplay);
			visWidthParent -= d3.select(".leftCol").node().offsetWidth;
		}
		else
		{
			
			document.getElementById("leftHide").innerHTML = "⊞";
			visWidthParent += d3.select(".leftCol").node().offsetWidth;
			d3.selectAll(".leftCol").style("display", toDisplay);
		}
		start(true);
	}
	
	var filters = [];
	var filtersTitle = [];
	var startFilters = 0;
	
	var firstFilter = {}
	firstFilter["Prefix"] = "";
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
	var eventAdmin = "<%=eventAdmin %>";
	
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
			urlToPost += "&filterPrefix" + x + "=" + filters[entry]["Prefix"];
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
				});
	}
	
	function rebuildFilters()
	{
		var tableData = filtersTitle.concat(filters);
		d3.select("#innerFilterTable")
			.selectAll("tr")
			//.data(tableData)
			//.exit()
			.remove();
		d3.select("#innerFilterTable")
			.selectAll("tr")
			.data(tableData)
			.enter()
			.append("tr")
			.style("height", function(d, i)
					{
						//return "100%";
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
						+"<td id = \"filter_" + (i - startFilters) + "_prefix\">"
						+d["Prefix"]
						+"</td>"
						+"<td id = \"filter_" + (i - startFilters) + "_field\">"
						+d["Field"]
						+"</td>"
						+"<td style=\"overflow-x:auto; overflow-y:auto; word-break:break-all; height:100%;\" id = \"filter_" + (i - startFilters) + "_value\">"
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
		
		rebuildPetriMenu();
	}
	
	//rebuildFilters();

	async function removeFilter(filterNum)
	{
		filterChanged = true;
		
		filters.splice(filterNum - 1, 1);
		rebuildFilters();
		await start(true);
	}
	
	var filterChanged = true;
	
	
	async function addFilter()
	{
		filterChanged = true;
		
		levelVal = document.getElementById("filter_add_level_field").value;
		prefixVal = document.getElementById("filter_add_prefix_field").value;
		fieldVal = document.getElementById("filter_add_field_field").value;
		valueVal = document.getElementById("filter_add_value_field").value;
		var newFilter = {}
		newFilter["Level"] = Number(levelVal);
		newFilter["Prefix"] = prefixVal;
		newFilter["Field"] = fieldVal;
		newFilter["Value"] = valueVal;
		filters.push(newFilter);
		
		rebuildFilters();
		await start(true);
	}
	
	function addFilterDirect(levelVal, prefixVal, fieldVal, valueVal)
	{
		filterChanged = true;
		//levelVal = document.getElementById("filter_add_level_field").value;
		//fieldVal = document.getElementById("filter_add_field_field").value;
		//valueVal = document.getElementById("filter_add_value_field").value;
		var newFilter = {}
		newFilter["Level"] = Number(levelVal);
		newFilter["Prefix"] = prefixVal;
		newFilter["Field"] = fieldVal;
		newFilter["Value"] = valueVal;
		filters.push(newFilter);
		
		rebuildFilters();
		start(true);
	}
	
	async function getProcessData()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_processes");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}
	
	async function getProcessDataFiltered()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_processes_filtered");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}
	
	async function storeProcessDataFiltered(toStore)
	{
		if(this.session == "Aggregated")
		{
			
		}
		else
		{
			var isDone = false;
			while(!isDone)
			{
				var hashVal = SHA256(this.user + this.session + "_processes_filtered");
				isDone = await persistData(hashVal, toStore);
			}
		}
	}
	
	async function getMouseData()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_mouse");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}
	
	async function getMouseDataFiltered()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_mouse_filtered");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}
	
	async function storeMouseDataFiltered(toStore)
	{
		if(this.session == "Aggregated")
		{
			
		}
		else
		{
			var isDone = false;
			while(!isDone)
			{
				var hashVal = SHA256(this.user + this.session + "_mouse_filtered");
				isDone = await persistData(hashVal, toStore);
			}
		}
	}
	
	async function getKeystrokesData()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_keystrokes");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}
	
	async function getKeystrokesDataFiltered()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_keystrokes_filtered");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}
	
	async function storeKeystrokesDataFiltered(toStore)
	{
		if(this.session == "Aggregated")
		{
			
		}
		else
		{
			var isDone = false;
			while(!isDone)
			{
				var hashVal = SHA256(this.user + this.session + "_keystrokes_filtered");
				isDone = await persistData(hashVal, toStore);
			}
		}
	}

	
	var startedDownload = {};
	
	async function downloadUser(user)
	{
		let theNormDataInit = ((await retrieveData("indexdata")).value);
		console.log(theNormDataInit);
		console.log(user);
		for(session in theNormDataInit[user])
		{
			if(Object.keys(theNormDataInit[user][session]).length < 3)
			{
				delete theNormDataInit[user][session];
				continue;
			}
			
			var hashValDownload = SHA256(user + session + "_download");
			if(!startedDownload[hashValDownload])
			{
				console.log("Starting first download " + user + ":" + session);
				startedDownload[hashValDownload] = true;
				downloadImages(user, session, theNormDataInit[user][session]["screenshots"], 0);
				downloadProcesses(user, session, 0);
				downloadMouse(user, session, 0);
				downloadKeystrokes(user, session, 0);
			}
		}
	}
	
	function preprocess(dataToModify)
	{
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
				if(!startedDownload[hashValDownload])
				{
					colorButtons(user, session);
				}
				else
				{
					console.log("Already downloaded " + user + ":" + session);
				}
				
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
	async function filter(dataToFilter, filters)
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
					var isAsync = false;
					var dataSource = dataToFilter[user][session][data];
					if(!dataSource)
					{
						console.log("No data source for " + user + ":" + session + ":" + data)
						continue;
					}
					if(dataToFilter[user][session][data]["data"] && (typeof dataToFilter[user][session][data]["data"]) == "function")
					{
						dataSource = (await dataToFilter[user][session][data]["data"]());
						if(!dataSource)
						{
							console.log("No data source for " + user + ":" + session + ":" + data)
							continue;
						}
						dataSource = dataSource.value;
						if(!dataSource)
						{
							console.log("No data source for " + user + ":" + session + ":" + data)
							continue;
						}
						isAsync = true;
					}
					toFilter = filterMap[2];
					if(toFilter)
					{
						for(curFilter in toFilter)
						{
							if(!(eval("'" + data + "'" + toFilter[curFilter]["Value"])))
							{
								dataSource = [];
							}
						}
					}
					toSplice = [];
					entry = 0;
					if(!dataSource)
					{
						console.log("No data source for " + user + ":" + session + ":" + data)
						continue;
					}
					curLength = dataSource.length;
					while(entry < curLength)
					//for(entry in dataToFilter[user][session][data])
					{
						toFilter = filterMap[3];
						var filteredOut = false;
						if(toFilter)
						{
							for(curFilter in toFilter)
							{
								if(toFilter[curFilter]["Field"] in dataSource[entry])
								{
									if(!(eval(toFilter[curFilter]["Prefix"] + "'" + dataSource[entry][toFilter[curFilter]["Field"]] + "'" + toFilter[curFilter]["Value"])))
									{
										dataSource.splice(entry, 1);
										entry--;
										curLength = dataSource.length;
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
								if(!(dataSource[entry]["Command"] in userProcFound))
								{
									if(dataSource[entry]["Command"] in summaryProcStats)
									{
										summaryProcStats[dataSource[entry]["Command"]]["count"]++;
									}
									else
									{
										procStatMap = {};
										procStatMap["Command"] = dataSource[entry]["Command"];
										procStatMap["count"] = 1;
										summaryProcStats[dataSource[entry]["Command"]] = procStatMap;
									}
									userProcFound[dataSource[entry]["Command"]] = 0
								}
							}
						}
						entry++;
					}
					
					if(isAsync)
					{
						dataSource = await dataToFilter[user][session][data]["storefiltered"](dataSource);
					}
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
		return dataToFilter;
	}
	
	var theNormData;
	var theNormDataClone;
	var theNormDataDone = false;
	var origTitle = d3.select("#title").text();
	
	var savedFilters = {};
	
	async function main()
	{
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
					
				d3.select("#innerFilterTable")
				.selectAll("tr")
				.each(function(d, i)
						{
							filtersTitle.push(this);
							startFilters = i;
						});
				rebuildFilters();
				downloadData();
			})
	}

	var db;
	var objectStore;
	
	var curQueue = [];
	
	var persistWriting = false;

	
	async function persistData(key, value)
	{
		var args = {};
		args["key"] = key;
		args["value"] = value;
		curQueue.push(args);
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
		curQueue.push(args);
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
		var hashVal = this["ImageHash"];
		var toReturn = (await retrieveData(hashVal));
		return toReturn.value;
	}
	
	async function hasScreenshot(entry)
	{
		var hashVal = entry["ImageHash"];
		var toReturn = (await hasData(hashVal));
		return toReturn;
	}
	
	var downloadedImageSize = 0;
	var downloadedProcessSize = 0;
	var downloadedMouseSize = 0;
	var downloadedKeystrokesSize = 0;
	var downloadedSize = 0;
	
	var updating = false;
	
	async function refreshData()
	{
		console.log("Refreshing data");
		if(updating)
		{
			console.log("Refresh already underway");
			return;
		}
		updating = true;
		start(true);
		
		updating = false;
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
	var doneDownloading = false;
	
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
		lastTime = (await retrieveData("time"));
		//origTitle += ", last visit on " + lastTime;
		
		d3.select("#title")
			.html(origTitle);

		if(needsUpdate)
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

			d3.json("logExport.json?event=" + eventName + "&datasources=windows,events,environment,screenshotindices&normalize=none" + userSessionFilter, async function(error, data)
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
					theNormData = preprocess(data);
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
					
					theNormDataDone = true;
					
					d3.select("#title")
						.html(origTitle + "<br />Index data: <b>" + downloadedSize + "</b> bytes; new image data: <b>" + downloadedImageSize + "</b> bytes; new process data: <b>" + downloadedProcessSize + "</b> bytes; finished " + downloadedSessions + " of " + totalSessions + " sessions.")

					d3.select("body").style("cursor", "");
					start(true);
				})
				.on("progress", function(d, i)
						{
							downloadedSize = d["loaded"];
							d3.select("#title")
									.html(origTitle + "<br />Data Size: <b>" + d["loaded"] + "</b> bytes")
						});
		}
		else
		{
			theNormDataDone = true;
			d3.select("body").style("cursor", "");
			start(true);
		}
	}
	
	var sessionDownloadCount = {};
	var numAsync = 4;
	
	function addDownloadCount(userName, sessionName)
	{
		if(!(userName in sessionDownloadCount))
		{
			sessionDownloadCount[userName] = {};
		}
		if(!(sessionName in sessionDownloadCount[userName]))
		{
			sessionDownloadCount[userName][sessionName] = 0;
		}
		sessionDownloadCount[userName][sessionName] = sessionDownloadCount[userName][sessionName] + 1;
		return sessionDownloadCount[userName][sessionName];
	}
	
	var downloadedSessions = 0;
	var downloadedProcessSessions = 0;
	var downloadedMouseSessions = 0;
	var downloadedKeystrokesSessions = 0;
	var totalSessions = 0;
	
	var processChunkSize = 500000;
	
	var downloadedSessionProcesses = 0;
	
	var maxDownloadingProcesses = 4;
	var curDownloadingProcesses = 0;
	var maxDownloadingProcessesCeil = 8;
	var processDownloadQueue = [];
	
	async function downloadProcesses(userName, sessionName, nextCount, sheet)
	{
		console.log("Downloading process data for: " + userName + ":" + sessionName + ", index " + nextCount);
		if(curDownloadingProcesses >= maxDownloadingProcesses)
		{
			console.log("Already downloading max, put in queue.");
			var argList = [userName, sessionName, nextCount, sheet];
			processDownloadQueue.push(argList);
			return;
			
		}
		curDownloadingProcesses++;
		if(!sheet)
		{
			var hashVal = SHA256(user + session + "_processes");
			var hasStored = ((await hasData(hashVal)))
			if(hasStored)
			{
				var curProcArray = ((await retrieveData(hashVal)).value);
				//nextCount = curProcArray.length;
				var isDone = false;
				while(!isDone)
				{
					isDone = await persistData(hashVal, []);
				}
				
			}
			
			var sheet = document.getElementById("style_" + SHA256(userName + sessionName));
			if(!sheet)
			{
				var sheet = document.createElement('style');
				sheet.id = "style_" + SHA256(userName + sessionName);
			}
		}
		
		sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Yellow;}";
		document.body.appendChild(sheet);
		
		var curCount = nextCount;
		
		var curSelect = "&users=" + userName + "&sessions=" + sessionName + "&first=" + curCount + "&count=" + processChunkSize;
		
		var failed = true;
	
		await d3.json("logExport.json?event=" + eventName + "&datasources=processes&normalize=none" + curSelect, async function(error, data)
		{
			if(error)
			{
				maxDownloadingProcesses = maxDownloadingProcesses / 2;
				if(maxDownloadingProcesses < 1)
				{
					maxDownloadingProcesses = 1;
				}
				curDownloadingProcesses--;
				failed = true;
				console.log("Error, retrying...");
				console.log(error);
				downloadProcesses(userName, sessionName, curCount, sheet);
				return;
			}
			else
			{
				maxDownloadingProcesses = maxDownloadingProcesses * 2;
				if(maxDownloadingProcesses > maxDownloadingProcessesCeil)
				{
					maxDownloadingProcesses = maxDownloadingProcessesCeil;
				}
				if(processDownloadQueue.length > 0)
				{
					var nextArgs = processDownloadQueue.pop();
					downloadProcesses(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
				}
			}
			failed = false;
			//for(user in data)
			//if(data[userName])
			{
				//for(session in data[user])
				//if(data[userName][sessionName])
				{
					var curProcessList;
					if(!data[userName][sessionName])
					{
						
					}
					else
					{
						curProcessList = data[userName][sessionName]["processes"];
					}
					if(curProcessList)
					{
						var hashVal = SHA256(userName + sessionName + "_processes");
						
						for(entry in curProcessList)
						{
							curProcessList[entry]["Original Session"] = sessionName;
						}
						
						try
						{
							var hasStored = ((await hasData(hashVal)))
							var curProcArray = curProcessList;
							if(hasStored)
							{
								curProcArray = ((await retrieveData(hashVal)).value);
								curProcArray = curProcArray.concat(curProcessList);
							}
							
							var isDone = false;
							while(!isDone)
							{
								isDone = await persistData(hashVal, curProcArray);
							}
						}
						catch(err)
						{
							failed = true;
							console.log(err);
						}
						curDownloadingProcesses--;
						downloadProcesses(userName, sessionName, curCount + processChunkSize, sheet);
					}
					else
					{
						curDownloadingProcesses--;
						downloadedProcessSessions++;
						console.log("Done downloading processes for " + userName + ":" + sessionName);
						//start(true);
						d3.select("#title")
						.html(origTitle + "<br />Index data: <b>"
								+ downloadedSize
								+ "</b> bytes; new image data: <b>"
								+ downloadedImageSize
								+ "</b> bytes; new process data: <b>"
								+ downloadedProcessSize
								+ "</b> bytes; new keystrokes data: <b>"
								+ downloadedKeystrokesSize
								+ "</b> bytes; new mouse data: <b>"
								+ downloadedMouseSize + "</b> bytes; finished "
								+ downloadedSessions
								+ " screenshot, "
								+ downloadedProcessSessions + " process, "
								+ downloadedKeystrokesSessions + " keystrokes, and "
								+ downloadedMouseSessions + " mouse sessions of "
								+ totalSessions
								+ " total sessions.")
						if(addDownloadCount(userName, sessionName) >= numAsync)
						{
							sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Chartreuse;}";
							if(downloadedMouseSessions == totalSessions && downloadedKeystrokesSessions == totalSessions && downloadedProcessSessions == totalSessions && downloadedSessions == totalSessions)
							{
								await removeFilter(1);
								doneDownloading = true;
							}
						}
						
						if(processDownloadQueue.length > 0)
						{
							var nextArgs = processDownloadQueue.pop();
							downloadProcesses(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
						}
					}
					
				}
			}
		})
		.on("progress", async function(d, i)
		{
			//downloadedSize = d["loaded"];
			downloadedProcessSize += d["loaded"];
			d3.select("#title")
			.html(origTitle + "<br />Index data: <b>"
					+ downloadedSize
					+ "</b> bytes; new image data: <b>"
					+ downloadedImageSize
					+ "</b> bytes; new process data: <b>"
					+ downloadedProcessSize
					+ "</b> bytes; new keystrokes data: <b>"
					+ downloadedKeystrokesSize
					+ "</b> bytes; new mouse data: <b>"
					+ downloadedMouseSize + "</b> bytes; finished "
					+ downloadedSessions
					+ " screenshot, "
					+ downloadedProcessSessions + " process, "
					+ downloadedKeystrokesSessions + " keystrokes, and "
					+ downloadedMouseSessions + " mouse sessions of "
					+ totalSessions
					+ " total sessions.")
		});
	}
	
	var mouseChunkSize = 1000000;
	
	var downloadedSessionMouse = 0;
	
	var maxDownloadingMouse = 2;
	var curDownloadingMouse = 0;
	var mouseDownloadQueue = [];
	var maxDownloadingMouseCeil = 4;
	
	async function downloadMouse(userName, sessionName, nextCount, sheet)
	{
		console.log("Downloading mouse data for: " + userName + ":" + sessionName + ", index " + nextCount);
		if(curDownloadingMouse >= maxDownloadingMouse)
		{
			console.log("Already downloading max, put in queue.");
			var argList = [userName, sessionName, nextCount, sheet];
			mouseDownloadQueue.push(argList);
			return;
			
		}
		curDownloadingMouse++;
		if(!sheet)
		{
			var hashVal = SHA256(user + session + "_mouse");
			var hasStored = ((await hasData(hashVal)))
			if(hasStored)
			{
				var curMouseArray = ((await retrieveData(hashVal)).value);
				//nextCount = curProcArray.length;
				var isDone = false;
				while(!isDone)
				{
					isDone = await persistData(hashVal, []);
				}
				
			}
			
			var sheet = document.getElementById("style_" + SHA256(userName + sessionName));
			if(!sheet)
			{
				var sheet = document.createElement('style');
				sheet.id = "style_" + SHA256(userName + sessionName);
			}
		}
		
		sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Yellow;}";
		document.body.appendChild(sheet);
		
		var curCount = nextCount;
		
		var curSelect = "&users=" + userName + "&sessions=" + sessionName + "&first=" + curCount + "&count=" + mouseChunkSize;
		
		var failed = true;
	
		await d3.json("logExport.json?event=" + eventName + "&datasources=mouse&normalize=none" + curSelect, async function(error, data)
		{
			if(error)
			{
				maxDownloadingMouse = maxDownloadingMouse / 2;
				if(maxDownloadingMouse < 1)
				{
					maxDownloadingMouse = 1;
				}
				curDownloadingMouse--;
				failed = true;
				console.log("Error, retrying...");
				console.log(error);
				downloadMouse(userName, sessionName, curCount, sheet);
				return;
			}
			else
			{
				maxDownloadingMouse = maxDownloadingMouse * 2;
				if(maxDownloadingMouse > maxDownloadingMouseCeil)
				{
					maxDownloadingMouse = maxDownloadingMouseCeil;
				}
				if(mouseDownloadQueue.length > 0)
				{
					var nextArgs = mouseDownloadQueue.pop();
					downloadMouse(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
				}
			}
			failed = false;
			//for(user in data)
			//if(data[userName])
			{
				//for(session in data[user])
				//if(data[userName][sessionName])
				{
					var curMouseList;
					if(!(data[userName][sessionName]))
					{
						
					}
					else
					{
						curMouseList = data[userName][sessionName]["mouse"];
					}
					if(curMouseList)
					{
						var hashVal = SHA256(userName + sessionName + "_mouse");
						
						for(entry in curMouseList)
						{
							curMouseList[entry]["Original Session"] = sessionName;
						}
						
						try
						{
							var hasStored = ((await hasData(hashVal)))
							var curMouseArray = curMouseList;
							if(hasStored)
							{
								curMouseArray = ((await retrieveData(hashVal)).value);
								curMouseArray = curMouseArray.concat(curMouseList);
							}
							
							var isDone = false;
							while(!isDone)
							{
								isDone = await persistData(hashVal, curMouseArray);
							}
						}
						catch(err)
						{
							failed = true;
							console.log(err);
						}
						curDownloadingMouse--;
						downloadMouse(userName, sessionName, curCount + mouseChunkSize, sheet);
					}
					else
					{
						curDownloadingMouse--;
						downloadedMouseSessions++;
						console.log("Done downloading mouse for " + userName + ":" + sessionName);
						//start(true);
						d3.select("#title")
						.html(origTitle + "<br />Index data: <b>"
								+ downloadedSize
								+ "</b> bytes; new image data: <b>"
								+ downloadedImageSize
								+ "</b> bytes; new process data: <b>"
								+ downloadedProcessSize
								+ "</b> bytes; new keystrokes data: <b>"
								+ downloadedKeystrokesSize
								+ "</b> bytes; new mouse data: <b>"
								+ downloadedMouseSize + "</b> bytes; finished "
								+ downloadedSessions
								+ " screenshot, "
								+ downloadedProcessSessions + " process, "
								+ downloadedKeystrokesSessions + " keystrokes, and "
								+ downloadedMouseSessions + " mouse sessions of "
								+ totalSessions
								+ " total sessions.")
						if(addDownloadCount(userName, sessionName) >= numAsync)
						{
							sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Chartreuse;}";
							if(downloadedMouseSessions == totalSessions && downloadedKeystrokesSessions == totalSessions && downloadedProcessSessions == totalSessions && downloadedSessions == totalSessions)
							{
								await removeFilter(1);
								doneDownloading = true;
							}
						}
						
						if(mouseDownloadQueue.length > 0)
						{
							var nextArgs = mouseDownloadQueue.pop();
							downloadMouse(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
						}
					}
					
				}
			}
		})
		.on("progress", async function(d, i)
		{
			//downloadedSize = d["loaded"];
			downloadedMouseSize += d["loaded"];
			d3.select("#title")
			.html(origTitle + "<br />Index data: <b>"
					+ downloadedSize
					+ "</b> bytes; new image data: <b>"
					+ downloadedImageSize
					+ "</b> bytes; new process data: <b>"
					+ downloadedProcessSize
					+ "</b> bytes; new keystrokes data: <b>"
					+ downloadedKeystrokesSize
					+ "</b> bytes; new mouse data: <b>"
					+ downloadedMouseSize + "</b> bytes; finished "
					+ downloadedSessions
					+ " screenshot, "
					+ downloadedProcessSessions + " process, "
					+ downloadedKeystrokesSessions + " keystrokes, and "
					+ downloadedMouseSessions + " mouse sessions of "
					+ totalSessions
					+ " total sessions.")
		});
	}
	
	var keystrokesChunkSize = 1000000;
	
	var downloadedSessionKeystrokes = 0;
	
	var maxDownloadingKeystrokes = 2;
	var curDownloadingKeystrokes = 0;
	var keystrokesDownloadQueue = [];
	var maxDownloadingKeystrokesCeil = 4;
	
	async function downloadKeystrokes(userName, sessionName, nextCount, sheet)
	{
		console.log("Downloading keystrokes data for: " + userName + ":" + sessionName + ", index " + nextCount);
		if(curDownloadingKeystrokes >= maxDownloadingKeystrokes)
		{
			console.log("Already downloading max, put in queue.");
			var argList = [userName, sessionName, nextCount, sheet];
			keystrokesDownloadQueue.push(argList);
			return;
			
		}
		curDownloadingKeystrokes++;
		if(!sheet)
		{
			var hashVal = SHA256(user + session + "_keystrokes");
			var hasStored = ((await hasData(hashVal)))
			if(hasStored)
			{
				var curKeystrokesArray = ((await retrieveData(hashVal)).value);
				//nextCount = curProcArray.length;
				var isDone = false;
				while(!isDone)
				{
					isDone = await persistData(hashVal, []);
				}
				
			}
			
			var sheet = document.getElementById("style_" + SHA256(userName + sessionName));
			if(!sheet)
			{
				var sheet = document.createElement('style');
				sheet.id = "style_" + SHA256(userName + sessionName);
			}
		}
		
		sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Yellow;}";
		document.body.appendChild(sheet);
		
		var curCount = nextCount;
		
		var curSelect = "&users=" + userName + "&sessions=" + sessionName + "&first=" + curCount + "&count=" + keystrokesChunkSize;
		
		var failed = true;
	
		await d3.json("logExport.json?event=" + eventName + "&datasources=keystrokes&normalize=none" + curSelect, async function(error, data)
		{
			if(error)
			{
				maxDownloadingKeystrokes = maxDownloadingKeystrokes / 2;
				if(maxDownloadingKeystrokes < 1)
				{
					maxDownloadingKeystrokes = 1;
				}
				curDownloadingKeystrokes--;
				failed = true;
				console.log("Error, retrying...");
				console.log(error);
				downloadKeystrokes(userName, sessionName, curCount, sheet);
				return;
			}
			else
			{
				maxDownloadingKeystrokes = maxDownloadingKeystrokes * 2;
				if(maxDownloadingKeystrokes > maxDownloadingKeystrokesCeil)
				{
					maxDownloadingKeystrokes = maxDownloadingKeystrokesCeil;
				}
				if(keystrokesDownloadQueue.length > 0)
				{
					var nextArgs = keystrokesDownloadQueue.pop();
					downloadKeystrokes(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
				}
			}
			failed = false;
			//for(user in data)
			//if(data[userName])
			{
				//for(session in data[user])
				//if(data[userName][sessionName])
				{
					var curKeystrokesList;
					if(!data[userName][sessionName])
					{
						
					}
					else
					{
						curKeystrokesList = data[userName][sessionName]["keystrokes"];
					}
					if(curKeystrokesList)
					{
						var hashVal = SHA256(userName + sessionName + "_keystrokes");
						
						for(entry in curKeystrokesList)
						{
							curKeystrokesList[entry]["Original Session"] = sessionName;
						}
						
						try
						{
							var hasStored = ((await hasData(hashVal)))
							var curKeystrokesArray = curKeystrokesList;
							if(hasStored)
							{
								curKeystrokesArray = ((await retrieveData(hashVal)).value);
								curKeystrokesArray = curKeystrokesArray.concat(curKeystrokesList);
							}
							
							var isDone = false;
							while(!isDone)
							{
								isDone = await persistData(hashVal, curKeystrokesArray);
							}
						}
						catch(err)
						{
							failed = true;
							console.log(err);
						}
						curDownloadingKeystrokes--;
						downloadKeystrokes(userName, sessionName, curCount + keystrokesChunkSize, sheet);
					}
					else
					{
						curDownloadingKeystrokes--;
						downloadedKeystrokesSessions++;
						console.log("Done downloading mouse for " + userName + ":" + sessionName);
						//start(true);
						d3.select("#title")
						.html(origTitle + "<br />Index data: <b>"
								+ downloadedSize
								+ "</b> bytes; new image data: <b>"
								+ downloadedImageSize
								+ "</b> bytes; new process data: <b>"
								+ downloadedProcessSize
								+ "</b> bytes; new keystrokes data: <b>"
								+ downloadedKeystrokesSize
								+ "</b> bytes; new mouse data: <b>"
								+ downloadedMouseSize + "</b> bytes; finished "
								+ downloadedSessions
								+ " screenshot, "
								+ downloadedProcessSessions + " process, "
								+ downloadedKeystrokesSessions + " keystrokes, and "
								+ downloadedMouseSessions + " mouse sessions of "
								+ totalSessions
								+ " total sessions.")
						if(addDownloadCount(userName, sessionName) >= numAsync)
						{
							sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Chartreuse;}";
							if(downloadedMouseSessions == totalSessions && downloadedKeystrokesSessions == totalSessions && downloadedProcessSessions == totalSessions && downloadedSessions == totalSessions)
							{
								await removeFilter(1);
								doneDownloading = true;
							}
						}
						
						if(keystrokesDownloadQueue.length > 0)
						{
							var nextArgs = keystrokesDownloadQueue.pop();
							downloadKeystrokes(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
						}
					}
					
				}
			}
		})
		.on("progress", async function(d, i)
		{
			//downloadedSize = d["loaded"];
			downloadedKeystrokesSize += d["loaded"];
			d3.select("#title")
			.html(origTitle + "<br />Index data: <b>"
					+ downloadedSize
					+ "</b> bytes; new image data: <b>"
					+ downloadedImageSize
					+ "</b> bytes; new process data: <b>"
					+ downloadedProcessSize
					+ "</b> bytes; new keystrokes data: <b>"
					+ downloadedKeystrokesSize
					+ "</b> bytes; new mouse data: <b>"
					+ downloadedMouseSize + "</b> bytes; finished "
					+ downloadedSessions
					+ " screenshot, "
					+ downloadedProcessSessions + " process, "
					+ downloadedKeystrokesSessions + " keystrokes, and "
					+ downloadedMouseSessions + " mouse sessions of "
					+ totalSessions
					+ " total sessions.")
		});
	}
	
	async function colorButtons(userName, sessionName)
	{
		var sheet = document.createElement('style');
		sheet.id = "style_" + SHA256(userName + sessionName);
		sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Yellow;}";
		document.body.appendChild(sheet);
	}
	
	var chunkSize = 50;
	
	var maxDownloadingImages = 4;
	var curDownloadingImages = 0;
	var imageDownloadQueue = [];
	var maxDownloadingImagesCeil = 4;
	
	async function downloadImages(userName, sessionName, imageArray, nextCount, sheet)
	{
		console.log("Downloading image data for: " + userName + ":" + sessionName + ", index " + nextCount);
		
		if(curDownloadingImages >= maxDownloadingImages)
		{
			console.log("Already downloading max images, put in queue.");
			var argList = [userName, sessionName, imageArray, nextCount, sheet];
			console.log(argList);
			imageDownloadQueue.push(argList);
			return;
			
		}
		
		if(!imageArray)
		{
			console.log("No images: " + userName + ": " + sessionName);
			if(imageDownloadQueue.length > 0)
			{
				var nextArgs = imageDownloadQueue.pop();
				downloadImages(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3], nextArgs[4]);
			}
			else
			{
				curDownloadingImages--;
			}
			return;
		}
		
		curDownloadingImages++;
		if(!sheet)
		{
			var sheet = document.getElementById("style_" + SHA256(userName + sessionName));
			if(!sheet)
			{
				var sheet = document.createElement('style');
				sheet.id = "style_" + SHA256(userName + sessionName);
			}
		}
		sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Yellow;}";
		document.body.appendChild(sheet);

		var curCount = nextCount;
		
		while(curCount < imageArray.length)
		{
			if(!imageArray[curCount]["ImageHash"])
			{
				imageArray[curCount]["ImageHash"] = SHA256(user + session + imageArray[curCount]["Index MS"]);
			}
			var entry = curCount;
			var curScreenshot = (await hasScreenshot(imageArray[curCount]));
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
			var curSelect = "&users=" + userName + "&sessions=" + sessionName + "&first=" + curCount + "&count=" + chunkSize;
			await d3.json("logExport.json?event=" + eventName + "&datasources=screenshots&normalize=none" + curSelect, async function(error, data)
			{
				if(error)
				{
					maxDownloadingImages = maxDownloadingImages / 2;
					if(maxDownloadingImages < 1)
					{
						maxDownloadingImages = 1;
					}
					failed = true;
					console.log("Error, retrying...");
					console.log(error);
					curDownloadingImages--;
					downloadImages(userName, sessionName, imageArray, curCount, sheet);
					return;
				}
				else
				{
					maxDownloadingImages = maxDownloadingImages * 2;
					if(maxDownloadingImages > maxDownloadingImagesCeil)
					{
						maxDownloadingImages = maxDownloadingImagesCeil;
					}
					if(imageDownloadQueue.length > 0)
					{
						var nextArgs = imageDownloadQueue.pop();
						downloadImages(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3], nextArgs[4]);
					}
				}
				//for(user in data)
				{
					//for(session in data[user])
					{
						
						var curScreenshotList = data[userName][sessionName]["screenshots"];
						
						for(screenshot in curScreenshotList)
						{
							var hashVal = SHA256(userName + sessionName + curScreenshotList[screenshot]["Index MS"]);
							try
							{
								var isDone = false;
								while(!isDone)
								{
									isDone = await persistData(hashVal, curScreenshotList[screenshot]["Screenshot"]);
								}
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
				.html(origTitle + "<br />Index data: <b>"
						+ downloadedSize
						+ "</b> bytes; new image data: <b>"
						+ downloadedImageSize
						+ "</b> bytes; new process data: <b>"
						+ downloadedProcessSize
						+ "</b> bytes; new keystrokes data: <b>"
						+ downloadedKeystrokesSize
						+ "</b> bytes; new mouse data: <b>"
						+ downloadedMouseSize + "</b> bytes; finished "
						+ downloadedSessions
						+ " screenshot, "
						+ downloadedProcessSessions + " process, "
						+ downloadedKeystrokesSessions + " keystrokes, and "
						+ downloadedMouseSessions + " mouse sessions of "
						+ totalSessions
						+ " total sessions.")

				if(curCount < imageArray.length)
				{
					console.log("Continuing screenshots from " + userName + ", " + sessionName + ": " + curCount + " : " + chunkSize + " of " + imageArray.length);
					curDownloadingImages--;
					downloadImages(userName, sessionName, imageArray, curCount, sheet);
				}
				else
				{
					curDownloadingImages--;
					downloadedSessions++;
					d3.select("#title")
					.html(origTitle + "<br />Index data: <b>"
							+ downloadedSize
							+ "</b> bytes; new image data: <b>"
							+ downloadedImageSize
							+ "</b> bytes; new process data: <b>"
							+ downloadedProcessSize
							+ "</b> bytes; new keystrokes data: <b>"
							+ downloadedKeystrokesSize
							+ "</b> bytes; new mouse data: <b>"
							+ downloadedMouseSize + "</b> bytes; finished "
							+ downloadedSessions
							+ " screenshot, "
							+ downloadedProcessSessions + " process, "
							+ downloadedKeystrokesSessions + " keystrokes, and "
							+ downloadedMouseSessions + " mouse sessions of "
							+ totalSessions
							+ " total sessions.")
					if(addDownloadCount(userName, sessionName) >= numAsync)
					{
						sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Chartreuse;}";
						if(downloadedMouseSessions == totalSessions && downloadedKeystrokesSessions == totalSessions && downloadedProcessSessions == totalSessions && downloadedSessions == totalSessions)
						{
							await removeFilter(1);
							doneDownloading = true;
						}
					}
					if(imageDownloadQueue.length > 0)
					{
						var nextArgs = imageDownloadQueue.pop();
						downloadImages(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
					}
				}
				
			})
			.on("progress", async function(d, i)
					{
						//downloadedSize = d["loaded"];
						downloadedImageSize += d["loaded"];
						d3.select("#title")
						.html(origTitle + "<br />Index data: <b>"
								+ downloadedSize
								+ "</b> bytes; new image data: <b>"
								+ downloadedImageSize
								+ "</b> bytes; new process data: <b>"
								+ downloadedProcessSize
								+ "</b> bytes; new keystrokes data: <b>"
								+ downloadedKeystrokesSize
								+ "</b> bytes; new mouse data: <b>"
								+ downloadedMouseSize + "</b> bytes; finished "
								+ downloadedSessions
								+ " screenshot, "
								+ downloadedProcessSessions + " process, "
								+ downloadedKeystrokesSessions + " keystrokes, and "
								+ downloadedMouseSessions + " mouse sessions of "
								+ totalSessions
								+ " total sessions.")
					});
		}
		else
		{
			curDownloadingImages--;
			downloadedSessions++;
			d3.select("#title")
			.html(origTitle + "<br />Index data: <b>"
					+ downloadedSize
					+ "</b> bytes; new image data: <b>"
					+ downloadedImageSize
					+ "</b> bytes; new process data: <b>"
					+ downloadedProcessSize
					+ "</b> bytes; new keystrokes data: <b>"
					+ downloadedKeystrokesSize
					+ "</b> bytes; new mouse data: <b>"
					+ downloadedMouseSize + "</b> bytes; finished "
					+ downloadedSessions
					+ " screenshot, "
					+ downloadedProcessSessions + " process, "
					+ downloadedKeystrokesSessions + " keystrokes, and "
					+ downloadedMouseSessions + " mouse sessions of "
					+ totalSessions
					+ " total sessions.")
			if(addDownloadCount(userName, sessionName) >= numAsync)
			{
				sheet.innerHTML = "#playbutton_" + SHA256(userName + sessionName) + " {fill:Chartreuse;}";
				if(downloadedMouseSessions == totalSessions && downloadedKeystrokesSessions == totalSessions && downloadedProcessSessions == totalSessions && downloadedSessions == totalSessions)
				{
					await removeFilter(1);
					doneDownloading = true;
				}
			}
			if(imageDownloadQueue.length > 0)
			{
				var nextArgs = imageDownloadQueue.pop();
				downloadImages(nextArgs[0], nextArgs[1], nextArgs[2], nextArgs[3]);
			}
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
	
	async function getProcessMapData()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_processes_map");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}

	async function storeProcessDataMap(toStore)
	{
		if(this.session == "Aggregated")
		{
			
		}
		else
		{
			var isDone = false;
			//while(!isDone)
			{
				var hashVal = SHA256(this.user + this.session + "_processes_map");
				isDone = await persistDataAndWait(hashVal, toStore);
			}
		}
	}
	
	async function getProcessLookupData()
	{
		if(this.session == "Aggregated")
		{
			return [];
		}
		else
		{
			var hashVal = SHA256(this.user + this.session + "_processes_lookup");
			var toReturn = (await retrieveData(hashVal));
			return toReturn;
		}
	}

	async function storeProcessDataLookup(toStore)
	{
		if(this.session == "Aggregated")
		{
			
		}
		else
		{
			var isDone = false;
			while(!isDone)
			{
				var hashVal = SHA256(this.user + this.session + "_processes_lookup");
				isDone = await persistDataAndWait(hashVal, toStore);
			}
		}
	}
	
	var colorScale = d3.scaleOrdinal(d3.schemeCategory20);
	var colorScaleAccent = d3.scaleOrdinal(d3["schemeAccent"]);
	
	var processToWindow = {};
	var windowToProcess = {};

	var timelineTick;
	var timelineText;

	var visWidthParent = (containingTableRow.offsetWidth - visPadding);
	
	function getInnerHeight(elementID)
	{
		var toReturn = 0;
		toReturn = document.getElementById(elementID).getBoundingClientRect().height;
		toReturn -= parseInt(getComputedStyle(document.getElementById(elementID), null).getPropertyValue('border-top-width'), 10);
		toReturn -= parseInt(getComputedStyle(document.getElementById(elementID), null).getPropertyValue('border-bottom-width'), 10);
		toReturn -= parseInt(getComputedStyle(document.getElementById(elementID), null).getPropertyValue('padding-bottom'), 10);
		toReturn -= parseInt(getComputedStyle(document.getElementById(elementID), null).getPropertyValue('padding-top'), 10)
		return toReturn;
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
		curSelectSess = sessionStroke;
		if(curSelectSess)
		{
			curSelectSess.attr("stroke", curSelectSess.attr("initStroke")).attr("stroke-width", curSelectSess.attr("initStrokeWidth"));
			sessionStroke = undefined;
		}
		
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
		
		for(element in curHighlight)
		{
			curHighlight[element].attr("stroke-width", 0);
		}
		curHighlight = [];
		
		if(theNormDataDone)
		{
			
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
	
	
	
	var processTooltip;
	var processTooltipRect;
	var lastMouseOver;
	var lastMouseHash;
	
	
	function refreshUser(userName)
	{
		var curSelect = "&users=" + userName;
		d3.json("logExport.json?event=" + eventName + "&datasources=events&normalize=none" + curSelect, async function(error, data)
		{
			console.log("Downloaded")
			console.log(data);
			let theNormDataInit = ((await retrieveData("indexdata")).value);
			console.log("Adding to")
			console.log(theNormDataInit);
			
			for(sessionName in data[userName])
			{
				if(data[userName][sessionName]["events"])
				{
					theNormDataInit[userName][sessionName]["events"] = data[userName][sessionName]["events"];
				}
				else if(theNormDataInit[userName][sessionName]["events"])
				{
					delete theNormDataInit[userName][sessionName]["events"];
				}
			}
			
			try
			{
				var isDone = false;
				while(!isDone)
				{
					isDone = await persistDataAndWait("indexdata", theNormDataInit);
				}
			}
			catch(err)
			{
				console.log(err);
			}
			
			theNormData = preprocess(theNormDataInit);
			console.log("New norm data")
			console.log(theNormData)
			try
			{
				var isDone = false;
				while(!(isDone == true))
				{
					isDone = (await (persistDataAndWait("data", theNormData)));
				}
				start(true);
			}
			catch(err)
			{
				console.log(err);
			}
			
		});
		/*
		for(session in theNormData[user]["Session Ordering"]["Order List"])
		{
			var curSession = theNormData[user]["Session Ordering"][theNormData[user]["Session Ordering"]["Order List"][session]];
			console.log(curSession);
			refreshSession(userName, curSession);
		}
		*/
	}
	
	function refreshSession(userName, sessionName)
	{
		var curSelect = "&users=" + userName + "&sessions=" + sessionName;
		d3.json("logExport.json?event=" + eventName + "&datasources=events&normalize=none" + curSelect, async function(error, data)
		{
			console.log("Downloaded")
			console.log(data);
			let theNormDataInit = ((await retrieveData("indexdata")).value);
			console.log("Adding to")
			console.log(theNormDataInit);
			
			theNormDataInit[userName][sessionName]["events"] = data[userName][sessionName]["events"];
			try
			{
				var isDone = false;
				while(!isDone)
				{
					isDone = await persistDataAndWait("indexdata", theNormDataInit);
				}
			}
			catch(err)
			{
				console.log(err);
			}
			
			theNormData = preprocess(theNormDataInit);
			console.log("New norm data")
			console.log(theNormData)
			try
			{
				var isDone = false;
				while(!(isDone == true))
				{
					isDone = (await (persistDataAndWait("data", theNormData)));
				}
				if(fromAni)
				{
					document.getElementById("addTaskAniStart").value = "Start (MS Session Time)";
					document.getElementById("addTaskAniEnd").value = "End (MS Session Time)";
					document.getElementById("addTaskAniName").value = "";
					document.getElementById("tagsAni").value = "";
					document.getElementById("addTaskAniGoal").value = "";
				}
				start(true);
			}
			catch(err)
			{
				console.log(err);
			}
			
		});
	}
	
	var curSelectUser = "";
	var curSelectSession = "";
	
	function addTask(userName, sessionName, isUpdate, fromAni)
	{
		var startTask = "";
		var endTask = "";
		var taskName = "";
		var taskTags = "";
		var taskGoal = "";
		if(fromAni)
		{
			startTask = Number(document.getElementById("addTaskAniStart").value) + theNormData[userName][sessionName]["Index MS Session Min Universal"];
			endTask = Number(document.getElementById("addTaskAniEnd").value) + theNormData[userName][sessionName]["Index MS Session Min Universal"];
			taskName = document.getElementById("addTaskAniName").value;
			taskTags = encodeURIComponent(document.getElementById("tagsAni").value);
			taskGoal = document.getElementById("addTaskAniGoal").value;
		}
		else if(isUpdate)
		{
			startTask = Number(document.getElementById("updateTaskStart").value) + theNormData[userName][sessionName]["Index MS Session Min Universal"];
			endTask = Number(document.getElementById("updateTaskEnd").value) + theNormData[userName][sessionName]["Index MS Session Min Universal"];
			taskName = document.getElementById("updateTaskName").value;
			taskTags = encodeURIComponent(document.getElementById("updateTags").value);
			taskGoal = document.getElementById("updateTaskGoal").value;
		}
		else
		{
			startTask = Number(document.getElementById("addTaskStart").value) + theNormData[userName][sessionName]["Index MS Session Min Universal"];
			endTask = Number(document.getElementById("addTaskEnd").value) + theNormData[userName][sessionName]["Index MS Session Min Universal"];
			taskName = document.getElementById("addTaskName").value;
			taskTags = encodeURIComponent(document.getElementById("tags").value);
			taskGoal = document.getElementById("addTaskGoal").value;
		}
		
		var taskUrl = "addTask.json?event=" + eventName + "&userName=" + userName + "&sessionName=" + sessionName + "&start=" + startTask + "&end=" + endTask + "&taskName=" + taskName + "&taskGoal=" + taskGoal + "&taskTags=" + taskTags;
		
		d3.json(taskUrl, function(error, data)
					{
						if(data["result"] == "okay")
						{
							console.log("Added task, now refreshing")
							var curSelect = "&users=" + userName + "&sessions=" + sessionName;
							d3.json("logExport.json?event=" + eventName + "&datasources=events&normalize=none" + curSelect, async function(error, data)
							{
								console.log("Downloaded")
								console.log(data);
								let theNormDataInit = ((await retrieveData("indexdata")).value);
								console.log("Adding to")
								console.log(theNormDataInit);
								
								theNormDataInit[userName][sessionName]["events"] = data[userName][sessionName]["events"];
								try
								{
									var isDone = false;
									while(!isDone)
									{
										isDone = await persistDataAndWait("indexdata", theNormDataInit);
									}
								}
								catch(err)
								{
									console.log(err);
								}
								
								theNormData = preprocess(theNormDataInit);
								console.log("New norm data")
								console.log(theNormData)
								try
								{
									var isDone = false;
									while(!(isDone == true))
									{
										isDone = (await (persistDataAndWait("data", theNormData)));
									}
									if(fromAni)
									{
										document.getElementById("addTaskAniStart").value = "Start (MS Session Time)";
										document.getElementById("addTaskAniEnd").value = "End (MS Session Time)";
										document.getElementById("addTaskAniName").value = "";
										document.getElementById("tagsAni").value = "";
										document.getElementById("addTaskAniGoal").value = "";
									}
									start(true);
								}
								catch(err)
								{
									console.log(err);
								}
								
							});
						}
						
					});
	}
	
	var searchTerms = ["Reverse", "Engineering", "Produces", "Resuls"];
	function filterTags()
	{
		var input = document.getElementById("searchTags");
		var filter = input.value.toUpperCase();
		var selected = document.getElementById("storedTags");
		var items = selected.getElementsByTagName("option");
		for (i = 0; i < items.length; i++)
		{
			var txtValue = items[i].textContent || items[i].innerText;
			if(txtValue.toUpperCase().indexOf(filter) > -1)
			{
				items[i].style.display = "";
			}
			else
			{
				items[i].style.display = "none";
				items[i].selected = false;
			}
		}
	}
	
	function delBlankLines(isAni)
	{
		 var tagEle = document.getElementById('tags');
		 if(isAni)
		 {
			 tagEle = document.getElementById('tagsAni');
		 }
		 var stringArray = tagEle.value.split('\n');
		 var temp = [""];
		 var x = 0;
		 for (var i = 0; i < stringArray.length; i++)
		 {
		   if (stringArray[i].trim() != "")
		   {
		     temp[x] = stringArray[i];
		     x++;
		   }
		 }

		 temp = temp.join('\n');
		 tagEle.value = temp;
	}
	
	function addTag(isAni)
	{
		var tagbox = document.getElementById("tags");
		var selected = document.getElementById("storedTags");
		if(isAni)
		{
			tagbox = document.getElementById("tagsAni");
			selected = document.getElementById("storedTagsAni");
		}
		var items = selected.getElementsByTagName("option");
		for (i = 0; i < items.length; i++)
		{
			if(items[i].selected)
			{
				var txtValue = items[i].textContent || items[i].innerText;
				tagbox.value = tagbox.value + "\n" + txtValue;
			}
		}
		delBlankLines(isAni);
	}

	var selectRect;
	var timeScaleAni;
	
	var lastSessionUser = "";
	var lastSessionSession = "";
	var cachedProcessMap;
	var cachedSortedList;
	var cachedMaxCPU;
	var cachedFinalProcList;
	var cachedLineFormattedData;
	var cachedNewSvg;
	var cachedNewSvgParent;
	var procPointsCached;
	var procPointsWindowCached;
	var enterExitCached;
	var procLinesCached;
	
	
	async function showSession(owningUser, owningSession)
	{
		var selector = "#background_rect_" + SHA256(owningUser + owningSession);
		if(sessionStroke)
		{
			if(sessionStroke.attr("id") != selector)
			{
				console.log("Not showing session yet");
				
				sessionStroke.attr("stroke-width", sessionStroke.attr("initStrokeWidth"));
				sessionStroke.attr("stroke", sessionStroke.attr("initStroke"));
				
				clearWindow();
			}
			else
			{
				console.log("Already showing session");
				return;
			}
		}
		else
		{
			clearWindow();
		}
		
		
		
		var curSelectSess = d3.select(selector);
		//console.log(selector);
		//console.log(curSelectSess);
		curSelectSess.attr("initStrokeWidth", curSelectSess.attr("stroke-width"));
		curSelectSess.attr("initStroke", curSelectSess.attr("stroke"));
		curSelectSess.attr("stroke", "#ff0000").attr("stroke-width", xAxisPadding / 50);
		
		sessionStroke = curSelectSess;
		//if((!filterChanged) && lastSessionUser == curSelectUser && lastSessionSession = curSelectSession)
		//{
		//	
		//}
		curMode = "session";
		curSelectUser = owningUser;
		curSelectSession = owningSession;
		
		
		bottomVizFontSize = bottomVisHeight / 25;
		
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
					//showLightbox("<tr><td><div width=\"100%\"><img src=\"./getScreenshot.jpg?username=" + owningUser + "&timestamp=" + getScreenshot(owningUser, screenshotSession, screenshotIndex)["Index MS"] + "&session=" + screenshotSession + "&event=" + eventName + "\" style=\"max-height: " + (windowHeight * .9) + "px; max-width:100%\"></div></td></tr>");
					showLightbox("<tr><td><div width=\"100%\"><img src=\"data:image/jpg;base64," + (await (theNormData[owningUser][owningSession]["screenshots"][0]["Screenshot"]())) + "\" style=\"max-height: " + (windowHeight * .9) + "px; max-width:100%\"></div></td></tr>");
				});

		
		//Get cached things if nothing has changed
		var getCached = false;
		if((!filterChanged) && lastSessionUser == curSelectUser && lastSessionSession == curSelectSession)
		{
			getCached = true;
			console.log("Process map cached");
			curProcessMap = cachedProcessMap;
		}
		else
		{
			console.log("Getting process map");
			curProcessMap = (await processMap[owningUser][owningSession]["data"]()).value;
		}
		cachedProcessMap = curProcessMap;
		lastSessionUser = curSelectUser;
		lastSessionSession = curSelectSession
		
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
			.html("<td><div id=\"addTaskTitle\" align=\"center\">Add Task</div></td>");
		
		var selectEntries = "";
		for(var x = 0; searchTerms && x < searchTerms.length; x++)
		{
			selectEntries = selectEntries + "<option value=\"" + searchTerms[x] + "\">" + searchTerms[x] + "</option>";
		}
		
		var addTagRow = d3.select("#infoTable").append("tr").append("td")
		.attr("width", visWidthParent + "px")
				.append("table").attr("width", visWidthParent + "px").append("tr").attr("width", visWidthParent + "px")
					.html(	"<td colspan=\"2\" width=\"50%\"><div align=\"center\"><b>Search Tags:</b></div><div align=\"center\"><input type=\"text\" style=\"width:75%\" id=\"searchTags\" name=\"searchTags\" value=\"Search/New\" onkeyup=\"filterTags()\"><button type=\"button\" style=\"width:20%\" onclick=\"addTag()\">Add</button></div>" +
							"<div align=\"center\"><select style=\"width:100%\" name=\"storedTags\" id=\"storedTags\" size=\"3\" multiple>" + selectEntries + "</select></div></td>" +
							"<td colspan=\"2\" width=\"50%\"><div align=\"center\"><b>Task Tags:</b></div><div align=\"center\"><textarea id=\"tags\" name=\"tags\" rows=\"5\" cols=\"50\"></textarea></div></td>");
		
		var addGoalRow = d3.select("#infoTable").append("tr").append("td")
		.attr("width", visWidthParent + "px")
				.append("table").attr("width", visWidthParent + "px").append("tr").attr("width", visWidthParent + "px")
					.html(	"<td colspan=\"4\" width=\"100%\"><div align=\"center\"><b>Task Goal:</b></div><div align=\"center\"><textarea id=\"addTaskGoal\" name=\"addTaskGoal\" rows=\"2\" cols=\"100\"></textarea></div></td>");
		
		var addTaskRow = d3.select("#infoTable").append("tr").append("td")
		.attr("width", visWidthParent + "px")
				.append("table").attr("width", visWidthParent + "px").append("tr").attr("width", visWidthParent + "px")
					.html("<td width=\"25%\"><div align=\"center\"><input type=\"text\" id=\"addTaskStart\" name=\"addTaskStart\" value=\"Start (MS Session Time)\"></div></td>" +
							"<td width=\"25%\"><div align=\"center\"><input type=\"text\" id=\"addTaskEnd\" name=\"addTaskEnd\" value=\"End (MS Session Time)\"></div></td>" +
							"<td width=\"25%\"><div align=\"center\"><input type=\"text\" id=\"addTaskName\" name=\"addTaskName\" value=\"Task Name\"></div></td>" +
							"<td width=\"25%\"><div align=\"center\"><button type=\"button\" onclick=\"addTask('" + owningUser + "', '" + owningSession + "')\">Submit</button></div></td>");
		
		var newAxis = d3.axisTop(timeScale);
		
		var initX = 0;
		
		timeScaleAni = timeScale;
		
		var dragAddTask = d3.drag()
			.on("drag", dragmoveAddTask)
			.on("start", function(d)
					{
						initX = d3.mouse(this)[0];
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
			//var x = d3.event.x;
			//var y = d3.event.y;
			//console.log(d3.event);
			var x = d3.mouse(this)[0];
			var y = d3.mouse(this)[1];
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
			
			timelineTick.attr("x", x)
			.attr("y", function()
					{
						return userSessionAxisY[owningUser][owningSession]["y"];
					})
			.attr("height", barHeight / 4)
			.attr("width",  xAxisPadding / 50);
			timelineTick.raise();
			
			timelineText.attr("x", x + xAxisPadding / 50)
			.attr("y", function()
			{
				return userSessionAxisY[owningUser][owningSession]["y"];
			})
			.text(function()
					{
						userName = owningUser;
						sessionName = owningSession;
						//var scale = theNormData[userName][sessionName]["Time Scale"];
						maxSession = Number(theNormData[userName][sessionName]["Index MS Session Max"]);
						minSession = theNormData[userName][sessionName]["Index MS Session Min Universal"];
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
								.attr("src", "data:image/jpg;base64," + (await getScreenshot(userName, sessionName, (scale(x) * 60000) + minSession)["Screenshot"]()))
								//.attr("src", "./getScreenshot.jpg?username=" + userName + "&timestamp=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Index MS"] + "&session=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Original Session"] + "&event=" + eventName)
								.attr("style", "cursor:pointer;")
								.on("click", async function()
										{
											//showLightbox("<tr><td><div width=\"100%\"><img src=\"./getScreenshot.jpg?username=" + userName + "&timestamp=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Index MS"] + "&session=" + getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Original Session"] + "&event=" + eventName + "\" style=\"max-height: " + (windowHeight * .9) + "px; max-width:100%\"></div></td></tr>");
											showLightbox("<tr><td><div width=\"100%\"><img src=\""+ "data:image/jpg;base64," + (await getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Screenshot"]()) + "\" style=\"max-height: " + (windowHeight * .9) + "px; max-width:100%\"></div></td></tr>");
										});
						}
						updateScreenshot();
						//showLightbox("<tr><td><div width=\"100%\"><img src=\"./getScreenshot.jpg?username=" + userName + "&timestamp=" + getScreenshot(userName, sessionName, screenshotIndex)["Index MS"] + "&session=" + sessionName + "&event=" + eventName + "\" style=\"max-height: " + (windowHeight * .9) + "px; max-width:100%\"></div></td></tr>");
						return scale(x)
					});
			timelineText.raise();
		}
		
		var axisRow = d3.select("#infoTable").append("tr").append("td")
				.attr("width", visWidthParent)
				.style("max-width", visWidthParent + "px")
				.style("overflow-x", "auto");
		
		var addTaskAxisSVG = axisRow.append("svg")
				.attr("class", "clickableBar")
				.attr("width", visWidth + "px")
				.attr("height", (barHeight / 1.75) + "px")
				.call(dragAddTask);
		
		selectRect = addTaskAxisSVG.append("g")
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

		//var newRow = d3.select("#infoTable").append("tr").append("td")
		//	.attr("width", visWidthParent)
		//	.style("max-width", visWidthParent + "px")
		//	.style("overflow-x", "auto");
		var newSVG;
		var newSvgParent;
		if(!getCached)
		{
			
			newSVGParent = axisRow.append("svg")
			.attr("width", visWidth + "px")
			.attr("height", bottomVisHeight + "px")
			.attr("id", "processGraphSvg");
			var newSVG = newSVGParent.append("g");
		}
		else
		{
			newSVG = cachedNewSvg;
			newSVGParent = cachedNewSvgParent;
			//axisRow.append(newSVGParent);
			newSVGParent = axisRow.append("svg")
			.attr("width", visWidth + "px")
			.attr("height", bottomVisHeight + "px")
			.attr("id", "processGraphSvg");
			newnewSVG = newSVGParent.append("g");//.html(newSVG.html());
			newSVG = newnewSVG;
		}
		cachedNewSvg = newSVG;
		cachedNewSvgParent = newSVGParent;
		
		
		cpuSortedList = [];
		var maxCPU = 0;
		if(!getCached)
		{
		console.log("Generating new proc list");
		for(osUser in curProcessMap)
		{
			for(started in curProcessMap[osUser])
			{
				for(pid in curProcessMap[osUser][started])
				{
					var curProcList = curProcessMap[osUser][started][pid]
					var totalAverage = curProcList[curProcList.length-1]["Aggregate CPU"] / curProcList.length;
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
		}
		else
		{
			console.log("Using cached proc list");
			cpuSortedList = cachedSortedList;
			maxCPU = cachedMaxCPU;
		}
		cachedMaxCPU = maxCPU;
		cachedSortedList = cpuSortedList;

		var cpuScale = d3.scaleLinear();
		cpuScale.domain([0, maxCPU]);
		cpuScale.range([bottomVisHeight, 0]);

		
		var finalProcList = [];
		
		var lineFormattedData = []

		if(!getCached)
		{
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
		}
		else
		{
			finalProcList = cachedFinalProcList;
			lineFormattedData = cachedLineFormattedData;
		}
		cachedFinalProcList = finalProcList;
		cachedLineFormattedData = lineFormattedData;
		
		var procPoints;
		var procPointsWindow;
		var enterExit;
		var procLines;
		
		//if(!getCached)
		{
		procPoints = newSVG.selectAll("circle")
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
						if(document.getElementById("processAutoSelect").checked)
						{
							showWindow(owningUser, owningSession, "Processes", d["Hash"], d["Index MS"]);
						}
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
		
		enterExit = [];

		procLines = newSVG.selectAll("path")
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

		procPointsWindow = newSVG.append("g").selectAll("circle")
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
		.attr("id", "processTooltipRect")
		.attr("y", "0px")
		.attr("x", "0px")
		.attr("width", "0px")
		.attr("height", "0px")
		.attr("fill", "yellow")
		.attr("opacity", ".75");
		
		processTooltip = newSVG.append("g")
		.append("text")
		.attr("id", "processTooltip")
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
		
		procPointsCached = procPoints;
		procPointsWindowCached = procPointsWindow;
		enterExitCached = enterExit;
		procLinesCached = procLines;
		}
		/*
		else
		{
			procPoints = procPointsCached;
			procPointsWindow = procPointsWindowCached;
			enterExit = enterExitCached;
			procLines = procLinesCached;
			
			newSVG.insert
			
			
			console.log("Loaded from cache");
		}
		*/
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
		
		var revCpuSortedList;
		if(getCached)
		{
			revCpuSortedList = cpuSortedList;
		}
		else
		{
			revCpuSortedList = cpuSortedList.reverse();
		}
		var legendProcess = legendSVGProcess.append("g")
				.selectAll("rect")
				.data(revCpuSortedList)
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
		.data(revCpuSortedList)
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
		.data(revCpuSortedList)
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
		
		filterChanged = false;
	}
	

	
	var prevScreenshot;
	
	function getScreenshot(userName, sessionName, indexMS)
	{
		var screenshotIndexArray = theNormData[userName][sessionName]["screenshots"];
		var finalScreenshot = screenshotIndexArray[closestIndexMSBinary(screenshotIndexArray, indexMS)];
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
	
	function updateTask(userName, sessionName, taskName, startTime, tagger)
	{
		var taskUrl = "deleteTask.json?event=" + eventName + "&userName=" + userName + "&sessionName=" + sessionName + "&taskName=" + taskName + "&startTime=" + startTime + "&tagger=" + tagger;
		d3.json(taskUrl, function(error, data)
				{
					if(data["result"] == "okay")
					{
						addTask(userName, sessionName, true);
					}
				});
	}
	
	function deleteTask(userName, sessionName, taskName, startTime, tagger)
	{
		var taskUrl = "deleteTask.json?event=" + eventName + "&userName=" + userName + "&sessionName=" + sessionName + "&taskName=" + taskName + "&startTime=" + startTime + "&tagger=" + tagger;
		d3.json(taskUrl, function(error, data)
				{
					if(data["result"] == "okay")
					{
						if(data["result"] == "okay")
						{
							console.log("Added task, now refreshing")
							var curSelect = "&users=" + userName + "&sessions=" + sessionName;
							d3.json("logExport.json?event=" + eventName + "&datasources=events&normalize=none" + curSelect, async function(error, data)
							{
								let theNormDataInit = ((await retrieveData("indexdata")).value);
								
								theNormDataInit[userName][sessionName]["events"] = data[userName][sessionName]["events"];
								if(!theNormDataInit[userName][sessionName]["events"])
								{
									delete theNormDataInit[userName][sessionName]["events"];
								}
								
								try
								{
									var isDone = false;
									while(!isDone)
									{
										isDone = await persistDataAndWait("indexdata", theNormDataInit);
									}
								}
								catch(err)
								{
									console.log(err);
								}
								
								theNormData = preprocess(theNormDataInit);
								console.log("New norm data")
								console.log(theNormData)
								try
								{
									var isDone = false;
									while(!(isDone == true))
									{
										isDone = (await (persistDataAndWait("data", theNormData)));
									}
									start(true);
								}
								catch(err)
								{
									console.log(err);
								}
								
							});
						}
						
					}
				});
	}
	
	var objectCacheMap = {};
	
	var curSelectProcess;
	var curSelElements = [];
	
	async function showWindow(username, session, type, timestamp, lookupIndex, exactEntry)
	{
		console.log("Looking up " + username + " : " + session + " : " + timestamp + " : " + lookupIndex);
		//curMode = "window";
		curSelectUser = username;
		curSelectSession = session;
		curSelectType = type;
		curSelectTimestamp = timestamp;
		curLookupIndex = lookupIndex;
		
		if(username != curSelectUser || session != curSelectSession)
		{
			clearWindow();
		}
		var curSlot;
		
		if(exactEntry)
		{
			curSlot = exactEntry;
		}
		else
		{
		curSlot = lookupTable[username][session][type];
		
		if(curSlot["data"])
		{
			curSlot = ((await (curSlot["data"]())).value)[timestamp];
			//This does a linear search but only on the subset of the data that can be marked "Prev"
			//IE the previous entries for the same process.  If this needs to be optimized then the
			//the curSlot entry can be converted to an array of entries rather than the current
			//linked list style.  Doing so should not incur a memory penalty, though this can also
			//be further optimized for memory by storing "Prev" and "Next" in persistence as well.
			if(lookupIndex)
			{
				while(lookupIndex != curSlot["Index MS"] && curSlot["Prev"])
				{
					curSlot = curSlot["Prev"];
				}
			}
		}
		else
		{
			curSlot = curSlot[timestamp];
		}
		}
		console.log(curSlot);
		
		curSlot["Hash"] = SHA256(curSlot["User"] + curSlot["Original Session"] + curSlot["Index MS"]);
		
		var formattedSlot = [];
		var finalFormattedSlot = [];
		
		var highlights = [];
		
		var count = 0;
		for(key in curSlot)
		{
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
		
		formattedSlot = formattedSlot.sort(function(a, b)
		{
			if(a.key < b.key) { return -1; }
			if(a.key > b.key) { return 1; }
			return 0;
		})

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
		
		d3.select("#extraInfoTable")
				.selectAll("tr")
				.remove();

		if(type == "Events")
		{
			
			if(curSlot["Original Session"] != "User")
			{
				var delRow = d3.select("#extraInfoTable")
					.append("tr");
				delRow.append("td")
					.attr("colspan", "2")
					.attr("width", "50%")
					.html("<button type=\"button\" onclick=\"deleteTask('" + curSlot["Owning User"] + "', '" + curSlot["Original Session"] + "', '" + curSlot["TaskName"] + "', '" + curSlot["Index MS"] + "','" + curSlot["Source"] + "')\">Delete</button>");
				delRow.append("td")
					.attr("colspan", "2")
					.attr("width", "50%")
					.html("<button type=\"button\" onclick=\"updateTask('" + curSlot["Owning User"] + "', '" + curSlot["Original Session"] + "', '" + curSlot["TaskName"] + "', '" + curSlot["Index MS"] + "','" + curSlot["Source"] + "')\">Update</button>");
			
				var updateRow = d3.select("#extraInfoTable")
					.append("tr");
				updateRow.append("td")
					.attr("colspan", "4")
					.html("<div align='center'>New Values</div>");
				
				updateRow = d3.select("#extraInfoTable")
					.append("tr");
				updateRow.append("td")
					.attr("colspan", "2")
					.attr("width", "50%")
					.html("<div align='center'>Task Name</div><div align='center'><input type=\"text\" id=\"updateTaskName\" name=\"updateTaskName\" value=\"" + curSlot["TaskName"] + "\"></div>");
				
				var curTags = "";
				if(curSlot["Tags"])
				{
					curTags = curSlot["Tags"].join('\n');
				}	
				updateRow.append("td")
					.attr("colspan", "2")
					.attr("width", "50%")
					.html("<div align='center'>Tags</div><div align='center'><textarea id=\"updateTags\" name=\"updateTags\" rows=\"5\" cols=\"50\">" + curTags + "</textarea></div>");
				
				updateRow = d3.select("#extraInfoTable")
					.append("tr");
				updateRow.append("td")
					.attr("colspan", "4")
					.html("<div align='center'>Goal</div><div align='center'><textarea id=\"updateTaskGoal\" name=\"updateTaskGoal\" rows=\"2\" cols=\"100\">" + curSlot["Goal"] + "</textarea></div>");
				
				updateRow = d3.select("#extraInfoTable")
					.append("tr");
				updateRow.append("td")
					.attr("colspan", "2")
					.html("<div align='center'>Start Time (MS)</div><div align='center'><input type=\"text\" id=\"updateTaskStart\" name=\"updateTaskStart\" value=\"" + curSlot["Index MS Session"] + "\"></div>");
				updateRow.append("td")
					.attr("colspan", "2")
					.html("<div align='center'>End Time (MS)</div><div align='center'><input type=\"text\" id=\"updateTaskEnd\" name=\"updateTaskEnd\" value=\"" + curSlot["Next"]["Index MS Session"] + "\"></div>");
				
			}
			
			objectCacheMap[curSlot["Hash"]] = curSlot;
			
			d3.select("#extraInfoTable")
				.append("tr")
				.html("<td colspan=\"2\"><button type=\"button\" onclick=\"buildTaskMapTop('" + curSlot["Owning User"] + "', '" + curSlot["Original Session"] + "', '" + curSlot["Hash"] + "', true)\">Build Attack Graph Session Limited</button></td>"
						+ "<td colspan=\"2\"><button type=\"button\" onclick=\"buildTaskMapTop('" + curSlot["Owning User"] + "', '" + curSlot["Original Session"] + "', '" + curSlot["Hash"] + "', false)\">Build Attack Graph User Limited</button></td>");
		}
		
		var infoTitleRow = d3.select("#extraInfoTable")
			.append("tr");
		infoTitleRow.append("td")
			.attr("colspan", "4")
			.html("<div align='center'><b>Selected Data Attributes</b></div>");
		
		d3.select("#extraInfoTable").append("tr").append("td").attr("colspan", "4").append("table").attr("width", "100%")
				.selectAll("tr")
				.data(finalFormattedSlot)
				.enter()
				.append("tr")
				.html(function(d, i)
						{
							return "<td width=\"12.5%\" style=\" max-width:" + (.125 * visWidthParent) + "px\">" + d["key1"] + "</td>" + "<td width=\"37.5%\" style=\" max-width:" + (.375 * visWidthParent) + "px; overflow-x:auto;\">" + d["value1"] + "</td>" + "<td width=\"12.5%\" style=\" max-width:" + (.125 * visWidthParent) + "px\">" + d["key2"] + "</td>" + "<td width=\"37.5%\" style=\" max-width:" + (.375 * visWidthParent) + "px; overflow-x:auto;\">" + d["value2"] + "</td>";
						});

		d3.select("#screenshotDiv")
				.selectAll("*")
				.remove();

		d3.select("#screenshotDiv")
				.append("img")
				.attr("width", "100%")
				.attr("src", "data:image/jpg;base64," + (await (getScreenshot(curSlot["Owning User"], curSlot["Original Session"], curSlot["Index MS"])["Screenshot"]())))
				.attr("style", "cursor:pointer;")
				.on("click", async function()
						{
							showLightbox("<tr><td><div width=\"100%\"><img src=\"data:image/jpg;base64," + (await (getScreenshot(curSlot["Owning User"], curSlot["Original Session"], curSlot["Index MS"])["Screenshot"]())) + "\" style=\"max-height: " + (windowHeight * .9) + "px; max-width:100%\"></div></td></tr>");
							
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
	

	
	function back()
	{
		var baseURL = "vissplash.jsp?event=" + eventName + "&eventAdmin=" + eventAdmin;
		window.location.replace(baseURL);
	}

</script>
<script src="./timeline.js" onload="main()"></script>
<script src="./search.js"></script>
<script src="./playAnimation.js"></script>
<script src="./petriNetGenerator.js"></script>
</html>
