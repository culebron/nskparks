delete from houses where fake;
/* generate 250x.57m grid in residential and allotments areas, not near real houses */
insert into houses (centroid_913, centroid, fake)
with genx as (
		select osm_id, way,
			generate_series(floor(st_xmin(way))::int, ceiling(st_xmax(way))::int, 200) as x
		from transit_polygon
		where landuse='residential' and residential='rural'),
	geny as (
		select osm_id, 
			generate_series(floor(st_ymin(way))::int, ceiling(st_ymax(way))::int, 200) as y
		from transit_polygon
		where landuse='residential' and residential='rural'),
	gen as (
		select
			genx.osm_id, genx.way,
			/* grid from min to max x and y */
			x, y
		from genx, geny
		where genx.osm_id=geny.osm_id
	),
	/* convert x & y into points */
	pts as (SELECT st_setsrid(st_point(x,y),900913) pt, way FROM gen),

	/* a 35-meter buffer around existing houses */
	buffered as (select st_union(st_buffer(centroid_913, 100)) buff from houses)
select pt, st_transform(pt, 4326) pt_4326, true
from pts, buffered
where st_intersects(way,pt) and not st_within(pt, buffered.buff);


/* insert centroids into areas that have no (virtual) points inside */
insert into houses (centroid_913, centroid, fake)
with
	/* left join to find empty areas */
	orphan_areas as (
		select osm_id, way, houses.id
		from transit_polygon
			left join houses on
			fake and st_within(centroid_913, way)
		where landuse='residential'
		and residential='rural'
		and houses.id is null
	),

	/* insert those points into the areas */
	centroids as (
		select centroid(way) ctr from orphan_areas)

select
	ctr centroid_913,
	st_transform(ctr, 4326) centroid,
	true fake
from centroids;


/* points inside novosibirsk area, every 500 m */
insert into houses (centroid_913, centroid, fake)
with
	buffered as (select st_union(st_buffer(centroid_913, 436)) buff from houses),
	river as (select st_union(way) banks from transit_polygon where waterway is not null or "natural"='water'),
	genx as (
		select
			st_convexhull(way) convex_way,
			generate_series(floor(st_xmin(way))::int, ceiling(st_xmax(way))::int, 872) as x
	 	from transit_polygon where osm_id=-1751445
	),
	geny as (
		select
			generate_series(floor(st_ymin(way))::int, ceiling(st_ymax(way))::int, 872) as y
	 	from transit_polygon where osm_id=-1751445
	),
	gen as (
		select
			convex_way, x, y
		from genx, geny
 	),
	pts as (SELECT st_setsrid(st_point(x,y),900913) pt, convex_way FROM gen)
select pt, st_transform(pt, 4326) pt_4326, true
from pts, buffered, river
where
	st_intersects(convex_way, pt)
	and not st_within(pt, buffered.buff)
	and not st_within(pt, banks);

/* points on major roads */
insert into houses (centroid_913, centroid, fake)
with
	buffered as (select st_union(st_buffer(centroid_913, 50)) buff from houses),
    section as (select 250 len),
    raw_data as (
        select 
            -- real length in meters
            st_length(st_transform(way, 4326)::geography) real_length,
            -- scale factor due to latitude 
            1/cos(radians(st_y(st_transform(st_centroid(way), 4326)))) aspect_ratio,
            way
        from transit_roads
        where highway in ('primary', 'secondary', 'trunk', 'primary_link', 'trunk_link', 'secondary_link')
    ),
    repeated as (
        select
            real_length, aspect_ratio,
            ST_AddMeasure((ST_Dump(way)).geom,
            0::float, real_length) way,
            generate_series(len, real_length::int, section.len::int) section_stop
        from
            section, raw_data
    ),
    generated as (
	select real_length, 
	    ST_Locate_along_measure(way, section_stop*aspect_ratio) as centroid_913
	from repeated rp)
select
	st_setsrid(centroid_913, 900913),
	st_transform(centroid_913, 4326) centroid,
	true
from 
	buffered, generated
where not st_isempty(centroid_913) and not st_within(centroid_913, buff);




update houses set query='fake ' || id where fake;

insert into distances (park, house)
select p.id, h.id from parks p, houses h where fake and osm_id in (25642995, 25642909, 847, -866)
and h.id not in (select house from distances group by house)
;

