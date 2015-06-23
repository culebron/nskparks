insert into houses (centroid_913, centroid, fake)
with 
	buffered as (select st_union(st_buffer(centroid_913, 250)) buff from houses),
	centroids as (select st_centroid(way) ctr from transit_polygon where landuse in ('residential', 'allotments'))
select
	ctr centroid_913,
	st_transform(ctr, 4326) centroid,
	true fake
from centroids, buffered
where not st_within(ctr, buff);

/* generate 250*.57m grid in residential and allotments areas, not near real houses */
insert into houses (centroid_913, centroid, fake)
with gen as (SELECT
		way,
		/* grid from min to max x and y */
		generate_series(floor(st_xmin(way))::int, ceiling(st_xmax(way))::int, 250) as x,
		generate_series(floor(st_ymin(way))::int, ceiling(st_ymax(way))::int, 250) as y 
		from transit_polygon
		where landuse in ('residential', 'allotments')
	),
	pts as (SELECT st_setsrid(st_point(x,y),900913) pt, way FROM gen),
	buffered as (select st_union(st_buffer(centroid_913, 250)) buff from houses)
select pt, st_transform(pt, 4326) pt_4326, true
from pts, buffered
where st_intersects(way,pt) and not st_within(pt, buffered.buff);

/* points inside novosibirsk area, every 500 m */
insert into houses (centroid_913, centroid, fake)
with
	buffered as (select st_union(st_buffer(centroid_913, 250)) buff from houses),
	river as (select st_union(way) banks from transit_polygon where waterway is not null or "natural"='water'),
	gen as (
		select
			way,
			generate_series(floor(st_xmin(way))::int, ceiling(st_xmax(way))::int, 500) as x,
			generate_series(floor(st_ymin(way))::int, ceiling(st_ymax(way))::int, 500) as y 
	 	from transit_polygon where osm_id=-1751445
	 ),
	pts as (SELECT st_setsrid(st_point(x,y),900913) pt, way FROM gen)
select pt, st_transform(pt, 4326) pt_4326, true
from pts, buffered, river
where st_intersects(way, pt) and not st_within(pt, buffered.buff) and not st_within(pt, banks);

/* points on major roads */
insert into houses (centroid_913, centroid, fake)
with
	buffered as (select st_union(st_buffer(centroid_913, 250)) buff from houses),
    section as (select 250 len),
    raw_data as (
        select 
            -- real length in meters
            st_length(st_transform(way, 4326)::geography) real_length,
            -- scale factor due to latitude 
            1/cos(radians(st_y(st_transform(st_centroid(way), 4326)))) aspect_ratio,
            way
        from transit_roads
        where highway is not null
    ),
    repeated as (
        select
            real_length, aspect_ratio,
            ST_AddMeasure((ST_Dump(way)).geom, 0::float, real_length) way,
            generate_series(len, real_length::int, section.len::int) section_stop
        from
            section, raw_data
    ),
    generated as (
	select real_length, 
	    ST_Locate_along_measure(way, section_stop*aspect_ratio) as centroid_913
	from repeated rp)
select st_setsrid(centroid_913, 900913), st_transform(centroid_913, 4326) centroid, true
from 
	buffered, generated
where not st_isempty(centroid_913) and not st_within(centroid_913, buff);




update houses set query='fake ' || id where fake;

insert into distances (park, house)
select p.id, h.id from parks p, houses h where fake=true and osm_id in (25642995, 25642909, 847)
and h.id not in (select house from distances group by house)
;

