var journalineAppVersion = "2.7";
Config.appIdentifier = 'journaline';
Config.startPanelUrl = 'http://127.0.0.1/journaline/0.xml?0';
Config.geocoderEnabled = false;
var urlPrefix = 'http://127.0.0.1/journaline/';
var objectId = '0';
var refreshTime = "0";
var retryTime = "5000";
var refreshContent = false;
var objectType;
var suffix;
var successCount = 0;
var timer;
var hotButtonMenuActiv = false;
var req = false; // Request helper
var currentResponse;
var variant = "NBT";
var hmiPlugin;

/* use this tooltips if the translation file couldn't be loaded or language is unknown*/
var i18nFallback = { 
		"locale" : "en_UK",
		"pageTitle" : "Journaline",
		"scrollUp" : "Scroll up",
		"scrollDown" : "Scroll down",
		"readOut" : "Read out",
		"telCall" : "Phone call"
};

initApp = function() {

	hmiPlugin = document.getElementById("HMIPlugin");
	
	if( hmiPlugin != null)
	{
	   hmiPlugin.addNotificationOnDisplaySize(function(res){
            resizeScreen(res.xSize);
        });
	}
	else
	{
            LOG.error( "Journaline: hmiPlugin is null!" );
	}

	addNBTEventListener();
	EFIHelper.init();
	
	PM.init();
	
	LOG.info('UA: ' + PM.getUserAgent() );
	
	variant = PM.getUserAgent().split(';', 1)[0].split('(', 2)[1];
	
	if( variant == 'NBT_RSE')
	{
	   Config.startPanelUrl = 'http://160.48.199.119/journaline/0.xml?0';
	   urlPrefix = 'http://160.48.199.119/journaline/';
	}
	
	I18N.init();
	LOG.info( 'Init complete. journalineApp.js ver: ' + journalineAppVersion + '. Variant: ' + variant );
	
	var newCursorPos = new Cursor.cursorPosition( 0, 0, 0); /* root page */
	Cursor.cursorStack.push(newCursorPos); 
	
	loadContent(Config.startPanelUrl);
}


var generalKeydownHandler = function(evt) {
	var k = evt.keyCode;
	switch (k) {
	case 13: {// enter			
		if(objectType == "menu"){
			if( $('#current').find('.selected').hasClass('inactive') == false ) {	
				refreshContent = false;	
				clearTimeout(timer);

				if( req ){ // cancel current request
					req.abort();
				}	
				Cursor.storePosition();
			}
		} 		
		else if( (objectType == "message") || (objectType == "list") || (objectType == "titleOnly") ) {
			var selected = $('#current').find('.selected');
			if( selected.hasClass('scrollUp') == false && selected.hasClass('scrollDown') == false && selected.hasClass('textToSpeech') == false ) {	
				refreshContent = false;	
				clearTimeout(timer);

				if( req ){ // cancel current request
					req.abort();
				}
				
				if( selected.hasClass('hotButton') == false )
				{
					Cursor.storePosition();
				}
			}
		}
	}
	case 39: // right arrow
		if (!PM.blockUI) {
			PM.execute();
		}
		break;
	case 38: // up arrow
		if (!PM.blockUI) {
			PM.scrollUp();
		}
		break;
	case 40: // down arrow
		if (!PM.blockUI) {
			PM.scrollDown();
		}
		break;
	case 37: // left arrow
		if( req ){ // cancel current request
			req.abort();
		}
	
		PM.back();
		break;
	}
};


