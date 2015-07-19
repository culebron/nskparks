
drop view direct_distances;
create or replace view direct_distances as
with grouped as (select park, ceiling(direct_distance/1000)::int dist, sum(virtual_population) people from distances d, houses h where d.house=h.id group by park, dist)
select name, dist, people
from grouped g, parks p
where g.park=p.id;

drop view car_distances;
create or replace view car_distances as
with grouped as (select park, ceiling(car_distance/1000)::int dist, sum(virtual_population) people from distances d, houses h where d.house=h.id group by park, dist)
select name, dist, people
from grouped g, parks p
where g.park=p.id;

drop view transit_distances;
create or replace view transit_distances as
with grouped as (select park, ceiling(transit_distance/60/5)::int*5 dist, sum(virtual_population) people from distances d, houses h where d.house=h.id group by park, dist)
select name, dist, people
from grouped g, parks p
where g.park=p.id;


drop view transit_effort;
create or replace view transit_effort as
with grouped as (select park, ceiling(transit_effort/60/10)::int*10 dist, sum(virtual_population) people from distances d, houses h where d.house=h.id group by park, dist)
select name, dist, people
from grouped g, parks p
where g.park=p.id;


