/*
Author  : Ankit Vohra
Date    : Sep-2020
Version : 1.0
Purpose : Purpose of this function is to allow trading of (multiple) players among 2 teams.
            Following validations are done before successful trading:
            1) Check validity of team ids
            2) Check if teams are full
            3) Check if entered players belong to same team , are valid players & are not injured
            4) Check if contract values are within permissible limits
Input parameters : 	1) Source team id
					2) Source team's players as string e.g. '221,211,222'
					3) Target team id
					4) Target team's players

Usage 			: 	SELECT  fn_trade_pl (2 , '221,211' , 4 , '314,311') FROM DUAL ; 					
Return value 	: 	This returns a table type object "table_stat_log" with appropriate success or failure message.
			
*/


create or replace function fn_trade_pl(src_team INTEGER,src_players VARCHAR,tgt_team INTEGER,tgt_players VARCHAR) 
RETURNS table (t_msg VARCHAR(200)) LANGUAGE 'plpgsql'  AS
$$
Declare 
--rec1            table_stat_log  := table_stat_log(); 
v_mx_players    INTEGER     := 0 ;  --holds max players allowed per team
v_max_budget    NUMERIC(14, 2)   DEFAULT 50000000; --holds max authorised budget per team
v_continue      INTEGER     := 0 ;
v_src_av        NUMERIC(14,2)    := 0 ;  --holds contract value for source team
v_tgt_av        NUMERIC(14,2)    := 0 ;  --holds contract value for target team
v_errm          VARCHAR(200)   ; --for error handling 
v_trade_id		INTEGER     := 0 ; 	--holds trade id for a trade

--FUNCTION       RET_MSG (msg VARCHAR) RETURN table_stat_log;

--FUNCTION RET_MSG (msg VARCHAR) RETURN VOID IS
--BEGIN
 --   RAISE NOTICE 'Calling inner proc now';
--    --rec1.extend;
--    --rec1(rec1.count) := stat_log_obj(msg);
--	t_msg := $1;
--    return next;
--END ;

--PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	 	--*********************************************
 		-- Check if team 1 parameter is a valid team id*
		--**********************************************

                SELECT CASE WHEN  c.cnt = 1 THEN 1 ELSE 0 END 
                INTO v_continue
                FROM (SELECT COUNT(1) cnt FROM TEAMS_T WHERE team_id=src_team) c ; 

                IF v_continue = 0 THEN
					t_msg := 'Failed : Invalid team ' ||to_char(src_team,'999') ;
					return next;
                END IF;

	 	--*********************************************
		--* Check if team parameter 2 is a valid team id*
	 	--**********************************************

                SELECT CASE WHEN  c.cnt = 1 THEN 1 ELSE 0 END 
                INTO v_continue
                FROM (SELECT COUNT(1) cnt FROM TEAMS_T WHERE team_id=tgt_team) c ; 

                IF v_continue = 0 THEN
                    t_msg := 'Failed : Invalid team ' ||to_char(tgt_team,'999');
					return next;
                END IF;

	 	--************************************************************************
		--* Fetch max players & budget allowed per team for current active season*
	 	--************************************************************************

                SELECT  max_players_num     ,max_season_budget 
                INTO    v_mx_players        ,v_max_budget 
                FROM    LEAGUE_SEASON_T 
                WHERE   ACTIVE_SEASON='Y' ;
				
	 	--**************************
		--* Check if team 1 is full *
	 	--**************************
 
                --SELECT CASE WHEN  (c.cnt+(regexp_count (tgt_players, '[^,]+'))) - (regexp_count (src_players, '[^,]+')) <= v_mx_players THEN 1 ELSE 0 END 
				SELECT CASE WHEN  (c.cnt+(select count(1) from regexp_split_to_table(tgt_players, ',')) ) 
						- (select count(1) from regexp_split_to_table(src_players, ','))  <= v_mx_players THEN 1 ELSE 0 END 
                INTO v_continue
                FROM (SELECT COUNT(1) cnt FROM CONTRACTS_T WHERE team_id=src_team AND injured_flag='N') c ; 

                IF v_continue = 0 THEN
                    t_msg := 'Failed : team ' ||to_char(src_team,'999') ||  ' does not have enough empty slots.';
					return next;
                END IF;

	 	--****************************
		--* Check if team 2 if full *
	 	--**************************

                SELECT CASE WHEN  (c.cnt+(select count(1) from regexp_split_to_table(src_players, ',')) )
						- (select count(1) from regexp_split_to_table(tgt_players, ',')) <= v_mx_players THEN 1 ELSE 0 END 
                INTO v_continue
                FROM (SELECT COUNT(1) cnt FROM CONTRACTS_T WHERE team_id=tgt_team AND injured_flag='N') c ; 

                IF v_continue = 0 THEN
                   t_msg := 'Failed : team ' ||to_char(tgt_team,'999') ||  ' does not have enough empty slots.';
					return next;
                END IF;

	 	--**************************************************************************************************************
		-- Check if source players are not injured & are valid ids : all players belong to team 1 are valid & existing *
	 	--*************************************************************************************************************

                SELECT CASE WHEN count(1) =  (select count(1) from regexp_split_to_table(src_players, ',')) THEN 1 ELSE 0 END  as a
                INTO v_continue
                FROM  CONTRACTS_T
                WHERE team_id = src_team
                AND  injured_flag='N'
                AND  player_id in (select regexp_split_to_table(src_players, ',') );
                                   -- select regexp_substr (src_players, '[^,]+',1, rownum) str
                                   -- from dual
                                  --  connect by level <= regexp_count (src_players, '[^,]+') 
                                   -- );

                IF v_continue = 0 THEN
                    t_msg :='Failed : Invalid/Injured player ID(s) for team ' ||to_char(src_team,'999');
                END IF;

	 	--*************************************************************************************************************
		--* Check if target players are not injured & are valid ids : all players belong to team 2 are valid & existing *
	 	--**************************************************************************************************************

                SELECT CASE WHEN count(1) =  (select count(1) from regexp_split_to_table(tgt_players, ',')) THEN 1 ELSE 0 END  as a
                INTO v_continue
                FROM  CONTRACTS_T
                WHERE team_id = tgt_team
                AND  injured_flag='N'
                AND  player_id in (select regexp_split_to_table(tgt_players, ',') );
                                   -- select regexp_substr (tgt_players, '[^,]+',1, rownum) str
                                   -- from dual
                                  --  connect by level <= regexp_count (tgt_players, '[^,]+') 
                                   -- );

                IF v_continue = 0 THEN
                    t_msg :='Failed : Invalid/Injured player ID(s) for team ' ||to_char(tgt_team,'999');
                END IF;
 
	 	--************************
		--*Check contract values*
	 	--***********************

                SELECT      CASE WHEN
                                 ((s.av - t.av) = 0   )
                                 OR
                                 ((s.av < t.av) AND  ( (t.av - s.av ) <= s.av/5 ))
                                 OR
                                 ((t.av < s.av) AND  ( (s.av - t.av ) <= t.av/5 ))
                            THEN 1 ELSE 0 END  as a
                            ,s.av , t.av
                INTO v_continue , v_src_av , v_tgt_av 
                FROM  
                (   SELECT SUM(annual_contract_value) av
                    FROM CONTRACTS_T
                    WHERE injured_flag='N'
                    AND  player_id in (select regexp_split_to_table(src_players, ',') )
                                   -- select regexp_substr (src_players, '[^,]+',1, rownum) str
                                  --  from dual
                                   -- connect by level <= regexp_count (src_players, '[^,]+') 
                                   -- )
                 ) s
                ,(   SELECT SUM(annual_contract_value) av
                    FROM CONTRACTS_T
                    WHERE injured_flag='N'
                    AND  player_id in (select regexp_split_to_table(tgt_players, ',') )
                                 --   select regexp_substr (tgt_players, '[^,]+',1, rownum) str
                                --    from dual
                                 --   connect by level <= regexp_count (tgt_players, '[^,]+') 
                                 --   )
                 )t;                   


                IF v_continue = 0 THEN
                    t_msg :='Failed : Trade value mismatch: '|| to_char(v_src_av,'9999999999') || ' & ' || to_char(v_tgt_av,'9999999999') ;
                END IF;
 /*
		--****************************************************************
		--*If ALL business validations are Successful, proceed with trade*               
		--****************************************************************

                BEGIN

			    --Switch team id for player ids in 1st string
                            UPDATE CONTRACTS_T 
                            SET team_id = tgt_team
                            WHERE player_id in (
                                                select regexp_substr (src_players, '[^,]+',1, rownum) str
                                                from dual
                                                connect by level <= regexp_count (src_players, '[^,]+') 
                                                );
				
			    --Switch team id for player ids in 2nd string
                            UPDATE CONTRACTS_T 
                            SET team_id = src_team
                            WHERE player_id in (
                                                select regexp_substr (tgt_players, '[^,]+',1, rownum) str
                                                from dual
                                                connect by level <= regexp_count (tgt_players, '[^,]+') 
                                                );

				
			    SELECT trade_id_gen.nextval INTO v_trade_id FROM DUAL; 				

			    --Maintaining trade history	
                            INSERT INTO TRADE_HIST_T (trade_id, player_id,current_team,previous_team,traded_value) 
                            select v_trade_id,player_id, tgt_team , src_team , annual_contract_value
                            FROM CONTRACTS_T
                                WHERE player_id in (
                                                select regexp_substr (src_players, '[^,]+',1, rownum) str
                                                from dual
                                                connect by level <= regexp_count (src_players, '[^,]+') 
                                                );                 

                            INSERT INTO TRADE_HIST_T (trade_id,player_id,current_team,previous_team,traded_value) 
                            select v_trade_id,player_id, src_team , tgt_team , annual_contract_value
                            FROM CONTRACTS_T
                                WHERE player_id in (
                                                select regexp_substr (tgt_players, '[^,]+',1, rownum) str
                                                from dual
                                                connect by level <= regexp_count (tgt_players, '[^,]+') 
                                                );                       

                            COMMIT;

                            return RET_MSG('Trade Successfull. Contract values: ' || to_char(v_src_av) || ' & ' || to_char(v_tgt_av) );

                            EXCEPTION
                                WHEN OTHERS THEN
                                ROLLBACK;
								--v_errm := SUBSTR(SQLERRM, 1 , 200);
                                RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
                END;*/

EXCEPTION        
                WHEN OTHERS THEN
                    RAISE NOTICE 'Final ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;

END;
$$