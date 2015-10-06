/*
   #################################################
  #                                                 #
  #    GOOGLE MAPS ROUTINES                         #
  #                                                 #
   #################################################
*/

function get_location() {
	myLocation = new google.maps.LatLng(39.712601004088974,-105.19349098205566);
	if ( app === 'iosmkt' ) {
	} else if ( app === 'andrmkt' ) {
		Android.api_load_completed();
	} else if ( app === 'testgeos' ) {
		setInterval(function(){kqcheck(39.480758642742224,-106.04617595672607,25);},30000);
	} else if ( navigator.geolocation ) {
		wpid = navigator.geolocation.watchPosition(function(pos) {
			notify( kqcheck(pos.coords.latitude,pos.coords.longitude,pos.coords.accuracy) );
		}, function(error) {
			if ( document.getElementById('gonearby') ) document.getElementById('gonearby').style.visibility = 'visible';
		},{enableHighAccuracy: true, maximumAge: 0, timeout: 30000});
	} else {
		if ( document.getElementById('gonearby') ) document.getElementById('gonearby').style.visibility = 'visible';
	}
}

var current_overlay = 'none';
var mapPopOn = false;
var layer_traff;
var layer_traff_reloader;
var layer_speed;
var layer_conds;
var layer_alert;
var layer_camwr;
var layer_strea;
var layer_signs;
var layer_bicyc;
var layer_parks;

