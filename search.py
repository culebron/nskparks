import sys

from psycopg2 import connect
from psycopg2.extras import RealDictCursor

if len(sys.argv) < 2:
	print 'usage: $ search.py [string 1] [string 2]'
search = sys.argv[1:]

connection = connect(database='nskparks', cursor_factory=RealDictCursor)
read_cursor = connection.cursor()

read_cursor.execute("with strings as (select unnest(%s) x) select distinct osm_id, name from osm_polygon, strings where name like '%%' || x || '%%'", (search,))

for i in read_cursor:
	print i['osm_id'], i['name']