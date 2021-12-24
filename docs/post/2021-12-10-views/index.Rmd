---
title: Views
author: goettlic
date: '2021-12-10'
slug: []
categories:
  - mofgeodb
  - Analysis
tags:
  - database
subtitle: ''
description: 'Views are used to get a defined subset and collection of data from different relations.'
image: ''
toc: yes
output:
  blogdown::html_page:
    keep_md: yes
weight: 100
---
# Views
Views are used to get a defined subset and collection of data from different relations. All views are nemed with a prefix `vw_`.

### Time dependent data
For all time dependent data views on the actual dataset is implement to get a single 1:1 connection. For example the view on the `lut_tree_state` table:
```sql
CREATE VIEW vw_actual_tree_state AS
    SELECT id,tree_id,creator_id, max(date) AS date, state_id, remarks FROM tree_state
    GROUP BY tree_id;
```
Following views are implemented:

* vw_actual_tree_decomposition
* vw_actual_tree_dendroband^1^
* vw_actual_tree_diameter
* vw_actual_tree_habitat^1^
* vw_actual_tree_height
* vw_actual_tree_lyingdeadwood
* vw_actual_tree_roost
* vw_actual_tree_socialposition
* vw_actual_tree_state
* vw_actual_tree_vitality

^1^Views with concatenated datafield.

### All trees with actual parameters:
All living trees with the actual parameters and additional information from the species list. Selection is done with the `state_id`. That is the view to visualize the active trees:
```sql
CREATE VIEW "vw_tree_living" AS
SELECT "a"."id" AS "id", "a"."tree_id" AS "tree_id", "a"."creator_id" AS "creator_id", "a"."date" AS "first_date", "a"."species_id" AS "species_id",
	"a"."easting" AS "easting", "a"."northing" AS "northing", "a"."geomeasurement_id" AS "geomeasurement_id", "a"."status" AS "status", 
    "a"."remarks" AS "remarks", "a"."geometry" AS "geometry",
	"b"."creator_id" AS "creator_state", "b"."date" AS "state_date", "b"."state_id" AS "state_id", "b"."remarks" AS "state_remarks",
	c.tp_id AS "tp_id", c.angle AS "angle", c.distance AS "distance", c.valid AS "valid",
	d.color_rgb AS "color_rgb",
	"e"."diameter" AS "dbh",
	"f"."height" AS "height", "f"."method" AS "method",
	"g"."socialposition" AS "socialposition",
    s.taxon_name AS "taxon_name", s.taxon_author AS "taxon_author", s.nativename AS "nativename"
FROM "tree" AS "a"
JOIN "vw_actual_tree_state" AS "b" USING ("tree_id")
Left JOIN tree_cp AS c USING (tree_id)
JOIN lut_tree_species AS d USING (species_id)
Left JOIN (SELECT * FROM "vw_actual_tree_diameter" WHERE measurement_height = 1.3) AS "e" USING ("tree_id")
Left JOIN vw_actual_tree_height AS "f" USING ("tree_id")
Left JOIN "vw_actual_tree_socialposition" AS "g" USING ("tree_id")
JOIN germansl_species AS s USING (species_id)
WHERE b.state_id IN ('0','1.1','1.2', '3.3', '3.4')
ORDER BY "a"."tree_id";
```

### Dead trees
All dead trees (standing and lying) are composed respectively with:
```sql
CREATE VIEW "vw_tree_dead" AS
SELECT "a"."id" AS "id", "a"."tree_id" AS "tree_id", "a"."creator_id" AS "creator_id", "a"."date" AS "first_date", "a"."species_id" AS "species_id",
	"a"."easting" AS "easting", "a"."northing" AS "northing", "a"."geomeasurement_id" AS "geomeasurement_id", "a"."status" AS "status", 
    "a"."remarks" AS "remarks", "a"."geometry" AS "geometry",
	"b"."creator_id" AS "creator_state", "b"."date" AS "state_date", "b"."state_id" AS "state_id", "b"."remarks" AS "state_remarks",
	c.tp_id AS "tp_id", c.angle AS "angle", c.distance AS "distance", c.valid AS "valid",
	d.color_rgb AS "color_rgb",
	"e"."diameter" AS "dbh", "e_zero"."diameter" AS "d_basal",
	"f"."height" AS "height", "f"."method" AS "method",
   	g.decomposition AS "decomposition",
    s.taxon_name AS "taxon_name", s.taxon_author AS "taxon_author", s.nativename AS "nativename"
FROM "tree" AS "a"
JOIN "vw_actual_tree_state" AS "b" USING ("tree_id")
Left JOIN tree_cp AS c USING (tree_id)
JOIN lut_tree_species AS d USING (species_id)
Left JOIN (SELECT * FROM "vw_actual_tree_diameter" WHERE measurement_height = 1.3) AS "e" USING ("tree_id")
Left JOIN (SELECT * FROM "vw_actual_tree_diameter" WHERE measurement_height = 0) AS "e_zero" USING ("tree_id")
Left JOIN vw_actual_tree_height AS "f" USING ("tree_id")
Left JOIN vw_actual_tree_decomposition AS "g" USING ("tree_id")
JOIN germansl_species AS s USING (species_id)
WHERE b.state_id IN ('2.1','2.2','2.3','2.4', '2.5', '3.1', '3.2')
ORDER BY "a"."tree_id";
```

