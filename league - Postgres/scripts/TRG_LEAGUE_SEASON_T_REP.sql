create or replace FUNCTION   FN_TRG_LEAGUE_SEASON_T_REP()   
RETURNS TRIGGER  LANGUAGE PLPGSQL AS
$$
DECLARE
	v_cnt	INTEGER := 0;
BEGIN  

--SELECT dblink_connect('myconn', 'db2remote') into v_flag;

IF (TG_OP = 'INSERT')  OR (TG_OP = 'UPDATE')  THEN

	select * from dblink('myconn','select COUNT(1) from LEAGUE_SEASON_T WHERE season_id ='|| NEW.season_id)  AS t(a integer) INTO v_cnt ;
	
	IF v_cnt > 0 THEN
						
			PERFORM dblink_exec('myconn','
									UPDATE LEAGUE_SEASON_T  SET 
									season_name = '||''''||NEW.season_name||''''||',' 
									'active_season = ' ||''''||NEW.active_season||''''||','|| 
									'max_players_num = ' ||NEW.max_players_num||','|| 
									'max_season_budget = ' ||NEW.max_season_budget  ||
									'WHERE season_id= '||NEW.season_id
								);										
		ELSE	
			
			PERFORM dblink_exec('myconn',' 
								INSERT INTO LEAGUE_SEASON_T (season_name, active_season, max_players_num,  max_season_budget)  
								VALUES('||''''||NEW.season_name||''''||  ',' 
										||''''||NEW.active_season||''''||  ',' 
										||NEW.max_players_num||',' 
										||NEW.max_season_budget||') 
								');							
															
	END IF;	
END IF;

IF (TG_OP = 'DELETE') THEN
	raise notice 'I am in trigger delete';
	PERFORM dblink_exec('myconn','DELETE FROM LEAGUE_SEASON_T WHERE season_id= '||OLD.season_id
								);
END IF;	

--        RAISE EXCEPTION 'Debit value must be non-negative';
	
RETURN NEW;
EXCEPTION        
    WHEN OTHERS THEN
		RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;  
$$




/*
CREATE  TRIGGER TRG_LEAGUE_SEASON_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON LEAGUE_SEASON_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_LEAGUE_SEASON_T_REP();
  */
  