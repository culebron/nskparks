# requires packages: psycopg2, requests

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

read_cursor.execute('select * from rows_for_car_routing')
for row in read_cursor:
	args = {'loc': [row['house_center'], row['park_center']]}
	url = urlunsplit(('', '', base_url, urlencode(args, True), None))
	resp = get(url)
	data = loads(resp.content)
	dist = data['route_summary']['total_distance']

	write_cursor.execute('update distances set car_distance=%s where park=%s and house=%s;',
		(dist, row['park'], row['house']))

	print row, 'distance: ', dist
	connection2.commit()
	sleep(1)
