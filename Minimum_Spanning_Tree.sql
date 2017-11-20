/*
Program     : Minimum Spanning Tree of Undirected Weighted Graph
Description : Finds the shortest possible path for all nodes of a graph in PostgreSQL using functions and relational programming
Author      : Jigar Madia 
Email       : jigarmadia@gmail.com
*/
CREATE TABLE graph(source integer, target integer, weight integer);
CREATE TABLE visited_graph(source integer, target integer, weight integer, visited boolean);
CREATE TABLE minimum_spanning_tree(source integer, target integer, weight integer);

INSERT INTO graph VALUES(1,2,5);
INSERT INTO graph VALUES(2,1,5);
INSERT INTO graph VALUES(1,3,3);
INSERT INTO graph VALUES(3,1,3);
INSERT INTO graph VALUES(2,3,2);
INSERT INTO graph VALUES(3,2,2);
INSERT INTO graph VALUES(2,5,2);
INSERT INTO graph VALUES(5,2,2);
INSERT INTO graph VALUES(3,5,4);
INSERT INTO graph VALUES(5,3,4);
INSERT INTO graph VALUES(2,4,8);
INSERT INTO graph VALUES(4,2,8);

--Copy all values in the visited_graph table from graph table and mark visited flag false for each edge
INSERT INTO visited_graph SELECT source, target, weight, false FROM graph;

--Creates minimum spanning tree in the minimum_spanning_tree table
CREATE OR REPLACE FUNCTION create_min_spanning_tree()
 RETURNS void AS
 $$
 	DECLARE unvisited_nodes integer;
 	BEGIN

 		--Get count of nodes;
		SELECT INTO unvisited_nodes count(1) FROM ( SELECT DISTINCT source FROM visited_graph ) c;

 		--Begin with random node. For convinience we select the edge with minimum weight and add it to spanning tree.
 		WITH 
 		--Get the mimimum weight in the graph
 		min_valid_weight AS ( SELECT min(vg.weight) AS weight FROM visited_graph vg ),
 		--Get a single edge with the minimum weight to start the spanning
 		valid_edge AS ( SELECT vg.source AS src, vg.target AS trg 
 						  FROM visited_graph vg NATURAL JOIN min_valid_weight mvw
 			  	  		 LIMIT 1 )
 		--Set the visited flag of the valid_edge as true for the edge and its reverse edge in the visited_graph table
 		UPDATE visited_graph SET visited = true
 		  FROM valid_edge ve
 		 WHERE ( source = ve.src AND target = ve.trg )
 		 	OR ( target = ve.src AND source = ve.trg );

 		--We add 2 nodes in first pass so number of unvisited nodes is less by 2 now
 		unvisited_nodes := unvisited_nodes - 2;

 		--Iteratively add the shortest paths for unvisited nodes starting with visited nodes.
 		WHILE unvisited_nodes != 0
 		 LOOP

 		 	WITH 
 		 	--Get all the visited nodes
 		 	visited_nodes AS ( SELECT DISTINCT source 
 		 						 FROM visited_graph 
 		 	  		  			WHERE visited = true ),
 		 	--Get all the unvisited nodes
 		 	unvisited_nodes AS ( SELECT mv.source 
 		 						   FROM visited_graph mv
 		 	  		  			  WHERE mv.visited != true),
 		 	--Find valid nodes by taking a difference of source columns of visited nodes from unvisited nodes
 		 	valid_nodes AS ( SELECT un.source FROM unvisited_nodes un 
 		 		      EXCEPT SELECT vn.source FROM visited_nodes vn ),
 		 	--From all valid edges, get the minimum weight 
 		 	min_valid_weight AS ( SELECT min(vg.weight) AS min_weight
 		 						  FROM visited_graph vg NATURAL JOIN valid_nodes vn ),
 		 	--Select single row with the lowest weight value
 		 	valid_edge AS ( SELECT vg.source AS src, vg.target AS trg 
 		 					  FROM visited_graph vg, min_valid_weight mvw
 		 	  		  		 WHERE vg.weight = mvw.min_weight 
 		 	  		  		 LIMIT 1 )
 		 	--Set the visited value of that edge to true and its reverse edge as well
 		 	UPDATE visited_graph SET visited = true 
 		 	  FROM valid_edge ve 
 		 	 WHERE ( source = ve.src AND target = ve.trg )
 		 		OR ( target = ve.src AND source = ve.trg );

 		 	unvisited_nodes := unvisited_nodes - 1;

 		 END LOOP;

 		 --Get minimum spanning tree values
 		 INSERT INTO minimum_spanning_tree 
 		 	  SELECT vg.source, vg.target, vg.weight 
 		 	    FROM visited_graph vg 
 		 	   WHERE vg.visited = true;

 	END;

 $$ LANGUAGE plpgsql;

SELECT vg.source, vg.target, vg.weight FROM visited_graph vg;
SELECT 'Minimum Spanning Tree Generated' AS CREATE_MIN_SPANNING_TREE FROM create_min_spanning_tree();
SELECT mst.source, mst.target FROM minimum_spanning_tree mst;

/*
Expected Output : 

 source | target | weight
--------+--------+--------
      1 |      2 |      5
      2 |      1 |      5
      1 |      3 |      3
      3 |      1 |      3
      2 |      3 |      2
      3 |      2 |      2
      2 |      5 |      2
      5 |      2 |      2
      3 |      5 |      4
      5 |      3 |      4
      2 |      4 |      8
      4 |      2 |      8
(12 rows)


    create_min_spanning_tree
---------------------------------
 Minimum Spanning Tree Generated
(1 row)


 source | target
--------+--------
      2 |      3
      3 |      2
      2 |      5
      5 |      2
      1 |      3
      3 |      1
      2 |      4
      4 |      2
(8 rows)

*/