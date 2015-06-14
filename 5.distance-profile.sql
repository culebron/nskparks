create type distance_type as enum('direct', 'car', 'transit');
create table if not exists distance_profile
(
   park integer NOT NULL, 
   distance double precision not null, 
   dtype distance_type,
   people_local integer not null default 0,
   people_total integer not null default 0,
   PRIMARY KEY (park, distance, dtype), 
   FOREIGN KEY (park) REFERENCES parks (id) ON UPDATE NO ACTION ON DELETE cascade
);


/* direct */
delete from distance_profile where dtype='direct';

insert into distance_profile
	(park, distance, dtype)
with
	x as (select park, max(direct_distance::int) md from distances group by park)
select park, generate_series(250, md, 250) dst, 'direct' from x;

with
	local_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, (select park, house, direct_distance distance, population from distances) b
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
	and dp.dtype = 'direct'
	and dp.distance = local_data.distance;

with
	total_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, (select park, house, direct_distance distance, population from distances) b
		where
			a.park = b.park
			and b.distance <= a.distance
		group by a.park, a.distance
	)
update distance_profile dp
set people_total = td.pop
from total_data td
where dp.park = td.park
	and dp.distance = td.distance
	and dp.dtype = 'direct';



/* car */
delete from distance_profile where dtype='car';

insert into distance_profile
	(park, distance, dtype)
with
	x as (select park, max(car_distance::int) md from distances group by park)
select park, generate_series(250, md, 250) dst, 'car' from x;

with
	local_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, (select park, house, car_distance distance, population from distances) b
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
	and dp.dtype = 'car'
	and dp.distance = local_data.distance;

with
	total_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, (select park, house, car_distance distance, population from distances) b
		where
			a.park = b.park
			and b.distance <= a.distance
		group by a.park, a.distance
	)
update distance_profile dp
set people_total = td.pop
from total_data td
where dp.park = td.park
	and dp.distance = td.distance
	and dp.dtype = 'car';



/* transit */
delete from distance_profile where dtype='transit';

insert into distance_profile
	(park, distance, dtype)
with
	x as (select park, max(transit_distance::int) md from distances group by park)
select park, generate_series(300, md, 300) dst, 'transit' from x;

with
	minimum_time as (
		select
			park, house, population,
			least(transit_distance, direct_distance/1000/5*3600) distance
		from distances),
	local_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, minimum_time b
		where
			a.park = b.park
			and b.distance <= a.distance
			and b.distance >= a.distance - 300
		group by a.park, a.distance
	)
update distance_profile dp
set people_local = local_data.pop
from local_data
where dp.park = local_data.park
	and dp.dtype = 'transit'
	and dp.distance = local_data.distance;

with
	minimum_time as (
		select
			park, house, population,
			least(transit_distance, direct_distance/1000/5*3600) distance
		from distances),
	total_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, minimum_time b
		where
			a.park = b.park
			and b.distance <= a.distance
		group by a.park, a.distance
	)
update distance_profile dp
set people_total = td.pop
from total_data td
where dp.park = td.park
	and dp.distance = td.distance
	and dp.dtype = 'transit';