function initialize_map(zoom) {

	var xxStyle =
[
  {
    featureType: "administrative",
    stylers: [
      { visibility: "on" }
    ]
  },{
    featureType: "landscape",
    stylers: [
      { visibility: "off" }
    ]
  },{
    featureType: "poi",
    stylers: [
      { visibility: "off" }
    ]
  },{
    featureType: "road.arterial",
    stylers: [
      { visibility: "simplified" }
    ]
  },{
    featureType: "road.local",
    stylers: [
      { visibility: "simplified" }
    ]
  },{
    featureType: "transit",
    stylers: [
      { visibility: "off" }
    ]
  },{
    featureType: "water",
    stylers: [
      { visibility: "on" }
    ]
  }
]
	;

	var styledMapOptions = {
		name: 'CDOT'
	};
	var xxMapType = new google.maps.StyledMapType(xxStyle, styledMapOptions);

/*	var icon_me = './app.resimage/I70/icon_me2.png';*/
	var icon_me = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAYAAADE6YVjAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NTcxMzgwRkFCNjU4MTFFMTg5RjZBRjAyRkI5MzU2OUIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NTcxMzgwRkJCNjU4MTFFMTg5RjZBRjAyRkI5MzU2OUIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpEOUUzREE2MUI1NUQxMUUxODlGNkFGMDJGQjkzNTY5QiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpEOUUzREE2MkI1NUQxMUUxODlGNkFGMDJGQjkzNTY5QiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PoNHCXgAAAL8SURBVHjavFbLTttAFL1jx6/YxEkaYiggRFC7Zs826o/0C/ol/YL+COqWPat2RyXUIhKUOH7Fb7t3kmtk0iRQ1DLSkSbjO+fM3NeElWUJ/3sI8ArjVUQa1eTj55+r3xiBH0SszfkoENzPeW3+h9+/fDp8LLJCXhFLCBmh0ryyzxApIkIkNK8Lrr/JioBExAaihdhB6AiF7GJEgPAQLsInwXSdUGNNjCQiNBG7CAvRR3QQTbKbI2zEGDFC3CMcEq5utVaEkYtUEjhAnMRxcBa40/MoDAZZEpuLTbLiqJp+rbe6l4qiX5FLoeayR7dZFZHIRfwGJ747+eDa46HRN6zDwRF0usbC0J76vdl42pvc3Ry3Ov2+0XpzQbGp4pNtEhHoRDwGVhz5Z87kdmgedCxzfxdMTQJdWu4rTQ2Y3AdBZJbz63YoycpYUY0ZxSigmBXr6qRyFQ9y37VH56IClqzKkHghsCQGIU0W4HO+xr9xG25LcdshDnFbTKqgd0LfHki6BHPHB6Eh4xEzKMKleRBnEDgRFFmCPimA21Ji6MTBNokI9JunaTMJXLMUmkhULkQibw6qvDxglOSQZ9lCJEsjSIO5SZmnEIewLYUfRlHkEM4cYGIIIooIogQ+o71lAUWeohDeJEcXMuF5bYUClVHQ5pKiOs79XQ/5UEAGJkgIgTQKRIpCGB9cMnf3HKqdmDiKTSIlpR/PDls12tfT25te6AVI1ADGRASJoHJZ5iiUgbajA7el4qyKcWPF59QaeBqO272jy9CbHM/d71ZoY9dAAUbxLDkHCqktDTr7ByNuS9XvEUe+qdUXVEy8F400vX3V3Tv9+vbd+5FmqniLDJIwWIDP+Rr/xm24LbUXlziedJdPvUjGE17Imj5GkvPAGQ1CzDhuqOktRzet6/beyWVT73KBH7THf8pdZc1lDq0lSDJrnna/PbNBVq7a2oWLWvBzurpHRH/T6re+J2VNqC5o/8tHC1ae1Ye6ecnz+2TF1zZWYi8e7DX+d/0WYAARu23SY6nJbwAAAABJRU5ErkJggg==';

	me = new google.maps.Marker({
		map: map,
		icon: icon_me,
		zIndex: 1000000,
		clickable: false,
		position: myLocation,
		animation: google.maps.Animation.DROP
	});

	google.maps.visualRefresh = true;

	infoWindow = new google.maps.InfoWindow();
	infoWindow.setOptions({maxWidth: 250});

	if ( ! zoom ) zoom = 11;
	map = new google.maps.Map(document.getElementById('nearby'),{
		zoom: zoom,
		center: myLocation,
		mapTypeControl: true,
		mapTypeControlOptions: {
			mapTypeIds: [google.maps.MapTypeId.TERRAIN, 'xxstyle'],
			style: google.maps.MapTypeControlStyle.HORIZONTAL_BAR,
			position: google.maps.ControlPosition.TOP_CENTER
		},
		panControl: false,
		zoomControl: true,
		zoomControlOptions: {
			position: google.maps.ControlPosition.RIGHT_BOTTOM
		},
		scaleControl: false,
		streetViewControl: false,
	});
	map.mapTypes.set('xxstyle', xxMapType);
	map.setMapTypeId('xxstyle');

	layer_traff = new google.maps.TrafficLayer();
	layer_traff.setMap(map);

/*
	layer_speed = new google.maps.FusionTablesLayer({ map: map, query: { from: '2828658' }, clickable: false });

	var speedReload = document.createElement('DIV');
	speedReload.innerText = 'refresh';
	speedReload.index = 1;
	google.maps.event.addDomListener(speedReload, 'click', function() {
		layer_speed.setOptions({
			query: {
				select: 'Latitude',
				from: '2828658'
			}
		});
	});
	map.controls[google.maps.ControlPosition.RIGHT_BOTTOM].push(speedReload);
*/

	layer_conds = new google.maps.FusionTablesLayer({ query: { from: '2829880' } });

	google.maps.event.addListener(layer_conds, 'click', function(e) {
		_gaq.push(['_trackEvent','Map','Conditions',e.row['RouteName'].value.replace(/\s/g,'_')+'-id='+e.row['WeatherRouteId'].value]);
	});

/*
	layer_alert = new google.maps.FusionTablesLayer({ map: map, query: { select: 'LATITUDE', from: '3308540', where: "Impact='Severe'" }, suppressInfoWindows: true });

	google.maps.event.addListener(layer_alert, 'click', function(e) {
		_gaq.push(['_trackEvent','Map','Alert',e.row['Title'].value.replace(/\s/g,'_')+'-id='+e.row['AlertId'].value]);
		var mapPop = document.getElementById('mapPop');
		while ( mapPop.firstChild ) {
			mapPop.removeChild(mapPop.firstChild);
		}

		var mapPopAlt = document.createElement('div');
		mapPopAlt.id = 'mapPopAlt';
		mapPopAlt.className = 'deal-map-pop-inner';
		var mapPopDesc = e.row['Description'].value ? e.row['Description'].value : e.row['Headline'].value;
		mapPopAlt.innerHTML = '<span class="alert_icon">' + alertData[e.row['AlertId'].value]['icon'] + '</span> ' + mapPopDesc;
		mapPop.style.height = mapPopAlt.style.height;
		mapPop.appendChild(mapPopAlt);
		mapPopOpen();
	});
*/

	layer_camwr = new google.maps.FusionTablesLayer({
		query: {
			select: 'Latitude',
			from: '3299685',
			where: 'CameraId > 0'
		},
		suppressInfoWindows: true
	});

	google.maps.event.addListener(layer_camwr, 'click', function(e) {
		var mapPop = document.getElementById('mapPop');
		while ( mapPop.firstChild ) {
			mapPop.removeChild(mapPop.firstChild);
		}

		if ( e.row['CameraId'].value > 1 ) {
			_gaq.push(['_trackEvent','Map','Camera',e.row['Name'].value.replace(/\s/g,'_')+'-id='+e.row['CameraId'].value]);

			var mapPopAlt = document.createElement('div');
			mapPopAlt.id = 'mapPopAlt';
			mapPopAlt.className = 'map-image-wrapper';
			mapPop.appendChild(mapPopAlt);

			if ( bugData[e.row['CameraId'].value] ) {
				var mapPopBug = document.getElementById('mapPopBug');
				mapPopBug.src = './app.resimage/I70/' + bugData[e.row['CameraId'].value];
				mapPopBug.style.display = 'block';
/*
				var mapPopBug = document.createElement('img');
				mapPopBug.src = './app.resimage/I70/' + bugData[e.row['CameraId'].value];
				mapPopBug.style.float = 'right';
				mapPopBug.style.opacity = '0.7';				
				mapPopBug.style.position = 'absolute';				
				mapPopBug.style.bottom = '15px';				
				mapPopBug.style.left = '15px';				
				mapPopBug.style.zIndex = 1000000;
				document.getElementById('deal-list').appendChild(mapPopBug);
*/
			} else {
				document.getElementById('mapPopBug').style.display = 'none';
			}

			var stills = e.row['ImageLocations'].value.split("\t");
			var gallery = new SwipeView('#mapPopAlt', { numberOfPages: stills.length, loop: false });

			for (var i=0; i<3; i++) {
				var page = i==0 ? stills.length-1 : i-1;
				if ( ! stills[page] ) break;
				var el = document.createElement('img');
				el.className = 'map-image';
				el.src = stills[page];
				if (i==0) {
					el.onload = function () {
						mapPopAlt.style.height = this.height+'px';
						mapPop.style.height = this.height+'px';
						mapPopOpen();
					}
				}
				gallery.masterPages[i].appendChild(el);
			}
			mapPopLoading();
		}
/*
		if ( e.row['WeatherStationId'].value > 1 ) {
			_gaq.push(['_trackEvent','Map','WeatherStation',e.row['Name'].value.replace(/\s/g,'_')+'-id='+e.row['WeatherStationId'].value]);
			mapPopInner += '<div class="deal-map-pop-inner">' + e.row['Name'].value + '<br>';
			mapPopInner += 'Temp: ' + e.row['EssAirTemp'].value + '<br>';
			mapPopInner += 'Humidity: ' + e.row['EssRelHumidity'].value + '<br>';
			mapPopInner += 'Max/Min: ' + + e.row['EssMaxTemp'].value + '/' + e.row['EssMinTemp'].value + '<br>';
			mapPopInner += 'Wind: ' + e.row['EssAvgWindSpeed'].value + ' ' + e.row['EssAvgWindDir'].value + '<br>';
			mapPopInner += 'Visibility: ' + e.row['EssVisibilityTxt'].value + '</div>';
		}
*/
	});

	layer_strea = new google.maps.FusionTablesLayer({ query: { from: '1I-zFkP1IpVN3SzGaSLShMbyAizvhK2a0pvMNZhy6' }, styleId: 2, suppressInfoWindows: true });

	google.maps.event.addListener(layer_strea, 'click', function(e) {
		stream_video(e.row['StreamURL'].value,4);
	});

	layer_signs = new google.maps.FusionTablesLayer({ query: { from: '2846939' }, suppressInfoWindows: true });

	google.maps.event.addListener(layer_signs, 'click', function(e) {
		_gaq.push(['_trackEvent','Map','RoadSigns',e.row['CommonName'].value.replace(/\s/g,'_')+'-id='+e.row['DMSId'].value]);

		var mapPop = document.getElementById('mapPop');
		while ( mapPop.firstChild ) {
			mapPop.removeChild(mapPop.firstChild);
		}

		var mapPopAlt = document.createElement('div');
		mapPopAlt.id = 'mapPopAlt';
		mapPopAlt.className = 'map-image-wrapper';
		mapPop.appendChild(mapPopAlt);

		var el = document.createElement('img');
		el.className = 'map-image';
		el.src = e.row['MessageImage'].value;
		el.onload = function () {
			mapPopAlt.style.height = this.height+'px';
			mapPop.style.height = this.height+'px';
			mapPopOpen();
		};
		mapPopAlt.appendChild(el);
		mapPopLoading();
	});

	layer_parks = new google.maps.FusionTablesLayer({query:{from:'15slTQk09D-mh5ahYob-nlrH2JOi82YBw2ML5Ja4'},templateId:2,styles:[{markerOptions:{iconName:'parks'}}]});

	me.setMap(map);

	var ctrControl = document.createElement('DIV');
	ctrControl.className= 'mapButton-solo';
	ctrControl.id = 'mapButton-compass';
	ctrControl.appendChild(document.getElementById('mapButtonIcon-compass'));
	ctrControl.appendChild(document.getElementById('mapButtonLabel-compass'));
	ctrControl.index = 1;
	google.maps.event.addDomListener(ctrControl, 'click', function() {
		_gaq.push(['_trackEvent','Map','Controls','Center']);
		map.setCenter(myLocation);
	});
	map.controls[google.maps.ControlPosition.LEFT_TOP].push(ctrControl);

	var cameraControl = document.createElement('DIV');
	cameraControl.className= 'mapButton-first';
	cameraControl.id = 'mapButton-camera';
	cameraControlImg = document.createElement('IMG');
	cameraControlImg.id = 'mapButtonIcon-camera';
	cameraControlImg.src = document.getElementById('mapButtonSrc-camera').src;
	cameraControl.appendChild(cameraControlImg);
	cameraControl.appendChild(document.getElementById('mapButtonLabel-camera'));
	cameraControl.index = 2;
	google.maps.event.addDomListener(cameraControl, 'click', function() {
		_gaq.push(['_trackEvent','Map','Controls','Cameras']);
		change_layer('camera');
	});
	map.controls[google.maps.ControlPosition.LEFT_TOP].push(cameraControl);
/*
	var weatherControl = document.createElement('DIV');
	weatherControl.className= 'mapButton-mid';
	weatherControl.id = 'mapButton-weather';
	weatherControlImg = document.createElement('IMG');
	weatherControlImg.id = 'mapButtonIcon-weather';
	weatherControlImg.src = document.getElementById('mapButtonSrc-weather').src;
	weatherControl.appendChild(weatherControlImg);
	weatherControl.appendChild(document.getElementById('mapButtonLabel-weather'));
	weatherControl.index = 3;
	google.maps.event.addDomListener(weatherControl, 'click', function() {
		_gaq.push(['_trackEvent','Map','Controls','WeatherStations']);
		change_layer('weather');
	});
	map.controls[google.maps.ControlPosition.LEFT_TOP].push(weatherControl);
*/
	var signsControl = document.createElement('DIV');
	signsControl.className= 'mapButton-mid';
	signsControl.id = 'mapButton-signs';
	signsControlImg = document.createElement('IMG');
	signsControlImg.id = 'mapButtonIcon-signs';
	signsControlImg.src = document.getElementById('mapButtonSrc-signs').src;
	signsControl.appendChild(signsControlImg);
	signsControl.appendChild(document.getElementById('mapButtonLabel-signs'));
	signsControl.index = 4;
	google.maps.event.addDomListener(signsControl, 'click', function() {
		_gaq.push(['_trackEvent','Map','Controls','RoadSigns']);
		change_layer('signs');
	});
	map.controls[google.maps.ControlPosition.LEFT_TOP].push(signsControl);

	var condControl = document.createElement('DIV');
	condControl.className= 'mapButton-mid';
	condControl.id = 'mapButton-cond';
	condControlImg = document.createElement('IMG');
	condControlImg.id = 'mapButtonIcon-cond';
	condControlImg.src = document.getElementById('mapButtonSrc-cond').src;
	condControl.appendChild(condControlImg);
	condControl.appendChild(document.getElementById('mapButtonLabel-cond'));
	condControl.index = 5;
	google.maps.event.addDomListener(condControl, 'click', function() {
		_gaq.push(['_trackEvent','Map','Controls','Conditions']);
		change_layer('cond');
	});
	map.controls[google.maps.ControlPosition.LEFT_TOP].push(condControl);


	var parksControl = document.createElement('DIV');
	parksControl.className= 'mapButton-last';
	parksControl.id = 'mapButton-parks';
	parksControlImg = document.createElement('IMG');
	parksControlImg.id = 'mapButtonIcon-parks';
	parksControlImg.style.marginLeft = '4px';
	parksControlImg.src = document.getElementById('mapButtonSrc-parks').src;
	parksControl.appendChild(parksControlImg);
	parksControl.appendChild(document.getElementById('mapButtonLabel-parks'));
	parksControl.index = 6;
	google.maps.event.addDomListener(parksControl, 'click', function() {
		change_layer('parks');
	});
	map.controls[google.maps.ControlPosition.LEFT_TOP].push(parksControl);

/*
	var bicycleControl = document.createElement('DIV');
	bicycleControl.className= 'mapButton-last';
	bicycleControl.id = 'mapButton-bicycle';
	bicycleControlImg = document.createElement('IMG');
	bicycleControlImg.id = 'mapButtonIcon-bicycle';
	bicycleControlImg.src = document.getElementById('mapButtonSrc-bicycle').src;
	bicycleControl.appendChild(bicycleControlImg);
	bicycleControl.appendChild(document.getElementById('mapButtonLabel-bicycle'));
	bicycleControl.index = 6;
	google.maps.event.addDomListener(bicycleControl, 'click', function() {
		_gaq.push(['_trackEvent','Map','Controls','BicycleLayer']);
		change_layer('bicycle');
	});
	map.controls[google.maps.ControlPosition.LEFT_TOP].push(bicycleControl);
*/

	google.maps.event.addListener(map, 'zoom_changed', function() {
		_gaq.push(['_trackEvent','Map','Controls','Zoom']);
		if ( current_overlay === 'camera' ) layer_camwr.setOptions({
			styles: [{
				markerOptions:{iconName:'purple_circle'}
			},{
				where: 'ZoomLevel >' + map.getZoom(),
				markerOptions:{iconName:'measle_grey'}
			}]
		});
		if ( current_overlay === 'signs' ) {
			var where = map.getZoom() < 11 ? "BlankMessage='false'" : "BlankMessage NOT EQUAL TO 'blank'";
			layer_signs.setOptions({
				query: {
					select: 'Latitude',
					from: '2846939',
					where: where
				}
			});
		}
	});

	var script = document.createElement('script');
	script.type = 'text/javascript';
	script.src = 'https://www.google.com/jsapi?autoload={"modules":[{"name":"visualization","version":"1","nocss":true,"callback":"display_viz"}]}';
	document.body.appendChild(script);
}

