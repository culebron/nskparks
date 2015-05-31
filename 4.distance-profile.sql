CREATE TABLE if not exists distances
(
   park integer NOT NULL, 
   house integer NOT NULL, 
   distance double precision, 
   population integer,
   PRIMARY KEY (park, house), 
   FOREIGN KEY (house) REFERENCES houses (id) ON UPDATE NO ACTION ON DELETE cascade, 
   FOREIGN KEY (park) REFERENCES parks (id) ON UPDATE NO ACTION ON DELETE cascade
);
delete from distances;
	
insert into distances
select
	parks.id, houses.id, 
	(parks.contour_913 <-> houses.centroid_913)
	* cos(radians(st_y(st_setsrid(houses.centroid, 4326)))),
	population
from parks, houses;


create table if not exists distance_profile
(
   park integer NOT NULL, 
   distance double precision not null, 
   people_local integer not null default 0,
   people_total integer not null default 0,
   PRIMARY KEY (park, distance), 
   FOREIGN KEY (park) REFERENCES parks (id) ON UPDATE NO ACTION ON DELETE cascade
);
delete from distance_profile;

insert into distance_profile
	(park, distance)
with
	x as (select park, max(distance::int) md from distances group by park)
select x.park, generate_series(250, x.md, 250) dst from x;

with
	local_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, distances b
		where
			a.park = b.park
			and b.distance <= a.distance
			and b.distance >= a.distance - 250
		group by a.park, a.distance
	)
update distance_profile dp
set people_local = local_data.pop
from local_data
where dp.park = local_data.park
 and dp.distance = local_data.distance;

with
	total_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, distances b
		where
			a.park = b.park
			and b.distance <= a.distance
		group by a.park, a.distance
	)
update distance_profile dp
set people_total = td.pop
from total_data td
where dp.park = td.park and dp.distance = td.distance;