var Cursor = {
	selectedId : 0,
	scrollHeight : 0,
	contentStyle : 0,
	cursorStack : new Array(),
	
	cursorPosition : function( selectedId, scrollHeight, contentStyle ) {
		this.selectedId = selectedId;
		this.scrollHeight = scrollHeight;
		this.contentStyle = contentStyle; 
	},
	
	storePosition : function() {	
		if( objectType == "menu" ) 
		{
			var t_selectedId = $('#current').find('.selected').children().attr('id');
			var t_scrollHeight = $('#current ul.content').attr('scrollheight');
			var t_contentStyle = $('#current ul.content').attr('style');
		}	   
		else 
		{
			var t_selectedId = $('#current').find('.toolbar .selected').index();
			var t_scrollHeight = $('#current .content').attr('scrollheight');
			var t_contentStyle = $('#current .content').attr('style');
		}

		var newCursorPos = new Cursor.cursorPosition( t_selectedId, t_scrollHeight, t_contentStyle);
		Cursor.cursorStack.push(newCursorPos);
		LOG.info('Store cursor id: ' + t_selectedId + ' scrollHeight: ' + t_scrollHeight + ' contentStyle: ' + t_contentStyle + ' StackSize: ' + Cursor.cursorStack.length);
	},
	restorePosition : function() {
		var cursorStack = Cursor.cursorStack;
		if(cursorStack.length > 0) {
			Cursor.selectedId = cursorStack[ cursorStack.length-1].selectedId;
			Cursor.scrollHeight = cursorStack[ cursorStack.length-1].scrollHeight;			
			Cursor.contentStyle = cursorStack[ cursorStack.length-1].contentStyle;
		
			LOG.info('Restore cursor id: ' + Cursor.selectedId + ' scrollHeight: ' + Cursor.scrollHeight + ' contentStyle: ' + Cursor.contentStyle + ' StackSize: ' + cursorStack.length);	
			cursorStack.pop();
		}
	},
	checkStack : function() {
		var extrakt = suffix.slice(5);
		var objectIdArray = extrakt.split(",");
		
		/*
		* check if maybe some objects were deleted and reduce the cursor stack appropriate 
		*/
		var cursorStack = Cursor.cursorStack;
		if( cursorStack.length > 0)
		{
			for(var i = cursorStack.length; i >= 0 ; i--)
			{					
				if( cursorStack[i-1].selectedId == objectIdArray[objectIdArray.length-1] )
				{
					break;
				}
				else
				{
					for(var i = 0; i < objectIdArray.length; i++)
					{
						LOG.info('Suffix id ' + i + ':' + objectIdArray[i] );
					}
					
					if( cursorStack.length > 0)
					{
						for(var i = cursorStack.length - 1; i >= 0 ; i--)
						{
							LOG.info('Cursor stack ' + i + ':' + cursorStack[i].selectedId );
						}
					}
					
					cursorStack.pop();
					LOG.info( 'Cursor stack: ' + cursorStack.length );
				}
			}
		}
	}
};


loadContent = function(loadUrl){
    LOG.info('Request Nr. ' + successCount + ': ' + loadUrl );
	req = $.ajax({
		url : loadUrl,
		dataType : 'xml',
		data:'_t=' + PM.now(),
		timeout : Config.ajaxTimeout,
		success : function(xml, textStatus, jqXHR) {
			
			clearTimeout(timer);
			req = null;
			
			
			currentResponse = $(xml).find("journaline");
			objectType = currentResponse.children().prop("nodeName");
			objectId = currentResponse.children().attr("id");
			refreshTime = currentResponse.children().attr("refreshTimeMs");			
			suffix = currentResponse.children().find('suffix').text();

			LOG.info('Response: Nr.:' + successCount + ',objectType: ' + objectType + ',objectId: ' + objectId + ',refreshTime: ' + refreshTime );
			successCount++;

			Cursor.checkStack();
			
			switch (objectType) {
			   case "menu":
			   produceMenu();
			   break;
			   case "message":
			   case "list":
			   case "titleOnly":
			   produceText();
			   break;
			   
			   default:
			   break;
			}			
		},
		error : function(jqXHR) {
			LOG.error('Journaline. Req ret: ' + jqXHR.statusText + " " + jqXHR.status );
			
			if( jqXHR.statusText == "error" )
			{
                setTimeout("loadContent(Config.startPanelUrl)",retryTime);
			}
		}
	});
}


