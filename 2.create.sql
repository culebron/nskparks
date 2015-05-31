CREATE TABLE if not exists parks (
    id serial primary key,
    osm_id integer unique,
    name character varying(255),
    contour geometry,
    contour_913 geometry
);

delete from parks;

insert into parks ( osm_id, name, contour, contour_913 )
	select osm_id, name, way, st_transform(way, 900913)
		from osm_polygon
		where name is not null;

