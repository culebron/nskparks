dropdb nskparks 
createdb nskparks -T template_postgis 
osm2pgsql --slim --style 1.parks.style -d nskparks 1.parks.osm -p osm --multi-geometry
