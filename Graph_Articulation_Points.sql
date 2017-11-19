
CREATE TABLE connected_graph(source integer, target integer);
CREATE TABLE transitive_closure(source integer, target integer);
CREATE TABLE articulation_points(node integer);

CREATE OR REPLACE FUNCTION new_rows(skip_node integer)
 RETURNS table (source integer, target integer) AS
 $$
	( SELECT tc.source, cg.target 
		FROM transitive_closure tc, connected_graph cg
	   WHERE tc.target = cg.source
	   	 AND cg.source != skip_node
 		 AND cg.target != skip_node )
	EXCEPT
	( SELECT tc.source, tc.target 
		FROM transitive_closure tc );
 $$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION transitive_closure(skip_node integer)
 RETURNS void AS 
 $$	
 	BEGIN
 		DELETE FROM transitive_closure;
 		INSERT INTO transitive_closure 
 			 SELECT cg.source, cg.target FROM connected_graph cg 
 			 WHERE cg.source != skip_node
 			   AND cg.target != skip_node;
 		WHILE EXISTS( SELECT * FROM new_rows(skip_node))
 		 LOOP
 		 	INSERT INTO transitive_closure SELECT * FROM new_rows(skip_node);
 		 END LOOP;
 	END;
 $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION articulation_points()
  RETURNS void AS
  $$
  	DECLARE art_point RECORD;
  	BEGIN
  	
  		FOR art_point IN ( SELECT DISTINCT n.source FROM connected_graph n)
  	 	 LOOP
  	 	
  	 		PERFORM transitive_closure(art_point.source);

  	 		WITH
  	 		other_nodes AS ( SELECT DISTINCT n.source FROM connected_graph n WHERE n.source != art_point.source )
  	 		INSERT INTO articulation_points
  	 		 SELECT DISTINCT art_point.source 
  	 		   FROM other_nodes n1, other_nodes n2
  	 		  WHERE n1.source != n2.source
  	 		    AND NOT EXISTS ( SELECT 1 FROM transitive_closure tc
  	 	   						  WHERE tc.source = n1.source AND tc.target = n2.source );

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

SELECT 'Articulation Nodes Collected' AS collect_articulation_nodes FROM articulation_points();
SELECT * FROM articulation_points;

--Example 2 with previous entries combined with new entries
INSERT INTO connected_graph VALUES(2,4);
INSERT INTO connected_graph VALUES(4,2);
INSERT INTO connected_graph VALUES(2,5);
INSERT INTO connected_graph VALUES(5,2);
INSERT INTO connected_graph VALUES(4,5);
INSERT INTO connected_graph VALUES(5,4);

SELECT 'Articulation Nodes Collected' AS collect_articulation_nodes FROM articulation_points();
SELECT * FROM articulation_points;