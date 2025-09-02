/*
Author  : Ankit Vohra
Date    : Sep-2020
Version : 1.0
Purpose : Purpose of this function is to mark a player as injured or non-injured. 
Input parameters : 	Valid Player ID.
Usage 			: 	SELECT  fn_toggle_injured (<player id>)  ; ; 					
Return value 	: 	This returns VARCHAR string mentioning the status of operation.
			
*/

create or replace FUNCTION fn_toggle_injured (id integer DEFAULT 0) RETURNS VARCHAR LANGUAGE 'plpgsql' AS
$$
Declare  
v_errm          VARCHAR(200);
v_continue      INTEGER     := 0 ;
c_impacted_count	INTEGER     := 0 ;
--PRAGMA          AUTONOMOUS_TRANSACTION;

BEGIN
       
        /* Check if player parameter is a valid */
        SELECT CASE WHEN  c.cnt = 1 THEN 1 ELSE 0 END 
        INTO v_continue
        FROM (SELECT COUNT(1) cnt FROM CONTRACTS_T WHERE player_id=id) c ; 

        IF v_continue = 0 THEN
            raise notice  'Failed : Invalid Player id';
            RETURN 'Failed : Invalid Player id' ;
        END IF;
                        
        UPDATE  CONTRACTS_T 
        SET     injured_flag=  'Y' 
        WHERE   player_id = id
        AND     injured_flag='N';
		
		GET DIAGNOSTICS c_impacted_count = ROW_COUNT;
        --raise notice  'ii';
		
        IF c_impacted_count =1 THEN
            RETURN 'Success: Marked Injured' ;
        END IF;
        
        UPDATE  CONTRACTS_T 
        SET     injured_flag=  'N' 
        WHERE   player_id = id
        AND     injured_flag='Y';
        
		GET DIAGNOSTICS c_impacted_count = ROW_COUNT;
		
        IF c_impacted_count =1 THEN
            RETURN 'Success: Marked NOT Injured' ;
        END IF;

EXCEPTION

WHEN OTHERS THEN
        --ROLLBACK;
        v_errm := SUBSTR(SQLERRM, 1 , 200);
        RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;
$$