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
	print 'usage: json-to-time.py [osm_id1] [osm_id2] etc.'
	sys.exit(1)

ids = sys.argv[1:]


read_cursor.execute('select house, park, transit_json from distances d, parks p '
	'where transit_json is not null '
	'and house=18001 and d.park=p.id and osm_id in %s', (tuple(int(i) for i in ids),))
for row in read_cursor:
	
	try:	
		data = loads(row['transit_json'])
	except ValueError:
		print 'no data: ', row
		continue
	
	try:
		items = data['result']['items']
	except KeyError:
		print 'no route: ', row
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
	print 'before:' , items[0]['total_duration'], ' after: ', travel_time
	# print row['name'], row['addr'].strip(), round(travel_time / 60.), 'минут'

	# надо переписать, это записывается в раздел "общ. транспорт"
	write_cursor.execute('update distances set transit_distance=%s where park=%s and house=%s;',
	 	(travel_time, row['park'], row['house']))
connection2.commit()

