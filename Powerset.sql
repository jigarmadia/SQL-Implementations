/*
Program     : Powerset
Description : Create a Powerset list of elements in Postgre SQL using functions and relational programming
Author      : Jigar Madia 
Email       : jigarmadia@gmail.com
*/

CREATE TABLE A(x integer, 
               PRIMARY KEY(x));
CREATE TABLE A_Powerset(xa integer[]);

INSERT INTO A VALUES(1);
INSERT INTO A VALUES(2);
INSERT INTO A VALUES(3);
INSERT INTO A VALUES(4);
INSERT INTO A VALUES(5);

--Adds the x value to xa array and returns combination
CREATE OR REPLACE FUNCTION merge_array_value(x integer, xa anyarray)
 RETURNS anyarray AS 
 $$
 	SELECT ARRAY( SELECT x 
                  FROM ( ( SELECT x ) 
                   UNION ( SELECT UNNEST(xa) AS x) 
                       ) a 
                ORDER BY x );
 $$ LANGUAGE sql;

--Creates powerset values from the uniary table A
CREATE OR REPLACE FUNCTION generate_powerset()
  RETURNS void AS
  $$
  	DECLARE row_count integer;
  			              i	integer;
  	BEGIN

  		--Insert null into powerset
  		INSERT INTO A_Powerset VALUES('{}');

  		--Get original row count
  		SELECT INTO row_count count(1) 
      FROM A;

    --The new row_count will be the number of times we need to multiply the row_count cardinality values with original values
  		row_count := row_count - 1;

  		FOR i IN 0..row_count
  		 LOOP
  		 	WITH 
        --Original entries from table A
  		 	  original_entries AS ( SELECT a.x FROM A a ),
        
        --Powerset entries with row_count cardinality
  		 	  powerset_entries AS ( SELECT ap.xa 
                                FROM A_Powerset ap
  		 						                    WHERE CARDINALITY(ap.xa) = i 
                             ),
                             
        --New row combinations by multiplying original with powerset_entries of cardinality i 
        --We dont consider combinations where original entry is already in the multiplying powerset entry
        --and original entries which are greater than any of the elements in the multiplying powerset collection
        --to maintain unique combinations 
  		 	  new_rows AS ( SELECT o.x, p.xa 
  		 			                FROM original_entries o, powerset_entries p
  		 			   	           WHERE NOT ( o.x = SOME(p.xa) )
  		 			   	 	               AND o.x < ALL(p.xa) 
                     )
                     
        --Merge possible combinations in one array and add to powerset table
  		 	  INSERT INTO A_Powerset SELECT merge_array_value(nr.x,nr.xa) 
                                 FROM new_rows nr;

  		 END LOOP;
  	END
  $$ LANGUAGE plpgsql;

--Generate Powerset from the uniary table A
SELECT 'Powerset Generated' AS generate_powerset FROM generate_powerset();

--Display the powerset values
SELECT xa AS Powerset FROM A_Powerset;

/*

Expected Output :
  powerset
-------------
 {}
 {1}
 {2}
 {3}
 {4}
 {5}
 {1,2}
 {1,3}
 {2,3}
 {1,4}
 {2,4}
 {3,4}
 {1,5}
 {2,5}
 {3,5}
 {4,5}
 {1,2,3}
 {1,2,4}
 {1,3,4}
 {2,3,4}
 {1,2,5}
 {1,3,5}
 {2,3,5}
 {1,4,5}
 {2,4,5}
 {3,4,5}
 {1,2,3,4}
 {1,2,3,5}
 {1,2,4,5}
 {1,3,4,5}
 {2,3,4,5}
 {1,2,3,4,5}
 
(32 rows)
*/
