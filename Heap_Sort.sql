/*
Program     : Binary Heap and Heap Sort Algorithm
Description : Sorts data using binary heap data structure in PostgreSQL using functions and relational programming
Author      : Jigar Madia 
Email       : jigarmadia@gmail.com
*/

CREATE TABLE data(index integer, 
				  value integer, 
				  PRIMARY KEY(index));
CREATE TABLE heap_data(index integer, 
					   value integer, 
					   PRIMARY KEY(index));
CREATE TABLE sorted_data(index integer, 
						 value integer);

--This function is called to swap 2 node values if parent node value is greater than child node value.
--It however works on any 2 nodes even if they are not parent and child
CREATE OR REPLACE FUNCTION heap_swap(parent_index integer, child_index integer)
 RETURNS boolean AS
 $$
 	DECLARE parent_value integer;
 			child_value integer;
 	BEGIN 
 		--Get Parent value
 		SELECT INTO parent_value h.value 
 		  FROM heap_data h 
 		 WHERE h.index = parent_index;

 		IF EXISTS( SELECT 1 
 					 FROM heap_data h 
 					WHERE h.index = child_index 
 				 ) THEN 	

 			--Get child value
 			SELECT INTO child_value h.value 
 			  FROM heap_data h 
 			 WHERE h.index = child_index;

 			--Swap if parent is less than child
 			IF ( parent_value < child_value) THEN 			

 				UPDATE heap_data SET value = child_value 
 				 WHERE index = parent_index;

 				UPDATE heap_data SET value = parent_value 
 				 WHERE index = child_index;

 				RETURN true; 		

 			ELSE

 				RETURN false; 			
 			
 			END IF;
 		
 		ELSE
 		
 			RETURN false;
 		
 		END IF;
 	END;
 $$ LANGUAGE plpgsql;

-- Used to get index of parent node by checking if its a left node of parent or right node.
CREATE OR REPLACE FUNCTION get_parent_index(x_index integer)
 RETURNS integer AS
 $$
 	BEGIN
 		--If index is odd number this is a right node else left node
 		IF ( x_index % 2 != 0 ) THEN
 			RETURN ((x_index - 1)/2);
 		ELSE
 			RETURN (x_index/2);
 		END IF;
 	END;
 $$ LANGUAGE plpgsql;

-- Inserts the value in last node and adjusts the heap_data to maintain binary heap
CREATE OR REPLACE FUNCTION heap_insert(x integer)
 RETURNS void AS
 $$
 	DECLARE x_index integer;
 			parent_index integer;
 			data_swapped boolean;
 	BEGIN
		
		--If heap is empty insert as root in position 1 else get the maximum index value
		IF EXISTS( SELECT 1 
					 FROM heap_data h 
					LIMIT 1 ) THEN 
 			SELECT INTO x_index max(h.index) 
 			  FROM heap_data h;
 		ELSE 
 			x_index := 0;
 		END IF;
 		
 		x_index := x_index + 1;

 		--Insert the new node at the end of heap
 		INSERT INTO heap_data VALUES(x_index,x);

 		--If its index is greater than 1, it has parents so check if it needs to be bubbled up
 		IF ( x_index > 1 ) THEN

 			SELECT INTO parent_index * 
 			  FROM get_parent_index(x_index);

 			--Swap data with parent if needed, returns false if no change
 			SELECT INTO data_swapped * 
 			  FROM heap_swap(parent_index, x_index);

 			--Keep swapping and bubbling the new node up the hierarchy till it is less than its parent value
 			WHILE (data_swapped = true) 
 			 LOOP
 			 	x_index := parent_index;

 				SELECT INTO parent_index * 
 				  FROM get_parent_index(x_index);

 				SELECT INTO data_swapped * 
 				  FROM heap_swap(parent_index, x_index);
 			 END LOOP;
 		END IF;

 	END;

 $$ LANGUAGE plpgsql;