function display_viz() {
	var query = "SELECT AlertId,Type,Title,Headline,Description,Direction,Latitude,Longitude FROM 1xxGP5-GpzaJ1_qYq01j4Pe3JIDhWt4xTy7dIWuU WHERE 'Impact'='Severe'";
	var gvizQuery = new google.visualization.Query('https://www.google.com/fusiontables/gvizdata?tq='+encodeURIComponent(query));

	var createMarker = function (coordinate,alert_id,type,title,headline,description) {

		/* http://mapicons.nicolasmollet.com/category/markers/transportation/ colored c03639 */
		var image = 'caution.png';
		if ( type == 'Road Work' || (type == 'Incident' && title == 'Road Work') ) image = 'construction.png';
		else if ( type == 'Road Closure' || type == 'Seasonal Closure' ) image = 'accesdenied.png';
		else if ( (type == 'Restriction' && title == 'Rock Work') || type == 'Avalanche Control' ) image = 'fallingrocks.png';
		else if ( type == 'Incident' && (title == 'Accident' || title == 'Injury Accident' || title.match(/^Overturned/) || title == 'Vehicle on Fire') ) image = 'caraccident.png';

		var marker = new google.maps.Marker({map:map,title:title,position:coordinate,icon:{
				url: './app.resimage/mapicons/'+image,
				size: new google.maps.Size(26,30),
				scaledSize: new google.maps.Size(26,30),
				origin: new google.maps.Point(0,0),
				anchor: new google.maps.Point(13,30)
			},opacity:0.8,optimized:true});

		google.maps.event.addListener(marker, 'click', function (event) {
			_gaq.push(['_trackEvent','Map','Alert',title.replace(/\s/g,'_')+'-id='+alert_id]);
			var mapPop = document.getElementById('mapPop');
			while ( mapPop.firstChild ) {
				mapPop.removeChild(mapPop.firstChild);
			}

			var mapPopAlt = document.createElement('div');
			mapPopAlt.id = 'mapPopAlt';
			mapPopAlt.className = 'deal-map-pop-inner';
			var mapPopDesc = description ? description : headline;
			mapPopAlt.innerHTML = '<span class="alert_icon">' + alertData[alert_id]['icon'] + '</span> ' + mapPopDesc;
			mapPop.style.height = mapPopAlt.style.height;
			mapPop.appendChild(mapPopAlt);
			mapPopOpen();
		});
	};

	gvizQuery.send(function (response) {
		var numRows = response.getDataTable().getNumberOfRows();

		for (var i = 0; i < numRows; i++) {
			var coordinate = new google.maps.LatLng(response.getDataTable().getValue(i,6),response.getDataTable().getValue(i,7));
			createMarker(coordinate,response.getDataTable().getValue(i,0),response.getDataTable().getValue(i,1),response.getDataTable().getValue(i,2),response.getDataTable().getValue(i,3),response.getDataTable().getValue(i,4),response.getDataTable().getValue(i,5));
		}
	});

	if ( document.getElementById('nearby').getAttribute('chain') == 1 ) display_viz_chain();
}

