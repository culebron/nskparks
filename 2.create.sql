CREATE TABLE if not exists parks (
    id serial primary key,
    osm_id integer unique,
    name character varying(255),
    contour_913 geometry,
    contour geometry
);

delete from parks;

insert into parks ( osm_id, name, contour, contour_geo )
	select osm_id, name, way, st_transform(way, 4326)
		from osm_polygon
		where name is not null;

