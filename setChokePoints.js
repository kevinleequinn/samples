/*
   #################################################
  #                                                 #
  #    CHOKEPOINT ROUTINES                          #
  #                                                 #
   #################################################
*/

var chokeData = new Array();
var chokeFavs = new Array();
var lastchokeFav;
var chokeIds = new Array();

function setChokePoints(all) {
	var blox = document.getElementById('choke-today');
	while( blox.hasChildNodes() ) { blox.removeChild(blox.lastChild); }

	var insideFavs = false;
	var unFavNode = false;
	var unFavBlock = false;
	var unFavBlockExits = 0;
	var unFavBlockAlerts = 0;

	for (var i=0; i<chokeIds.length; i++) {
		var idx = chokeIds[i];

		if ( !insideFavs && chokeFavs[idx] === 1 ) insideFavs = true;
		if ( insideFavs && lastchokeFav === idx ) insideFavs = false;

		if ( all === 1 || chokeFavs[idx] === 1 || (insideFavs && (chokeData[idx]['n_slo'] || chokeData[idx]['s_slo'])) ) {
		/* if we're showing all chokepoints or this chokepoint is a favorite or the chokepoint is slow */

			if ( alertPath[idx] ) {
				for ( var j=0; j<alertPath[idx].length; j++ ) {
				/* loop through all the alerts for this chokepoint */

					if ( alertData[alertPath[idx][j]]['impact'] == 'Severe' && insideFavs ) {

						if ( unFavBlock ) {
						/* close the unFavBlock if its open */
							unFavNode.firstChild.innerHTML = unFavBlockAlerts > 0 ? '<b>'+unFavBlockAlerts+' Alerts</b> &nbsp;&bull;&nbsp; '+unFavBlockExits+' Exits' : unFavBlockExits+' Exits';
							popChokePointEnd(unFavNode,blox);
							unFavBlock = false;
						}

						/* append the alert block */
						fillAlertFull(alertPath[idx][j]);
						var node = document.getElementById('cpa-full').cloneNode(true);
						popChokePointEnd(node,blox);

					} else {

						if ( ! unFavBlock ) {
						/* open an unFavBlock */
							unFavBlock = true;
							unFavBlockExits = 0;
							unFavBlockAlerts = 0;
							unFavNode = document.getElementById('cpb-unfav').cloneNode(true);
							unFavNode.onclick = function(obj){return function(){tapunFavBlock(obj)}}(unFavNode);
						}

						/* increment number of alerts and append the alert nip to unFavNode */
						unFavBlockAlerts++;
						fillAlertNip(alertPath[idx][j]);
						var node = document.getElementById('cpa-nip').cloneNode(true);
						popChokePointEnd(node,unFavNode.lastChild);
					}
				}
			}

			if ( unFavBlock ) {
			/* close the unFavBlock if its open */
				unFavNode.firstChild.innerHTML = unFavBlockAlerts > 0 ? '<b>'+unFavBlockAlerts+' Alerts</b> &nbsp;&bull;&nbsp; '+unFavBlockExits+' Exits' : unFavBlockExits+' Exits';
				popChokePointEnd(unFavNode,blox);
				unFavBlock = false;
			}

			/* build the full chokepoint block and slap it on the bottom */
			fillChokePointFull(idx);
			var node = document.getElementById('cpb-full').cloneNode(true);
			node.className = 'cpb-full-block';
			node.onclick = function(obj){return function(){tapfullChokePoint(obj)}}(node);
			popChokePointEnd(node,blox);

		} else {
		/* else this is a chokepoint nip */

			if ( unFavBlock ) {
			/* an unFavBlock is already open so just increment the number of exits */
				unFavBlockExits++;
			} else {
			/* open an unFavBlock if one wasn't yet */
				unFavBlock = true;
				unFavBlockExits = 1;
				unFavBlockAlerts = 0;
				unFavNode = document.getElementById('cpb-unfav').cloneNode(true);
				unFavNode.onclick = function(obj){return function(){tapunFavBlock(obj)}}(unFavNode);
			}

			if ( alertPath[idx] ) {
				for ( var j=0; j<alertPath[idx].length; j++ ) {

					if ( alertData[alertPath[idx][j]]['impact'] == 'Severe' && insideFavs ) {

						if ( unFavBlock ) {
						/* close the unFavBlock if its open */
							unFavBlockExits--;
							unFavNode.firstChild.innerHTML = unFavBlockAlerts > 0 ? '<b>'+unFavBlockAlerts+' Alerts</b> &nbsp;&bull;&nbsp; '+unFavBlockExits+' Exits' : unFavBlockExits+' Exits';
							popChokePointEnd(unFavNode,blox);
						}

						/* append the alert block */
						fillAlertFull(alertPath[idx][j]);
						var node = document.getElementById('cpa-full').cloneNode(true);
						popChokePointEnd(node,blox);

						/* open another unFavBlock */
						unFavBlockExits = 1;
						unFavBlockAlerts = 0;
						unFavNode = document.getElementById('cpb-unfav').cloneNode(true);
						unFavNode.onclick = function(obj){return function(){tapunFavBlock(obj)}}(unFavNode);

					} else {

						if ( ! unFavBlock ) {
						/* open an unFavBlock */
							unFavBlock = true;
							unFavBlockExits = 0;
							unFavBlockAlerts = 0;
							unFavNode = document.getElementById('cpb-unfav').cloneNode(true);
							unFavNode.onclick = function(obj){return function(){tapunFavBlock(obj)}}(unFavNode);
						}

						/* increment number of alerts and append the alert nip to unFavNode */
						unFavBlockAlerts++;
						fillAlertNip(alertPath[idx][j]);
						var node = document.getElementById('cpa-nip').cloneNode(true);
						popChokePointEnd(node,unFavNode.lastChild);
					}
				}
			}

			/* build the nip and slap it on the end of the unFavNode */
			fillChokePointFull(idx);
			var node = document.getElementById('cpb-full').cloneNode(true);
			node.className = 'cpb-nip-block';
			node.onclick = function(obj){return function(){tapnipChokePoint(obj)}}(node);
			popChokePointEnd(node,unFavNode.lastChild);
		}
	}

	/* clean up the last open unFavBlock (if it exists) */
	if ( unFavBlock ) {
		unFavNode.firstChild.innerHTML = unFavBlockAlerts > 0 ? '<b>'+unFavBlockAlerts+' Alerts</b> &nbsp;&bull;&nbsp; '+unFavBlockExits+' Exits' : unFavBlockExits+' Exits';
		popChokePointEnd(unFavNode,blox);
	}

	if ( scrolling && currentPage.id === 'today' ) scrolling.refresh();
}

