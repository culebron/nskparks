
Подготовка учётной записи
=========================

Откройте системную консоль и переключитесь на пользователя postgres:

	sudo su - postgres

Командная строка переключится с такого вида:

	dmitri.lebedev@laptop:~$ 

На такой:

	postgres=#

Выполните в ней следующие команды, заменив `<user>` на имя пользователя в Ubuntu:

	psql -c "CREATE ROLE <user> CREATEDB;"
	psql -c \"ALTER ROLE <user> with password 'gis';\"

С этого момента вы сможете создавать и пересоздавать свои базы данных.

Шаблон базы данных postgis
==========================

Зайдите в запись postgres (как описано выше) и выполните следующие команды:

	createdb -E UTF8 -U postgres template_postgis
	createlang -d template_postgis plpgsql;
	psql -U postgres -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
	psql -U postgres -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
	psql -U postgres -d template_postgis -c "GRANT ALL ON geometry_columns TO PUBLIC;"
	psql -U postgres -d template_postgis -c "GRANT ALL ON spatial_ref_sys TO PUBLIC;"
	psql -U postgres -d template_postgis -c "GRANT ALL ON geography_columns TO PUBLIC;"
	psql -U postgres -c "update pg_database set datistemplate=true  where datname='template_postgis';"
	psql -U postgres -d template_postgis -c"select postgis_lib_version();"

