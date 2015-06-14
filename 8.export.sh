psql nskparks < 7.direct-distance-results.sql
psql nskparks -c 'copy (select * from distance_profile_results) to stdout csv header;' > 7.distance-results.csv