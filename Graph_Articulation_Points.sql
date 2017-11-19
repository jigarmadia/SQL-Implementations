/*
Program     : Graph Articulation Points
Description : Finds articulation points of a given connected graph in Postgre SQL using functions and relational programming
Author      : Jigar Madia 
Email       : jigarmadia@gmail.com
*/

CREATE TABLE connected_graph(source integer, 
           		     target integer);
CREATE TABLE transitive_closure(source integer, 
        			target integer);
CREATE TABLE articulation_points(node integer);

--Find all possible new rows in transitive_closure table without taking skip_node into consideration except previously added rows
--CONCEPT THOUGHT BY PROF. DIRK VAN GUCHT, INDIANA UNIVERSITY BLOOMINGTON, USA 
--IN HIS ADVANCED DATABASE CONCEPTS CLASS NOTES 
CREATE OR REPLACE FUNCTION new_rows(skip_node integer)
 RETURNS table (source integer, target integer) AS
 $$
  ( SELECT tc.source, cg.target 
      FROM transitive_closure tc, 
     	   connected_graph cg
     WHERE tc.target = cg.source
       AND cg.source != skip_node
       AND cg.target != skip_node )
  EXCEPT
  ( SELECT tc.source, tc.target 
      FROM transitive_closure tc );
 $$ LANGUAGE SQL;

--Creates transitive closure of the graph. 
--CONCEPT THOUGHT BY PROF. DIRK VAN GUCHT, INDIANA UNIVERSITY BLOOMINGTON, USA 
--IN HIS ADVANCED DATABASE CONCEPTS CLASS NOTES 
CREATE OR REPLACE FUNCTION transitive_closure(skip_node integer)
 RETURNS void AS 
 $$ 
  BEGIN
    --Delete previous transitive closure
    DELETE FROM transitive_closure;

    --Insert initial entries of graph
    INSERT INTO transitive_closure 
         SELECT cg.source, cg.target 
           FROM connected_graph cg 
          WHERE cg.source != skip_node
      	    AND cg.target != skip_node;

    --Insert new entries in transitive_closure table till the time there are no new rows possible
    WHILE EXISTS( SELECT * FROM new_rows(skip_node))
     LOOP
      INSERT INTO transitive_closure 
           SELECT * FROM new_rows(skip_node);
     END LOOP;
  END;
 $$ LANGUAGE plpgsql;

--For each node in graph, checks all possible paths in the connected graph using transitive closure and finds missing paths
CREATE OR REPLACE FUNCTION articulation_points()
  RETURNS void AS
  $$
    DECLARE art_point RECORD;
    BEGIN
      --For each unique node in graph
      FOR art_point IN ( SELECT DISTINCT n.source 
             		   FROM connected_graph n )
       LOOP     
        --Create transitive closure without the current node 
        PERFORM transitive_closure(art_point.source);

        WITH
        --Get all other nodes in graph except current node
        other_nodes AS ( SELECT DISTINCT n.source 
             		   FROM connected_graph n 
            		  WHERE n.source != art_point.source 
		       )
        --Insert the current node as articulation if for any of the combination of nodes in other_nodes a path is missing in transitive closure
        INSERT INTO articulation_points
             SELECT DISTINCT art_point.source 
               FROM other_nodes n1, 
                    other_nodes n2
              WHERE n1.source != n2.source
                AND NOT EXISTS ( SELECT 1 
               			   FROM transitive_closure tc
                  		  WHERE tc.source = n1.source 
                		    AND tc.target = n2.source 
			       );

       END LOOP;
    END

 $$ LANGUAGE plpgsql;

--Example 1
INSERT INTO connected_graph VALUES(1,2);
INSERT INTO connected_graph VALUES(2,1);
INSERT INTO connected_graph VALUES(1,3);
INSERT INTO connected_graph VALUES(3,1);
INSERT INTO connected_graph VALUES(2,3);
INSERT INTO connected_graph VALUES(3,2);

--Collect Articulation points in articulation_points table
SELECT 'Articulation Nodes Collected' AS collect_articulation_nodes FROM articulation_points();

--Display Articulation points of graph
SELECT * FROM articulation_points;

--Example 2 with previous entries combined with new entries
INSERT INTO connected_graph VALUES(2,4);
INSERT INTO connected_graph VALUES(4,2);
INSERT INTO connected_graph VALUES(2,5);
INSERT INTO connected_graph VALUES(5,2);
INSERT INTO connected_graph VALUES(4,5);
INSERT INTO connected_graph VALUES(5,4);

--Collect Articulation nodes in articulation_points table
SELECT 'Articulation Nodes Collected' AS collect_articulation_nodes FROM articulation_points();

--Display Articulation points of graph
SELECT * FROM articulation_points;
/*
Expected Output : 

CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
  collect_articulation_nodes
------------------------------
 Articulation Nodes Collected
(1 row)


 node
------
(0 rows)


INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
  collect_articulation_nodes
------------------------------
 Articulation Nodes Collected
(1 row)


 node
------
    2
(1 row)

*/