function display_viz_chain() {
	document.getElementById('nearby').setAttribute('chain',2);
	var query = "SELECT Name,Route,Direction,Longitude,Latitude,MileMarker,Spaces FROM 1eZrcCwszKoAeAYpU6WPQ1UI3E5v-ScJbim7wuXXm";
	var gvizQuery = new google.visualization.Query('https://www.google.com/fusiontables/gvizdata?tq='+encodeURIComponent(query));

	var createMarker = function (coordinate,description,direction,mmarker,spaces) {

		var image = {
				url: './app.resimage/mapicons/chain_down.png',
				size: new google.maps.Size(26,30),
				scaledSize: new google.maps.Size(26,30),
				origin: new google.maps.Point(0,0),
				anchor: new google.maps.Point(13,30)
			};
		if ( direction == 'EB' ) image = {
				url: './app.resimage/mapicons/chain_up.png',
				size: new google.maps.Size(26,30),
				scaledSize: new google.maps.Size(26,30),
				origin: new google.maps.Point(0,0),
				anchor: new google.maps.Point(13,0)
			};

		var marker = new google.maps.Marker({map:map,title:description,position:coordinate,icon:image,opacity:0.8,optimized:true});

		google.maps.event.addListener(marker, 'click', function (event) {
			_gaq.push(['_trackEvent','Map','Chain_Station',description.replace(/\s/g,'_')]);
			var mapPop = document.getElementById('mapPop');
			while ( mapPop.firstChild ) {
				mapPop.removeChild(mapPop.firstChild);
			}

			var mapPopAlt = document.createElement('div');
			mapPopAlt.id = 'mapPopAlt';
			mapPopAlt.className = 'deal-map-pop-inner';
			var milemarker = mmarker ? ' MM '+ mmarker : '';
			mapPopAlt.innerHTML = '<span class="alert_icon">d</span> '+ description +' - '+ direction + milemarker +' ('+ spaces +' spaces)';
			mapPop.style.height = mapPopAlt.style.height;
			mapPop.appendChild(mapPopAlt);
			mapPopOpen();
		});
	};

	gvizQuery.send(function (response) {
		var numRows = response.getDataTable().getNumberOfRows();

		for (var i = 0; i < numRows; i++) {
			var coordinate = new google.maps.LatLng(response.getDataTable().getValue(i,4),response.getDataTable().getValue(i,3));
			createMarker(coordinate,response.getDataTable().getValue(i,0),response.getDataTable().getValue(i,2),response.getDataTable().getValue(i,5),response.getDataTable().getValue(i,6));
		}
	});
}

