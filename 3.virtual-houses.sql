
drop view if exists total_population;
drop view virtual_population;
create or replace view virtual_population as
with
	nsk as (
		select way nskborder
		from residential_polygon
		where osm_id=-366544
	),
	residential_areas as (
		select osm_id, way, st_area(st_transform(way, 4326)::geography) area
		from residential_polygon, nsk
		where
			landuse='residential' and
			residential='rural' and
			st_intersects(way, nskborder)
	),
	total_area as (
		select sum(area) total_area from residential_areas
	),
	portions as (
		select osm_id, area, area/total_area portion
		from residential_areas, total_area
	),
	house_and_area as (
		select houses.id, osm_id, query
		from houses, residential_areas
		where st_within(centroid_913, way)
		and fake
	),
	house_count as (
		select osm_id, count(*) house_number
		from house_and_area
		group by osm_id
	),
	suburb_population as (select 350000 pop)
select id, pop * portion / house_number population
from
	house_and_area haa, portions p,
	suburb_population sp,
	house_count hc
where
	haa.osm_id=p.osm_id and
	haa.osm_id=hc.osm_id
;

create view total_population as
select h.id, centroid_913, centroid, fake, query, coalesce(h.population, vp.population) virtual_population
from houses h left join virtual_population vp
on h.id=vp.id;


update houses set virtual_population=population;
update houses h
set virtual_population=vp.population
from virtual_population vp
where h.id=vp.id;
