drop view if exists distance_profile_results;
create view distance_profile_results as
	select p.id, p.osm_id, p.name, dp.dtype, dp.distance, dp.people_local, dp.people_total
	from distance_profile dp, parks p
	where dp.park = p.id;
