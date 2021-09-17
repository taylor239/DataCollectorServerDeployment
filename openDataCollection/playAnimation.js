//This is the code that runs the animation part of the visualization.

var animationTimeout;

//This variable determines how quickly mouse clicks fade.
var degradeCoefficient = 60000;

var oldUser;
var oldSession;
var oldSeek;

async function playAnimation(owningUser, owningSession, seekTo)
{
	//If it is the same user and we do not have a specific seek time,
	//restart play at the last known timestamp.
	if(oldUser == owningUser && oldSession == owningSession)
	{
		if(seekTo)
		{
			
		}
		else
		{
			seekTo = oldSeek;
		}
	}
	else
	{
		oldUser = owningUser
		oldSession = owningSession
	}
	
	showLightbox("<tr><td id=\"animationRow\"><div id=\"animationDiv\" width=\"100%\" height=\"100%\"></div></td></tr>");
	
	var playing = true;
	
	var playbackSpeedMultiplier = Number(document.getElementById("playbackSpeed").value);
	
	var aniRow = d3.select("#animationRow");
	var aniDiv = d3.select("#animationDiv");
	
	var divBounds = aniRow.node().getBoundingClientRect();
	
	var screenshots = theNormData[owningUser][owningSession]["screenshots"];
	var keystrokes = (await theNormData[owningUser][owningSession]["keystrokes"]["getfiltered"]()).value;
	var mouse = (await theNormData[owningUser][owningSession]["mouse"]["getfiltered"]()).value;
	var windows = theNormData[owningUser][owningSession]["windows"];
	var processes = (await theNormData[owningUser][owningSession]["processes"]["getfiltered"]()).value;
	var events = theNormData[owningUser][owningSession]["events"];
	
	var garbageToRemove = [];
	
	var animationSvg = aniDiv.append("svg")
		.attr("width", divBounds["width"])
		.attr("height", divBounds["height"]);
	
	var backgroundG = animationSvg.append("g");
	
	var animationAxisG = animationSvg.append("g");
	var animationAxisGMin = animationSvg.append("g");

	
	//The typed text and mouse click elements, including scroll bar for the text.
	
	//Scroll functions:
	var aniTextScroll = d3.drag()
	.on("drag", aniTextDrag)
	.on("start", function(d)
			{
				
			});
	
	function aniTextDrag(d)
	{
		var curHeight = Number(d3.select("#animationTextScrollbar").attr("height"));
		
		var x = d3.mouse(this)[0];
		var y = d3.mouse(this)[1] - (curHeight / 2);
		
		var minY = Number(d3.select("#animationTextScrollbar").attr("minY"));
		
		var scrollPercent;
		if(y < minY)
		{
			y = minY;
			scrollPercent = 0;
		}
		
		var maxY = Number(d3.select("#animationTextScrollbar").attr("maxY"));
		
		
		if(Number(y) + Number(curHeight) > maxY)
		{
			y = maxY - curHeight;
		}
		
		
		d3.select("#animationTextScrollbar")
			.attr("y", y);
		
		if(!scrollPercent)
		{
			scrollPercent = (y - minY) / (maxY - curHeight - minY);
		}
		
		
		if(!scrollPercent)
		{
			scrollPercent = 0;
		}
		
		var maxTextHeight = Number(keyboardInputs[keyboardInputs.length - 1].attr("initY")) - divBounds["height"];
		var minTextHeight = Number(keyboardInputs[0].attr("initY")) - divBounds["height"];
		var minText = Number(keyboardInputs[0].attr("initY"));
		var heightDiff = maxTextHeight - minTextHeight;
		var toSubtract = scrollPercent * heightDiff;
		for(entry in keyboardInputs)
		{
			var entryY = keyboardInputs[entry].attr("initY");
			var calcY = entryY - toSubtract;
			keyboardInputs[entry].attr("y", calcY);
			
			if(calcY < minText)
			{
				keyboardInputs[entry].style("opacity", 0);
			}
			else
			{
				keyboardInputs[entry].style("opacity", 1);
			}
		}
		
	}
	
	var animationG = animationSvg.append("g");
	var animationGKeyHolder = animationSvg.append("g").attr("id", "animationGKeyHolder");
	var animationGKey = animationGKeyHolder.append("g").attr("id", "animationGKey");
	var textScrollBar = animationGKeyHolder.append("rect")
		.attr("x", (divBounds["width"]) / 2 - (divBounds["width"]) / 144)
		.attr("y", 0)
		.attr("width", (divBounds["width"]) / 144)
		.attr("height", 0)
		.attr("id", "animationTextScrollbar")
		.call(aniTextScroll);
	
	
		
	
	var curScreenshot = backgroundG.append("image")
		.attr("width", divBounds["width"])
		.attr("height", divBounds["height"])
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
	
	var timeScaleAnimationMin = d3.scaleLinear();
	timeScaleAnimationMin.domain
				(
					[0, maxSessionAnimation / 60000]
				)
	timeScaleAnimationMin.range
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
	var animationAxisMin = d3.axisTop().scale(timeScaleAnimationMin);
	animationAxisG.call(animationAxis);
	animationAxisG.attr("transform", "translate(" + 0 + "," + (divBounds["height"] * .8) + ")")
	var textPadding = animationAxisG.node().getBBox()["height"];
	animationAxisGMin.call(animationAxisMin);
	animationAxisGMin.attr("transform", "translate(" + 0 + "," + ((divBounds["height"] * .8)) + ")")
	animationAxisGMin.style("pointer-events", "none");
	animationAxisGMin.selectAll("*")
			.style("stroke", "white");
	
	var curTimer = 0;
	var screenshotIndex = 0;
	var keystrokesIndex = 0;
	var mouseIndex = 0;
	var windowsIndex = 0;
	var eventsIndex = 0;
	var processIndex = 0;
	var numTopProcesses = 5;
	var topProcesses = [];
	var curTop = {};
	
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
	
	var initX = 0;
	
	var dragAddTask = d3.drag()
		.on("drag", dragmoveAddTask)
		.on("start", function(d)
				{
					initX = d3.event.x;
					selectRect.attr("x", initX);
					selectRect.attr("width", 0);
					selectRectAni.attr("x", initX);
					selectRectAni.attr("width", 0);
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
			selectRectAni.attr("x", x);
			selectRectAni.attr("width", initX - x);
			startPoint = timeScaleAnimation.invert(x);
			endPoint = timeScaleAnimation.invert(initX);
		}
		else
		{
			selectRectAni.attr("x", initX);
			selectRectAni.attr("width", x - initX);
			startPoint = timeScaleAnimation.invert(initX);
			endPoint = timeScaleAnimation.invert(x);
		}
		selectRect.attr("x", timeScaleAni(startPoint) + xAxisPadding);
		selectRect.attr("width", timeScaleAni(endPoint - startPoint));
		document.getElementById("addTaskStart").value = startPoint;
		document.getElementById("addTaskEnd").value = endPoint;
	}
	
	var dragBarG = animationSvg.append("g")
			.call(dragAddTask);
	
	var scaleLabelG = animationSvg.append("g");
	var scaleLabel = scaleLabelG.append("text")
			.attr("x", divBounds["width"])
			.attr("y", (divBounds["height"] * .8))
			.attr("text-anchor", "end")
			.style("pointer-events", "none")
			.text("Minutes");
	
	var dragLabelG = animationSvg.append("g");
	var dragLabel = dragLabelG.append("text")
			.attr("x", 0)
			.attr("y", (divBounds["height"] * .8))
			.style("pointer-events", "none")
			.text("Add Task");
	
	var dragBar = dragBarG.append("rect")
			.attr("x", 0)
			.attr("y", (divBounds["height"] * .8) - textPadding)
			.attr("height", textPadding)
			.attr("width", animationSvg.attr("width"))
			.attr("style", "cursor:pointer;")
			.style("stroke", "Cyan")
			.style("fill-opacity", ".25")
			.style("fill", "Cyan");
	
	var selectRectAni = dragBarG
			.append("rect")
			.attr("x", 0)
			.attr("y", (divBounds["height"] * .8) - textPadding)
			.attr("width", 0)
			.attr("height", textPadding)
			.attr("fill", "Pink")
			.attr("pointer-events", "none");
	
	var axisLabelG = animationSvg.append("g");
	var axisLabel = axisLabelG.append("text")
			.attr("x", 0)
			.attr("y", (divBounds["height"] * .8) + textPadding)
			.style("pointer-events", "none")
			.text("Seek");
	
	var timeLog = axisLabelG.append("text")
			.attr("x", divBounds["width"])
			.attr("y", (divBounds["height"] * .8) + textPadding)
			.attr("text-anchor", "end")
			.style("pointer-events", "none")
			.text("Time");
	
	var axisTickG = animationSvg.append("g");
	var axisTick = axisTickG.append("rect")
			.style("pointer-events", "none")
			.attr("width", divBounds["width"]/400)
			.attr("height", textPadding)
			.attr("stroke", "crimson")
			.attr("x", 0)
			.attr("y", (divBounds["height"] * .8));
	
	var maxProcCPU = 0;
	var processGraphAniG = animationSvg.append("g");
	var processGraphAni = processGraphAniG.append("rect")
			.attr("width", (2 * divBounds["width"]) / 9)
			.attr("height", (divBounds["height"] * .2) - textPadding)
			.attr("fill", "Yellow")
			.style("fill-opacity", ".25")
			.attr("stroke", "Black")
			.attr("x", (4.5 * divBounds["width"]) / 9)
			.attr("y", (divBounds["height"] * .8) + textPadding);
	var processGraphAniBarG = processGraphAniG.append("g");
	var processGraphAniLabel = processGraphAniG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "end")
			.attr("dominant-baseline", "hanging")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("Top Process %CPU")
			.attr("x", (6.5 * divBounds["width"]) / 9)
			.attr("y", (divBounds["height"] * .8) + textPadding);
	var processGraphAniMaxLabel = processGraphAniG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "end")
			.attr("dominant-baseline", "Auto")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("100")
			.attr("x", (6.5 * divBounds["width"]) / 9)
			.attr("y", (divBounds["height"]));
	var processGraphAniMinLabel = processGraphAniG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "start")
			.attr("dominant-baseline", "Auto")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("0")
			.attr("x", (4.5 * divBounds["width"]) / 9)
			.attr("y", (divBounds["height"]));
	
	var playPauseG = animationSvg.append("g");
	var playPause = playPauseG.append("rect")
			.attr("width", divBounds["width"] / 9)
			.attr("height", (divBounds["height"] * .05))
			.attr("fill", "Chartreuse")
			.attr("stroke", "Black")
			.attr("x", (6.5 * divBounds["width"]) / 9)
			.attr("y", (divBounds["height"] * .8) + textPadding)
			.style("cursor", "pointer");
	var playPauseLabel = playPauseG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "middle")
			.attr("dominant-baseline", "middle")
			.attr("font-weight", "bolder")
			.attr("textLength", divBounds["width"] / 9)
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .0375))
			.text("⏸")
			.style("cursor", "pointer")
			.attr("x", (7 * divBounds["width"]) / 9)
			.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .03125));
	var activeWindowTitle = playPauseG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "end")
			.attr("dominant-baseline", "middle")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("Active Window and Tasks")
			.attr("x", divBounds["width"])
			.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .03125));
	var activeWindow = playPauseG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "end")
			.attr("dominant-baseline", "middle")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("...")
			.attr("x", divBounds["width"])
			.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .075));
	var activeWindowName = playPauseG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "end")
			.attr("dominant-baseline", "middle")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("...")
			.attr("x", divBounds["width"])
			.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .1));
	
	
	var activeEvents = [];
	var activeEventName = playPauseG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "end")
			.attr("dominant-baseline", "middle")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("...")
			.attr("x", divBounds["width"])
			.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .125));
	var activeEventName2 = playPauseG.append("text")
			.style("pointer-events", "none")
			.attr("text-anchor", "end")
			.attr("dominant-baseline", "middle")
			.attr("fill", "Black")
			.attr("stroke", "Black")
			.attr("font-size", (divBounds["height"] * .025))
			.text("")
			.attr("x", divBounds["width"])
			.attr("y", (divBounds["height"] * .8) + textPadding + (divBounds["height"] * .15));

	
	
	animationAxisGMin.raise();
	
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
		var eventsTime = Infinity;
		if(events && eventsIndex < events.length)
		{
			eventsTime = Number(events[eventsIndex]["Index MS Session"]);
		}
		var processTime = Infinity;
		if(processes && processIndex < processes.length)
		{
			processTime = Number(processes[processIndex]["Index MS Session"]);
		}
		
		if(screenshotTime < keystrokesTime)
		{
			if(screenshotTime < mouseTime)
			{
				if(screenshotTime < windowsTime)
				{
					if(processTime < screenshotTime)
					{
						if(eventsTime < processTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							processIndex++;
							return processes[processIndex - 1];
						}
					}
					else
					{
						if(eventsTime < screenshotTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							screenshotIndex++;
							return screenshots[screenshotIndex - 1];
						}
					}
				}
				else
				{
					if(processTime < windowsTime)
					{
						if(eventsTime < processTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							processIndex++;
							return processes[processIndex - 1];
						}
					}
					else
					{
						if(eventsTime < windowsTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							windowsIndex++;
							return windows[windowsIndex - 1];
						}
					}
				}
			}
			else
			{
				if(mouseTime < windowsTime)
				{
					if(processTime < mouseTime)
					{
						if(eventsTime < processTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							processIndex++;
							return processes[processIndex - 1];
						}
					}
					else
					{
						if(eventsTime < mouseTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							mouseIndex++;
							return mouse[mouseIndex - 1];
						}
					}
				}
				else
				{
					if(processTime < windowsTime)
					{
						if(eventsTime < processTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							processIndex++;
							return processes[processIndex - 1];
						}
					}
					else
					{
						if(eventsTime < windowsTime)
						{
							eventsIndex++;
							return events[eventsIndex - 1];
						}
						else
						{
							windowsIndex++;
							return windows[windowsIndex - 1];
						}
					}
				}
			}
		}
		else if(mouseTime < keystrokesTime)
		{
			if(mouseTime < windowsTime)
			{
				if(processTime < mouseTime)
				{
					if(eventsTime < processTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						processIndex++;
						return processes[processIndex - 1];
					}
				}
				else
				{
					if(eventsTime < mouseTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						mouseIndex++;
						return mouse[mouseIndex - 1];
					}
				}
			}
			else
			{
				if(processTime < windowsTime)
				{
					if(eventsTime < processTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						processIndex++;
						return processes[processIndex - 1];
					}
				}
				else
				{
					if(eventsTime < windowsTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						windowsIndex++;
						return windows[windowsIndex - 1];
					}
				}
			}
		}
		else
		{
			if(keystrokesTime < windowsTime)
			{
				if(processTime < keystrokesTime)
				{
					if(eventsTime < processTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						processIndex++;
						return processes[processIndex - 1];
					}
				}
				else
				{
					if(eventsTime < keystrokesTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						keystrokesIndex++;
						return keystrokes[keystrokesIndex - 1];
					}
				}
			}
			else
			{
				if(processTime < windowsTime)
				{
					if(eventsTime < processTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						processIndex++;
						return processes[processIndex - 1];
					}
				}
				else
				{
					if(eventsTime < windowsTime)
					{
						eventsIndex++;
						return events[eventsIndex - 1];
					}
					else
					{
						windowsIndex++;
						return windows[windowsIndex - 1];
					}
				}
			}
		}
	}
	
	var lastFrame;
	var lastImg = new Image();

	var lastMouseClicks = [];
	
	var keyboardInputs = [];
	
	var curKeyInput = animationGKey.append("text").attr("x", 0)
						.attr("y", 0)
						.attr("initY", 0)
						.text("")
						.attr("text", "")
						.attr("font-size", 0);
	
	keyboardInputs.unshift(curKeyInput);
	
	var typedText;
		
	var textHeight = 0;
	
	var startY = 0;
	
	var prevLastScreenshot;
	
	async function loadImage(theFrame)
	{
		return new Promise(async function (resolve, reject)
		{
			lastImg.onload = async function()
			{
				resolve(lastImg);
			}
			lastImg.src = "data:image/jpg;base64," + (await (theFrame["Screenshot"]()));
		})
	}
	
	async function runAnimation()
	{
		var curFrame = screenshots[screenshotIndex];
		
		lastImg = await loadImage(curFrame);
		
		curScreenshot = backgroundG.append("image")
			.attr("width", divBounds["width"])
			.attr("height", divBounds["height"])
			.attr("preserveAspectRatio", "none");
			
			var xRatio = divBounds["width"] / lastImg["naturalWidth"];
			var yRatio = (divBounds["height"] * .8) / lastImg["naturalHeight"];
			var finalRatio = xRatio;
			if(xRatio > yRatio)
			{
				finalRatio = yRatio;
			}

			var finalWidth = finalRatio * lastImg["width"];
			var finalX = (divBounds["width"] - finalWidth) / 2;
			
			curScreenshot.attr("width", finalWidth)
						.attr("x", finalX)
						.attr("onload", function()
								{
									
								})
						.attr("height", finalRatio * lastImg["height"]);
			
			curScreenshot.attr("href", "data:image/jpg;base64," + (await curFrame["Screenshot"]()));
			
			textHeight = curScreenshot.attr("width") / 50;
			
			startY = (divBounds["height"] * .8);
			
			if(!typedText)
			{
				typedText = animationGKey.append("text").attr("x", 0)
					.attr("y", startY + textHeight + textPadding)
					.text("Input:")
					.attr("font-size", textHeight);
			}
			
			if(prevLastScreenshot)
			{
				garbageToRemove.push(prevLastScreenshot);
			}
			if(lastScreenshot)
			{
				prevLastScreenshot = lastScreenshot;
				
			}
			lastScreenshot = curScreenshot;
			for(toRemove in garbageToRemove)
			{
				if(curFrame["Index MS Session"] - garbageToRemove[toRemove]["Index MS Session"] > 10000)
				{
					garbageToRemove[toRemove].remove();
				}
			}
		
		textScrollBar.attr("y", startY  + textPadding);
		textScrollBar.attr("minY", startY  + textPadding);
		runAnimationWrapped();
	}
	
	var updateProcAni = false;
	
	async function runAnimationWrapped()
	{
		if(foregroundExit)
		{
			return;
		}
		startY = (divBounds["height"] * .8)
		var curFrame = nextFrame();

		if(curFrame)
		{
			axisTick .attr("x", timeScaleAnimation(curFrame["Index MS Session"]));
			
			for(entry in lastMouseClicks)
			{
				//if(entry != lastMouseClicks.length)
				{
					var sessionTime = Number(lastMouseClicks[entry].attr("indexTime"));
					var curType = lastMouseClicks[entry].attr("Type");
					var timeDiff = Number(curFrame["Index MS Session"]) - sessionTime;
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
						nextColor = "Crimson";
						if(curType == "Down")
						{
							nextColor = "Crimson"
						}
						lastMouseClicks[entry].attr("stroke", nextColor);
					}
					
				}
			}
		}
		
		if(curFrame)
		{
			oldSeek = curFrame["Index MS Session"];
			scaleLabel.text((Math.round( ( (curFrame["Index MS Session"] / 60000) + Number.EPSILON ) * 100 ) / 100) + " Minutes");
			timeLog.text(curFrame["Index MS Session"] + " MS");
		}
		
		if(curFrame && curFrame["Screenshot"])
		{
			curScreenshot = backgroundG.append("image")
			.attr("width", divBounds["width"])
			.attr("height", divBounds["height"])
			//.attr("preserveAspectRatio", "xMidYMid meet");
			.attr("preserveAspectRatio", "none");
			
			//lastImg.src = "data:image/jpg;base64," + (await curFrame["Screenshot"]());
			lastImg = await loadImage(curFrame);

			var xRatio = divBounds["width"] / lastImg["naturalWidth"];
			var yRatio = (divBounds["height"] * .8) / lastImg["naturalHeight"];
			var finalRatio = xRatio;
			if(xRatio > yRatio)
			{
				finalRatio = yRatio;
			}
			
			var finalWidth = finalRatio * lastImg["width"];
			var finalX = (divBounds["width"] - finalWidth) / 2;
			
			curScreenshot.attr("width", finalWidth)
						.attr("x", finalX)
						.attr("onload", function()
								{
									
								})
						.attr("height", finalRatio * lastImg["height"]);
			
			curScreenshot.attr("href", "data:image/jpg;base64," + (await curFrame["Screenshot"]()));
			
			textHeight = curScreenshot.attr("width") / 50;
			
			//startY = finalRatio * lastImg["height"];
			var startYOld = startY;
			startY = (divBounds["height"] * .8);
			
			if(startY != startYOld)
			{
				//TODO: Do some stuff here to update the layout
			}
			
			if(!typedText)
			{
				typedText = animationGKey.append("text").attr("x", 0)
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
				//if(curFrame["Index MS Session"] - garbageToRemove[toRemove]["Index MS Session"] > 10000)
				{
					garbageToRemove[toRemove].remove();
				}
			}
		}
		if(curFrame && curFrame["TaskName"])
		{
			if(curFrame["Description"] == "start")
			{
				activeEvents.push(curFrame["TaskName"]);
			}
			else
			{
				var curIndex = activeEvents.indexOf(curFrame["TaskName"]);
				if(curIndex > -1)
				{
					activeEvents.splice(curIndex, 1);
				}
			}
			//activeEventName.attr("font-size", (divBounds["height"] * .025));
			activeEventName.text(activeEvents.join(', '));
			activeEventName2.text("");
			activeEventName.attr("textLength", "")
			activeEventName2.attr("textLength", "")
			if(activeEventName.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
			{
				var splitString = activeEvents;
				var firstString = splitString.slice(0, Math.ceil(splitString.length / 2)).join(", ");
				var secondString = splitString.slice(Math.ceil(splitString.length / 2), splitString.length).join(", ");
				activeEventName.text(firstString);
				activeEventName2.text(secondString);
				//activeEventName.attr("font-size", (divBounds["height"] * .0125));
				if(activeEventName.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
				{
					activeEventName.attr("textLength", (2.5 * divBounds["width"]) / 9);
				}
				if(activeEventName2.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
				{
					activeEventName2.attr("textLength", (2.5 * divBounds["width"]) / 9);
				}
			}
			else
			{
				activeEventName.attr("textLength", "")
			}
		}
		if(curFrame && curFrame["FirstClass"])
		{
			activeWindow.text(curFrame["FirstClass"]);
			activeWindow.attr("textLength", "")
			if(activeWindow.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
			{
				activeWindow.attr("textLength", (2.5 * divBounds["width"]) / 9)
			}
			else
			{
				activeWindow.attr("textLength", "")
			}
			activeWindowName.text(curFrame["Name"]);
			activeWindowName.attr("textLength", "")
			if(activeWindowName.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
			{
				activeWindowName.attr("textLength", (2.5 * divBounds["width"]) / 9)
			}
			else
			{
				activeWindowName.attr("textLength", "")
			}
		}
		
		if(curFrame && curFrame["XLoc"])
		{
			var xLoc = Number(curFrame["XLoc"]);
			xLoc = xLoc / lastImg["width"];
			xLoc = xLoc * curScreenshot.attr("width");
			xLoc = xLoc + Number(curScreenshot.attr("x"));
			var yLoc = Number(curFrame["YLoc"]) / lastImg["height"];
			yLoc = yLoc * curScreenshot.attr("height");
			var centerColor = "Black";
			var outerColor = "Crimson"
			if(curFrame["Type"] == "down")
			{
				outerColor = "Chartreuse"
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
			else if(buttonToType == "Volume Up")
			{
				buttonToType = "🔊";
			}
			else if(buttonToType == "Volume Dow")
			{
				buttonToType = "🔈";
			}
			else if(buttonToType == "Enter")
			{
				//keyboardInputs.shift();
				//keyboardInputs.unshift(curLine);
				curKeyInput = animationGKey.append("text").attr("x", 0)
				.attr("y", startY  + textPadding)
				.attr("initY", startY  + textPadding)
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
				if(curKeyInput.node().getBBox()["width"] + textHeight > (divBounds["width"]) / 2)
				{
					//keyboardInputs.shift();
					//keyboardInputs.unshift(curLine);
					curKeyInput = animationGKey.append("text").attr("x", 0)
					.attr("y", startY  + textPadding)
					.attr("initY", startY  + textPadding)
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
			
			var totalTextHeight = Number(keyboardInputs[keyboardInputs.length - 1].attr("initY")) + Number(keyboardInputs[keyboardInputs.length - 1].attr("font-size")) - (startY  + textPadding);
			var totalBarHeight = (divBounds["height"] - (startY  + textPadding));
			var adjustedBarHeight = totalBarHeight;
			
			//console.log(totalTextHeight);
			//console.log(totalBarHeight);
			
			if(totalTextHeight > totalBarHeight)
			{
				adjustedBarHeight = (totalBarHeight / totalTextHeight) * totalBarHeight;
			}
			
			//console.log(adjustedBarHeight);
			
			textScrollBar.attr("height", adjustedBarHeight);
			textScrollBar.attr("maxY", divBounds["height"]);
		}
		
		if(curFrame && curFrame["PID"])
		{
			if(curFrame["CPU"] > 0)
			{
				if(curTop[curFrame["PID"]])
				{
					for(var x = 0; x < topProcesses.length; x++)
					{
						if(curFrame["PID"] == topProcesses[x]["PID"])
						{
							//if(curFrame["CPU"] != topProcesses[x]["CPU"])
							{
								topProcesses.splice(x, 1);
								delete curTop[curFrame["PID"]];
								//break;
								updateProcAni = true;
							}
						}
					}
				}
				//else
				{
					for(var x = 0; curFrame["Next"] && x < numTopProcesses; x++)
					{
						if(topProcesses.length <= x)
						{
							topProcesses.push(curFrame);
							curTop[curFrame["PID"]] = true;
							updateProcAni = true;
							break;
						}
						else
						{
							if(curFrame["CPU"] > topProcesses[x]["CPU"])
							{
								curTop[curFrame["PID"]] = true;
								topProcesses.splice(x, 0, curFrame);
								if(topProcesses[numTopProcesses])
								{
									delete curTop[topProcesses[numTopProcesses]["PID"]];
								}
								topProcesses = topProcesses.slice(0, numTopProcesses);
								updateProcAni = true;
								break;
							}
						}
					}
				}
			}
			{
				{
					if(updateProcAni)
					{
						
						if(topProcesses[0])
						{
							maxProcCPU = topProcesses[0]["CPU"];
						}
						else
						{
							maxProcCPU = 0;
						}
						processGraphAniMaxLabel.text(maxProcCPU);
						processGraphAniBarG.selectAll("*")
								//.data(topProcesses)
								//.exit()
								.remove();
						processGraphAniBarG.selectAll("rect")
								.data(topProcesses)
								.enter()
								.append("rect")
								//.attr("width", (2 * divBounds["width"]) / 9)
								.attr("width", function(d, i)
										{
											if(maxProcCPU == 0)
											{
												return 0;
											}
											return ((d["CPU"] / maxProcCPU) * (2 * divBounds["width"]) / 9);
										})
								.attr("height", (((divBounds["height"] * .2) - textPadding) / numTopProcesses))
								.attr("fill", function(d, i)
										{
											//var scaleMult = 20 / numTopProcesses;
											//if(scaleMult > 1)
											//{
											//	return colorScale(i * scaleMult);
											//}
											//else
											//{
												return colorScale(((i % 10) * 2) + 1);
											//}
										})
								.style("fill-opacity", ".9")
								.attr("stroke", "Black")
								.attr("x", (4.5 * divBounds["width"]) / 9)
								.attr("y", function(d, i)
										{
											var initReturn =  ((divBounds["height"] * .8) + textPadding);
											return initReturn + (i * (((divBounds["height"] * .2) - textPadding) / numTopProcesses));
										});
						
						//processGraphAniBarG.selectAll("text")
						//		.data(topProcesses)
								//.exit()
						//		.remove();
						processGraphAniBarG.selectAll("text")
								.data(topProcesses)
								.enter()
								.append("text")
								.attr("dominant-baseline", "hanging")
								.attr("font-size", (((divBounds["height"] * .2) - textPadding) / numTopProcesses) / 2)
								.attr("stroke", "Black")
								.text(function(d, i)
										{
											return d["Command"] + " " + d["PID"] + ": " + d["CPU"];
										})
								.attr("x", (4.5 * divBounds["width"]) / 9)
								.attr("y", function(d, i)
										{
											var initReturn =  ((divBounds["height"] * .8) + textPadding);
											return initReturn + (i * (((divBounds["height"] * .2) - textPadding) / numTopProcesses));
										});
							
					}
				}
			}
		}
		
		for(entry in keyboardInputs)
		{
			keyboardInputs[entry].attr("y", startY  + textPadding + ((Number(entry) + 2) * textHeight))
								.attr("initY", startY  + textPadding + ((Number(entry) + 2) * textHeight))
								.style("opacity", 1)
								.attr("font-size", textHeight);
		}
		d3.select("#animationTextScrollbar").attr("y", d3.select("#animationTextScrollbar").attr("minY"));

		if(playing && curFrame && (!(lastFrame)))
		{
			axisTick .style("transition", (Number(curFrame["Index MS Session"]) / playbackSpeedMultiplier) + "ms linear");
			animationTimeout = setTimeout(runAnimationWrapped, Number(curFrame["Index MS Session"]) / playbackSpeedMultiplier);
		}
		else if(playing && curFrame)
		{
			axisTick .style("transition", ((Number(curFrame["Index MS Session"]) - Number(lastFrame["Index MS Session"])) / playbackSpeedMultiplier) + "ms linear");
			animationTimeout = setTimeout(runAnimationWrapped, (Number(curFrame["Index MS Session"]) - Number(lastFrame["Index MS Session"])) / playbackSpeedMultiplier);
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
				var curX = d3.mouse(this)[0];
				var curY = d3.mouse(this)[1];
				var selectTime = timeScaleAnimationLookup(curX);
				seekTime(selectTime);
				d3.event.stopPropagation();
			});
	
	//Iterate through events to build a list for the given time
	function updateEventList(selectTime)
	{
		if(!events)
		{
			return;
		}
		var curTime = 0;
		var curEventIndex = 0;
		
		while(curTime < selectTime && curEventIndex < events.length)
		{
			curFrame = events[curEventIndex];
			if(curFrame)
			{
				curTime = curFrame["Index MS Session"];
				if(curTime >= selectTime)
				{
					break;
				}
				{
					if(curFrame["Description"] == "start")
					{
						activeEvents.push(curFrame["TaskName"]);
					}
					else
					{
						var curIndex = activeEvents.indexOf(curFrame["TaskName"]);
						if(curIndex > -1)
						{
							activeEvents.splice(curIndex, 1);
						}
					}
				}
				
			}
			curEventIndex++;
		}
		
		activeEventName.attr("font-size", (divBounds["height"] * .025));
		activeEventName.text(activeEvents.join(', '));
		activeEventName2.text("");
		activeEventName.attr("textLength", "")
		activeEventName2.attr("textLength", "")
		if(activeEventName.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
		{
			var splitString = activeEvents;
			var firstString = splitString.slice(0, Math.ceil(splitString.length / 2)).join(", ");
			var secondString = splitString.slice(Math.ceil(splitString.length / 2), splitString.length).join(", ");
			activeEventName.text(firstString);
			activeEventName2.text(secondString);
			activeEventName.attr("font-size", (divBounds["height"] * .0125));
			if(activeEventName.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
			{
				activeEventName.attr("textLength", (2.5 * divBounds["width"]) / 9);
			}
			if(activeEventName2.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
			{
				activeEventName2.attr("textLength", (2.5 * divBounds["width"]) / 9);
			}
		}
		else
		{
			activeEventName.attr("textLength", "")
		}
	}
	
	//Iterate through the processes to get the top processes at a given time.
	function updateTopProcesses(selectTime)
	{
		if(!processes)
		{
			return;
		}
		var curTime = 0;
		var curProcessIndex = 0;
		
		while(curTime < selectTime && processIndex < processes.length)
		{
			curFrame = processes[curProcessIndex];
			
			
			if(curFrame)
			{
				curTime = curFrame["Index MS Session"];
				if(curTime >= selectTime)
				{
					break;
				}
				
				if(curFrame["CPU"] > 0)
				{
					if(curTop[curFrame["PID"]])
					{
						for(var x = 0; x < topProcesses.length; x++)
						{
							if(curFrame["PID"] == topProcesses[x]["PID"])
							{
								//if(curFrame["CPU"] != topProcesses[x]["CPU"])
								{
									topProcesses.splice(x, 1);
									delete curTop[curFrame["PID"]];
									//break;
									updateProcAni = true;
								}
							}
						}
					}
					//else
					{
						for(var x = 0; curFrame["Next"] && x < numTopProcesses; x++)
						{
							if(topProcesses.length <= x)
							{
								topProcesses.push(curFrame);
								curTop[curFrame["PID"]] = true;
								updateProcAni = true;
								break;
							}
							else
							{
								if(curFrame["CPU"] > topProcesses[x]["CPU"])
								{
									curTop[curFrame["PID"]] = true;
									topProcesses.splice(x, 0, curFrame);
									if(topProcesses[numTopProcesses])
									{
										delete curTop[topProcesses[numTopProcesses]["PID"]];
									}
									topProcesses = topProcesses.slice(0, numTopProcesses);
									updateProcAni = true;
									break;
								}
							}
						}
					}
				}
			}
			curProcessIndex++;
		}
		
		
		if(topProcesses[0])
		{
			maxProcCPU = topProcesses[0]["CPU"];
		}
		else
		{
			maxProcCPU = 0;
		}
		processGraphAniMaxLabel.text(maxProcCPU);
		processGraphAniBarG.selectAll("*")
				//.data(topProcesses)
				//.exit()
				.remove();
		processGraphAniBarG.selectAll("rect")
				.data(topProcesses)
				.enter()
				.append("rect")
				//.attr("width", (2 * divBounds["width"]) / 9)
				.attr("width", function(d, i)
						{
							if(maxProcCPU == 0)
							{
								return 0;
							}
							return ((d["CPU"] / maxProcCPU) * (2 * divBounds["width"]) / 9);
						})
				.attr("height", (((divBounds["height"] * .2) - textPadding) / numTopProcesses))
				.attr("fill", function(d, i)
						{
							//var scaleMult = 20 / numTopProcesses;
							//if(scaleMult > 1)
							//{
							//	return colorScale(i * scaleMult);
							//}
							//else
							//{
								return colorScale(((i % 10) * 2) + 1);
							//}
						})
				.style("fill-opacity", ".9")
				.attr("stroke", "Black")
				.attr("x", (4.5 * divBounds["width"]) / 9)
				.attr("y", function(d, i)
						{
							var initReturn =  ((divBounds["height"] * .8) + textPadding);
							return initReturn + (i * (((divBounds["height"] * .2) - textPadding) / numTopProcesses));
						});
		
		//processGraphAniBarG.selectAll("text")
		//		.data(topProcesses)
				//.exit()
		//		.remove();
		processGraphAniBarG.selectAll("text")
				.data(topProcesses)
				.enter()
				.append("text")
				.attr("dominant-baseline", "hanging")
				.attr("font-size", (((divBounds["height"] * .2) - textPadding) / numTopProcesses) / 2)
				.attr("stroke", "Black")
				.text(function(d, i)
						{
							return d["Command"] + " " + d["PID"] + ": " + d["CPU"];
						})
				.attr("x", (4.5 * divBounds["width"]) / 9)
				.attr("y", function(d, i)
						{
							var initReturn =  ((divBounds["height"] * .8) + textPadding);
							return initReturn + (i * (((divBounds["height"] * .2) - textPadding) / numTopProcesses));
						});
	}
	
	function seekTime(selectTime)
	{
				clearTimeout(animationTimeout);
				
				curKeyInput = animationGKey.append("text").attr("x", 0)
				.attr("y", startY  + textPadding)
				.attr("initY", startY  + textPadding)
				.text("Seek to: " + selectTime)
				.attr("text", "Seek to: " + selectTime)
				.attr("font-size", textHeight);
				
				keyboardInputs.unshift(curKeyInput);
				
				topProcesses = [];
				curTop = {};
				updateProcAni = true;
				var curDiff = Infinity;
				if(screenshots)
				{
					screenshotIndex = closestIndexMSBinarySession(screenshots, selectTime);
					var curScreenshot = screenshots[screenshotIndex];
				}
				if(keystrokes)
				{
					keystrokesIndex = closestIndexMSBinarySession(keystrokes, selectTime);
					var curKeystrokes = keystrokes[keystrokesIndex];
				}
				if(mouse)
				{
					mouseIndex = closestIndexMSBinarySession(mouse, selectTime);
					var curMouse = mouse[mouseIndex];
				}
				if(windows)
				{
					windowsIndex = closestIndexMSBinarySession(windows, selectTime);
					var curWindows = windows[windowsIndex];
				}
				if(processes)
				{
					processIndex = closestIndexMSBinarySession(processes, selectTime);
					var curProcess = processes[processIndex];
				}
				if(events)
				{
					eventsIndex = closestIndexMSBinarySession(events, selectTime);
					var curEvent = events[eventsIndex];
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
				if(processes && curProcess && curDiff > Math.abs(Number(curProcess["Index MS Session"]) - selectTime))
				{
					selectedEntry = curProcess;
					curDiff = Math.abs(Number(curProcess["Index MS Session"]) - selectTime);
				}
				if(events && curEvent && curDiff > Math.abs(Number(curEvent["Index MS Session"]) - selectTime))
				{
					selectedEntry = curEvent;
					curDiff = Math.abs(Number(curEvent["Index MS Session"]) - selectTime);
				}
				
				//Getting last known window before the closest seek entry
				activeWindow.text("...");
				activeWindowName.text("...");
				
				var tmpWindow = curWindows;
				var windowIndexSubtract = 1;
				while(tmpWindow && tmpWindow["Index MS Session"] > selectedEntry["Index MS Session"])
				{
					if(windows[windowsIndex - windowIndexSubtract])
					{
						tmpWindow = windows[windowsIndex - windowIndexSubtract];
						windowIndexSubtract++;
					}
					else
					{
						break;
					}	
				}
				
				if(tmpWindow)
				{
					activeWindow.text(tmpWindow["FirstClass"]);
					activeWindow.attr("textLength", "")
					if(activeWindow.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
					{
						activeWindow.attr("textLength", (2.5 * divBounds["width"]) / 9)
					}
					else
					{
						activeWindow.attr("textLength", "")
					}
					activeWindowName.text(tmpWindow["Name"]);
					activeWindowName.attr("textLength", "")
					if(activeWindowName.node().getBBox()["width"] + textHeight > ((2.5 * divBounds["width"]) / 9))
					{
						activeWindowName.attr("textLength", (2.5 * divBounds["width"]) / 9)
					}
					else
					{
						activeWindowName.attr("textLength", "")
					}
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
				while(processes && processIndex < processes.length && Number(processes[processIndex]["Index MS Session"]) < Number(selectedEntry["Index MS Session"]))
				{
					processIndex++;
				}
				while(events && eventsIndex < events.length && Number(events[eventsIndex]["Index MS Session"]) < Number(selectedEntry["Index MS Session"]))
				{
					eventsIndex++;
				}
				
				
				lastFrame = selectedEntry;
				axisTick.style("transition", "none");
				axisTick .attr("x", timeScaleAnimation(selectedEntry["Index MS Session"]));
				
				updateTopProcesses(selectedEntry["Index MS Session"]);
				
				activeEvents = [];
				activeEventName.text("...");
				updateEventList(selectedEntry["Index MS Session"]);
				
				curKeyInput = animationGKey.append("text").attr("x", 0)
				.attr("y", startY  + textPadding)
				.attr("initY", startY  + textPadding)
				.text("Play from: " + selectedEntry["Index MS Session"])
				.attr("text", "Play from: " + selectedEntry["Index MS Session"])
				.attr("font-size", textHeight);
				
				keyboardInputs.unshift(curKeyInput);
				
				curKeyInput = animationGKey.append("text").attr("x", 0)
				.attr("y", startY  + textPadding)
				.attr("initY", startY  + textPadding)
				//.text("⏯")
				//.attr("text", "⏯")
				.text("")
				.attr("text", "")
				.attr("font-size", textHeight);
				
				keyboardInputs.unshift(curKeyInput);
				
				
				for(entry in lastMouseClicks)
				{
					
						lastMouseClicks[entry].remove();
						lastMouseClicks.splice(entry, 1);
						entry--;
						continue;
					
				}
				
				var totalTextHeight = Number(keyboardInputs[keyboardInputs.length - 1].attr("initY")) + Number(keyboardInputs[keyboardInputs.length - 1].attr("font-size")) - (startY  + textPadding);
				var totalBarHeight = (divBounds["height"] - (startY  + textPadding));
				var adjustedBarHeight = totalBarHeight;
				
				if(totalTextHeight > totalBarHeight)
				{
					adjustedBarHeight = (totalBarHeight / totalTextHeight) * totalBarHeight;
				}
				
				textScrollBar.attr("height", adjustedBarHeight);
				textScrollBar.attr("maxY", divBounds["height"]);
				
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
	}
	
	if(seekTo)
	{
		seekTime(seekTo);
	}
	
}