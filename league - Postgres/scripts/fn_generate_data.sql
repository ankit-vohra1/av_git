/*
Author  : Ankit Vohra
Date    : Sep-2020
Version : 1.0
Purpose : This function generates sample data for BLMS. It generates contract values (in Mn $) & contract duration (in years) randomly.  
			Playing positions is picked from an array in sequence.
Input Parameters :  1) Number of teams in league
					2) Number of max players 
					3) Max budget allowed for a season
Usage 			: 	SELECT  fn_generate_data (5 , 13 , 50000000)  ; 	
Return value 	: 	This returns VARCHAR string mentioning the status of operation.					
*/


-- FUNCTION: public.fn_generate_data(integer, integer, integer)

-- DROP FUNCTION public.fn_generate_data(integer, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_generate_data(
	ip_max_teams integer,
	ip_max_players integer,
	ip_max_budget integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    
AS $$
Declare  
--arr_pos 				arr_positions; 		--This holds player playing positions
arr_pos		VARCHAR ARRAY[5];
arr_pos_cnt				INTEGER := 0 ;	--to hold count of array elements
v_errm                  VARCHAR(200);		--For error handling
v_season_id             INTEGER := 0;	--This holds current active season id
v_pos                   INTEGER := 1 ;	--This is for looping thru playing positions array
v_no_of_pos             INTEGER := 0 ;  --Number of positions that a player may hold (random number)
v_pos_player            INTEGER := 0 ;  --This is for looping thru playing positions array for multiple positions for a player
v_player_gen_counter    INTEGER := 0 ;	--This holds value genrated from sequence for player id 


BEGIN
    ip_max_teams := $1;
	--Empty the tables
    call trunc_tbl() ;
		/*
			CREATE OR REPLACE PROCEDURE public.trunc_tbl() 			LANGUAGE 'plpgsql' 			AS $BODY$
			Declare
					BEGIN
						EXECUTE    'truncate table  league_season_t cascade';
						EXECUTE  'truncate table contracts_t cascade';
						EXECUTE  'truncate table teams_t cascade';
						EXECUTE  'truncate table players_t cascade';
						EXECUTE  'truncate table positions_t cascade';
						EXECUTE  'truncate table player_positions_t cascade';
					END; 			$BODY$;
		*/
	INSERT INTO LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2016-2017' ,  'N' , 15, 50000000 ); 
	INSERT INTO LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2017-2018' ,  'N' , 12, 50000000 ) ;
	INSERT INTO LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2018-2019' ,  'N' , 18, 50000000 ) ;
	INSERT INTO LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2019-2020' ,  'N' , 10, 50000000 ) ;
	INSERT INTO LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2020-2021' ,  'Y' , NULL, NULL) ;

    INSERT INTO POSITIONS_T (position_id,description ) values ('P1','Point Guard');
    INSERT INTO POSITIONS_T (position_id,description ) values ('P2','Shooting Guard');
    INSERT INTO POSITIONS_T (position_id,description ) values ('P3','Small Forward');
    INSERT INTO POSITIONS_T (position_id,description ) values ('P4','Power Forward');
    INSERT INTO POSITIONS_T (position_id,description ) values ('P5','Center');

	--Filling up playing positions	
    --arr_pos := arr_positions('P1','P2','P3','P4','P5'); 
    arr_pos := ARRAY ['P1','P2','P3','P4','P5'];

    --Set max players for the active season	
    UPDATE  LEAGUE_SEASON_T
    SET     max_players_num = ip_max_players
            ,max_season_budget =  ip_max_budget
    WHERE   active_season = 'Y' 
    RETURNING season_id into v_season_id;

	--Looping till max number of teams 	
    FOR i in 1..ip_max_teams LOOP

		--Inserting 1 record in teams table for each team.
        INSERT INTO TEAMS_T (team_id, team_name) VALUES (i, 'Team-'||to_char(i,'99') );
        --INSERT INTO TEAMS_T (team_id, team_name) VALUES (1, 'Team-'||to_char(1,'99') );

		--Looping till max number of players 	
        FOR j in 1..ip_max_players LOOP
            v_player_gen_counter := nextval('player_id_gen') ;

			--Inserting 1 record in player table for each player.
            INSERT INTO PLAYERS_T (player_id,name) VALUES (v_player_gen_counter,'Player-'||to_char(v_player_gen_counter,'999') );

					--Inserting sample data into contracts table. Contract value & duration are randomly generated. Playing position is set in sequence.
                    INSERT INTO CONTRACTS_T (
                                player_id   ,           team_id             ,       season_id               , 
                                playing_position    ,   injured_flag        ,       annual_contract_value   , 
                                contract_start_dt   ,   contract_dur_yr
                                )
                    VALUES      (
                                v_player_gen_counter,   i                   ,       v_season_id , 
                                arr_pos[v_pos]      ,  'N'                  ,       CAST ( ceil(floor(random() * (9000000-1000000+1) + 1000000)/1000000)*1000000 as integer)  ,
                                CURRENT_DATE             ,   CAST(random()* (5-1+1)+1 as INTEGER)
                    );

                    --*This loop will assign multiple positions to a given player. #positions is a random number (1,5)*
                    v_no_of_pos := CAST(random()* (4-1+1)+1 as INTEGER) ;
                    v_pos_player := v_pos;  --take current array position

                    --RETURN 'Success0'||to_char(v_no_of_pos,'99') ||' --- '|| to_char(v_player_gen_counter,'999') ;

                    --This will run till number of positions a player can play is reached & will insert that many positions into table
                    FOR m in 1..v_no_of_pos LOOP
                        INSERT INTO PLAYER_POSITIONS_T (player_id,position_id) VALUES (v_player_gen_counter,arr_pos[v_pos_player] ) ;				
						
						--EXECUTE format('SELECT count(*) FROM LEAGUE_SEASON_T') INTO c;
						SELECT coalesce(array_length(arr_pos, 1), 0) into arr_pos_cnt;
						
                        IF v_pos_player = arr_pos_cnt THEN
                            v_pos_player := 1; 
                        ELSE
                            v_pos_player := v_pos_player+1;
                            END IF;

                    END LOOP;
                    --RETURN 'Success3';
			--COMMIT;

                    IF v_pos = arr_pos_cnt THEN
                        v_pos := 1; 
                    ELSE
                        v_pos := v_pos+1;
                    END IF;

        END LOOP;

        v_pos := 1;

    END LOOP;

	--If all well, return Success message	
    RETURN 'Data generated successfully.';

EXCEPTION        
                WHEN OTHERS THEN
                    --ROLLBACK;
                    --v_errm := SUBSTR(SQLERRM, 1 , 200);
                    --RETURN ('Error errmsg=>'||v_errm||' :: '||DBMS_UTILITY.format_error_backtrace);
					RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;
$$;

ALTER FUNCTION public.fn_generate_data(integer, integer, integer)
    OWNER TO ankit;
