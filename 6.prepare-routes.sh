psql nskparks < 6.prepare-routes.sql
psql nskparks -c 'copy (select * from rows_for_car_routing) to stdout csv header;' > 6.routes.csv
# python 6.route-houses.py