function fillChokePointFull(idx) {

	document.getElementById('cpb-full').setAttribute('chokepoint_id',idx);

	if ( chokeFavs[idx] === 1 ) {
		document.getElementById('cpb-full-name').innerHTML = '&nbsp;<b>'+chokeData[idx]['name']+'</b> &nbsp;<span class="icon_font" style="color: red; font-size: .6em; vertical-align: middle">l</span>&nbsp; Exit '+chokeData[idx]['exit'];
	} else {
		document.getElementById('cpb-full-name').innerHTML = '&nbsp;<b>'+chokeData[idx]['name']+'</b> &nbsp;&bull;&nbsp; Exit '+chokeData[idx]['exit'];
	}

	/* prime the speed arrows */
	if (chokeData[idx]['s_spd'] > 1) {
		document.getElementById('cpb-full-sbs').innerHTML = '<span>'+chokeData[idx]['s_spd']+'</span>MPH';
	} else {
		document.getElementById('cpb-full-sbs').innerHTML = '<span>--</span>';
	}
	if (chokeData[idx]['n_spd'] > 1) {
		document.getElementById('cpb-full-nbs').innerHTML = '<span>'+chokeData[idx]['n_spd']+'</span>MPH';
	} else {
		document.getElementById('cpb-full-nbs').innerHTML = '<span>--</span>';
	}

	/* prime the speed conditions background */
	document.getElementById('cpb-full-sbs').className = 'cpb-sbs'+speed2flow(chokeData[idx]['s_spd']);
	document.getElementById('cpb-full-nbs').className = 'cpb-nbs'+speed2flow(chokeData[idx]['n_spd']);

	/* prime the feedback text */
	var feedbackTxt = '<span class="conditions">'+chokeData[idx]['road_cond']+'</span>';
	if (chokeData[idx]['n_slo'] && chokeData[idx]['s_slo'])
	{
		feedbackTxt += '<span class="delays">Expect Delays</span>';
	} else if (chokeData[idx]['n_slo']) {
		feedbackTxt += '<span class="delays">Northbound Delays</span>';
	} else if (chokeData[idx]['s_slo']) {
		feedbackTxt += '<span class="delays">Southbound Delays</span>';
	} else {
/*		feedbackTxt += '<span class="delays">No Delays</span>'; */
	}
	document.getElementById('cpb-full-feedback').innerHTML = feedbackTxt;

	/* prime the cam and map buttons */
	if (chokeData[idx]['stream']) {
		document.getElementById('cpb-full-cams').innerHTML = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEcAAABHCAYAAABVsFofAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAACZSURBVHja7NlRCoAgEEBBN7z/le0GkmiR7sxvP/FYt8BSAAAAAIDzRedZ2/z9p10bh3ldTRimPZ3AmmgQ2qpjlT5MhsmZWhFVlFzHatkHpYpiIYsjjjjiiCOOOOIgjjjiiCOOOOKI8z9RFl/ynTg5Ic4HU3T6zpmKlGUhhziLpyjTXfnwFPnPGYwTsvQnRyAAAAAAIIlbgAEAcjoKV1scxSIAAAAASUVORK5CYII%3D" style="display: block; margin: auto; height: 2.7em;">Video';
		document.getElementById('cpb-full-cams').setAttribute('stream',chokeData[idx]['stream']);
	} else {
		document.getElementById('cpb-full-cams').innerHTML = '<span>o</span>Cameras';
		if (chokeData[idx]['cams'] == 0) document.getElementById('cpb-full-cams').className = 'cpb-cams-disabled';
		document.getElementById('cpb-full-cams').removeAttribute('stream');
	}
	document.getElementById('cpb-full-cams').setAttribute('chokepoint_id',idx);
	document.getElementById('cpb-full-map').setAttribute('chokepoint_id',idx);
	document.getElementById('cpb-full-map').setAttribute('lat',chokeData[idx]['destLat']);
	document.getElementById('cpb-full-map').setAttribute('lng',chokeData[idx]['destLng']);

	/* prime the fav button */
	document.getElementById('cpb-full-fav').setAttribute('chokepoint_id',idx);
	if ( chokeFavs[idx] === 1 ) {
		document.getElementById('cpb-full-fav').setAttribute('fav',1);
		document.getElementById('cpb-full-fav').innerHTML = '<span class="redHeart">l</span>Un-Favorite';
	} else {
		document.getElementById('cpb-full-fav').setAttribute('fav',0);
		document.getElementById('cpb-full-fav').innerHTML = '<span>m</span>Favorite';
	}

	/* throw in the advertisement if exists for now */
	if ( chokeData[idx]['advert_id'] ) {
		document.getElementById('cpb-full-ad').innerHTML = chokeAds[chokeData[idx]['advert_id']];
	} else {
		document.getElementById('cpb-full-ad').innerHTML = '';
	}
}
