create table if not exists houses (
	id serial primary key,
	query char(100),
	centroid geometry,
	centroid_913 geometry,
	population double precision,
	virtual_population double precision
);

create index houses_id_ind on houses (id);
delete from houses;