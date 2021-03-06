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
	'where transit_distance is null and transit_json is null '
	'and osm_id in %s', (tuple(int(i) for i in ids),))
for row in read_cursor:
	sleep(.2)
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
		items = data['result']['items']
	except KeyError:
		print 'no route: ', row
		print 'response: ', data
		write_cursor.execute('update distances set transit_json=%s where park=%s and house=%s;',
		(resp.content, row['park'], row['house']))	
		connection2.commit()
		continue

	def calc_item(item):
		travel_time = 0
		for move in item['movements']:
			if move['type'] == 'walkway':
				travel_time += move['distance'] / 4. * 3.6
				continue
			if move['type'] == 'passage':
				tmp = move['movement_duration']
				# print move['waiting_duration']
				routes = sum(len(alt['routes']) for alt in move['alternatives'])
				tmp += float(move['waiting_duration']) / max(routes - 1, 1)
				# print 'move before: ', move['total_duration'], ' after: ', tmp, 'routes', routes
				travel_time += tmp
				continue
			travel_time += move['total_duration'] # не movement_duration, это только поездки без ожидания
		return travel_time

	travel_time = min(calc_item(item) for item in items)

	print row['name'], row['addr'].strip(), int(items[0]['total_duration']/60.), round(travel_time / 60.), 'минут'

	# надо переписать, это записывается в раздел "общ. транспорт"
	write_cursor.execute('update distances set transit_distance=%s, transit_json=%s where park=%s and house=%s;',
		(travel_time, resp.content, row['park'], row['house']))

	connection2.commit()