### Tree history
The history in changing of the `tree_state` is compiled with concatenated fields:
```sql
CREATE VIEW "vw_tree_history" AS
SELECT "a"."id" AS "id", "a"."tree_id" AS "tree_id", "a"."creator_id" AS "creator_id", "a"."date" AS "first_date", "a"."species_id" AS "species_id",
	"a"."easting" AS "easting", "a"."northing" AS "northing", "a"."geomeasurement_id" AS "geomeasurement_id", "a"."status" AS "status", 
    "a"."remarks" AS "remarks", "a"."geometry" AS "geometry",
		group_concat("b"."state_id") AS "state_id_history", group_concat("b"."date") AS "date_history"
FROM "tree" AS "a" 
LEFT JOIN "tree_state" AS "b" USING ("tree_id") 
GROUP BY b.tree_id
ORDER BY "a"."tree_id";
```

### Special trees
Trees with a special investigation are combined with the values from the `vw_actual_tree_X`.  Special investigations are for 

* micro habitats
* dendrometer bands
* sapflow
* roosts (bats)
* yearring

For example the view on the micro habitat trees looks like:
```sql
CREATE VIEW "vw_tree_habitat" AS
SELECT "a"."id" AS "id", "a"."tree_id" AS "tree_id", "a"."species_id" AS "species_id", "a"."geometry" AS "geometry",
	"b"."date" AS "state_date", "b"."state_id" AS "state_id", "b"."remarks" AS "state_remarks",
	"d"."diameter" AS "dbh",
	"e"."creator_id" AS "habitat_creator_id", "e"."date" AS "date", "e"."habitatfeature" AS "habitatfeature", "e"."habitatvalue" AS "habitatvalue", "e"."remarks" AS "habitat_remarks"
FROM "tree" AS "a"
JOIN "vw_actual_tree_state" AS "b" USING ("tree_id")
Left JOIN (SELECT * FROM "vw_actual_tree_diameter" WHERE measurement_height = 1.3) AS "d" USING ("tree_id")
JOIN vw_actual_tree_habitat AS e USING (tree_id)
ORDER BY "a"."tree_id";
```
More information on the special investigations can be found under the [Analysis section](https://marburgopenforest.github.io/MOFexplain/categories/analysis/)

### Herblayer
To get the species list for the herblayer following view is established:
```sql
CREATE VIEW "vw_species_herblayer" AS
Select phl.plot_diary_id, phl.species_id, group_concat(DISTINCT phl.status) AS status, group_concat(phl.cover_bb,';') AS cover_bb, 
	round(avg(phl.cover_percent),2) AS cover_percent, group_concat(phl.voucher,';') AS voucher, group_concat(phl.note,';') AS note,
	group_concat(substr(phl.subplot_id,-3),';') AS subplots, count() AS no_subplots,
	spec.taxon_name, spec.taxon_author, spec.synonym, spec.nativename, spec.taxon_rank, spec.division, spec.taxon_parent_id,
	pd.plot_id, pd.creator_id, pd.date, pd.action_id, pd.notice 
From plot_herblayer AS phl
JOIN germansl_species AS spec USING (species_id)
Join plot_diary AS pd ON phl.plot_diary_id = pd.id
Where plot_diary_id IN (Select id from (
    Select *, max(pd.date) FROM plot_diary AS pd 
	WHERE pd.action_id = 5 --alle Krautschichtaufnahmen
	Group By pd.plot_id )) 
Group By plot_diary_id, species_id
Order By plot_diary_id;
```

### Plots
The different types of plots are distinguished with various views. Following types of plots are implemented by now:

* forest structure - fs
* exclosure experiments - exp
* dendrometer band fields - dm
* dendro-ecology - de
* pasture structure - ps

For example all general information for a forest structure plot is determined with:
```sql
CREATE VIEW "vw_plot_fs" AS
SELECT a."id" AS "id", a."plot_id" AS "plot_id", a."plottype_id" AS "plottype_id", a."creator_id" AS "creator_id", a."status" AS "status",
	a."date" AS "dateFirstSurvey", a."slope" AS "slope", a."aspect" AS "aspect", a."angle" AS "angle", a."xlength" AS "xlength", a."ylength" AS "ylength",
    a."remarks" AS "remarks", a."geometry" AS "geometry"
FROM "plot" As a
WHERE a.plottype_id = 'fs'
Order By a.plot_id;
```
For more information on the various plots see the [plot section](https://marburgopenforest.github.io/MOFexplain/post/2021-12-10-plots/).
