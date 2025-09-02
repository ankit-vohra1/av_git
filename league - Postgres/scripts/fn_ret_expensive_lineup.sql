/*
Author  : Ankit Vohra
Date    : Sep-2020
Version : 1.0
Purpose : Purpose of this function is display most expensive line-up for a given team. 
Input parameters : 	Valid Team ID.
Usage 			: 	select  (fn_ret_expensive_lineup(5)) ; 					
Return value 	: 	This returns a table type object "table_expensive_lineup" giving player info and playing position.
			
*/

create or replace FUNCTION fn_ret_expensive_lineup(t_id INTEGER) RETURNS table (
			player_id INTEGER,
			position_id VARCHAR,
			contract_value INTEGER
		) LANGUAGE 'plpgsql'  AS
$$
Declare   
v_continue      INTEGER     := 0 ;
r record;					--to loop thru cursor
--INVALID_TEAM    EXCEPTION;
v_tab_player INTEGER[] ;	--To store player ids
v_tab_position VARCHAR[];	--To store position ids
BEGIN


    /**********************************************/
    /* Check if input parameter is a valid team id*/
	/**********************************************/

    SELECT CASE WHEN  c.cnt = 1 THEN 1 ELSE 0 END 
    INTO v_continue
    FROM (SELECT COUNT(1) cnt FROM TEAMS_T WHERE team_id=t_id) c ; 

    --If invalid team id passed, Raise exception
    IF v_continue = 0 THEN
        --RAISE INVALID_TEAM; 
		RAISE EXCEPTION 'INVALID TEAM' USING ERRCODE='S0001';
    END IF;

    
FOR r in (  SELECT e.player_id,pos.position_id ,pos.description,av , ROW_NUMBER() 
		  OVER(PARTITION BY e.position_id ORDER BY av DESC, e.position_id) r

			FROM (
				SELECT p.player_id,p.position_id,c.annual_contract_value av 
				FROM PLAYER_POSITIONS_T p , contracts_t c 
				WHERE p.player_id = c.player_id
				AND c.team_id=t_id and c.injured_flag='N' order by annual_contract_value
				) e, positions_t pos 

				WHERE e.position_id = pos.position_id 
		)
		LOOP
				 --Check if player or position values already exists
				IF (  (ARRAY[r.player_id] <@ v_tab_player )  OR (ARRAY[r.position_id] <@ v_tab_position) ) THEN
					NULL;
				ELSE
					v_tab_player := v_tab_player || r.player_id;
					player_id := r.player_id;

					v_tab_position := v_tab_position || r.position_id;
					position_id := r.position_id;
					
					contract_value := r.av;
					
					return next;
				END IF;
		END LOOP;

EXCEPTION
WHEN SQLSTATE 'S0001' THEN
        raise notice 'Error errmsg=> Invalid team id entered';
		player_id := t_id;
		position_id := 'INVALID TEAM ID';
		contract_value := null;
		return next;
		--rec1(rec1.count) := expensive_lineup2_obj(t_id,'INVALID TEAM ID',null);
        --RETURN rec1;
WHEN OTHERS THEN
        RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
		--rec1(rec1.count) := expensive_lineup2_obj(t_id,v_errm,null);
        --RETURN rec1;
END;
$$