psql nskparks < 6.direct-distance-results.sql
psql nskparks -c 'copy (select * from distance_profile_results) to stdout csv header;' > 6.direct-distance.csv