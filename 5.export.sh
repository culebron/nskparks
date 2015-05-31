psql nskparks < 5.direct-distance-results.sql
psql nskparks -c 'copy (select * from distance_profile_results) to stdout csv header;' > 5.direct-distance.csv