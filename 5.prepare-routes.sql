drop view if exists rows_for_routing;
create view rows_for_routing as
with
	park_data as (select id, osm_id, st_centroid(contour) park_center, name from parks),
	house_data as (select id, centroid house_center, query addr, fake from houses)
select
	park, osm_id, name, house, addr, fake,
	st_y(park_center) || ',' || st_x(park_center) park_center,
	st_y(house_center) || ',' || st_x(house_center) house_center,
	st_x(park_center) || ',' || st_y(park_center) park_center_lonlat,
	st_x(house_center) || ',' || st_y(house_center) house_center_lonlat,
	car_distance, transit_distance, direct_distance, transit_json
from distances d, park_data p, house_data h
where
	d.park = p.id and
	d.house = h.id
order by park, addr;

/* (774, 25642909, 25657738) naberezhn, central, roscha */
/* where osm_id in (290224818, 25642999, 25768832) */
/* -512 36774872 329894924 */
 /*, 290224818, 25657738, 25642999, 25768832, -512, 36774872, 329894924)*/