create table if not exists houses (
	id serial primary key,
	query char(100),
	centroid geometry,
	centroid_913 geometry,
	population integer
);

delete from houses;