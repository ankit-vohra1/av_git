/*
Author  : Ankit Vohra
Date    : Sep-2020
Version : 1.0
Purpose : Purpose of this function is to report teams with exceeding budget limit & calculates luxury tax. 
Input parameters : 	NONE
Usage 			: 	select fn_lux_tax(); 					
Return value 	: 	This returns a table type object "table_lux_tax" giving team info and tax applicable.
			
*/

create or replace FUNCTION fn_lux_tax() RETURNS table (
			team_id INTEGER,
			team_name VARCHAR,
			tax INTEGER
		) LANGUAGE 'plpgsql'  AS
$$
Declare   
--rec1            table_lux_tax   := table_lux_tax(); 
v_max_budget    NUMERIC(14, 2)   DEFAULT 50000000; --holds max authorised budget per team
v_errm          VARCHAR(200)   ; --for error handling
r 				record;
BEGIN
	--Retrieve data as per function's purpose and put into table object
    
    SELECT  max_season_budget 
    INTO    v_max_budget
    FROM    LEAGUE_SEASON_T 
    WHERE   active_season = 'Y' ;
    
	FOR r IN (SELECT t.team_id,t.team_name,(e.s - v_max_budget) TAX
		FROM teams_t t
		,(SELECT c.team_id,sum(annual_contract_value) s FROM contracts_t c WHERE INJURED_FLAG='N' GROUP BY c.team_id ) e
		WHERE t.team_id = e.team_id
		AND e.s> v_max_budget 
		ORDER BY t.team_id) 
	LOOP

				team_id := r.team_id;
				team_name := r.team_name;
				tax := r.tax;
				
		return next;			
		--rec1.extend;
		--rec1(rec1.count) := lux_tax_obj(r.team_id,r.team_name,r.tax);

	END LOOP;

	--RETURN rec1;
EXCEPTION        
WHEN OTHERS THEN
    RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
    --dbms_output.put_line('Error errmsg=>'||v_errm||' :: '||DBMS_UTILITY.format_error_backtrace);
END;
$$