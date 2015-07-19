# -*- coding: utf-8 -*-

# requires packages: psycopg2, requests

import sys
import gc
from psycopg2 import connect
from psycopg2.extras import RealDictCursor
from requests import get
from urllib import urlencode
from urlparse import urlunsplit
from json import loads
from time import sleep


coefficient = {'wait': 1.63, 'walkway': 2.795, 'crossing': .696}


def calc_items(items, row):
	def _item(item):
		if len(item['movements']) == 1:
			val = row['direct_distance'] / 4. * 3.6
			return val, val * coefficient['walkway']

		travel_effort = 0
		travel_time = 0

		for move in item['movements']:
			if move['type'] in ('walkway', 'crossing'):
				diff = move['distance'] / 4. * 3.6
				travel_time += diff
				travel_effort += diff * coefficient[move['type']]
				continue

			if move['type'] == 'passage':
				diff = move['movement_duration']
				travel_time += diff
				travel_effort += diff
				# print move['waiting_duration']
				routes = sum(len(alt['routes']) for alt in move['alternatives'])
				diff = float(move['waiting_duration']) / max(routes - 1, 1)
				travel_time += diff
				travel_effort += diff * coefficient['wait']
				# print 'move before: ', move['total_duration'], ' after: ', tmp, 'routes', routes
				
				continue

			print 'not parsed', move['type']
			travel_effort += move['total_duration'] # не movement_duration, это только поездки без ожидания
			travel_time += move['total_duration'] # не movement_duration, это только поездки без ожидания
		return travel_time, travel_effort

	travel_time, travel_effort = zip(*(_item(item) for item in items))
	return min(travel_time), min(travel_effort)



if __name__ == '__main__':
	connection = connect(database='nskparks', cursor_factory=RealDictCursor)
	read_cursor = connection.cursor()
	connection2 = connect(database='nskparks')
	write_cursor = connection2.cursor()

	while True:
		read_cursor.execute('select count(*) totals from distances where transit_effort is null and transit_json is not null')
		print read_cursor.fetchone()['totals'], 'rows left'

		bad = set()
		read_cursor.execute('select house, park, transit_json, direct_distance from distances where transit_json is not null and transit_effort is null order by house limit 10000')
		total_rows = read_cursor.rowcount

		for row in read_cursor:
			try:	
				data = loads(row['transit_json'])
			except ValueError:
				bad.add((row['house'], row['park']))
				#print 'no route: ', row
				#print 'response: ', row['transit_json']
				continue
			
			try:
				items = data['result']['items']
			except KeyError:
				bad.add((row['house'], row['park']))
				# print 'no route: ', row
				# print 'response: ', data
				continue

			
			travel_time, travel_effort = calc_items(items, row)

			# print row['house'], row['park'], 'было', \
			#  	int(items[0]['total_duration']/60.), 'стало время', \
			#  	round(travel_time/60.), 'усилие', round(travel_effort / 60.), 'минут'

			# надо переписать, это записывается в раздел "общ. транспорт"
			write_cursor.execute('update distances set transit_effort=%s, transit_distance=%s where park=%s and house=%s;',
				(travel_effort, travel_time, row['park'], row['house']))
	 
		if total_rows - len(bad) == 0:
			break

		connection2.commit()
		gc.collect()
			