delete from distance_profile where dtype='car';
insert into distance_profile
	(park, distance, dtype)
with
	x as (select park, max(car_distance::int) md from distances where car_distance is not null group by park)
select park, generate_series(250, md, 250) dst, 'car' from x;

with
	local_data as (
		select
			a.park, a.distance, sum(b.population) pop
		from
			distance_profile a, (select park, house, car_distance distance, population from distances where car_distance is not null) b
		where
			a.park = b.park
			and b.distance <= a.distance
			and b.distance >= a.distance - 250
			and a.dtype = 'car'
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
			and a.dtype = 'car'
		group by a.park, a.distance
	)
update distance_profile dp
set people_total = td.pop
from total_data td
where dp.park = td.park
	and dp.distance = td.distance
	and dp.dtype = 'car';
