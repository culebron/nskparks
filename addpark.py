import sys

from psycopg2 import connect
from psycopg2.extras import RealDictCursor

if len(sys.argv) < 2:
	print 'usage: $ search.py [osm_id1] [osm_id2]'

connection = connect(database='nskparks', cursor_factory=RealDictCursor)
cursor = connection.cursor()

cursor.execute('''
insert into parks ( osm_id, name, contour_913, contour )
select osm_id, name, way, st_transform(way, 4326)
from osm_polygon
where name is not null and leisure='park' and osm_id in (select unnest(%s)::int x)
''', (sys.argv[1:],))

cursor.execute("""

insert into distances (park, house, direct_distance, population)
select
	parks.id, houses.id,
	(parks.contour_913 <-> houses.centroid_913)
	* cos(radians(st_y(st_setsrid(houses.centroid, 4326)))),
	population
from parks, houses
where parks.osm_id in (select unnest(%s)::int x)
""", (sys.argv[1:],))


connection.commit()
