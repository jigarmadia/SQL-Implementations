/*
Program     : K-Means Algorithm
Description : Simple K-Means algorithm implemented in Postgre SQL using functions and relational programming
Author      : Jigar Madia 
Email       : jigarmadia@gmail.com
*/

CREATE TABLE points(point integer, 
                        x float, 
                        y float, 
                  cluster integer, 
              PRIMARY KEY (point)
                    );
CREATE TABLE clusters(cluster integer, 
                            x float, 
                            y float
                      );

INSERT INTO points VALUES(1, 1.0, 1.0);
INSERT INTO points VALUES(2, 1.5, 2.0);
INSERT INTO points VALUES(3, 3.0, 4.0);
INSERT INTO points VALUES(4, 5.0, 7.0);
INSERT INTO points VALUES(5, 3.5, 5.0);
INSERT INTO points VALUES(6, 4.5, 5.0);
INSERT INTO points VALUES(7, 3.5, 4.5);

--For this example we work with 2 clusters.
--Creating initial centroids at opposite ends of graph for allocating initial clusters
INSERT INTO clusters VALUES ( 1 , 
                              ( SELECT min(x) FROM points ) ,
                              ( SELECT min(y) FROM points ) 
                            );
INSERT INTO clusters VALUES ( 2 , 
                              ( SELECT max(x) FROM points ) ,
                              ( SELECT max(y) FROM points ) 
                            );

--Find the nearest centroid for a given point using Euclidean distance
CREATE OR REPLACE FUNCTION get_new_cluster(point_x float, point_y float)
 RETURNS integer AS
 $$
 	DECLARE cluster integer;
 		distance float;
 		c record;
 		c_distance float;
 	BEGIN
 		
    --Initialize cluster value and set maximum distance for initial comparison
 		cluster := 0;
 		distance := 1000.00;

    --Check for each centroid
 		FOR c IN SELECT * FROM clusters
 		 LOOP

      --Calculate Euclidean distance 
 		 	c_distance = sqrt( ( ( c.x - point_x ) ^ 2 ) + ( ( c.y - point_y ) ^ 2 ) );

      --If distance is less than minimum value captured, update the minimum value
 		 	IF ( distance >= c_distance ) THEN
 		 		cluster = c.cluster;
 		 		distance = c_distance;
 		 	END IF;

 		 END LOOP;

    --Return the nearest centroid
 		RETURN cluster;

 	END;
 $$ LANGUAGE plpgsql;

--Assign clusters function sets the cluster value of point to its nearest centroid
CREATE OR REPLACE FUNCTION assign_clusters()
 RETURNS void AS
 $$
 	
  --Find the nearest centroid by calculating distance of point from all centroids and update if necessary
 	UPDATE points p 
 	   SET cluster = pn.new_cluster
 	  FROM ( SELECT p.point, get_new_cluster(p.x, p.y) AS new_cluster
 	  	   FROM points p 
          	) pn
 	 WHERE p.point = pn.point;

 $$ LANGUAGE SQL;

--K-Means function which assigns points to its relaive cluster
 CREATE OR REPLACE FUNCTION k_means()
  RETURNS void AS 
  $$
  	BEGIN

  		--Assign Initial Clusters based on default centroids
  		PERFORM assign_clusters();

      --Keep changing centroids and assigning new clusters till the centroids dont change
      --While condition gets the average of x and y values of points assigned to that cluster and compares with current values
      --We stop when the values dont change and cluster allocation is consistent
  		WHILE EXISTS( SELECT 1 FROM clusters c
  			       WHERE c.x != ( SELECT avg(p.x) 
                                  		FROM points p 
                                     	       WHERE cluster = c.cluster 
                                  	     )
  				  OR c.y != ( SELECT avg(p.y) 
                                     	        FROM points p 
                                     	       WHERE cluster = c.cluster 
                                  	     ) 
                  	      )
  		 LOOP
       --Since centroid values have changed, we update new values to centroids
  		 	UPDATE clusters c 
  		 	   SET x = ( SELECT avg(p.x) 
                       		       FROM points p 
                      		      WHERE cluster = c.cluster 
                    		    ),
  		 	       y = ( SELECT avg(p.y) 
                       		       FROM points p 
                      		      WHERE cluster = c.cluster 
                    		    );
        
        --Assign points to new clusters based on new centroid values               
  		 	PERFORM assign_clusters();
  		 
       		  END LOOP;
  	END;

  $$ LANGUAGE plpgsql;

--Display initial values in clusters
SELECT * FROM clusters;

--Call K-Means Function
SELECT 'Clusters created' AS create_k_means_clusters FROM k_means();

--Display clusters with new centroid values and collection of points in cluster
SELECT c.cluster, c.x, c.y, 
       ( SELECT ARRAY( SELECT p.point 
	 		 FROM points p 
	   		WHERE p.cluster = c.cluster 
                     ) 
       	) AS points 
  FROM clusters c;

/*

Expected Output :

 cluster | x | y
---------+---+---
       1 | 1 | 1
       2 | 5 | 7
(2 rows)


 create_k_means_clusters
-------------------------
 Clusters created
(1 row)


 cluster |  x   |  y  |   points
---------+------+-----+-------------
       1 | 1.25 | 1.5 | {1,2}
       2 |  3.9 | 5.1 | {3,4,5,6,7}
(2 rows)

*/
