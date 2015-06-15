create or replace view travel_to_center as
SELECT
	h.id,
	substr(h.query::text, 14) AS addr,
	h.centroid_913,
	d.transit_distance / 60::double precision AS minutes,
	d.transit_distance / 3600::double precision AS hours
FROM distances d, houses h, parks p
WHERE
	d.house = h.id AND
	d.park = p.id AND
	p.osm_id = 25642995
;
