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

base_url = "http://router.project-osrm.org/viaroute"

# where osm_id in (290224818, 25642999, 25768832)

if len(sys.argv) == 1:
	print 'specify parks osm ids (numbers, space-separated)'
	sys.exit(1)

read_cursor.execute('select * from rows_for_routing where car_distance is null and osm_id in %s', (tuple(int(i) for i in sys.argv[1:]),))
for row in read_cursor:
	sleep(.5)
	args = {'loc': [row['house_center'], row['park_center']]}
	url = urlunsplit(('', '', base_url, urlencode(args, True), None))
	resp = get(url)
	try:	
		data = loads(resp.content)
	except ValueError:
		print 'no route: ', row
		print 'response: ', resp.content
		continue
	
	try:
		dist = data['route_summary']['total_distance']
	except KeyError:
		print 'no route: ', row
		print 'response: ', data.content
		continue

	write_cursor.execute('update distances set car_distance=%s where park=%s and house=%s;',
		(dist, row['park'], row['house']))

	connection2.commit()
