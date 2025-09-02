/*
Author  : Ankit Vohra
Date    : Sep-2020
Version : 1.0
Purpose : Purpose of this procedure is to generate luxury tax record for teams exceeding contract budget value for the season. 
Input parameters : 	NONE
Usage 			:	--call proc_lux_tax();
 	
					This runs via a monthly scheduled job (GENERATE_LUXURY_TAX_RECS). For adhoc run, run below block : 
					BEGIN 
						DBMS_SCHEDULER.run_job (job_name            =>'GENERATE_LUXURY_TAX_RECS');  
					END;
					/	
  					
Return value 	: 	This generates a text file in name format LUXURY_TAX_MMDDYYYY_HHMISS.txt
			
*/


CREATE OR REPLACE PROCEDURE proc_lux_tax() LANGUAGE 'plpgsql'  AS
$$
Declare  
path VARCHAR(500) := 'E:\2 PRACTICE\league - Postgres\scripts\LUX_TAX.txt'   ; 
BEGIN

	--Retrieve data as per function's purpose and put into file
	Copy (
			WITH K AS (SELECT  max_season_budget FROM    LEAGUE_SEASON_T    WHERE   active_season = 'Y')
			SELECT t.team_id,t.team_name,e.s val,(e.s - k.max_season_budget) TAX
			FROM teams_t t, k
			,(SELECT team_id,sum(annual_contract_value) s FROM contracts_t WHERE INJURED_FLAG='N' GROUP BY team_id ) e
			WHERE t.team_id = e.team_id
			AND e.s> k.max_season_budget
			ORDER BY t.team_id 
		) 
			To 'E:\2 PRACTICE\league - Postgres\scripts\LUX_TAX.txt' With DELIMITER '|' ;


EXCEPTION        
WHEN OTHERS THEN
    RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;
$$