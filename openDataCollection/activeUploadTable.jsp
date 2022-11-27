<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" import="java.util.ArrayList, java.util.HashMap, com.datacollector.*, java.sql.*, java.util.concurrent.ConcurrentHashMap, java.util.Map.Entry, java.util.Map"%>
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
						<div align="center" id="title">Latest Upload Segment Info for <%=eventName %></div>
					</td>
				</tr>
				<tr>
					<td id="visRow">
						<div align="center" id="mainVisualization">
						<table id="searchTable">
							<tr>
								<td colspan="3">
									<div align="center">User and Session Search Table</div>
								</td>
							</tr>
							<tr>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> <b>User Name</b>
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> <b>Upload Token</b>
								</td>
								<td class="searchCol">
									<a class="expandPlus" onclick="toggleCol(this)">➕</a> <b>Data</b>
								</td>
							</tr>
							<tr>
								<td colspan="3">
									<div align="center"><input type="button" value="Refresh Search" onclick="refreshSearch()"><input type="button" value="Visualize Selected" onclick="visualize()"></div>
								</td>
							</tr>
							<tr>
								<td>
									<input class="searchField" type="text" id="usernameField">
								</td>
								<td>
									<input class="searchField" type="text" id="emailField">
								</td>
								<td>
									<input class="searchField" type="text" id="nameField">
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
			
			
			d3.json("getUploadInfo.json?event=" + eventName, async function(error, data)
				{
					try
					{
						var isDone = false;
						while(!isDone)
						{
							isDone = await persistDataAndWait("upload", data);
						}
					}
					catch(err)
					{
						console.log(err);
					}
					theNormData = data;
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
						.html(origTitle + "<br />Upload data: <b>" + downloadedSize + "</b> bytes downloaded.")
					
					
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
		for(entry in theNormData)
		{
			console.log(entry);
			var user = entry;
			for(token in theNormData[entry])
			{
				var token = token;
				var data = theNormData[entry][token];
				
				var newRow = tbodyRef.insertRow();
				newRow.style.wordBreak = "break-all";
				newRow.id = SHA256(user);
				var newCell = newRow.insertCell();
				newCell.innerHTML = user;
				newCell = newRow.insertCell();
				newCell.innerHTML = token;
				newCell = newRow.insertCell();
				var dataTable = document.createElement('table');
				
				var curRow = dataTable.insertRow();
				var curCell = curRow.insertCell();
				curCell.innerHTML = "<b>Metric</b>";
				curCell = curRow.insertCell();
				curCell.innerHTML = "<b>Value</b>";
				
				for(dataPoint in data)
				{
					console.log(dataPoint);
					console.log(data[dataPoint]);
					if(dataPoint == "Attempted" || dataPoint == "Completed")
					{
						
					}
					else
					{
						curRow = dataTable.insertRow();
						curCell = curRow.insertCell();
						curCell.innerHTML = "<i>" + dataPoint + "</i>";
						curCell = curRow.insertCell();
						curCell.innerHTML = data[dataPoint];
					}
				}
				
				var curRow = dataTable.insertRow();
				var curCell = curRow.insertCell();
				curCell.colSpan = 3;
				curCell.innerHTML = "Upload Counts:";
				
				curRow = dataTable.insertRow();
				curCell = curRow.insertCell();
				curCell.width = "33.33%";
				curCell.innerHTML = "<b>Data Type</b>";
				curCell = curRow.insertCell();
				curCell.width = "33.33%";
				curCell.innerHTML = "<b>Attempted</b>";
				curCell = curRow.insertCell();
				curCell.width = "33.33%";
				curCell.innerHTML = "<b>Completed</b>";
				
				for(dataPoint in data["Attempted"])
				{
					curRow = dataTable.insertRow();
					curCell = curRow.insertCell();
					curCell.innerHTML = "<i>" + dataPoint + "</i>";
					curCell = curRow.insertCell();
					curCell.innerHTML = data["Attempted"][dataPoint];
					curCell = curRow.insertCell();
					curCell.innerHTML = data["Completed"][dataPoint];
				}
				
				newCell.appendChild(dataTable);
				//newCell.innerHTML = data;
			
			}
		}
	}
	
	
	
	function sleep(seconds)
	{
		var e = new Date().getTime + (seconds * 1000);
		while(new Date().getTime() < e) {}
	}
	
	
	
	function refreshSearch()
	{
		var usernameSearch = document.getElementById("usernameField").value;
		var emailSearch = document.getElementById("emailField").value;
		var nameSearch = document.getElementById("nameField").value;
		
		for(entry in theNormData)
		{
			var user = theNormData[entry]["username"];
			var email = theNormData[entry]["email"];
			var name = theNormData[entry]["name"];
			var curHash = SHA256(user)
			var curRow = document.getElementById(curHash)
			if(curRow)
			{
				curRow.style.display = "";
				if(!(user.includes(usernameSearch)))
				{
					curRow.style.display = "none";
				}
				if(!(email.includes(emailSearch)))
				{
					curRow.style.display = "none";
				}
				if(!(name.includes(nameSearch)))
				{
					curRow.style.display = "none";
				}
			}
		}
	}
	
	downloadData();

</script>
</html>