function reload_traffic() {
	layer_traff.setMap(null);
	setTimeout(function(){layer_traff.setMap(map)},1000);
}

function bridge_subPause() {
	if ( currentPage.id === 'nearby' && layer_traff_reloader ) {
		clearInterval(layer_traff_reloader);
		layer_traff_reloader = null;
	}
}

function bridge_subResume() {
	if ( currentPage.id === 'nearby' ) {
		reload_traffic();
		layer_traff_reloader = setInterval(function(){reload_traffic()},300000);
	}
}

function change_layer(lyr) {
	if ( current_overlay === lyr ) {
		layer_signs.setMap(null);
		layer_conds.setMap(null);
		layer_camwr.setMap(null);
		layer_strea.setMap(null);
		layer_parks.setMap(null);
		if ( layer_bicyc ) layer_bicyc.setMap(null);
		if ( ! layer_traff.getMap() ) layer_traff.setMap(map);
		document.getElementById('mapButton-'+current_overlay).className = document.getElementById('mapButton-'+current_overlay).className.slice(0,-3);
		document.getElementById('mapButtonIcon-'+current_overlay).src = document.getElementById('mapButtonSrc-'+current_overlay).src;
		current_overlay = 'none';
	} else {
		if ( lyr === 'signs' ) {
			var where = map.getZoom() < 11 ? "BlankMessage='false'" : "BlankMessage NOT EQUAL TO 'blank'";
			layer_signs.setOptions({
				query: {
					select: 'Latitude',
					from: '2846939',
					where: where
				}
			});
			layer_signs.setMap(map);
			layer_conds.setMap(null);
			layer_camwr.setMap(null);
			layer_strea.setMap(null);
			layer_parks.setMap(null);
			if ( layer_bicyc ) layer_bicyc.setMap(null);
			if ( ! layer_traff.getMap() ) layer_traff.setMap(map);
		} else if ( lyr === 'cond' ) {
			layer_signs.setMap(null);
			layer_conds.setMap(map);
			layer_camwr.setMap(null);
			layer_strea.setMap(null);
			layer_parks.setMap(null);
			if ( layer_bicyc ) layer_bicyc.setMap(null);
			if ( ! layer_traff.getMap() ) layer_traff.setMap(map);
		} else if ( lyr === 'camera' ) {
			layer_signs.setMap(null);
			layer_conds.setMap(null);
			layer_camwr.setOptions({
				styles: [{
					markerOptions:{iconName:'purple_circle'}
				},{
					where: 'ZoomLevel >' + map.getZoom(),
					markerOptions:{iconName:'measle_grey'}
				}]
			});
			layer_camwr.setMap(map);
			layer_strea.setMap(map);
			layer_parks.setMap(null);
			if ( layer_bicyc ) layer_bicyc.setMap(null);
			if ( ! layer_traff.getMap() ) layer_traff.setMap(map);
		} else if ( lyr === 'weather' ) {
			layer_signs.setMap(null);
			layer_conds.setMap(null);
			layer_camwr.setOptions({
				query: {
					select: 'Latitude',
					from: '3299685',
					where: 'WeatherStationId > 0 AND ZoomLevel NOT EQUAL TO \'\' AND ZoomLevel < '+map.getZoom()
				}
			});
			layer_camwr.setMap(map);
			layer_strea.setMap(null);
			layer_parks.setMap(null);
			if ( layer_bicyc ) layer_bicyc.setMap(null);
			if ( ! layer_traff.getMap() ) layer_traff.setMap(map);


		} else if ( lyr === 'parks' ) {
			layer_signs.setMap(null);
			layer_conds.setMap(null);
			layer_camwr.setMap(null);
			layer_strea.setMap(null);
			layer_parks.setMap(map);
			if ( layer_bicyc ) layer_bicyc.setMap(null);
			if ( ! layer_traff.getMap() ) layer_traff.setMap(map);
		} else if ( lyr === 'bicycle' ) {
			clearInterval(layer_traff_reloader);
			layer_traff_reloader = null;
			layer_traff.setMap(null);
			layer_signs.setMap(null);
			layer_conds.setMap(null);
			layer_camwr.setMap(null);
			layer_strea.setMap(null);
			layer_parks.setMap(null);
			if ( ! layer_bicyc ) layer_bicyc = new google.maps.BicyclingLayer();
			layer_bicyc.setMap(map);


		} else {
			layer_signs.setMap(null);
			layer_conds.setMap(null);
			layer_camwr.setMap(null);
			layer_strea.setMap(null);
			layer_parks.setMap(null);
			if ( layer_bicyc ) layer_bicyc.setMap(null);
			if ( ! layer_traff.getMap() ) layer_traff.setMap(map);
		}

		document.getElementById('mapButton-'+lyr).className = document.getElementById('mapButton-'+lyr).className + '-on';
		document.getElementById('mapButtonIcon-'+lyr).src = document.getElementById('mapButtonSrc-'+lyr+'-on').src;
		if ( current_overlay != 'none' ) {
			document.getElementById('mapButton-'+current_overlay).className = document.getElementById('mapButton-'+current_overlay).className.slice(0,-3);
			document.getElementById('mapButtonIcon-'+current_overlay).src = document.getElementById('mapButtonSrc-'+current_overlay).src;
		}
		current_overlay = lyr;
	}
}

function mapPopClose()
{
	document.getElementById('mapPopBug').style.display = 'none';
	var dealToClose = document.getElementById('mapPop');
	dealToClose.style.webkitAnimation = 'dealHide 100ms linear 0 1';
	while ( dealToClose.firstChild ) {
		dealToClose.removeChild(dealToClose.firstChild);
	}
	dealToClose.style.height = '0';
	mapPopOn = false;
}

function mapPopOpen()
{
	var dealToOpen = document.getElementById('mapPop');
	dealToOpen.style.webkitAnimation = 'dealShow 100ms linear 0 1';
	mapPopOn = true;
}

function mapPopLoading()
{
	var dealToOpen = document.getElementById('mapPop');
	dealToOpen.style.height = '20px';
	dealToOpen.style.webkitAnimation = 'dealPartial 100ms linear 0 1';
	mapPopOn = true;
}

