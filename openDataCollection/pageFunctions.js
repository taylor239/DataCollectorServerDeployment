
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

var curFunction;

var curTutorialIndex = 0;

var tutorialArray = [];

var titleTutorial = {id: "title", caption: "This is the event you are viewing and the progress of your download.  The visualization first downloads index data and presents that and asynchronously downloads screenshots after.  All data is cached locally."};
tutorialArray.push(titleTutorial);
var optionsTutorial1 = {id: "optionFilterTable", caption: "This is the options and filtering table.  'Playback Speed' is the rate animations are played at as a multiplier of real world time."};
tutorialArray.push(optionsTutorial1);
var optionsTutorial2 = {id: "optionFilterTable", caption: "'Timeline Zoom' allows you to zoom in and enlarge the data in the timeline window."};
tutorialArray.push(optionsTutorial2);
var optionsTutorial3 = {id: "optionFilterTable", caption: "'Filters' evaluate expressions on pieces of data and exclude them based on the result of the evaluation.  By default, the visualization shows only Aggregate sessions due to the default filter.  To remove this filter, click the X next to it.  The Server checkbox allows the expression to be done server side before downloading the data; this can sometimes drastically reduce the data size.  This feature is currently under construction.  If you are logged in, then your set of filters can be saved and loaded.  Features saved as 'Default' will be loaded by default.  Server-side executing filters must be saved as 'Default' to execute."};
tutorialArray.push(optionsTutorial3);
var timelineTutorial = {id: "visRow", caption: "This is the timeline view.  This shows what users were doing when they had data collection software open.  The first item you see on top is the username and the total time period they worked across all sessions - a session being a time period from startup to shutdown on a single device.  Below the username bar are individual sessions from that user.  The time scale for all data is relative to the session; that is, if a window is open 5 minutes into the session then that is where it will be on time time scale, which is visible and labeled just above the middle of each session bar.  The very top bar of each session shows the active window at the given time.  You can click on a window to focus on the session (bringing up the session process graph below, more on that in a minute) and info about the active window.  The bar below th active window bar (just above the time scale) shows screenshots.  You can mouse over to highlight and view individual screenshots.  The bottom bar (the bottom half of a session) is reserved for annotation/task/event data.  Both user supplied and analyst generated annotations go there.  Similarly to selecting a window, clicking on a task selects the session and provides the process info and info about the task.  Red bars lebeled Filter will filter out the data it is attached to - clicking Filter next to a username will filter out the user and clicking next to session bars will filter out the session.  The Play button shows the screenshots, keyboard, mouse, and window data from the session in an animation."};
tutorialArray.push(timelineTutorial);
var legendTutorial = {id: "legendTable", caption: "The legend shows what the colors on the timelines correspond to.  Note that windows are labeled by their program, not by their current title, which can be confusing when dealing with windows that frequently change titles such as web browsers.  Each separate title appears as a different entry on the timeline but of the same color.  The legend also shows which user(s) entered which tasks through color coding them."};
tutorialArray.push(legendTutorial);
var graphTutorial = {id: "graphCell", caption: "This is the graph table.  By default, it shows summary statistics from all of the sessions (after filters have been applied) and shows process CPU usage over time for sessions when selected.  When a session is selected, a timeline will also appear here; that timeline allows you to enter tasks/events/annotations manually.  Drag your mouse on the timeline to select the time period for your annotation and then enter the annotation and push the Submit button to save it.  It will now appear on the timeline for you.  Note that you must have an admin login to use this feature.  Finally, below the graph is a info table.  When you select items on the timeline, the detailed data of your selection will be there."};
tutorialArray.push(graphTutorial);

function tutorial()
{
	console.log("Starting tutorial")
	curTutorialIndex = 0;
	nestedTutorial();
}

function nestedTutorial()
{
	if(curTutorialIndex < tutorialArray.length)
	{
		dimBackground(document.getElementById(tutorialArray[curTutorialIndex]["id"]), tutorialArray[curTutorialIndex]["caption"], nestedTutorial);
		curTutorialIndex++;
	}
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
