create or replace view travel_results as
SELECT
	h.id,
	substr(h.query::text, 14) AS addr,
	h.centroid_913,
	transit_distance / 60 AS minutes ,
	transit_distance / 3600 AS hours,
	osm_id
FROM distances d, houses h, parks p
WHERE
	transit_distance > 0 and
	d.house = h.id AND
	d.park = p.id
;

create or replace view travel_to_center as
SELECT * FROM travel_results
WHERE osm_id = 25642995;

create or replace view travel_to_rechnoy as
SELECT * from travel_results
WHERE osm_id = 847;

create or replace view travel_to_marx as
SELECT * from travel_results
where p.osm_id = -866;

create or replace view bike_win as
WITH x AS (
        SELECT
         	h.id, h.centroid_913, d.population AS pop,
         	d.transit_distance,
         	d.transit_distance - d.car_distance * 3.6::double precision / 12::double precision AS win
        FROM distances d, houses h, parks p
        WHERE d.house = h.id AND d.park = p.id AND p.osm_id = 25642995
        ),
	percents as (
		select id, greatest(win, 0) / transit_distance * 100 win_percent
		from x
		)

 SELECT
 	x.id, x.centroid_913, x.pop,
 	greatest(x.win/60,0) win, x.pop * greatest(x.win/60, 0) AS pw,
 	 win_percent, win_percent * pop as relative_demand
   FROM x, percents
   where x.id=percents.id and win_percent > 0 and pop > 0;


create or replace view weighted_travel as
with
	grouped as (select
		house id,
		avg(transit_distance) / 60 minutes
	from distances d, parks p
	where d.park=p.id
		and osm_id in (
			25642995, /* lenin square */
			-866, /* marx square */
			25768832 /* circus */
		)
		and transit_distance is not null
	group by house
)
select g.id, centroid_913, minutes, population
from 
	grouped g, houses h
where g.id=h.id;
