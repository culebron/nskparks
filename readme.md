Исследования парков Новосибирска
================================

Это набор скриптов и запросов БД для исследования аудитории парков. Используются открытые данные - OpenStreetMap и базы данных департамента ЖКХ (не входит в репозиторий).

Вы можете использовать эти скрипты чтобы получить аналогичные результаты для своего исследования.

Для этого нужно

1. Сделать файл с контурами парков (2.parks.osm) - импортировать из OSM или нарисовав вручную. Каждый контур должен иметь тег leisure=park
1. Создать таблицу жителей в любой удобной группировке - по отдельным домам, кластеризованным домам, улицам или районам, с названием дома, чилом жителей и географическими координатами (srid 4326).
1. Настроить базу данных PostGIS
1. Выполнить последовательно скрипты (файлы .sh)
1. Форматировать результаты на ваш вкус. (Возможно, здесь появится информационная панель в формате HTML или на веб-приложениях.)

Системные требования

Подготовка учётной записи
-------------------------

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

Шаблон базы данных PostGIS
--------------------------

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

