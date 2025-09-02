CREATE OR REPLACE PROCEDURE trunc_tbl() 			LANGUAGE 'plpgsql' 			AS $$
			Declare
					BEGIN
						EXECUTE    'truncate table  league_season_t cascade';
						EXECUTE  'truncate table contracts_t cascade';
						EXECUTE  'truncate table teams_t cascade';
						EXECUTE  'truncate table players_t cascade';
						EXECUTE  'truncate table positions_t cascade';
						EXECUTE  'truncate table player_positions_t cascade';
					END; 			$$;