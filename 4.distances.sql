CREATE TABLE if not exists distances
(
   park integer NOT NULL,
   house integer NOT NULL,
   direct_distance double precision,
   car_distance double precision,
   transit_distance double precision,
   transit_json text
   population integer,
   PRIMARY KEY (park, house), 
   FOREIGN KEY (house) REFERENCES houses (id) ON UPDATE NO ACTION ON DELETE cascade, 
   FOREIGN KEY (park) REFERENCES parks (id) ON UPDATE NO ACTION ON DELETE cascade
);
delete from distances;

insert into distances (park, house, direct_distance, population)
select
	parks.id, houses.id,
	(parks.contour_913 <-> houses.centroid_913)
	* cos(radians(st_y(st_setsrid(houses.centroid, 4326)))),
	population
from parks, houses;
