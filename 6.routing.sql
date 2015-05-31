drop view if exists rows_for_car_routing;
create view rows_for_car_routing as
select d.*
from distances d, parks p
where
	d.park=p.id and
	osm_id in (774, 25642909, 25657738);

 /*, 290224818, 25657738, 25642999, 25768832, -512, 36774872, 329894924)*/