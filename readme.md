Parks Audience Research
=======================

[На русском][1]

This is a tool for parks audience research made in Novosibirsk city, Russia. The database uses open or purpose-mde data from OpenStreetMap and city public databases, and open routing services.

This tool is stored here to reproduce the results if needed, for portfolio or for others who want to make a similar research.

To just reuse the scripts you need

1. Make a file with parks contours (2.parks.osm). Import them from OpenStreetMap or draw in any OSM editor (like JOSM)
1. Prepare the table of population. Each row must have address, number of inhabitants and geographic coordinates (WKT format). Group it as you need: by house, by community, etc.
1. Set up a PostGIS database with proper access rights (see below)
1. Run the `.sh` scripts
1. Format the results in any software you prefer. (This project may once get an automated dashboard.)

System requirements
-------------------

Ubuntu operating system, 13.10 or later. Postgresql 9.1 or newer, PostGIS 1.5 or newer.

Preparing The DB User
---------------------

Open the system shell. The shell prompt should look like this:

	dmitri.lebedev@laptop:~$ 

Switch to user `postgres`:

	sudo su - postgres

(You'll have to enter your root password) The shell should look like this:

	postgres=#

Run the following commands, replace `<user>` with your Ubuntu username:

	psql -c "CREATE ROLE <user> CREATEDB;"
	psql -c \"ALTER ROLE <user> with password 'gis';\"

Now you can create and drop databases from your username in the shell.

PostGIS Database Template
-------------------------

Switch to user `postgres` (as described above) and execute the following commands. If your OS/PostGIS/Postgres version differs, file paths may be different. Search for files `postgis.sql` and `spatial_ref_sys.sql` to get correct paths and replace them in this script.

	createdb -E UTF8 -U postgres template_postgis
	createlang -d template_postgis plpgsql;
	psql -U postgres -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
	psql -U postgres -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
	psql -U postgres -d template_postgis -c "GRANT ALL ON geometry_columns TO PUBLIC;"
	psql -U postgres -d template_postgis -c "GRANT ALL ON spatial_ref_sys TO PUBLIC;"
	psql -U postgres -d template_postgis -c "GRANT ALL ON geography_columns TO PUBLIC;"
	psql -U postgres -c "update pg_database set datistemplate=true  where datname='template_postgis';"
	psql -U postgres -d template_postgis -c"select postgis_lib_version();"




  [1]: https://github.com/culebron/nskparks/blob/master/readme.ru.md
