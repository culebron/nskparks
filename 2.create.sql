CREATE TABLE if not exists parks (
    id serial primary key,
    osm_id integer unique,
    name character varying(255),
    contour geometry,
    contour_913 geometry
);

delete from parks;

insert into parks ( osm_id, name, contour_913, contour )
	select osm_id, name, way, st_transform(way, 4326)
		from osm_polygon
		where name is not null and leisure='park';

