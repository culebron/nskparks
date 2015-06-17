create or replace view travel_to_center as
SELECT
	h.id,
	substr(h.query::text, 14) AS addr,
	h.centroid_913,
	transit_distance / 60 AS minutes ,
	transit_distance / 3600 AS hours,
	osm_id
FROM distances d, houses h, parks p
WHERE
	transit_distance > 0 and
	d.house = h.id AND
	d.park = p.id AND
	p.osm_id = 25642995
;
