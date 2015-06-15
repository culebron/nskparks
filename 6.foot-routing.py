# requires packages: psycopg2, requests

import sys

from psycopg2 import connect
from psycopg2.extras import RealDictCursor
from requests import get
from urllib import urlencode
from urlparse import urlunsplit
from json import loads
from time import sleep


connection = connect(database='nskparks', cursor_factory=RealDictCursor)
read_cursor = connection.cursor()
connection2 = connect(database='nskparks')
write_cursor = connection2.cursor()

base_url = "https://graphhopper.com/api/1/route"
base_referer = 'http://www.openstreetmap.org/directions'

url_params = {
	'vehicle': 'foot',
	'locale': 'ru',
	'key': 'LijBPDQGfu7Iiq80w3HzwB4RUDJbMbhs6BU0dEnn',
	'type': 'json',
	'elevation': False,
	'instructions': False,
	'_': 1433419853347
}

referer_params = {'engine': 'graphhopper_foot'}

# where osm_id in (290224818, 25642999, 25768832)

if len(sys.argv) == 1:
	print 'specify parks osm ids (numbers, space-separated)'
	sys.exit(1)

read_cursor.execute('select * from rows_for_routing '
	'where transit_distance is null and direct_distance <= 2000 '
	'and osm_id in %s', (tuple(int(i) for i in sys.argv[1:]),))
for row in read_cursor:
	sleep(.5)
	url_args = url_params.copy()
	url_args.update({'point': [row['house_center'], row['park_center']]})
	url = urlunsplit(('', '', base_url, urlencode(url_args, True), None))

	ref_args = referer_params.copy()
	ref_args['route'] = '%s;%s' % (row['house_center'], row['park_center'])
	referer = urlunsplit(('', '', base_referer, urlencode(ref_args, True), None))

	print row['house_center'], row['park_center'], row['name']

	resp = get(url, headers={'Referer': referer})
	
	try:	
		data = loads(resp.content)
	except ValueError:
		print 'no route: ', row
		print 'response: ', resp.content
		continue
	
	try:
		dist = data['paths'][0]['distance']
	except KeyError:
		print 'no route: ', row
		print 'response: ', data.content
		continue

	print dist

	# надо переписать, это записывается в раздел "общ. транспорт"
	# write_cursor.execute('update distances set transit_distance=%s where park=%s and house=%s;',
		(dist, row['park'], row['house']))

	connection2.commit()
