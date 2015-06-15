psql nskparks < 8.distance-results.sql
psql nskparks -c 'copy (select * from distance_profile_results) to stdout csv header;' > 8.distance-results.csv