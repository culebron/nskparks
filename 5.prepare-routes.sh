psql nskparks < 5.prepare-routes.sql
# psql nskparks -c 'copy (select * from rows_for_car_routing) to stdout csv header;' > 6.routes.csv
