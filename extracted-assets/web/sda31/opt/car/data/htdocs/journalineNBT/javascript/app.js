Config.isBrowserStartPage = true;
Config.startPanelUrl = 'main';
Config.startPanelOptions = {
	indicator : false,
	localStorage : true,
};

var Main = {
	WidgetMaxAge : 300, // seconds
	WidgetMaxDistance : 10000, // meter
	MainPanelMaxAge : 604800, // seven days
	KeyTeaserLastLoaded : 'MainTeaserLastLoaded',
	KeyMainPanelLastLoaded : 'MainPanelLastLoaded',
	KeyWidgetLastLoaded : 'WidgetLastLoaded',
	KeyWidgetContent : 'WidgetContent',
	KeyWidgetGeoData : 'WidgetGeoData',
	KeyWidgetLocale : 'WidgetLocale',
	url : '../nbt_appstore/servlet/widget',
	init : function(isTenInchScreen) {
		PM.disableScroller();
		if (isTenInchScreen) {
			Main.initWidget();
		}

		if (!SM.get(Main.KeyMainPanelLastLoaded)) {
			SM.set(Main.KeyMainPanelLastLoaded, PM.now());
		}

		if (!PM.isNotExpired(SM.get(Main.KeyMainPanelLastLoaded), Main.MainPanelMaxAge)) {
			SM.clearPanel('Start');
			SM.clear(Main.KeyMainPanelLastLoaded);
		}

		Main.checkTeaser();
	},
	checkTeaser : function() {
		var lastLoaded = SM.get('KeyTeaserLastLoaded');
		if (!PM.isNotExpired(lastLoaded, 86400)) {
			// check only one time per day
			PM.load('Teaser', 'teaser', {
				indicator : false
			});
			SM.set('KeyTeaserLastLoaded', PM.now());
		}
	},
	closeTeaser : function(id) {
		PM.load('TeaserClosed', 'teaser?save=' + id, {
			background : true,
			indicator : false
		});
		PM.back();
	},
	initWidget : function() {
		LOG.info('->initializing widget...');
		if (SM.get(Main.KeyWidgetGeoData)) {
			var geoData = $.parseJSON(SM.get(Main.KeyWidgetGeoData));

			if (Geocoder.getDistance(geoData, Geocoder.positionByLocationType('cur')) > Main.WidgetMaxDistance) {
				Main.loadFromBackend();
				return;
			}
		}
		if (PM.getUserAgent()) {
			// read current locale from user agent
			var lastLocale = SM.get(Main.KeyWidgetLocale);
			if (PM.isLocaleChanged(lastLocale)) {
				LOG.info('locale changed, loading widget from backend...');
				Main.loadFromBackend();
				return;
			}
		}

		if (PM.isNotExpired(SM.get(Main.KeyWidgetLastLoaded), Main.WidgetMaxAge)) {
			Main.loadFromStorage();
		} else {
			Main.loadFromBackend();
		}
	},
	loadFromBackend : function() {
		LOG.info('->loading widget from backend...');
		PM.load('Widget', Main.url, {
			geocoder : 'cur',
			indicator : false,
			background : true,
			doNotShowNoPositionError : true,
			callback : Main.refreshWidget,
			errorCallback : Main.error
		});
	},
	loadFromStorage : function() {
		LOG.info('->loading widget from storage...');
		var content = SM.get(Main.KeyWidgetContent);
		if (!(content != null && Main.addWidgetContent(content))) {
			SM.clear('WidgetLastLoaded');
			Main.loadFromBackend();
		}

	},
	refreshWidget : function(data, panelId, geoDataString, locale) {
		LOG.info('->refreshing widget...');
		if (Main.addWidgetContent(data)) {
			SM.set(Main.KeyWidgetLastLoaded, PM.now());
			SM.set(Main.KeyWidgetContent, data);
			var geoData = $.parseJSON(geoDataString);
			if (geoData) {
				LOG.info('put geo data into storage: ' + geoDataString);
				SM.set(Main.KeyWidgetGeoData, geoDataString);
			}
			if (locale) {
				LOG.info('put locale into storage: ' + locale);
				SM.set(Main.KeyWidgetLocale, locale);
			}
		}
	},
	addWidgetContent : function(content) {
		var widget = $('#Widget');
		if (widget.length) {
			widget.html(content);
			return true;
		}
		return false;
	},
	error : function() {
		// do not load widget again. Main.loadFromStorage();
	}
};

var LiveSettings = {
	submitRadioButton : function(panelId, targetUrl, formular) {
		var data = $(formular).find('li.radiobutton.checked').attr('cdpvalue');
		data = 'data=' + data;
		if (targetUrl.indexOf('?') > -1) {
			PM.load(panelId, targetUrl + "&" + data, {});
		} else {
			PM.load(panelId, targetUrl + "?" + data, {});
		}
		return false;
	},
};