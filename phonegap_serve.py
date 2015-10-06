#!/usr/bin/python
import cgi, re
FORM = cgi.FieldStorage()

# this script is used to insert descrepancies whether it's a browser or the Cordova/Phonegap app.

def cordova_swap():
	"""determine cordova specifics and fill swap dictionary with replacements for browser vs app"""
	# gather specifics from cordova param and prime the swap dictionary
	swap = {}
	swap['cordova'] = FORM.getvalue('cordova','0|0|http|0|0|0')
	(swap['ver'],swap['cordver'],swap['platform'],swap['version'],swap['model'],swap['uuid']) = swap['cordova'].split('|',6)
	if int(swap['cordver']) > 3:
		swap['cordova3'] = 'true'
		cordova3 = True
	else:
		swap['cordova3'] = 'false'
		cordova3 = False

	# file location needs a prefix mainly between Cordova and normal web browser
	if swap['platform'] == 'iOS':
		swap['file_location'] = 'cdvfile://localhost/bundle'
	elif swap['platform'] == 'Android':
		swap['file_location'] = 'file:///android_asset'
	else:
		swap['file_location'] = '.'

	# the first of the two below is for production, the second adds debug via debug.build.phonegap.com
	if cordova3:
		swap['phonegap_script'] = "<script type='text/javascript' src='"+ swap['file_location'] +"/www/phonegap.js'></script><script type='text/javascript' charset='utf-8' src='"+ swap['file_location'] +"/www/PushNotification.js'></script>"
		#swap['phonegap_script'] = "<script type='text/javascript' src='"+ swap['file_location'] +"/www/phonegap.js'></script><script type='text/javascript' charset='utf-8' src='"+ swap['file_location'] +"/www/PushNotification.js'></script><script type='text/javascript' src='http://debug.build.phonegap.com/target/target-script-min.js#00ce7624-508e-11e3-bf9a-22000a98b3d6'></script>"

	# if Cordova then load Firebase locally
	if cordova3:
		swap['firebase_js'] = "<script src='"+ swap['file_location'] +"/www/res/js/firebase.js'></script>"
	else:
		swap['firebase_js'] = "<script src='https://cdn.firebase.com/js/client/2.2.7/firebase.js'></script>"

	# for Cordova then @import the fonts in css; if normal browser then link the font in via Google
	# find ttf's here:  https://github.com/google/fonts
	if cordova3:
		swap['font_css'] = """
@font-face {
  font-family: 'Josefin Sans';
  font-style: normal;
  font-weight: 400;
  src: url($swap{'file_location'}/www/res/fonts/JosefinSans-Regular.ttf) format('truetype');
}
@font-face {
  font-family: 'Josefin Sans';
  font-style: italic;
  font-weight: 600;
  src: url($swap{'file_location'}/www/res/fonts/JosefinSans-SemiBoldItalic.ttf) format('truetype');
}"""
	else:
		swap['font_link'] = "<link href='https://fonts.googleapis.com/css?family=Josefin+Sans:400,600italic' rel='stylesheet' type='text/css'>"

	return swap


def finish_and_send(swap):
	"""read in the template, replace swap values, gzip and send"""
	# read in html template
	with open('index.html','r') as template:
		data_raw = template.read()

	# regex in swap{} values
	data_1 = re.sub('~1#(\\d+)_plus_ios_topbar#','\\1',data_raw)
	data_done = re.sub('~1#([^#]+)#',lambda x: swap[x.group(1)] if x.group(1) in swap else None,data_1)

	# gzip output and send
	import zlib
	encoder = zlib.compressobj(9, zlib.DEFLATED, 16 + zlib.MAX_WBITS, zlib.DEF_MEM_LEVEL,0)
	data_zip = encoder.compress(data_done) + encoder.flush()
	print('Content-Type: text/html\nContent-Encoding: gzip\nContent-Length: '+ str(len(data_zip)) +'\n\n'+ data_zip)



finish_and_send(cordova_swap())

raise SystemExit()

