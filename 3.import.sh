psql nskparks < 3.houses.sql
psql nskparks -c "copy houses (query, centroid, population) from stdin delimiter ',' csv;" < 3.houses.csv
psql nskparks -c "update houses set centroid_913=transform(st_setsrid(centroid, 4326), 900913), centroid=st_setsrid(centroid, 4326); "