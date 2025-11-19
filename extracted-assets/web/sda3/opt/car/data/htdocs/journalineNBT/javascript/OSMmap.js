var size = new OpenLayers.Size(16, 25);
var offset = new OpenLayers.Pixel(-(size.w / 2), -size.h);

var OSM = {
	map : undefined,
	posIcon : new OpenLayers.Icon('../static/images/common/OSM_current.png', size, offset),
	destIcon : new OpenLayers.Icon('../static/images/common/OSM_destination.png', size, offset),
	markers : undefined,
	posMarker : undefined,
	destMarker : undefined,
	fromProjection : new OpenLayers.Projection("EPSG:4326"),
	toProjection : new OpenLayers.Projection("EPSG:900913"),
	zoom : 4,
	init : function() {
		OpenLayers.Control.Click = OpenLayers.Class(OpenLayers.Control, {
			defaultHandlerOptions : {
				'single' : true,
				'double' : false,
				'pixelTolerance' : 0,
				'stopSingle' : false,
				'stopDouble' : false
			},
			initialize : function(options) {
				this.handlerOptions = OpenLayers.Util.extend({},
						this.defaultHandlerOptions);
				OpenLayers.Control.prototype.initialize.apply(this, arguments);
				this.handler = new OpenLayers.Handler.Click(this, {
					'click' : this.onClick,
				}, this.handlerOptions);
			},
			onClick : function(evt) {
				var coord = OSM.map.getLonLatFromPixel(evt.xy).transform(
						OSM.toProjection, OSM.fromProjection);
				if ($('#OSM-PositionMode').is('.location_destination')) {
					OSM.setDestMarker(coord.lat, coord.lon, true);
				} else {
					OSM.setPosMarker(coord.lat, coord.lon, true);
				}
			},

		});

		this.map = new OpenLayers.Map("OSM-Map");
		var mapnik = new OpenLayers.Layer.OSM();

		this.map.addLayer(mapnik);

		var control = new OpenLayers.Control.Click({
			handlerOptions : {
				"single" : true
			}
		});
		this.map.addControl(control);
		control.activate();

		this.markers = new OpenLayers.Layer.Markers("Markers");
		this.map.addLayer(this.markers);

		if (Geocoder && car) {
			this.setPosMarker(Geocoder.convertWGS84ToDegree(car.posLat()),
					Geocoder.convertWGS84ToDegree(car.posLong()));
			this.setDestMarker(Geocoder.convertWGS84ToDegree(car.destLat()),
					Geocoder.convertWGS84ToDegree(car.destLong()));
			this.centerMap(48.189256, 11.566388);
		}
	},
	centerMap : function(lat, lon) {
		var position = new OpenLayers.LonLat(lon, lat).transform(
				this.fromProjection, this.toProjection);
		this.map.setCenter(position, this.zoom);
	},
	setPosMarker : function(lat, lon, updateCar) {
		if (this.posMarker) {
			this.posMarker.erase();
		}
		this.posMarker = new OpenLayers.Marker(new OpenLayers.LonLat(lon, lat)
				.transform(this.fromProjection, this.toProjection),
				this.posIcon);
		this.markers.addMarker(this.posMarker);
		if (car && updateCar) {
			car.setPosition(lat, lon);
		}
	},
	setDestMarker : function(lat, lon, updateCar) {
		if (this.destMarker) {
			this.destMarker.erase();
		}
		this.destMarker = new OpenLayers.Marker(new OpenLayers.LonLat(lon, lat)
				.transform(this.fromProjection, this.toProjection),
				this.destIcon);
		this.markers.addMarker(this.destMarker);
		if (car && updateCar) {
			car.setDestination(lat, lon);
		}
	},
	togglePosition : function() {
		var el = $('#OSM-PositionMode');
		if (el.is('.location_current')) {
			el.removeClass('location_current').addClass('location_destination');
		} else {
			el.addClass('location_current').removeClass('location_destination');
		}
	},
	toggleMap : function() {
		$('#OSM').toggle(250);
		if (!this.map) {
			OSM.init();
		}
	}
};