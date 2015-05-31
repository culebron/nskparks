DROP TABLE IF EXISTS houses;
create table houses (
	id serial primary key,
	query char(100),
	centroid geometry,
	centroid_913 geometry,
	population integer
);