# -*- coding: utf-8 -*-

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


# where osm_id in (290224818, 25642999, 25768832)

if len(sys.argv) == 1:
	print 'usage: transit-routing.py [api key] [osm_id1] [osm_id2] etc.'
	sys.exit(1)

api_key, ids = sys.argv[1], sys.argv[2:]

base_url = "http://catalog.api.2gis.ru/2.0/transport/calculate_routes"

url_params = {
	'type': 'json',
	'key': api_key
}

read_cursor.execute('select * from rows_for_routing '
	'where transit_distance is null '
	'and osm_id in %s', (tuple(int(i) for i in ids),))
for row in read_cursor:
	sleep(.3)
	url_args = url_params.copy()
	url_args.update({'start': row['house_center_lonlat'], 'end': row['park_center_lonlat']})
	url = urlunsplit(('', '', base_url, urlencode(url_args, True), None))


	resp = get(url)
	
	try:	
		data = loads(resp.content)
	except ValueError:
		print 'no route: ', row
		print 'response: ', resp.content
		continue
	
	try:
		travel_time = data['result']['items'][0]['total_duration']
	except KeyError:
		print 'no route: ', row
		print 'response: ', data
		continue

	print row['name'], row['addr'].strip(), round(travel_time / 60.), 'минут'

	# надо переписать, это записывается в раздел "общ. транспорт"
	write_cursor.execute('update distances set transit_distance=%s where park=%s and house=%s;',
		(travel_time, row['park'], row['house']))

	connection2.commit()