-- Extracts the value and adjusts the heap_Data to maintain binary heap
CREATE OR REPLACE FUNCTION heap_extract(x integer)
 RETURNS void AS
 $$
 	DECLARE x_index integer;
 			x_value integer;
 			l_index integer;
 			r_index integer;
 			l_value integer;
 			r_value integer;
 			largest_index integer;
 			largest_value integer;
 			max_index integer;
 			data_swapped boolean;
 	BEGIN
 		
 		x_index := 0;

 		--Get the index of value to be deleted
 		SELECT INTO x_index h.index 
 		  FROM heap_data h 
 		 WHERE h.value = x;

 		--Check if the element exists in the heap
 		IF ( x_index != 0 ) THEN

 			--Get max index to swap with node to be deleted
 			SELECT INTO max_index max(h.index) 
 			  FROM heap_data h; 

 			--If node to be deleted is not max node, swap them
 			IF ( x_index != max_index ) THEN
 				SELECT INTO data_swapped * 
 				  FROM heap_swap(max_index, x_index);
 			END IF;
 			
 			--Delete max node
 			DELETE FROM heap_data 
 			 WHERE index = max_index;

 			-- Get the swapped value, will be filled if index exists
 			SELECT INTO x_value h.value 
 			  FROM heap_data h 
 			 WHERE h.index = x_index;

 			--If values were swapped, keep looping till correct position is found
 			WHILE ( data_swapped = true )
 			 LOOP

 			 	--Reset flag
 			 	data_swapped := false; 

 			 	--Get left and right child nodes
 			 	l_index := x_index * 2;
 			 	r_index := l_index + 1;

 			 	SELECT INTO l_value h.value 
 			 	  FROM heap_data h WHERE h.index = l_index;

 			 	SELECT INTO r_value h.value 
 			 	  FROM heap_data h WHERE h.index = r_index;

 			 	--Set current node as largest
 			 	largest_index = x_index; 
 			 	largest_value = x_value;

 			 	--If left is largest, get its index and value in largest
 			 	IF ( l_index <= max_index 
 			 	 AND l_value > largest_value ) THEN 
 			 		largest_index = l_index;
 			 		largest_value = l_value;
 			 	END IF;

 			 	--If right is largest, get its index and value in largest
 			 	IF ( r_index <= max_index 
 			 	 AND r_value > largest_value ) THEN 
 			 		largest_index = r_index;
 			 		largest_value = r_value;
 			 	END IF;

 			 	--Swap element with larger of right or left child node
 			 	IF (  largest_index != x_index ) THEN
 			 		SELECT INTO data_swapped * 
 			 		  FROM heap_swap(x_index, largest_index);
 			 		x_index = largest_index; 
 			 	END IF;

 			 END LOOP;

 		END IF;

 	END;

 $$ LANGUAGE plpgsql;

-- Creates max_heap of data table values in the heap_data table and extracts maximum nodes 1 by 1 to add in sorted_data table.
CREATE OR REPLACE FUNCTION heap_sort()
 RETURNS void AS
 $$
 	DECLARE max_size integer;
 			root_value integer;
 			d record;
 	BEGIN

 		--Delete old heap data if any
 		DELETE FROM heap_data;

 		--Insert into heap all nodes from data table
 		FOR d IN SELECT * FROM data
 		 LOOP
 		 	PERFORM heap_insert(d.value);
 		 END LOOP;

 		SELECT INTO max_size max(index) FROM heap_data;

 		--Keep popping largest elements from max heap and add them in sorted_data table
 		WHILE (max_size >= 1)
 		LOOP	
 			SELECT INTO root_value h.value FROM heap_data h WHERE h.index = 1;
 			INSERT INTO sorted_data VALUES(max_size,root_value);
 			PERFORM heap_extract(root_value);
 			max_size := max_size - 1;
 		END LOOP;

 	END;

 $$ LANGUAGE plpgsql;

INSERT INTO data VALUES(1,1);
INSERT INTO data VALUES(2,3);
INSERT INTO data VALUES(3,2);
INSERT INTO data VALUES(4,0);
INSERT INTO data VALUES(5,7);
INSERT INTO data VALUES(6,8);
INSERT INTO data VALUES(7,9);
INSERT INTO data VALUES(8,11);
INSERT INTO data VALUES(9,1);
INSERT INTO data VALUES(10,3);

SELECT * FROM data;
SELECT 'Data Sorted' AS sort_data FROM heap_sort();
SELECT * FROM sorted_data ORDER BY index;
	
/*
Expected Output :
index | value
-------+-------
     1 |     1
     2 |     3
     3 |     2
     4 |     0
     5 |     7
     6 |     8
     7 |     9
     8 |    11
     9 |     1
    10 |     3
(10 rows)


  sort_data
-------------
 Data Sorted
(1 row)


 index | value
-------+-------
     1 |     0
     2 |     1
     3 |     1
     4 |     2
     5 |     3
     6 |     3
     7 |     7
     8 |     8
     9 |     9
    10 |    11
(10 rows)
*/