
\timing on

-- Put coverup landuse around boundary
drop table if exists coverups;
create table coverups ( name varchar, geom geometry(Geometry,3857));

insert into coverups ( name, geom ) (
       	select	'c1', ST_Buffer(wkb_geometry, 500)
	from	boundaries
);

insert into coverups ( name, geom ) (
       	select	'c2', ST_Buffer(wkb_geometry, 1000)
	from	boundaries
);

insert into coverups ( name, geom ) (
       	select	'c3', ST_Buffer(wkb_geometry, 1500)
	from	boundaries
);

insert into coverups ( name, geom ) (
       	select	'c4', ST_Buffer(wkb_geometry, 5000)
	from	boundaries
);

-- Delete all objects completely outside of the coverup 3 which is 90% opacity

delete from planet_osm_line where
	not ST_Intersects((select geom from coverups where name = 'c3'),way);

delete from planet_osm_polygon where
	not ST_Intersects((select geom from coverups where name = 'c3'),way);

delete from planet_osm_point where
	not ST_Intersects((select geom from coverups where name = 'c3'),way);

delete from planet_osm_roads where
	not ST_Intersects((select geom from coverups where name = 'c3'),way);



-- We are planning to cut/split lines. So lines will become MultiLineString
-- from LineString. Normal osm2pgsql schema does not allow this to alter
-- table to be able to hold MultiLineStrings
alter table planet_osm_line alter COLUMN way type geometry(Geometry,3857);
alter table planet_osm_roads alter COLUMN way type geometry(Geometry,3857);

-- Cut off everything overlapping the c3 our c3

update  planet_osm_line set way = ST_Intersection(c.geom, way)
from    coverups c 
where   ST_Crosses(c.geom, way)
and	c.name = 'c3';

update  planet_osm_roads set way = ST_Intersection(c.geom, way)
from    coverups c 
where   ST_Crosses(c.geom, way)
and	c.name = 'c3';

update  planet_osm_polygon set way = ST_Intersection(c.geom, way)
from    coverups c 
where   ST_Overlaps(c.geom, way)
and	c.name = 'c3';





-- Inner coverup
insert into planet_osm_polygon ( osm_id, landuse, way_area, way ) (
	select	-1, 'coverup1', ST_Area(way) way, way
	from	(
		select	ST_Subdivide(
				ST_Difference(
					(select geom from coverups where name = 'c1'),
					(select wkb_geometry from boundaries)
				),
			50) way
	) coverup1
);

insert into planet_osm_polygon ( osm_id, landuse, way_area, way ) (
	select	-1, 'coverup2', ST_Area(way) way, way
	from	(
		select	ST_Subdivide(
				ST_Difference(
					(select geom from coverups where name = 'c2'),
					(select geom from coverups where name = 'c1')
				),
			50) way
	) coverup2
);

insert into planet_osm_polygon ( osm_id, landuse, way_area, way ) (
	select	-1, 'coverup3', ST_Area(way) way, way
	from	(
		select	ST_Subdivide(
				ST_Difference(
					(select geom from coverups where name = 'c3'),
					(select geom from coverups where name = 'c2')
				),
			50) way
	) coverup2
);

insert into planet_osm_polygon ( osm_id, landuse, way_area, way ) (
	select	-1, 'coverup', ST_Area(way) way, way
	from	(
		select	ST_Subdivide(
				ST_Difference(
					(select geom from coverups where name = 'c4'),
					(select geom from coverups where name = 'c3')
				),
			50) way
	) coverup2
);