produceMenu = function(){

	if(refreshContent) 
	{
		Cursor.selectedId = $('#current').find('.selected').children().attr('id');
		Cursor.scrollHeight = $('#current ul.content').attr('scrollheight');
		Cursor.contentStyle = $('#current ul.content').attr('style');
	}

	if( $('#current').length )
	{
		$('#current').remove();
	}
	
	var panel = ('<div id="current" class="panel nohistory"><div class="header"><div class="title ">'+currentResponse.find('title').text()+'</div><div class="clear"/></div><div class="contentContainer"><ul class="content">');	
	PM.holder.append(panel);	
	
	var linkNr = 0;
	
	currentResponse.find('menuitem').each(function (index) 
	{
	var isActiv = $(this).attr("activ");
	
	if (isActiv=="n") 
		{
			$('.content').append('<li class="link inactive" onclick=""><div class="limited" id="' +  $(this).find('targetId').text() + '">' + $(this).find('itemlabel').text() +'</div></li>');
		}
		else
		{
			$('.content').append('<li class="link" onclick="loadContent(\'' + urlPrefix + $(this).find('targetId').text() + currentResponse.find('suffix').text() +'\');"><div class="limited" id="' +  $(this).find('targetId').text() + '">' + $(this).find('itemlabel').text() +'</div></li>' );  
		}
		
		if( Cursor.selectedId == $(this).find('targetId').text()) 
		{	
			linkNr = index;
			$('.link').removeClass('selected');
			$('.link').eq(index).addClass('selected');

			$('#current ul.content').attr('scrollheight', Cursor.scrollHeight);
			$('#current ul.content').attr('style', Cursor.contentStyle);
		}
	
	} );
	
	PM.show('current');
	
	LOG.info('Selected menu top: ' + $('#current').find('li.selected').position().top + ' scrollheight: ' +  Cursor.scrollHeight + ' linkNr: ' +  linkNr );
	
	//cursor is not visible
	if( $('#current').find('li.selected').position().top < 0 )
	{	
		if( linkNr )
		{
			LOG.info('Set scrollHeight: '  + (linkNr * Config.scrollHeight - Config.scrollHeight*2));
			PM.visiblePanel.setScrollHeight( linkNr * Config.scrollHeight - (Config.scrollHeight*2)); 
		}
		else
		{
			LOG.info('Sel pos < 0. Set scrollHeight: 0');
			PM.visiblePanel.setScrollHeight(0);
		}
	}
	else if( $('#current').find('li.selected').position().top > ( (Config.scrollHeight * Config.scrollPageRowsCount) - (Config.scrollHeight*2)) )
	{		
		if( linkNr )
		{
			LOG.info('Set scrollHeight: '  + (linkNr * Config.scrollHeight - Config.scrollHeight*2));
			PM.visiblePanel.setScrollHeight( linkNr * Config.scrollHeight - (Config.scrollHeight*2)); 
		}
		else
		{
			LOG.info('Set scrollHeight: 0' );
			PM.visiblePanel.setScrollHeight(0);
		}
	}
	else
	{
	}
	
	if( $('#current').find('li.selected').length < 1  ) //link not available ( deleted? )
	{
		if($('.link').length >= 0 )
		{
		   LOG.info('No selected link found. Set scrollHeight: 0' );
		   $('.link').eq(0).addClass('selected');
		   PM.visiblePanel.setScrollHeight(0);
		}
	}	   
	
	if(objectId == '0')
	{
	   PM.isStartPage = true;
	   PM.setStartPageDisplayed(true);
	}
	else
	{
	   PM.isStartPage = false;
	}
	
	refresh();
}


produceText = function(){
	if(refreshContent ) 
	{
		Cursor.selectedId = $('#current').find('.toolbar .selected').index();
		Cursor.scrollHeight = $('#current .content').attr('scrollheight');
		Cursor.contentStyle = $('#current .content').attr('style');
	}
	else if(hotButtonMenuActiv)
	{
		Cursor.restorePosition();
		hotButtonMenuActiv = false;
	}
	else
	{
		Cursor.selectedId = 0;
		Cursor.scrollHeight = 0;
		Cursor.contentStyle = 0;
	}	
	
	if( $('#current').length )
	{
		$('#current').remove();
	}
	
	var panel = ('<div id="current" class="detailPanel nohistory"><ul class="toolbar"></ul><div class="content">');	
	PM.holder.append(panel);
	
	var telAvailable = false;
	
	$('.content').append('<div class="header"><div class="title text">'+currentResponse.find('title').text()+'</div><div class="clear"/>');
	
	var text = currentResponse.find('body text').text();
	if( text.length > 1 )
	{
	    $('.content').append('<div class="text tts">' + text);
	}
	else
	{
	    $('.content').append('<div class="text">' + text);
	}
	
	if( variant == 'NBT')
	{
		var links = currentResponse.find('body objectparameters links');
		currentResponse.find('link').each(function (index) {
		var linkType = $(this).attr("type");

		if( telAvailable == false )
		{
			//found at least one tel
			if ( linkType == "tel" ) 
			{			
				telAvailable = true;
				$('.toolbar').append('<li class="tel" title="' + I18N.get('telCall') + '" onclick="loadPhoneLinkList();">');
				$('.tel').append('<div class="icon phone">');	
			}
		}

		} );
	}
	
	$('#current .content').attr('scrollheight', Cursor.scrollHeight);
	$('#current .content').attr('style', Cursor.contentStyle);
	
	LOG.info( 'TextObject scrollheight: ' +  Cursor.scrollHeight + ', style: ' + Cursor.contentStyle );
	
	PM.show('current');
	
	$('#current').find('.toolbar').children().removeClass('selected');
	$('#current').find('.toolbar').children().eq(Cursor.selectedId).addClass('selected');
	
	if(objectId == '0')
	{
	   PM.isStartPage = true;
	   PM.setStartPageDisplayed(true);
	}
	else
	{
	   PM.isStartPage = false;
	}
	
	if((objectType == "list")||(objectType == "titleOnly" )){
		refresh();
	}
}


