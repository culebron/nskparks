insert into houses (id, centroid_913, centroid, fake)
with 
	buffered as (select st_union(st_buffer(centroid_913, 250)) buff from houses),
	centroids as (select st_centroid(way) ctr from osm_polygon where landuse='residential')
select
	nextval('houses_id_seq'),
	ctr centroid_913,
	st_transform(ctr, 4326) centroid,
	true fake
from centroids, buffered
where not st_within(ctr, buff);

insert into houses (id, centroid_913, centroid, fake)
with gen as (SELECT
		way,
		generate_series(floor(st_xmin(way))::int, ceiling(st_xmax(way))::int, 250) as x,
		generate_series(floor(st_ymin(way))::int, ceiling(st_ymax(way))::int, 250) as y 
		from osm_polygon
		where landuse='residential'
	),
	pts as (SELECT st_setsrid(st_point(x,y),900913) pt, way FROM gen),
	buffered as (select st_union(st_buffer(centroid_913, 250)) buff from houses)
select nextval('houses_id_seq'), pt, st_transform(pt, 4326) pt_4326, true
from pts, buffered
where st_intersects(way,pt) and not st_within(pt, buffered.buff);

update houses set query='fake ' || id where fake;

insert into distances (park, house)
select p.id, h.id from parks p, houses h where fake=true and osm_id in (25642995, 25642909, 847);
