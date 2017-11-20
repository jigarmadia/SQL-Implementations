/*
Program     : HITS ( Hub and Authority) Algorithm
Description : Calculates Hub and Authority scores of nodes in directed graph in PostgreSQL using functions and relational programming
Author      : Jigar Madia 
Email       : jigarmadia@gmail.com
*/

CREATE TABLE directed_graph(source integer, target integer);
CREATE TABLE hits_score(node integer, hub_score float, authority_score float);

INSERT INTO directed_graph VALUES(1,2);
INSERT INTO directed_graph VALUES(3,2);
INSERT INTO directed_graph VALUES(1,3);
INSERT INTO directed_graph VALUES(3,4);
INSERT INTO directed_graph VALUES(4,1);

--Insert all nodes in hits_score table and set default hub and authority scores to 1
INSERT INTO hits_score
 SELECT g.node, 1.0, 1.0 FROM ( SELECT DISTINCT g.source AS node 
 								  FROM directed_graph g
 					  	  		 UNION 
 					  	  		SELECT DISTINCT g.target AS node 
 					  	  		  FROM directed_graph g
 					  	  	   ) g;

SELECT * FROM directed_graph;

--Calculate hub and authority score of nodes
CREATE OR REPLACE FUNCTION calculate_HITS_score(k integer)
 RETURNS void AS
 $$
 	DECLARE i integer;
 			norm float;
 			a_score float;
 			h_score float;
 			n record;
 	BEGIN
 		FOR i IN 1..k
 		 LOOP

 		 	--Normalization factor for convergence
 		 	norm := 0;

 		 	--For every node in graph we calculate authority score
 		 	FOR n IN SELECT * FROM hits_score
 		 	 LOOP
 		 	 	
 		 	 	--Initialize authority score
 		 	 	a_score := 0;

 		 	 	--If there are incoming paths for this node, we calculate authority score by sum of all hub scores of incoming nodes
 		 	 	IF EXISTS( SELECT 1 
 		 	 				 FROM directed_graph 
 		 	 				WHERE target = n.node 
 		 	 			  ) THEN
 		 	 		SELECT INTO a_score sum(n1.hub_score) 
 		 	 		  FROM hits_score n1 
 		 	  NATURAL JOIN ( SELECT g.source AS node 
 		 	  				   FROM directed_graph g 
 		 	  				  WHERE g.target = n.node ) g;
 		 	  	END IF;

 		 	  	--Update the authority score of node
 		 	  	UPDATE hits_score 
 		 	  	   SET authority_score = a_score
 		 	  	 WHERE node = n.node;

 		 	  	 --Add score to normalization factor
 		 	  	 norm := norm + (a_score^2);

 		 	 END LOOP;

 		 	SELECT INTO norm sqrt(norm);

 		 	--Normalize the authority scores of nodes using norm value
 		 	UPDATE hits_score SET authority_score = o.a_score/norm
 		 	  FROM ( SELECT node AS n, authority_score AS a_score 
 		 	  		   FROM hits_score ) o
 		 	  WHERE node = o.n;

 		 	--Repeat all steps above to calculate hub scores from incomming node authority scores and update.
 		 	norm := 0;

 		 	FOR n IN SELECT * FROM hits_score
 		 	 LOOP
 		 	 	
 		 	 	h_score := 0;

 		 	 	IF EXISTS( SELECT 1 
 		 	 				 FROM directed_graph 
 		 	 				WHERE source = n.node 
 		 	 			  ) THEN
 		 	 		SELECT INTO h_score sum(n1.authority_score) 
 		 	 		  FROM hits_score n1 
 		 	  NATURAL JOIN ( SELECT g.source AS node 
 		 	  				   FROM directed_graph g 
 		 	  				  WHERE g.source = n.node ) g;
 		 	  	END IF;

 		 	  	UPDATE hits_score 
 		 	  	   SET hub_score = h_score
 		 	  	 WHERE node = n.node;

 		 	  	 norm := norm + (h_score^2);

 		 	 END LOOP;

 		 	SELECT INTO norm sqrt(norm);

 		 	UPDATE hits_score SET hub_score = o.h_score/norm
 		 	  FROM ( SELECT node AS n, hub_score AS h_score 
 		 	  		   FROM hits_score ) o
 		 	  WHERE node = o.n;

 		 END LOOP;
 	END;
 $$ LANGUAGE plpgsql;

--Calculate scores by 10 iterations
SELECT 'Hub and Authority Scores Generated' AS generate_hub_authority_scores FROM calculate_HITS_score(10);

--Display scores
SELECT * FROM hits_score ORDER BY node;

/*
Expected Output :

 source | target
--------+--------
      1 |      2
      3 |      2
      1 |      3
      3 |      4
      4 |      1
(5 rows)


CREATE FUNCTION
   generate_hub_authority_scores
------------------------------------
 Hub and Authority Scores Generated
(1 row)


 node |     hub_score     |  authority_score
------+-------------------+-------------------
    1 | 0.666666666666667 | 0.377964473009227
    2 |                 0 | 0.755928946018455
    3 | 0.666666666666667 | 0.377964473009227
    4 | 0.333333333333333 | 0.377964473009227
(4 rows)

*/