loadPhoneLinkList = function(){
   LOG.info('Produce phone menu:' + currentResponse.find('title').text()); 
   
    if( $('#current').length )
	{
		$('#current').remove();
	}
	
	var panel = ('<div id="current" class="panel nohistory"><div class="header"><div class="title ">'+currentResponse.find('title').text()+'</div><div class="clear"/></div><div class="contentContainer"><ul class="content">');	
	PM.holder.append(panel);
   
   	var links = currentResponse.find('body objectparameters links');
	currentResponse.find('link').each(function (index) {
	   var linkType = $(this).attr("type");
	   
		if( linkType == "tel" ) {
		   $('.content').append('<li class="link hotButton" onclick="PM.makeVoiceCall(\'' + $(this).find('target').text() + '\');"><div>' + $(this).find('linktitle').text() +'</div></li>' );
	   } 
	
	} );
	
	hotButtonMenuActiv = true;
	PM.show('current');
}


refresh = function(){
    if(refreshTime != undefined && refreshTime != '0' )
	{
	    LOG.info('Refresh: ' + urlPrefix + objectId + suffix);
		timer = setTimeout( "loadContent(urlPrefix + objectId + suffix)", refreshTime );
	}
	
	refreshContent = true;
}

function resizeScreen( size ) {
	LOG.info("Journaline. ResizeScreen " + size);
	
	if( size == 1024 )
	{
		$("head").append("<style type='text/css'>" 
		+ "body {background-size: 1034px 420px;}"
		+ "div#Main {width: 1024px;}"
		+ "div#GenericPanelProgress {width: 1024px;}"
		+ "#ScrollerNotVisible {left: 990px;}"
		+ "#ScrollerVisible {left: 990px;}"
		+ "#Scroller {left: 990px;}"
		+ ".header .title {width: 975px;}"
		+ "li.dropdown>div {width: 910px;}"
		+ "input,input:FOCUS,textarea,textarea:FOCUS {width: 920px;}"
		+ ".SC input, .SC input:FOCUS, .SC textarea, .SC textarea:FOCUS {width: 900px;}"
		+ "div.poiListItem {width: 530px;}.poiListItem div.left {width: 465px;}"
		+ ".detailPanel .content .rightContent ~ div {width: 550px;}"
		+ ".detailPanel .content .rightContent {left: 650px;}"
		+ ".twolineLink {width: 850px;}"
		+ ".detailPanel .content>.text,.detailPanel .content div>.text {width: 900px;}"
		+ "</style>");
	}
	else if( size == 544 )
	{
		$("head").append("<style type='text/css'>" 
		+ "body {background-size: 544px 420px;}" 
		+ "div#Main {width: 544px;}"
		+ "div#GenericPanelProgress {width: 544px;}"
		+ "#ScrollerNotVisible {left: 504px;}"
		+ "#ScrollerVisible {left: 504px;}"
		+ "#Scroller {left: 504px;}"
		+ ".header .title {width: 485px;}"
		+ "li.dropdown>div {width: 450px;}"
		+ "input,input:FOCUS,textarea,textarea:FOCUS {width: 460px;}"
		+ ".SC input, .SC input:FOCUS, .SC textarea, .SC textarea:FOCUS {width: 420px;}"
		+ "div.poiListItem {width: 485px;}"
		+ ".poiListItem div.left {width: 415px;}"
		+ ".detailPanel .content .rightContent {	left: 420px;}"
		+ ".detailPanel>.rightContent {	width: 420px;}"
		+ ".detailPanel .content .rightContent ~ div {clear: both;}"
		+ ".twolineLink {width: 380px;}"
		+ ".detailPanel .content>.text,.detailPanel .content div>.text {width: 420px;}"		
		+ "</style>");
	}
	else
	{
		LOG.error( "Journaline: unknown res.xSize " + size );
	}
	
	if ( (objectType == "message") || (objectType == "list") )
	{
	   PM.visiblePanel.setScroller();
	   PM.visiblePanel.setScrollHeight(0);
	}
};


/* overwrite nbt.js code */
PM.init = function() {
	$('#Main').append( '<div id="ScrollerNotVisible"></div><div id="ScrollerVisible"></div><div id="Scroller"></div>');

	this.idrivePlugin = document.getElementById('idrivePlugin');
	this.holder = $('#PanelHolder');
}


