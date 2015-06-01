drop view if exists rows_for_car_routing;
create view rows_for_car_routing as
with
	park_data as (select id, st_centroid(contour) park_center, name from parks where osm_id in (774, 25642909, 25657738)),
	house_data as (select id, centroid house_center, query addr from houses)
select
	park, name, house, addr,
	st_y(park_center) || ',' || st_x(park_center) park_center,
	st_y(house_center) || ',' || st_x(house_center) house_center
from distances d, park_data p, house_data h
where
	d.park = p.id and
	d.house = h.id and
	car_distance is null;


 /*, 290224818, 25657738, 25642999, 25768832, -512, 36774872, 329894924)*/