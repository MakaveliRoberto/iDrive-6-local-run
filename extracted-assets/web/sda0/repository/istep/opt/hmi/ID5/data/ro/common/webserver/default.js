        function jquery(index, ui, check)
        {
            var index = index;
            var ui = ui;
            $.ajax({
                type: "POST",
                url: "/Scene/",
                data: {uiId: ui, gfxElementIndex: index, visibility: check},
                success: function(msg){
                }
            });
        }


    /*-------------------------------------------------------SHOWHIDE()---------------------------------------------------------------*/


        //The showHide-function is used to make a div visible or invisible
        function showHide(name)
        {
            //alert(document.getElementById(name).innerHTML);

            console.log(name);
            if(document.getElementById(name).style.display != 'block')
            {
                document.getElementById(name).style.display = 'block';
            }
            else document.getElementById(name).style.display = 'none';

            //alert(document.getElementById(name).style.display);
        }


    /*-------------------------------------------------------TOGGLE_INFOS()---------------------------------------------------------------*/


        function toggle_infos(name) {
            divs=document.getElementsByName(name);
            for(i=0;i<divs.length;i++)  {
                divs[i].style.display=(divs[i].style.display=="none") ?"block":"none";
            }
        }


    /*-------------------------------------------------------SEND()---------------------------------------------------------------*/


        function send() {
            var txt1 = document.getElementById("objectname").value;
            var txt2 = document.getElementById("uniformname").value;
            var txt3 = document.getElementById("value").value;

            $.ajax({
                type: "POST",
                url: "/Scene/",
                data: {objectname: txt1, uniformname: txt2, value: txt3},
                success: function(msg){
                }
            });
        }


    /*-------------------------------------------------------RESET()---------------------------------------------------------------*/


        function reset()
        {
            document.getElementById("objectname").value = document.getElementById("reset_modelName").value;
            document.getElementById("uniformname").value = document.getElementById("reset_uniformName").value;
            document.getElementById("value").value = document.getElementById("reset_uniformValue").value;
        }


    /*-------------------------------------------------------SHOWWIDGET()---------------------------------------------------------------*/


        var widgetWindow;
        var nodeWindow;

        //This ID is used to give every single Pop-Up generated through a click on a "Widget"-Button a unique name
        var windowID = 0;

        //The function gets called with the variable "container"; container stores a pointer of the node, whose "Widget"-button has been pressed
        function makeRoomForTree(container)
        {

            //If the PopUp with the name widgetWindow is not existent, we create it with the window.open command; this window displays the "Widget"-Webtool
            if(!widgetWindow)
            {
                widgetWindow = window.open("Widgets" , "widgets" , "scrollbars=yes,width=712,height=384,menubar=yes,toolbar=yes,titlebar=yes");
            }

            else if(widgetWindow.closed)
            {
                widgetWindow = window.open("Widgets" , "widgets" , "scrollbars=yes,width=712,height=384,menubar=yes,toolbar=yes,titlebar=yes");
            }

            //If the window already exists, we send a message to it containing a pointer stored in the variable container
            else
            {
                widgetWindow.postMessage(container, 'Widgets');
                var a,element;
                //The next two lines of code are responsible for scrolling to the Widget (<-- corresponding to the Node whose button has been pressed; see container) in widgetWindow
                //element = document.getElementById(container);
                //a = getPosition(element);
            }

            var x = 0;
            //As long as document.getElementsByName('show_widget_button')[x] returns true, we're looping thorugh all "Widget"-Buttons; if they're not disabled they become the common color for Buttons as backgroundcolor --> otherwise every button would be highlighted as pressed
            while(document.getElementsByName('show_widget_button')[x])
            {
                if(!document.getElementsByName('show_widget_button')[x].disabled)
                {
                    document.getElementsByName('show_widget_button')[x].style.background = '#34495e';
                }
                x++;
            }

            //The pressed "Widget"-button is highlighted in red
            document.getElementById("widget_button_" + container).style.background = 'red';
        }


    /*-------------------------------------------------------SHOWNODE()---------------------------------------------------------------*/


        function showNode(node)
        {
            //Equivalent to the functions in MAKEROOMFORTREE()
            if(!nodeWindow)
            {
                nodeWindow = window.open("SceneGraph" , "scene_graph" , "scrollbars=yes,width=712,height=384,menubar=yes,toolbar=yes,titlebar=yes");
            }

            //Equivalent to the functions in MAKEROOMFORTREE()
            else if(nodeWindow.closed)
            {
                nodeWindow = window.open("SceneGraph" , "scene_graph" , "scrollbars=yes,width=712,height=384,menubar=yes,toolbar=yes,titlebar=yes");
            }

            //Equivalent to the functions in MAKEROOMFORTREE()
            else
            {
                nodeWindow.postMessage(node, 'SceneGraph');
                var a,element;
                //element = document.getElementById(node);
                //a = getPosition(element);
            }

            var x = 0;
            //Equivalent to the functions in MAKEROOMFORTREE()
            while(document.getElementsByName('show_node_button')[x])
            {
                if(!document.getElementsByName('show_node_button')[x].disabled)
                {
                    document.getElementsByName('show_node_button')[x].style.background = '#34495e';
                }
                x++;
            }

            //Equivalent to the functions in MAKEROOMFORTREE()
            document.getElementById("node_button_" + node).style.background = 'red';
        }


    /*-------------------------------------------------------ONMESSAGE()---------------------------------------------------------------*/


        //Every site has the ability to react to a posted message
        window.onmessage = function(evt)
        {
            var element;
            var tmp;
            //With evt.data we get the pointer sent with the "postMessage"-function, which is then be used to find the position of the desired element; window.scrollTo the uses the x and y coordinates and scrolls to it  - now the element is in the upper left corner
            element = document.getElementById(evt.data);
            tmp = getPosition(element);
            window.scrollTo(0,tmp.y);
            //If the message was posted to the "SceneGraph"-Webtool, we have to call the function "getNodeElements", because only opening the table would display the placeholder-entries for the node-Details
            if(document.getElementById('table' + evt.data))
              getNodeElements(evt.data);
            //If the message is received by the "Widget"-Webtool, we only open the div, holding all the parameters of its widget (this is possible, because all information are loaded directly)
            else if(document.getElementById('div' + evt.data))
              getWidgetInformation(evt.data, 0);
        };


    /*-------------------------------------------------------GETPOSITION()---------------------------------------------------------------*/


        function getPosition(element)
        {
            var elem=element,tagname="",x=0,y=0;
            //As long as the submitted element is a DOM-object we loop up thorugh the DOM-model
            while ((typeof(elem)=="object")&&(typeof(elem.tagName)!="undefined"))
            {
                //Adding the offset of the corresponding element
                y+=elem.offsetTop;
                x+=elem.offsetLeft;

                //Getting the tagname of the element and transforming it to the upper case to avoid errors when checking if the tagname is the body tag
                tagname=elem.tagName.toUpperCase();

                if (tagname=="BODY")
                    elem=0;

                console.log(typeof(elem));
                console.log(element.offsetParent);
                console.log(element.offsetParent.tagName);

                //If the current element is an object and his parent too, then we set the parent-element as the current element (this is comparable to increasing a variable e.g. x++)
                if (typeof(elem)=="object")
                    if (typeof(elem.offsetParent)=="object")
                        elem=elem.offsetParent;
            }

            //After the loop, we create a new object and setting its x and y coordinates; after that we return the coordinates
            position=new Object();
            position.x=x;
            position.y=y;
            return position;
        }


    /*-------------------------------------------------------EXPAND()---------------------------------------------------------------*/

	function expand(element)
	{
		//alert(element.tagName);
		if(element.style.display == 'none')
		{
			element.style.display = 'block';
		}
		if(element.parentNode)
		{
			expand(element.parentNode);
		}
	}

    /*-------------------------------------------------------URLPARAM()---------------------------------------------------------------*/

	function urlParam(key)
	{
		var s = window.document.URL.toString();
		s = s.split(key+'=')[1];
		//alert(s.split('&')[0]);
		return s.split('&')[0];
	}

    /*-------------------------------------------------------WRAPPERFUNCTION()---------------------------------------------------------------*/

    var foldall;
        //wrapperFunction has the only purpose to summarize some other functions or some codefragments so they get called with one statement (in our case the wrapperFunction gets called on body.onLoad)
        function wrapperFunction()
        {
            fillNavigation();
            //widgetExists is responsible for checking if we're currently using the "SceneGraph"-Webtool and if a node is linked to a widget (for further information see the function itself)
            //widgetExists();

            //This block is responsible for creating some navigation-lines to visualize which objects are on the same level (unfortunately this code is very computationally intensive; that's why it its commented out)
            /*
            footer_element = document.getElementById("footer");
            footer_tmp = getPosition(footer_element);
            //window.scrollTo(0,tmp.y);

            for(var x = 0; document.getElementsByName("lines")[x]; x++)
            {
                lines_element = document.getElementsByName("lines")[x];
                lines_tmp = getPosition(lines_element);
                var line_height = footer_tmp.y - lines_tmp.y;
                line_height = line_height + "px";
                document.getElementsByName("lines")[x].style.height = line_height;
            }
            */



            //If we're using the "SceneGraph"-Webtool this is true, because there is an element with the id "hiddennodes"
            if(document.getElementById("hiddennodes"))
            {
                //createTreeSaver is generating the Tools on the left side (right now we have the Navigation-Menu, the Total Number of Node and Widgets, the "Save Tree" and "Load Tree" buttons and the Search); generating them in an extra function makes it easier to add some Tools (for more details see the function)
                createTreeSaver();
                //If a Webtool gets the toolbar the whole body is pushed to the right and the container for the tools is pushed to the left to avoid covering eachother
                document.getElementById("body").style.marginLeft = "200px";
                document.getElementById("navbar").style.marginLeft = "-180px";
                document.getElementById("scene_graph_infos").style.marginLeft = "-180px";
                document.getElementById("scene_graph_infos").style.marginTop = "60px";
                var numberofnodes = document.getElementById("hiddennodes").value;
                //With  the total amount of nodes we call the function foldSingleNode; this function normally gets called with a pointer too, which we now set to 0; calling this function with 0 triggers a special case of the function (for more details see the function)
                foldSingleNode(0,numberofnodes);
            }

            //If we're using the "Widgets"-Webtool this is true, because there are elements with the name "viewheadername"
            else if(document.getElementsByName("viewheadername"))
            {
                //The process is similar to the one for the "SceneGraph"-Webtool
                createTreeSaver();
                document.getElementById("body").style.marginLeft = "200px";
                document.getElementById("navbar").style.marginLeft = "-180px";
                document.getElementById("scene_graph_infos").style.marginLeft = "-180px";
                document.getElementById("scene_graph_infos").style.marginTop = "60px";
                foldSingleNodeForAW(0);
            }

            foldall = document.getElementById("body").innerHTML;

			expand(document.getElementById(urlParam('id')));
        }


    /*-------------------------------------------------------CREATETREESAVER()---------------------------------------------------------------*/


        var tmp_color;
        var already_searched;
        var now_node = 0;

        function createTreeSaver()
        {
            //The following lines of code ( from here to including line 1077) creating the Tools for the Toolbar and then assigning ids to them
            save = document.createElement("div");
            save.setAttribute('id', 'save_the_tree');
            save.onclick = function()
            {
                saveTheTrees();
            }
            save.setAttribute("onclick", "saveTheTrees()");

            load = document.createElement("div");
            load.setAttribute('id', 'load_the_tree');
            load.onclick = function ()
            {
                loadTheTrees();
            }
            load.setAttribute("onclick", "loadTheTrees()");

            searchbox = document.createElement("input");
            searchbox.setAttribute('id', 'search_box');
            searchbox.setAttribute("placeholder", "Search...");

            searchhits = document.createElement("div");
            searchhits.setAttribute('id', 'search_hits');

            foldallcontainer = document.createElement("div");
            foldallcontainer.setAttribute('id', 'foldallcontainer');
            foldallcontainer.onclick = function ()
            {
              foldAllElements();
            }
            foldallcontainer.setAttribute("onclick", "foldAllElements()");


            //Here we defining the code which gets executed,if the searchbutton is clicked
            searchbox.onkeydown = function(event)
            {
                if (event.keyCode == 13)
                {
                    if(already_searched != document.getElementById("search_box").value)
                    {
                        var hits = 0;
                        //getting the value of the searchfield e.g the user entered "hello", inputvalue is set to "hello"
                        var inputvalue = document.getElementById("search_box").value.toLowerCase();
                        //Now we check,if the pointer of a node/widget can be found anywhere in between the body tags
                        if(document.getElementById("body").innerHTML.toLowerCase().match(inputvalue))
                        {
                            if(document.getElementById("widgets"))
                            {
                                var rootNodes = document.getElementsByName("viewheadername");
                                var n = rootNodes.length;
                                console.log("#viewheadername: " + n);
                                for(var x = 0; x < n; x++)
                                {
                                    console.log("ja mal " + x);

                                    var rootNode = rootNodes[x];

                                    rootNode.style.background = "#34495e";
                                    rootNode.style.display = 'inline-block';

                                    document.getElementsByName("show_node_button")[x].style.display = 'inline-block';
                                    document.getElementsByName("show_hierarchie_button")[x].style.display = 'inline-block';
                                    //document.getElementsByName("widgetheader")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_t")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_d")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_o")[x].style.display = 'inline-block';
                                    document.getElementsByName("fold_single")[x].style.display = 'inline-block';

                                    if(rootNode.innerHTML.toLowerCase().match(inputvalue))
                                    {
                                        console.log("ja mal 3");
                                        //Here the found element gets highlighted
                                        rootNode.style.background = "#3498DB";
                                        hits++;
                                    }
                                }

                            }

                            else if(document.getElementById("hiddennodes"))
                            {
                                for(var x = 0; document.getElementsByName("viewheadername")[x]; x++)
                                {
                                    document.getElementsByName("viewheadername")[x].style.background = "#34495e";

                                    document.getElementsByName("viewheadername")[x].style.display = 'inline-block';
                                    document.getElementsByName("show_widget_button")[x].style.display = 'inline-block';
                                    document.getElementsByName("show_hierarchie_button")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_t")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_d")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_o")[x].style.display = 'inline-block';
                                    document.getElementsByName("fold_single")[x].style.display = 'inline-block';
                                    document.getElementsByName("scene_graph_container")[x].style.height = "";

                                    if(document.getElementsByName("viewheadername")[x].innerHTML.toLowerCase().match(inputvalue))
                                    {
                                        document.getElementsByName("viewheadername")[x].style.background = "#3498DB";
                                        hits++;
                                    }
                                }

                            }

                            else if(document.getElementById("hiddenalo"))
                            {
                                for(var x = 0; document.getElementsByName("header")[x]; x++)
                                {
                                    document.getElementsByName("header")[x].style.background = "#34495e";

                                    document.getElementsByName("header")[x].style.display = 'inline-block';
                                    document.getElementsByName("show_hierarchie_button")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_t")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_d")[x].style.display = 'inline-block';
                                    document.getElementsByName("debug_visualization_o")[x].style.display = 'inline-block';
                                    document.getElementsByName("fold_single")[x].style.display = 'inline-block';
                                    document.getElementsByName("alocontainer")[x].style.height = "";

                                    if(document.getElementsByName("header")[x].innerHTML.toLowerCase().match(inputvalue))
                                    {
                                        document.getElementsByName("header")[x].style.background = "#3498DB";
                                        hits++;
                                    }
                                }
                            }

                            document.getElementById("search_hits").innerHTML = "Hits: " + hits;
                            if(hits == 0) alert("Your search was not successful, sorry!");
                            already_searched = document.getElementById("search_box").value;
                            //return false;
                        }
                        else
                        {
                            if(document.getElementById("widgets"))
                            {
                                for(var x = 0; document.getElementsByName("viewheadername")[x]; x++)
                                {
                                    document.getElementsByName("viewheadername")[x].style.background = "#34495e";
                                }
                            }

                            else if(document.getElementById("hiddennodes"))
                            {
                                for(var x = 0; document.getElementsByName("viewheadername")[x]; x++)
                                {
                                    document.getElementsByName("viewheadername")[x].style.background = "#34495e";
                                }
                            }

                            else if(document.getElementById("hiddenalo"))
                            {
                                for(var x = 0; document.getElementsByName("header")[x]; x++)
                                {
                                    document.getElementsByName("header")[x].style.background = "#34495e";
                                }
                            }

                            hits = 0;
                            document.getElementById("search_hits").innerHTML = "Hits: " + hits;
                            already_searched = "";
                            alert("Your search was not successful, sorry!");
                            return false;
                        }
                    }

                    if(document.getElementById("widgets"))
                    {
                        for(now_node; document.getElementsByName("viewheadername")[now_node]; now_node++)
                        {
                            if(document.getElementsByName("viewheadername")[now_node].style.background == "rgb(52, 152, 219)" || document.getElementsByName("viewheadername")[now_node].style.backgroundColor == "rgb(52, 152, 219)")
                            {
                                element = document.getElementsByName("viewheadername")[now_node];
                                tmp = getPosition(element);
                                window.scrollTo(0,tmp.y);
                                now_node = now_node + 1;
                                return;
                            }
                        }
                        now_node = 0;
                        alert("Du bist am Ende der Suche angekommen!");
                    }

                    else if(document.getElementById("hiddennodes"))
                    {
                        for(now_node; document.getElementsByName("viewheadername")[now_node]; now_node++)
                        {
                            if(document.getElementsByName("viewheadername")[now_node].style.background == "rgb(52, 152, 219)" || document.getElementsByName("viewheadername")[now_node].style.backgroundColor == "rgb(52, 152, 219)")
                            {
                                element = document.getElementsByName("viewheadername")[now_node];
                                tmp = getPosition(element);
                                window.scrollTo(0,tmp.y);
                                now_node = now_node + 1;
                                return;
                            }
                        }
                        now_node = 0;
                        alert("Du bist am Ende der Suche angekommen!");
                    }

                    else if(document.getElementById("hiddenalo"))
                    {
                        for(now_node; document.getElementsByName("header")[now_node]; now_node++)
                        {
                            if(document.getElementsByName("header")[now_node].style.background == "rgb(52, 152, 219)" || document.getElementsByName("header")[now_node].style.backgroundColor == "rgb(52, 152, 219)")
                            {
                                element = document.getElementsByName("header")[now_node];
                                tmp = getPosition(element);
                                window.scrollTo(0,tmp.y);
                                now_node = now_node + 1;
                                return;
                            }
                        }
                        now_node = 0;
                        alert("Du bist am Ende der Suche angekommen!");
                    }
                }
            }


            //Now we create a container for our toolbar
            scene = document.createElement("div");
            scene.setAttribute('id', 'scene_graph_infos');

            //The next seven lines of code 'stitching' the created elements to the Webtool (first the our container "scene" to a div in the code with the id "container_for_load_and_save_tree_for_widget", then the remaining elements to our container "scene"
            document.getElementById("container_for_load_and_save_tree_for_widget").appendChild(scene);

            if(document.getElementById("hiddennodes"))
            {
                nodenumber = document.createElement("div");
                nodenumber.setAttribute('id', 'node_number');
                document.getElementById("scene_graph_infos").appendChild(nodenumber);
                var nodecount = document.getElementById("hiddennodes").value;
                document.getElementById("node_number").innerHTML = "Total # of Nodes: " + nodecount;

                var check = document.createElement("div");
                check.setAttribute('id', 'check_widgets');
                document.getElementById("scene_graph_infos").appendChild(check);
                document.getElementById("check_widgets").innerHTML = "Widget Check";
                document.getElementById("check_widgets").style.textAlign = "center";
                document.getElementById("check_widgets").style.lineHeight = "39px";
                document.getElementById("check_widgets").style.marginTop = "190px";

                check.onclick = function()
                {
                    widgetExists();
                }
                check.setAttribute("onclick", "widgetExists()");
            }

            else if(document.getElementsByName("viewheadername")[0])
            {
                widgetnumber = document.createElement("div");
                widgetnumber.setAttribute('id', 'widget_number');
                document.getElementById("scene_graph_infos").appendChild(widgetnumber);
                //Because we don't have the total number of Widgets, we need to count them via a function (for more details see the function)
                var widgetcount = getNumberOfWidgets();
                document.getElementById("widget_number").innerHTML = "Total # of Widgets: " + widgetcount;
            }

            document.getElementById("scene_graph_infos").appendChild(save);
            document.getElementById("scene_graph_infos").appendChild(load);
            document.getElementById("scene_graph_infos").appendChild(searchbox);
            document.getElementById("scene_graph_infos").appendChild(searchhits);
            document.getElementById("scene_graph_infos").appendChild(foldallcontainer);


            document.getElementById("save_the_tree").innerHTML = "Save Tree";
            document.getElementById("load_the_tree").innerHTML = "Load Tree";
            document.getElementById("save_the_tree").style.textAlign = "center";
            document.getElementById("load_the_tree").style.textAlign = "center";
            document.getElementById("save_the_tree").style.lineHeight = "39px";
            document.getElementById("load_the_tree").style.lineHeight = "39px";
            document.getElementById("save_the_tree").style.marginTop = "30px";
            document.getElementById("load_the_tree").style.marginTop = "79px";
            document.getElementById("foldallcontainer").innerHTML = "Fold All";
            document.getElementById("foldallcontainer").style.textAlign = "center";
            if(document.getElementById("hiddennodes"))
            {
                document.getElementById("foldallcontainer").style.marginTop = "73px";
            }

        }


    /*-------------------------------------------------------GETNUMBEROFWIDGETS()---------------------------------------------------------------*/


        function getNumberOfWidgets()
        {
            var x = 0;
            var howmanywidgets = 0;
            //document.getElementsByName("viewheadername")[x] delivers the first element of the page with the name "layourrootnodename" which represents in this case the Widgets; as long as there are some, we increase our counting variable; in the end "howmanywidgets" holds the total number of widgets
            while(document.getElementsByName("viewheadername")[x])
            {
                howmanywidgets++;
                x++;
            }

            return howmanywidgets;
        }


        /*-------------------------------------------------------WIDGETEXISTS()---------------------------------------------------------------*/


        function widgetExists()
        {
            //If we're not using the "SceneGraph"-Webtool (identified by the appearance of hiddennodes) this is ireelevant to us and we stop
            if(!document.getElementById("hiddennodes"))
            {
                return;
            }
            else
            {
                //But if we're using the "SceneGraph"-Webtool, we call overlay, which activates the loading animation and darkens the screen to avoid clicking (which causes new requests to the server), and starting the widgetExistsSend-function (short: this checks if a node has a widget or not)
                overlay("display");
                setTimeout('widgetExistsSend()',1000);
            }
        }


    /*-------------------------------------------------------WIDGETEXISTSSEND()---------------------------------------------------------------*/


        function widgetExistsSend(knoten)
        {
            //As already seen before, we get the total number of nodes from the hidden input field "hiddennodes"
            var knoten = document.getElementById("hiddennodes").value;

            //After that, we requesting the "Widgets"-Webtool, as a response we get a string with the source code of the site; now we loop through the nodes on the "SceneGraph"-Webtool and check if the id (which is in a pointer) is existent in the source code of widget; true: colorize the text green; false: colorize it red and disable the widget-button; at the end we then call overlay again but this time to brighten the screen again
            $.ajax({
                type: "GET",
                url: "Widgets",
                success: function(data) {
                    data.toString();
                    var i = 0;
                    for(i; i<=knoten; i++)
                    {
                        if(data.match(document.getElementsByName("viewheadername")[i].id) != null)
                        {
                            document.getElementsByName("viewheadername")[i].style.color = '#0ECC71';
                        }
                        else
                        {
                            document.getElementsByName("viewheadername")[i].style.color = '#E74C3C';
                            document.getElementsByClassName("show_widget_button")[i].disabled = true;
                        }
                    }
                    overlay('no');

                }
            });
        }

    /*-------------------------------------------------------OVERLAY()---------------------------------------------------------------*/

        //The overlay need a mode for working; "display" activates it, everyting else cause it to close
        function overlay(mode)
        {
            if(mode == 'display')
            {
                //If the mode is display (=activate the overlay) we create (if not already existent) the elements overlay (darkens the screen) and lightbbox (holds the loading animation)  and pin them to the body of our page
                if(document.getElementById("overlay") === null) {
                    div = document.createElement("div");
                    div.setAttribute('id', 'overlay');
                    div.setAttribute('className', 'overlayBG');
                    div.setAttribute('class', 'overlayBG');
                    document.getElementsByTagName("body")[0].appendChild(div);
                    lightbox = document.createElement("div");
                    lightbox.setAttribute('id', 'lightBox');
                    document.getElementsByTagName("body")[0].appendChild(lightbox);
                }
            } else
            {
                //If we call the function with something else than display, the elements we first created get thrown away
                document.getElementsByTagName("body")[0].removeChild(document.getElementById("overlay"));
                document.getElementsByTagName("body")[0].removeChild(document.getElementById("lightBox"));
            }
        }


    /*-------------------------------------------------------GETSCROLLXY()---------------------------------------------------------------*/


        //This function is responsible for the scrolling of the Navigation and the WidgetCheck-Button; it gets called, if we scroll the page
        function getScrollXY()
        {
            var scrOfX = 0, scrOfY = 0;
            //We are saving the offsets to the variables
            if( typeof( window.pageYOffset ) == 'number' )
            {
                //Netscape compliant
                scrOfY = window.pageYOffset;
                scrOfX = window.pageXOffset;
            }

            else if( document.documentElement && ( document.documentElement.scrollLeft || document.documentElement.scrollTop ) )
            {
                //IE6 standards compliant mode
                scrOfY = document.documentElement.scrollTop;
                scrOfX = document.documentElement.scrollLeft;
            }

            //Check if the divs exist
            if(document.getElementById("scene_graph_infos") && document.getElementById("navbar"))
            {
                //Scroll them by the amount of the Offset
                document.getElementById("scene_graph_infos").style.marginTop = 60 + scrOfY + "px";
                document.getElementById("navbar").style.marginTop = scrOfY + "px";
                document.getElementById("scene_graph_infos").style.marginLeft = -180 + scrOfX + "px";
                document.getElementById("navbar").style.marginLeft = -180 + scrOfX + "px";
            }

            else if(document.getElementById("scene_graph_infos_forW"))
            {
                document.getElementById("scene_graph_infos_forW").style.marginTop = -4700 + scrOfY + "px";
                document.getElementById("navbar").style.marginTop = scrOfY + "px";
            }

            else if(document.getElementById("navbar"))
            {
                document.getElementById("navbar").style.marginTop = scrOfY + "px";
                document.getElementById("navbar").style.marginLeft = -180 + scrOfX + "px";
            }
        }


        /*-------------------------------------------------------POSTMODEL()---------------------------------------------------------------*/


        //These functions are used to send data from the Pop-Up to the Widgets-Site
        function postModel(widgetPointer,inEx) {
            var paramlist = document.getElementById(inEx + widgetPointer);

            //The .serialize() method creates a text string in standard URL-encoded notation; It can act on a jQuery object that has selected individual form controls such as a <form>
            console.log($(paramlist).serialize());

            $.ajax({
                type: "POST",
                url: "Widgets",
                data: $(paramlist).serialize(),
                success: function(data) {
                    if(data=="reload")
                    {
                        alert("Webpage is outdated and will be reloaded after pressing OK. Then you can try again.");
                        location.reload();
                    }
                    else
                    {
                        divpointer = 'div' + widgetPointer;
                        document.getElementById(divpointer).innerHTML = data;
                    }
                }
            });
        }


    /*-------------------------------------------------------MAKEDIRTYAJAXWIDGET()---------------------------------------------------------------*/

        function makeDirtyLayoutAjaxWidget(wPointer) {
            $.ajax({
                type: "POST",
                url: "Widgets",
                data: { pointer: wPointer, makeDirty: true, layoutDirty: true },
                success: function (data) {
                }
            });
        }

        function makeDirtyRenderAjaxWidget(wPointer)
        {
            $.ajax({
                type: "POST",
                url: "Widgets",
                data: {pointer: wPointer, makeDirty: true, renderDirty: true },
                success: function(data) {
                }
            });
        }
        
    /*-------------------------------------------------------OUTPUTAJAXWIDGET()---------------------------------------------------------------*/


        function outputAjaxWidget(pointer)
        {
            var paramlist = document.getElementById('output' + pointer);

            console.log($(paramlist).serialize());

            $.ajax({
                type: "POST",
                url: "Widgets",
                data: $(paramlist).serialize(),
                success: function(data) {

                }
            });
        }


    /*-------------------------------------------------------DEBUGVISUAL()---------------------------------------------------------------*/

        //DebugVisual activates the Debug-Rectangles by sending a request to the server with an object pointer and an arbitrary mode info string
        function debugVisual(targetUrl, wPointer, mode)
        {
            $.ajax({
                type: "POST",
                url: targetUrl,
                data: {pointer: wPointer, debugVisualize: mode},
                success: function(data) {
					if(data=="reload")
					{
						alert("Webpage is outdated and will be reloaded after pressing OK. Then you can switch on the debug visualization again.");
						location.reload();
					}
                }
            });
        }


    /*-------------------------------------------------------EXECTRIGGER()---------------------------------------------------------------*/

        //action: 1=execute, 2=check condition, 3=execute if, 4=execute else
        function execTrigger(widget,trigger,action)
        {
            $.ajax({
                type: "POST",
                url: "Widgets",
                data: {widgetPtr: widget, triggerIndex: trigger, actionID: action},
                success: function(data) {
                    if(data=="reload")
                    {
                        alert("Webpage is outdated and will be reloaded after pressing OK. Then you can make your action again.");
                        location.reload();
                    }
                    if(data=="condition_true")
                    {
                        alert("Condition is true.");
                    }
                    if(data=="condition_false")
                    {
                        alert("Condition is false.");
                    }
                }
            });
        }

    /*-------------------------------------------------------SHOWELEMENTSOFSAMEHIERARCHIEFORSG()---------------------------------------------------------------*/

        //This function is called when the "Fold"-button got pressed; its purpose is to show only the elements which are located on the same DOM-level like the one whose button was being pressed
        function showElementsOfSameHierarchieForSG(pointer, numberofnodes)
        {
            //Now we check if the element with the id "pointer" is already folded (checking its background color); the two or-blocks check the same, but the first one is for Googles Chrome and the second one for Mozillas Firefox
            if(document.getElementById(pointer).style.background == "rgb(241, 196, 15)" || document.getElementById(pointer).style.backgroundColor == "rgb(241, 196, 15)")
            {
                //If the clicked element is already folded and got clicked again, we unfold everything by looping through the page and making everything visible again
                for(var x = 0; x < (numberofnodes+1); x++)
                {
                    document.getElementsByName("viewheadername")[x].style.background = "#34495e";
                    document.getElementsByName("viewheadername")[x].style.display = 'inline-block';
                    document.getElementsByName("show_widget_button")[x].style.display = 'inline-block';
                    document.getElementsByName("show_hierarchie_button")[x].style.display = 'inline-block';
                    document.getElementsByName("fold_single")[x].style.display = 'inline-block';
                    document.getElementsByName("scene_graph_container")[x].style.height = "";
                    document.getElementsByName("show_hierarchie_button")[x].value = "Fold";
                    document.getElementsByName("debug_visualization_t")[x].style.display = 'inline-block';
                    document.getElementsByName("debug_visualization_d")[x].style.display = 'inline-block';
                }
            }

            else
            {
                //The else-case is triggered if the button was not pressed before; first we need to find the number of our clicked element in the DOM --> looping through every element and checking if its id == pointer --> if so, then we save the number
                for(var x = 0; x < (numberofnodes+1); x++)
                {
                    if(document.getElementsByName("viewheadername")[x].id == pointer)
                    {
                        var saveNodeNumber = x;
                    }
                }

                //in i we now have the number of the element in the DOM
                var i = saveNodeNumber;

                document.getElementsByName("show_hierarchie_button")[i].value = "Unfold";

                var hindex = 0;

                //The next step is to find the index of our element - this means how deep is it in the DOM; therefore we loop from our element with the help of our variable "i" until we reach the body-tag
                var tag = document.getElementsByName("viewheadername")[i];
                while(tag.tagName.toUpperCase() != 'BODY')
                {
                    var tmp = tag.parentNode;
                    tag = tmp;
                    hindex++;
                }

                //This loop is getting the index of every element with the names of "viewheadername" or "scene_graph_container" and compares them to the index of our initial element
                for(var y = 0; y < (numberofnodes+1); y++)
                {
                    document.getElementsByName("sg_table")[y].style.display = 'none';
                    var newtag = document.getElementsByName("viewheadername")[y];
                    var newindex = 0;
                    while(newtag.tagName.toUpperCase() != 'BODY')
                    {
                        var newtmp = newtag.parentNode;
                        newtag = newtmp;
                        newindex++;
                    }

                    //If an element has the same index like our initial element, then we change is background color to show, that it is on the same level in the DOM
                    if(newindex == hindex)
                    {
                        document.getElementsByName("viewheadername")[y].style.background = '#F1C40F';
                        document.getElementsByName("show_hierarchie_button")[y].value = "Unfold";
                    }

                    //The index of the other element is higher than the one of our initial element means, that it is deeper in the DOM, which means on a deeper level (nested in our initial element); if this is the case we blend it out as well as its buttons
                    else if(newindex > hindex)
                    {
                        document.getElementsByName("viewheadername")[y].style.display = 'none';
                        document.getElementsByName("show_hierarchie_button")[y].style.display = 'none';
                        document.getElementsByName("show_widget_button")[y].style.display = 'none';
                        document.getElementsByName("fold_single")[y].style.display = 'none';
                        document.getElementsByName("sg_table")[y].style.display = 'none';
                        document.getElementsByName("scene_graph_container")[y].style.height = 0;
                        document.getElementsByName("debug_visualization_t")[y].style.display = 'none';
                        document.getElementsByName("debug_visualization_d")[y].style.display = 'none';
                    }

                    newindex = 0;
                }

            }

        }


    /*-------------------------------------------------------SHOWELEMENTSOFSAMEHIERARCHIEFORW()---------------------------------------------------------------*/


        //This function is almost identical to its counterpart for the SceneGraph, except for some variable names and the fact, that we don't submit the total number of widgets (like we did with the number of nodes) but getting this number by counting the widgets
        function showElementsOfSameHierarchieForW(pointer)
        {
            var layoutrootnodes = document.getElementsByName("viewheadername"); 
            var howmanywidgets = layoutrootnodes.length;

            if(document.getElementById(pointer).style.background == "rgb(241, 196, 15)" || document.getElementById(pointer).style.backgroundColor == "rgb(241, 196, 15)")
            {	//expand
                for(var x = 0; x < howmanywidgets; x++)
                {
                    layoutrootnodes[x].style.background = "#34495e";
                    layoutrootnodes[x].style.display = 'inline-block';
                    document.getElementsByName("show_node_button")[x].style.display = 'inline-block';
                    document.getElementsByName("show_hierarchie_button")[x].style.display = 'inline-block';
                    document.getElementsByName("debug_visualization_t")[x].style.display = 'inline-block';
                    document.getElementsByName("debug_visualization_d")[x].style.display = 'inline-block';
                    document.getElementsByName("debug_visualization_o")[x].style.display = 'inline-block';
                    document.getElementsByName("fold_single")[x].style.display = 'inline-block';
                    document.getElementsByName("show_hierarchie_button")[x].value = "Fold";
                }
            }
            else
            {	//collapse
                var saveNodeNumber = 0;
                for(var x = 0; x < howmanywidgets; x++)
                {
                    if(layoutrootnodes[x].id == pointer)
                    {
                        saveNodeNumber = x;
                    }
                }

                var hindex = 0;
                var tag = layoutrootnodes[saveNodeNumber];
                while(tag.tagName.toUpperCase() != 'BODY')
                {
                    var tmp = tag.parentNode;
                    tag = tmp;
                    hindex++;
                }

                for(var y = 0; y < howmanywidgets; y++)
                {
                    document.getElementsByName("w_table")[y].style.display = 'none';
                    var newtag = layoutrootnodes[y];
                    var newindex = 0;
                    while(newtag.tagName.toUpperCase() != 'BODY')
                    {
                        var newtmp = newtag.parentNode;
                        newtag = newtmp;
                        newindex++;
                    }

                    if(newindex == hindex)
                    {
                        layoutrootnodes[y].style.background = '#F1C40F';
                        document.getElementsByName("show_hierarchie_button")[y].value = "Unfold";
                    }
                    else if(newindex > hindex)
                    {
                        layoutrootnodes[y].style.display = 'none';
                        document.getElementsByName("show_hierarchie_button")[y].style.display = 'none';
                        document.getElementsByName("show_node_button")[y].style.display = 'none';
                        document.getElementsByName("debug_visualization_t")[y].style.display = 'none';
                        document.getElementsByName("debug_visualization_d")[y].style.display = 'none';
                        document.getElementsByName("debug_visualization_o")[y].style.display = 'none';
                        document.getElementsByName("fold_single")[y].style.display = 'none';
                        document.getElementsByName("w_table")[y].style.display = 'none';
                    }
                }
            }

        }

    /*-------------------------------------------------------SHOWELEMENTSOFSAMEHIERARCHIEFORALO()---------------------------------------------------------------*/

    function showElementsOfSameHierarchieForALO(pointer)
    {
        var x = 0;
        var howmanyobjects = 0;
        while(document.getElementsByName("header")[x])
        {
            howmanyobjects++;
            x++;
        }

        console.log("How many Objects are on the site: " + howmanyobjects);

        if(document.getElementById("div_"+pointer).style.background == "rgb(241, 196, 15)" || document.getElementById("div_"+pointer).style.backgroundColor == "rgb(241, 196, 15)")
        {
            for(var x = 0; x < (howmanyobjects); x++)
            {
                document.getElementsByName("header")[x].style.background = "#34495e";
                document.getElementsByName("header")[x].style.display = "inline-block";
                document.getElementsByName("show_hierarchie_button")[x].style.display = "inline-block";
                document.getElementsByName("show_hierarchie_button")[x].value = "Fold";
                document.getElementsByName("fold_single")[x].style.display = 'inline-block';
                document.getElementsByName("alocontainer")[x].style.height = "";
            }
        }

        else
        {
            console.log("else-case");
            for(var x = 0; x < howmanyobjects; x++)
            {
                if(document.getElementsByName("header")[x].id == "div_"+pointer)
                {
                    var saveNodeNumber = x;
                    console.log("x: " + x);
                }
            }

            var i = saveNodeNumber;
            var hindex = 0;

            console.log("Vor Tag Variable");

            var tag = document.getElementsByName("header")[i];
            while(tag.tagName.toUpperCase() != 'BODY')
            {
                var tmp = tag.parentNode;
                tag = tmp;
                hindex++;
            }

            for(var y = 0; y < howmanyobjects; y++)
            {
                document.getElementsByName("alotable")[y].style.display = 'none';
                var newtag = document.getElementsByName("header")[y];
                var newindex = 0;
                while(newtag.tagName.toUpperCase() != 'BODY')
                {
                    var newtmp = newtag.parentNode;
                    newtag = newtmp;
                    newindex++;
                }

                console.log("hindex: " + hindex);
                console.log("newindex: " + newindex);

                if(newindex == hindex)
                {
                    console.log("Treffer");
                    document.getElementsByName("header")[y].style.background = '#F1C40F';
                    document.getElementsByName("show_hierarchie_button")[y].value = "Unfold";
                }

                else if(newindex > hindex)
                {
                    document.getElementsByName("header")[y].style.display = 'none';
                    document.getElementsByName("show_hierarchie_button")[y].style.display = "none";
                    document.getElementsByName("alocontainer")[y].style.height = 0;
                    document.getElementsByName("fold_single")[y].style.display = 'none';
                    document.getElementsByName("alotable")[y].style.display = 'none';
                }

                newindex = 0;
            }
        }

    }

    /*-------------------------------------------------------GETNODEELEMENTS()---------------------------------------------------------------*/

        //GetNodeElements is used, like the name already says, to get the elements (or the information) from a node and displays it
        function getNodeElements(pointer)
        {
            var tablepointer = 'table' + pointer;
            //If the block with information is not already shown and there is no overlay right now, we create one as well as a lightbox and pin them to the body
            if(document.getElementById("overlay") === null && document.getElementById(tablepointer).style.display != 'block')
            {
                div = document.createElement("div");
                div.setAttribute('id', 'overlay');
                div.setAttribute('className', 'overlayBG');
                div.setAttribute('class', 'overlayBG');
                document.getElementsByTagName("body")[0].appendChild(div);
                lightbox = document.createElement("div");
                lightbox.setAttribute('id', 'lightBox');
                document.getElementsByTagName("body")[0].appendChild(lightbox);

                //While we wait for the request the overlay is still shown, so no other request can be send, which otherwise could cause some problems with the server; the data sends a string back, which we split at a specific position (here at "Trenner"); after that, we fill the information container ("tablepointer") with the new data and call showHide() which toggles the display property to block; last but not least we remove the overlay-elements again
                $.ajax({
                    type: "GET",
                    url: "SceneGraph/node/" + pointer,
                    success: function(data) {
                        if(data=="reload")
                        {
                            alert("Webpage is outdated and will be reloaded after pressing OK. Then you can open the detail view again.");
                            location.reload();
                        }
                        else
                        {
                            tablepointer = 'table' + pointer;
                            document.getElementById(tablepointer).innerHTML = data;
                            showHide(tablepointer);
                            document.getElementsByTagName("body")[0].removeChild(document.getElementById("overlay"));
                            document.getElementsByTagName("body")[0].removeChild(document.getElementById("lightBox"));
                        }
                    }
                });
            }
            else showHide(tablepointer);
        }


  /*-------------------------------------------------------GETWIDGETINFORMATION()---------------------------------------------------------------*/


     function getWidgetInformation(pointer,widgetpointer)
      {
          if(widgetpointer == 0)
          {
              widgetpointer = document.getElementById(pointer).wp;
          }
          var divpointer = "div" + widgetpointer;
          var cutpointer = "<!--cut" + pointer + "-->";
          console.log(divpointer);
          console.log(document.getElementById(divpointer));

          //If the block with information is not already shown and there is no overlay right now, we create one as well as a lightbox and pin them to the body
          if(document.getElementById("overlay") === null && document.getElementById(divpointer).style.display != 'block')
          {
              div = document.createElement("div");
              div.setAttribute('id', 'overlay');
              div.setAttribute('className', 'overlayBG');
              div.setAttribute('class', 'overlayBG');
              document.getElementsByTagName("body")[0].appendChild(div);
              lightbox = document.createElement("div");
              lightbox.setAttribute('id', 'lightBox');
              document.getElementsByTagName("body")[0].appendChild(lightbox);

              //While we wait for the request the overlay is still shown, so no other request can be send, which otherwise could cause some problems with the server; the data sends a string back, which we split at a specific position (here at "Trenner"); after that, we fill the information container ("tablepointer") with the new data and call showHide() which toggles the display property to block; last but not least we remove the overlay-elements again
              $.ajax({
                type: "GET",
                url: "/Widgets/widget/" + widgetpointer,
                success: function(data) {
                    if(data=="reload")
                    {
                        alert("Webpage is outdated and will be reloaded after pressing OK. Then you can open the detail view again.");
                        location.reload();
                    }
                    else
                    {
                        divpointer = 'div' + widgetpointer;
                        document.getElementById(divpointer).innerHTML = data;
                        showHide(divpointer);
                        document.getElementsByTagName("body")[0].removeChild(document.getElementById("overlay"));
                        document.getElementsByTagName("body")[0].removeChild(document.getElementById("lightBox"));
                        highlightParamIntern();
                    }
                }
              });
          }
          else showHide(divpointer);
      }

    /*-------------------------------------------------------HIGHLIGHTPARAM()---------------------------------------------------------------*/

        var highlightParamWidgetPointer;
        var highlightParamExOrIn;
        var highlightParamName;
        var originalParamBackgroundColor;
        var oldHighlightedParam;

        function highlightParam(pointer,widgetpointer,exorin,paramname)
        {
            highlightParamWidgetPointer = widgetpointer;
            highlightParamExOrIn = exorin;
            highlightParamName = paramname;
            if(document.getElementById(highlightParamWidgetPointer + highlightParamExOrIn + highlightParamName) == null)
            {
                getWidgetInformation(pointer,widgetpointer);
            }
            else
            {
                highlightParamIntern();
            }

        }

        function highlightParamIntern()
        {
            if(highlightParamName != null)
            {
                if(oldHighlightedParam != null)
                {
                    oldHighlightedParam.style.backgroundColor = originalParamBackgroundColor;
                }
                var node = document.getElementById(highlightParamWidgetPointer + highlightParamExOrIn + highlightParamName);
                originalParamBackgroundColor = node.style.backgroundColor;
                node.style.backgroundColor = "#FFFF00";
                oldHighlightedParam = node;
            }
        }

    /*-------------------------------------------------------FOLDSINGLENODE()---------------------------------------------------------------*/


        var indexarray = new Array();

        //foldSingleNode is used if some elements are folded with the "Fold"-button and you want to fold out only one element after another; again we have to almost identical versions for the "SceneGraph"- and the "Widgets"-Webtools
        function foldSingleNode(pointer, numberofnodes) {

            //Saving every DOM-Index for every Node in an array
            for(var x = 0; (x < numberofnodes); x++)
            {
                var indexcount = 0;
                var tag = document.getElementsByName("viewheadername")[x];
                //if (!tag) alert("Error x="+x);

                while(tag.tagName.toUpperCase() != 'BODY')
                {
                    var tmp = tag.parentNode;
                    tag = tmp;
                    if(tag.tagName.toUpperCase() == 'LI') indexcount++;
                }
                indexarray[x] = indexcount;
            }

            //If the function is called with 0 as pointer, we have the special case mentioned in WrapperFunction; we first save every index of every node in an array; after that we're looping through this new array and check if the index at a specific is larger than its successor - true: then disable the "+"-button, because there is no element after this one to fold out
            if(pointer == 0)
            {
                //Looping through the Array to disable the buttons that are at the end of a branch (if a number in the array is followed by a lower number, then it's the last of the branch)

                for(var z = 0; z < indexarray.length; z++)
                {
                    //document.getElementsByName("fold_single")[z].value = z;

                    if(z==indexarray.length-1 || indexarray[z] >= indexarray[z+1])
                    {
                        document.getElementsByName("fold_single")[z].disabled = true;
                        document.getElementsByName("fold_single")[z].style.background = 'grey';
                        document.getElementsByName("fold_single")[z].style.backgroundColor = 'grey';
                    }
                    else
                    {
                        document.getElementsByName("fold_single")[z].disabled = false;
                    }
                }
            }

            //The else-case is true, when we call foldSingleNode with a legit pointer
            else
            {
                //Which number has the clicked node
                for(var x = 0; x < (numberofnodes); x++)
                {
                    if(document.getElementsByName("viewheadername")[x].id == pointer)
                    {
                        var saveNodeNumber = x;
                    }
                }
                var i = saveNodeNumber;


                //Finding the DOM-Index of the clicked element
                var hindex = 0;
                var tag = document.getElementsByName("viewheadername")[i];
                while(tag.tagName.toUpperCase() != 'BODY')
                {
                    var tmp = tag.parentNode;
                    tag = tmp;
                    if(tag.tagName.toUpperCase() == 'LI') hindex++;
                }

                //Looping through the Array to disable the buttons that are at the end of a branch (if a number in the array is followed by a lower number, then it's the last of the branch)
                for(var z = 0; z < indexarray.length; z++)
                {
                    //document.getElementsByName("fold_single")[z].value = indexarray[z];

                    if (z == indexarray.length - 1 || indexarray[z] >= indexarray[z + 1])
                    {
                        document.getElementsByName("fold_single")[z].disabled = true;
                        document.getElementsByName("fold_single")[z].style.background = 'grey';
                        document.getElementsByName("fold_single")[z].style.backgroundColor = 'grey';
                    }
                    else
                    {
                        document.getElementsByName("fold_single")[z].disabled = false;
                    }
                }

                var checkindex = indexarray[i+1];

                //Start a loop from the Node we clicked; first we check if the index of our initial element (the one whose "+"-button has been pressed) ist not the same index as the one of its successor in the array and if it's bigger --> this means: the next element in the array is not on the same level and on a lower level as our initial element
                for(i; i < (numberofnodes); i++)
                {
                    if(indexarray[i+1] > hindex)
                    {
                        if(indexarray[i+1] == checkindex && document.getElementsByName("viewheadername")[i+1].style.display != 'inline-block')
                        {
                            document.getElementsByName("viewheadername")[i+1].style.display = 'inline-block';
                            document.getElementsByName("show_widget_button")[i+1].style.display = 'inline-block';
                            document.getElementsByName("show_hierarchie_button")[i+1].style.display = 'inline-block';
                            document.getElementsByName("fold_single")[i+1].style.display = 'inline-block';
                            document.getElementsByName("debug_visualization_t")[i+1].style.display = 'inline-block';
                            document.getElementsByName("debug_visualization_d")[i+1].style.display = 'inline-block';
                            document.getElementsByName("debug_visualization_o")[i+1].style.display = 'inline-block';
                            document.getElementsByName("scene_graph_container")[i+1].style.height = "";
                        }
                        else
                        {
                            document.getElementsByName("viewheadername")[i+1].style.display = 'none';
                            document.getElementsByName("show_widget_button")[i+1].style.display = 'none';
                            document.getElementsByName("show_hierarchie_button")[i+1].style.display = 'none';
                            document.getElementsByName("fold_single")[i+1].style.display = 'none';
                            document.getElementsByName("debug_visualization_t")[i+1].style.display = 'none';
                            document.getElementsByName("debug_visualization_d")[i+1].style.display = 'none';
                            document.getElementsByName("debug_visualization_o")[i+1].style.display = 'none';
                            document.getElementsByName("scene_graph_container")[i+1].style.height = "0px";
                            document.getElementsByName("sg_table")[i+1].style.display = 'none';

                            already_searched = "";
                        }
                    }
                    else return;
                }
            }
        }


    /*-------------------------------------------------------FOLDSINGLENODEFORAW()---------------------------------------------------------------*/


    var indexarrayForAW = new Array();
    var stopperForAW = 1;

    function hideElement(node)
    {
        if(node)
        {
            node.style.display = 'none';
        }
    }
    function showElement(node)
    {
        if (node)
        {
            node.style.display = 'inline-block';
        }
    }

    // foldSingleNode for active layout objects and widgets
    //For a detailed description of the process in this function check foldSingleNode(); these two function are almost identical again, only some variable names changed and we had to determine the total number of widgets again
    function foldSingleNodeForAW(pointer) {

        if(pointer == 0)
        {
            var x = 0;
            var howmanyitems = 0;
            while(document.getElementsByName("viewheadername")[x])
            {
                howmanyitems++;
                x++;
            }

            //Saving every DOM-Index for every Node in an array

            for(var x = 0; (x < howmanyitems); x++)
            {
                var indexcount = 0;
                var tag = document.getElementsByName("viewheadername")[x];
                while(tag.tagName.toUpperCase() != 'BODY')
                {
                    var tmp = tag.parentNode;
                    tag = tmp;
                    indexcount++;
                }
                indexarrayForAW[x] = indexcount;
            }


            //Looping through the Array to disable the buttons that are at the end of a branch (if a number in the array is followed by a lower number, then it's the last of the branch)
            for (var z = 0; z < indexarrayForAW.length; z++)
            {
                if (z == indexarrayForAW.length-1 || indexarrayForAW[z] >= indexarrayForAW[z + 1])
                {
                    document.getElementsByName("fold_single")[z].disabled = true;
                    document.getElementsByName("fold_single")[z].style.background = 'grey';
                    document.getElementsByName("fold_single")[z].style.backgroundColor = 'grey';
                }
                else
                {
                    document.getElementsByName("fold_single")[z].disabled = false;
                }
            }
        }

        else
        {
            var x = 0;
            var howmanyitems = 0;
            while(document.getElementsByName("viewheadername")[x])
            {
                howmanyitems++;
                x++;
            }

            //Which number has the clicked node
            for(var x = 0; x < (howmanyitems); x++)
            {
                if(document.getElementsByName("viewheadername")[x].id == pointer)
                {
                    var saveNodeNumber = x;
                }
            }
            //alert(pointer);
            //alert(saveNodeNumber);
            var i = saveNodeNumber;


            //Finding the DOM-Index of the clicked element
            var hindex = 0;
            var tag = document.getElementsByName("viewheadername")[i];
            while(tag.tagName.toUpperCase() != 'BODY')
            {
                var tmp = tag.parentNode;
                tag = tmp;
                hindex++;
            }

            //Right now we have:
            //  - NodeNumber
            //  - DOM-Index


            //Saving every DOM-Index for every Node in an array
            if(stopperForAW == 1)
            {
                for(var x = 0; (x < howmanyitems); x++)
                {
                    var indexcount = 0;
                    var tag = document.getElementsByName("viewheadername")[x];
                    while(tag.tagName.toUpperCase() != 'BODY')
                    {
                        var tmp = tag.parentNode;
                        tag = tmp;
                        indexcount++;
                    }
                    indexarrayForAW[x] = indexcount;
                }
            }

            //Looping through the Array to disable the buttons that are at the end of a branch (if a number in the array is followed by a lower number, then it's the last of the branch)
            if(stopperForAW == 1)
            {
                for (var z = 0; z < indexarrayForAW.length; z++)
                {
                    if (z == indexarrayForAW.length - 1 || indexarrayForAW[z] >= indexarrayForAW[z + 1])
                    {
                        document.getElementsByName("fold_single")[z].disabled = true;
                        document.getElementsByName("fold_single")[z].style.background = 'grey';
                        document.getElementsByName("fold_single")[z].style.backgroundColor = 'grey';
                    }
                    else
                    {
                        document.getElementsByName("fold_single")[z].disabled = false;
                    }
                }
                stopperForAW = 0;
            }

            var checkindex = indexarrayForAW[i + 1];

            console.log(hindex);

            //Start a loop from the Node we clicked
            for(i; i < (howmanyitems); i++)
            {
                //document.getElementsByName("w_table")[i].style.display = 'none';
                if (indexarrayForAW[i + 1] > hindex)
                {
                    if (indexarrayForAW[i + 1] == checkindex && document.getElementsByName("viewheadername")[i + 1].style.display != 'inline-block')
                    {
                        /*console.log(checkindex);
                        console.log(indexarrayForAW[i + 1]);
                        console.log(document.getElementsByName("viewheadername")[i + 1].style.display);*/

                        showElement(document.getElementsByName("viewheadername")[i + 1]);
                        showElement(document.getElementsByName("show_node_button")[i + 1]);
                        showElement(document.getElementsByName("show_hierarchie_button")[i + 1]);
                        showElement(document.getElementsByName("debug_visualization_t")[i + 1]);
                        showElement(document.getElementsByName("debug_visualization_d")[i + 1]);
                        showElement(document.getElementsByName("debug_visualization_o")[i + 1]);
                        showElement(document.getElementsByName("fold_single")[i + 1]);
                        showElement(document.getElementsByName("alocontainer")[i + 1]);
                    }
                    else
                    {
                        hideElement(document.getElementsByName("viewheadername")[i+1]);
                        hideElement(document.getElementsByName("show_node_button")[i+1]);
                        hideElement(document.getElementsByName("show_hierarchie_button")[i+1]);
                        hideElement(document.getElementsByName("debug_visualization_t")[i+1]);
                        hideElement(document.getElementsByName("debug_visualization_d")[i+1]);
                        hideElement(document.getElementsByName("debug_visualization_o")[i + 1]);
                        hideElement(document.getElementsByName("fold_single")[i + 1]);
                        hideElement(document.getElementsByName("alocontainer")[i + 1]);
                        hideElement(document.getElementsByName("w_table")[i]);
                        hideElement(document.getElementsByName("alotable")[i]);

                        already_searched = "";
                    }
                }
                else return;
            }
        }
    }


    /*-------------------------------------------------------SAVETHETREES()---------------------------------------------------------------*/


    var treesaver;

    //saveTheTree is pretty simple - if the button is pressed, the whole code between the body tags gets saved in a variable
    function saveTheTrees()
    {
        treesaver = document.getElementById("body").innerHTML;
        console.log(treesaver);
    }


    /*-------------------------------------------------------LOADTHETREES()---------------------------------------------------------------*/

        //loadTheTree is pretty simple too - if you press the loadbutton the code previously saved in the variable is set as new code for the body
        function loadTheTrees()
        {
            if(treesaver != null)
            {
                document.getElementById("body").innerHTML = treesaver;
            }
            else alert("Es wurde kein gespeicherter Baum gefunden!");
        }


    /*-------------------------------------------------------PARAMKEYPRESS()---------------------------------------------------------------*/


        //paramKeyPress can detect if the Enter-key was pressed (keyCode == 13); if this is true, we send an ajax request with the parameters - if this request was succesful the input field is colorized green as feedback for the user
        function paramKeyPress(value, keycode, key, index, inOrEx, widgetPointer)
        {
            if (keycode == 13)
            {
                $.ajax({
                    type: "POST",
                    url: "Widgets",
                    data: { paramKey0: key, paramValue0: value, paramModelType: inOrEx, index: index, pointer: widgetPointer },
                    success: function (data) {
                        if (data == "reload") {
                            alert("Webpage is outdated and will be reloaded after pressing OK. Then you can open the detail view again.");
                            location.reload();
                        }
                        else {
                            divpointer = 'div' + widgetPointer;
                            document.getElementById(divpointer).innerHTML = data;
                        }
                        /*if (inOrEx == 'internal') //who needs this?
                        {
                            document.getElementById(key + "_" + index + "_" + widgetPointer + "_internal").style.background = "#2ECC71";
                        }
                        else if (inOrEx == 'external')
                        {
                            document.getElementById(key + "_" + index + "_" + widgetPointer + "_external").style.background = "#2ECC71";
                        }*/
                    }
                });
            }
        }


  /*-------------------------------------------------------fillNavigation()---------------------------------------------------------------*/

    function fillNavigation()
    {
        $.ajax({
            type: "POST",
            url: "/",
            success: function(data) {
                console.log(data);
                var datatext = data;
                console.log(datatext);
                var parser = new DOMParser ();
                var doc = parser.parseFromString (datatext, "text/xml");
                for(var x = 1; doc.getElementsByTagName('div')[x]; x++)
                {
                    console.log("In the loop");
                    var listElement = document.createElement("li");
                    listElement.setAttribute("id", "item" + x);
                    var toolLink = document.createElement("a");
                    toolLink.setAttribute("href", "/" + doc.getElementsByTagName('div')[x].firstElementChild.getAttribute("href"));
                    toolLink.setAttribute("class", "navi_elements");
                    toolLink.innerHTML = doc.getElementsByTagName('div')[x].firstElementChild.getAttribute("href");
                    listElement.appendChild(toolLink);
                    document.getElementById("navbar").firstElementChild.getElementsByTagName("ul")[0].appendChild(listElement);
                    console.log(document.getElementById("navbar").firstElementChild.getElementsByTagName("ul")[0]);
                }
            }
        });
    }


  /*-------------------------------------------------------FOLDUIOBJECTS()---------------------------------------------------------------*/


    function foldUIObjects(node, nodename)
    {
      var element;
      var parent = node.parentNode;
      for(var x = 0; parent.getElementsByTagName("table")[x]; x++)
      {
          if(parent.getElementsByTagName("table")[x].getAttribute("name") != null)
          {
              if(parent.getElementsByTagName("table")[x].getAttribute("name").toUpperCase() == nodename.toUpperCase())
              {
                  element = parent.getElementsByTagName("table")[x];
              }
          }
      }

      if(element.getElementsByTagName("tr")[2].style.display == 'none')
      {
          element.getElementsByTagName("tr")[2].style.display = 'block';
          element.getElementsByTagName("tr")[3].style.display = 'block';
      }
      else
      {
          element.getElementsByTagName("tr")[2].style.display = 'none';
          element.getElementsByTagName("tr")[3].style.display = 'none';
      }
    }


  /*-------------------------------------------------------FOLDALL()---------------------------------------------------------------*/

  function foldAllElements()
  {
      document.getElementById("contentholder").innerHTML = "";
      var tmpfoldall = foldall.split("<!--splitForFoldAll-->  ",3);
      document.getElementById("contentholder").innerHTML = tmpfoldall[1];
  }

  /*-------------------------------------------------------UPDATEANIMATION()---------------------------------------------------------------*/

  function updateAnimation(animation) {
      var interpolator = document.getElementById("interpolator_" + animation).value;
      var duration = document.getElementById("duration_" + animation).value;

      //alert(interpolator);
      //alert(duration);

      $.ajax({
          type: "POST",
          url: "/Widgets",
          data: { animation: animation, interpolator: interpolator, duration: duration },
          success: function (data) {
              if (data == "reload") {
                  alert("Webpage is outdated. You will be redirected to the widget tree after pressing OK. Then you can go to the animations again.");
                  window.location.href = '/Widgets';
              }
          }
      });
  }

  /*-------------------------------------------------------SEARCHSHADER()---------------------------------------------------------------*/

  function searchShader(s)
  {
      var combobox = document.getElementById("selectShader");
      for (var x = 0; x < combobox.options.length; x++)
      {
          if (combobox.options[x].text.toLowerCase().indexOf(s.toLowerCase()) >= 0)
          {
              combobox.selectedIndex = x;
              return;
          }
      }
  }

/*-------------------------------------------------------SEARCHSHADERKEYDOWN()---------------------------------------------------------------*/

  function searchShaderKeyDown(event)
  {
      if (event.keyCode == 13)
      {
          document.getElementById("shaders_id").submit();
      }
  }
