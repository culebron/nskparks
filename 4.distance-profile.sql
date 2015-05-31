create type distance_type as enum ('direct', 'car', 'public');
create type aggregate_type as enum ('local', 'total');

CREATE TABLE if not exists distances
(
   park integer NOT NULL, 
   house integer NOT NULL, 
   dtype distance_type default 'direct',
   distance double precision, 
   population integer,
   PRIMARY KEY (park, house, dtype), 
   FOREIGN KEY (house) REFERENCES houses (id) ON UPDATE NO ACTION ON DELETE cascade, 
   FOREIGN KEY (park) REFERENCES parks (id) ON UPDATE NO ACTION ON DELETE cascade
);
delete from distances;

insert into distances
select
	parks.id, houses.id, 'direct',
	(parks.contour_913 <-> houses.centroid_913)
	* cos(radians(st_y(st_setsrid(houses.centroid, 4326)))),
	population
from parks, houses;


create table if not exists distance_profile
(
   park integer NOT NULL, 
   distance double precision not null, 
   dtype distance_type default 'direct',
   atype aggregate_type default 'local',
   people integer not null default 0,
   PRIMARY KEY (park, distance, dtype, atype), 
   FOREIGN KEY (park) REFERENCES parks (id) ON UPDATE NO ACTION ON DELETE cascade
);
delete from distance_profile;

insert into distance_profile
	(park, distance, dtype, atype)
with
	x as (select park, max(distance::int) md, dtype from distances group by park, dtype)
select
	park, generate_series(250, md, 250) dst, dtype, 'local' from x;

insert into distance_profile (park, distance, dtype, atype)
select park, distance, dtype, 'total' from distance_profile;

with
	local_data as (
		select
			a.park, a.distance, a.dtype, sum(b.population) pop
		from
			distance_profile a, distances b
		where
			a.park = b.park
			and b.distance <= a.distance
			and b.distance >= a.distance - 250
		group by a.park, a.distance, a.dtype
	)
update distance_profile dp
set people = local_data.pop
from local_data
where  dp.park = local_data.park
	and atype = 'local'
	and dp.dtype = local_data.dtype
	and dp.distance = local_data.distance;

with
	total_data as (
		select
			a.park, a.distance, a.dtype, sum(b.population) pop
		from
			distance_profile a, distances b
		where
			a.park = b.park
			and a.atype = 'local'
			and b.distance <= a.distance
		group by a.park, a.distance, a.dtype
	)
update distance_profile dp
set people = td.pop
from total_data td
where dp.park = td.park
	and atype = 'total'
	and dp.distance = td.distance
	and dp.dtype = td.dtype;