PM.show = function(panelId, url, options) {
	var newPanel = this.holder.find('#' + panelId);
	// for detail panels set the scroll buttons
	if (newPanel.is('.detailPanel')) {
		// add textToSpeech button if there are divs with class tts, not for RSE or NBT_ASN
		var ua = PM.getUserAgent();
		if (ua != undefined
				&& (ua.indexOf(';tts;') > -1 || ua.indexOf('Firefox') > -1 || ua.indexOf('Chrome') > -1)) {
			if (newPanel.find('div.tts').length != 0 && !newPanel.find('li.textToSpeech').length) {
				newPanel
						.find('.toolbar')
						.append(
								'<li class="textToSpeech" onclick="PM.readPage();"><div class="icon textToSpeech"></div></li>');
				newPanel.find('.textToSpeech').attr('title', I18N.get('readOut'));
			}
		}

		// add scroll buttons
		if (!newPanel.is('.fix') && !newPanel.find('li.scrollUp').length) {
			newPanel
					.find('.toolbar')
					.each(
							function() {
								if (!$(this).hasClass('submenu')) {
									$(this)
											.prepend(
													'<li class="scrollUp" onclick="PM.scrollUpPage();"><div class="icon scrollUp"></div></li>');
									$(this)
											.append(
													'<li class="scrollDown" onclick="PM.scrollDownPage();"><div class="icon scrollDown"></div></li>');
								}
							});
		}
	}
	// first make visible, then set scrollButtons inactive, if the content fits into the viewport
	this.changeVisiblePanel(newPanel);

	if (newPanel.find('li.scrollUp').length) {
		if (newPanel.outerHeight() <= newPanel.getViewportHeight()) {
			newPanel.find('li.scrollUp').addClass('inactive');
			newPanel.find('li.scrollDown').addClass('inactive');
		}
	}
}

PM.back = function() {
	
	LOG.info('Back' );
	if(hotButtonMenuActiv == true )
	{
	   produceText(currentResponse);
       hotButtonMenuActiv = false;
	   	   
	   return;
	}

	Cursor.restorePosition();
	
	clearTimeout(timer);
	refreshContent = false;
	loadContent( urlPrefix + 'up' + suffix );	
}


PM.readPage = function() {
	var header = this.visiblePanel.find('.content div.ttsheader');
	if (!header.length) {
		header = this.visiblePanel.find('.content div.header');
	}
	header = header.text();
	
	var temp = this.visiblePanel.find('.content div.tts').clone();
	temp.find("br").replaceWith(" \r\n\r\n");
	var text = temp.text();
	
	LOG.info('start reading');
	TTS.read('', header, text);
}


PM.showError = function(errorCode) {
	if (!errorCode) {
		errorCode = "Unexpected error";
	}
	
	LOG.error('An error occured: ' + errorCode);
}

/**
 * I18N - Translations
 */
var I18N = {
	data : {},
	/**
	 * This function search for the given key and returns the translation for the current locale.
	 * 
	 * @param key
	 * @returns
	 */
	get : function(key) {
		try {
			return I18N.data[key];
		} catch (e) {
		
		LOG.error('Journaline: I18N.get error: ' + e);
		
		if(I18N.data == undefined)
		{
		   I18N.data = i18nFallback;
		   return I18N.data[key];
		}
	    
	        return "";
           }
	},
	/**
	 * This function will be called automatically, if the DOM was loaded.
	 */
	init : function() {	
		var currentLocale = PM.getUserAgent().split(';', 7)[6];
		LOG.info('currentLocale: ' + currentLocale);
				
		if( currentLocale ) 
		{
			I18N.load(currentLocale);
		}
		else
		{
			LOG.error('CurrentLocale undefined. UA: ' + PM.getUserAgent());
			I18N.data = i18nFallback;
		}
	},
	load : function(locale) {
		$.ajax({
			url : ('journalineNBT/tooltips/' + locale),
			dataType: 'json',
			type : 'GET',
			async : true,
			cache : false,
			timeout : 10000,
			success : function(i18nJSON) {
				I18N.data = i18nJSON;				
			},
			error : function() {
				LOG.error('Journaline: Loading tooltips failed');
				I18N.data = i18nFallback;
			}
		});
	},
	/**
	 * If the locale differs from the stored locale, the i18n json will be refreshed from the file system.
	 * 
	 * @param locale
	 */
	update : function(locale) {
		if (I18N.get('locale') != locale) {
			I18N.load(locale);
		}
	}
};
