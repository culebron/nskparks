drop view if exists rows_for_car_routing;
create view rows_for_car_routing as
with
	notfound as (
		select
			p.id park, p.name, h.id house, h.query addr,
			astext(st_transform(centroid(p.contour), 4326)) park_center,
			astext(h.centroid) house_center
		from
			parks p inner join houses h on osm_id in (774, 25642909, 25657738)
			left join distances d on (
				p.id=d.park and 
				d.dtype='car' and
				h.id=d.house)
		where
			d.park is null and
			h.population > 0

	)
select
	park, name, house, addr,
	st_y(park_center) || ',' || st_x(park_center) park_center,
	st_y(house_center) || ',' || st_x(house_center) house_center
from notfound;


 /*, 290224818, 25657738, 25642999, 25768832, -512, 36774872, 329894924)*/