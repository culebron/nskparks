create table if not exists distance_type
	(name char(20) not null PRIMARY key);


CREATE TABLE if not exists distances
(
   park integer NOT NULL, 
   house integer NOT NULL, 
   direct_distance double precision, 
   car_distance double precision,
   transit_distance double precision,
   population integer,
   PRIMARY KEY (park, house, dtype), 
   FOREIGN KEY (house) REFERENCES houses (id) ON UPDATE NO ACTION ON DELETE cascade, 
   FOREIGN KEY (park) REFERENCES parks (id) ON UPDATE NO ACTION ON DELETE cascade
);
delete from distances;

insert into distances (park, house, direct_distance, population)
select
	parks.id, houses.id, 'direct',
	(parks.contour_913 <-> houses.centroid_913)
	* cos(radians(st_y(st_setsrid(houses.centroid, 4326)))),
	population
from parks, houses;


