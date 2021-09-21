	var refreshingStart = false;
	
	var curMode = "default";
	var curSelectUser;
	var curSelectSession;
	var curSelectType;
	var curSelectTimestamp;
	var curLookupIndex;
	
	async function start(needsUpdate)
	{
		if(refreshingStart)
		{
			console.log("Already restarting");
			return;
		}
		refreshingStart = true;
		d3.select(visRow).style("max-width", (visWidthParent + visPadding) + "px");
		d3.select(visTable).style("max-width", (visWidthParent + visPadding) + "px");
		
		var timelineZoom = Number(document.getElementById("timelineZoom").value);
		var timelineZoomVert = Number(document.getElementById("timelineZoomVert").value);
		visWidth = (visWidthParent) * timelineZoom;
		var visHeightNew = windowHeight * .5 * timelineZoomVert;
		barHeight = visHeightNew / 10;
		legendHeight = visHeightNew / 25;

		if(needsUpdate)
		{
			d3.select("#mainVisualization").selectAll("*").remove();
			//d3.select("#mainVisualization").html("");
			d3.select("#legend").selectAll("*").remove();
			
			//d3.select("#legend").html("");
			clearWindow();
			
			let theNormDataInit = ((await retrieveData("data")).value);
			
			for(user in theNormDataInit)
			{
				for(session in theNormDataInit[user])
				{
					if(!theNormDataInit[user][session]["processes"])
					{
						var processDataObject = {};
						processDataObject["user"] = user;
						processDataObject["session"] = session;
						processDataObject["data"] = getProcessData;
						processDataObject["getfiltered"] = getProcessDataFiltered;
						processDataObject["storefiltered"] = storeProcessDataFiltered;
						theNormDataInit[user][session]["processes"] = processDataObject;
					}
					if(!theNormDataInit[user][session]["mouse"])
					{
						var mouseDataObject = {};
						mouseDataObject["user"] = user;
						mouseDataObject["session"] = session;
						mouseDataObject["data"] = getMouseData;
						mouseDataObject["getfiltered"] = getMouseDataFiltered;
						mouseDataObject["storefiltered"] = storeMouseDataFiltered;
						theNormDataInit[user][session]["mouse"] = mouseDataObject;
					}
					if(!theNormDataInit[user][session]["keystrokes"])
					{
						var keystrokesDataObject = {};
						keystrokesDataObject["user"] = user;
						keystrokesDataObject["session"] = session;
						keystrokesDataObject["data"] = getKeystrokesData;
						keystrokesDataObject["getfiltered"] = getKeystrokesDataFiltered;
						keystrokesDataObject["storefiltered"] = storeKeystrokesDataFiltered;
						theNormDataInit[user][session]["keystrokes"] = keystrokesDataObject;
					}
				}
			}
			var filteredData = await filter(theNormDataInit, filters);
			console.log("Filtered:");
			console.log(filteredData);
			
			theNormData = filteredData//((await filter(theNormDataInit, filters)).value);
			//showDefault();
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
					minTimeSessionUniversal = Number.POSITIVE_INFINITY;
					minTimeUserSession = Number.POSITIVE_INFINITY;
					maxTimeSessionDate = "";
					minTimeSessionDate = "";
					theCurData = theNormData[user][session];
					for(dataType in theCurData)
					{
						thisData = theCurData[dataType];
						
						if(!(user in lookupTable))
						{
							lookupTable[user] = {};
						}
						if(!(session in lookupTable[user]))
						{
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
								lookupTable[user][session]["Processes"]["user"] = user;
								lookupTable[user][session]["Processes"]["session"] = session;
								lookupTable[user][session]["Processes"]["data"] = getProcessLookupData;
								lookupTable[user][session]["Processes"]["storedata"] = storeProcessDataLookup;
								await lookupTable[user][session]["Processes"]["storedata"](curLookupTable);
							}
							curLookupTable = (await (lookupTable[user][session]["Processes"]["data"]())).value;
							
							if(!(user in processMap))
							{
								processMap[user] = {};
							}
							if(!(session in processMap[user]))
							{
								//processMap[user][session] = {};
								var processMapDataObject = {};
								processMapDataObject["user"] = user;
								processMapDataObject["session"] = session;
								processMapDataObject["data"] = getProcessMapData;
								processMapDataObject["storedata"] = storeProcessDataMap;
								await processMapDataObject["storedata"]({});
								processMap[user][session] = processMapDataObject;
							}
							curUserSessionMap = (await (processMap[user][session]["data"]())).value;
						}
						
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
								minTimeSessionUniversal = firstTimeUserAbsolute;
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
					theCurData["Index MS Session Min Universal"] = minTimeSessionUniversal;
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
				//.attr("height", getInnerHeight("legendCell"))
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
		
		var legendFilter = legendSVG.append("g")
		.selectAll("rect")
		.data(windowLegend)
		.enter()
		.append("rect")
		.attr("x", "90%")
		.attr("width", "10%")
		//.attr("width", legendWidth)
		.attr("y", function(d, i)
				{
					return legendHeight * (i + 1);
				})
		.attr("height", legendHeight)
		.attr("stroke", "black")
		.style("cursor", "pointer")
		.attr("fill", function(d, i)
				{
					return "Crimson";
				})
		.on("click", function(d, i)
		{
			addFilterDirect(3, "FirstClass", "!= '" + d + "'");
		});
		
		var legendFilterText = legendSVG.append("g")
		.selectAll("text")
		.data(windowLegend)
		.enter()
		.append("text")
		//.attr("font-size", 11)
		.attr("x", "95%")
		.attr("y", function(d, i)
				{
					//return legendHeight * (i + 1);
					//return legendHeight * (i) + legendHeight;
					return legendHeight * (i + 1) + legendHeight * .5;
				})
		.attr("height", legendHeight * .75)
		.text(function(d, i)
				{
					return "X";
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
		.attr("text-anchor", "middle")
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
		
		var downloadButtonsUser = svg.append("g")
		.selectAll("rect")
		.data(userOrderArray)
		.enter()
		.append("rect")
		.attr("x", visWidth - (xAxisPadding / 1.75 - xAxisPadding / 20) - (barHeight - (xAxisPadding / 25)) * 2)
		.attr("width", xAxisPadding / 1.5 - xAxisPadding / 20)
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
		.attr("fill", "Pink")
		.attr("initFill", "Pink")
		.attr("stroke", "black")
		.attr("initStroke", "black")
		.attr("stroke-width", "0")
		.attr("initStrokeWidth", "0")
		.attr("z", 2)
		.classed("clickableBar", true)
		.attr("id", function(d, i)
				{
					if(autoDownload)
					{
						downloadUser(userOrderMap[d]);
					}
					
					return("downloadbuttonuser_" + SHA256(userOrderMap[d]));
				})
		.on("click", function(d, i)
				{
					downloadUser(userOrderMap[d]);
				});

		var downloadLabelsUser = svg.append("g")
		.selectAll("text")
		.data(userOrderArray)
		.enter()
		.append("text")
		.attr("x", visWidth - (xAxisPadding / 2 - xAxisPadding / 20) + xAxisPadding / 4 - xAxisPadding / 40 - (barHeight - (xAxisPadding / 25)) * 2)
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
		.text("Download")
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
		
		.attr("z", 2);
		
		var foregroundTextG = svg.append("g");

		
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
		timelineTick = svg.append("rect").style("pointer-events", "none");
		timelineText = svg.append("text")
			.style("fill", "Crimson")
			.style("pointer-events", "none")
			.style("font-size", barHeight / 4)
			.style("dominant-baseline", "hanging");
		
		var axisBars = svg.append("g")
		.selectAll("rect")
		.data(sessionList)
		.enter()
		.append("rect")
		.style("cursor", "pointer")
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
		.on("click", async function(d, i)
				{
					var curX = d3.mouse(this)[0];
					var curY = d3.mouse(this)[1];
					scale = d3.scaleLinear();
					scale.range([0, maxSession / 60000]);
					scale.domain([xAxisPadding, visWidth]);
					var seekTo = scale(curX) * 60000
					playAnimation(d["User"], d["Session"], seekTo);
				})
		.on("mousemove", async function(d, i)
				{
					var curX = d3.mouse(this)[0];
					var curY = d3.mouse(this)[1];
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
												.attr("src", "data:image/jpg;base64," + (await getScreenshot(userName, sessionName, (scale(curX) * 60000) + minSession)["Screenshot"]()))
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
										return scale(curX)
									});
					timelineText.raise();
				});
		
		var axisUnits = svg.append("g");
		var minuteLog = axisUnits.selectAll("text")
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
		
		var legendFilter = legendSVG.append("g")
			.selectAll("rect")
			.data(eventTypeArray)
			.enter()
			.append("rect")
			.attr("x", "90%")
			.attr("width", "10%")
			//.attr("width", legendWidth)
			.attr("y", function(d, i)
					{
						return legendHeight * (i + 1) + eventLegendBaseline;
					})
			.on("click", function(d, i)
					{
						addFilterDirect(3, "Source", "!= '" + d["Source"] + "'");
					})
			.attr("height", legendHeight)
			.style("cursor", "pointer")
			.attr("stroke", "Black")
			.attr("fill", function(d, i)
					{
						return "Crimson";
					});
		
		var legendFilterText = legendSVG.append("g")
		.selectAll("text")
		.data(eventTypeArray)
		.enter()
		.append("text")
		.style("pointer-events", "none")
		.attr("x", "95%")
		.attr("y", function(d, i)
				{
					//return legendHeight * (i + 1);
					//return legendHeight * (i) + legendHeight;
					return legendHeight * (i + 1) + legendHeight * .5 + eventLegendBaseline;
				})
		.attr("height", legendHeight * .75)
		.text(function(d, i)
				{
					return "X";
				})
		.attr("fill", function(d, i)
				{
					return "#000";
				})
		.attr("font-weight", "bolder")
		.attr("dominant-baseline", "middle")
		.attr("text-anchor", "middle")
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
		
		var visTableHeight = d3.select("#mainVisContainer").node().getBoundingClientRect().height;
		
		d3.select("#optionFilterTable").attr("height", getInnerHeight("optionFilterCell") + "px");
		
		d3.select("#legend").select("svg").style("height", (legendHeight * (2 + windowLegend.length + eventTypeArray.length)) + "px");
		//d3.select("#legend").style("height", getInnerHeight("legendCell") + "px");
		refreshingStart = false;
		if(curMode == "default")
		{
			showDefault();
		}
		else if(curMode == "window")
		{
			showWindow(curSelectUser, curSelectSession, curSelectType, curSelectTimestamp, curLookupIndex);
		}
		else if(curMode == "session")
		{
			showSession(curSelectUser, curSelectSession);
		}
	}