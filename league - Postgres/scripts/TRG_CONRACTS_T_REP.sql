create or replace FUNCTION   FN_TRG_CONRACTS_T_REP()   
RETURNS TRIGGER  LANGUAGE PLPGSQL AS
$$
DECLARE
	v_cnt	INTEGER := 0;
BEGIN  

--SELECT dblink_connect('myconn', 'db2remote') into v_flag;

IF (TG_OP = 'INSERT')  OR (TG_OP = 'UPDATE')  THEN

	select * from dblink('myconn','select COUNT(1) from CONTRACTS_T WHERE contract_id ='|| NEW.contract_id)  AS t(a integer) INTO v_cnt ;
	
	IF v_cnt > 0 THEN
						
			PERFORM dblink_exec('myconn','
									UPDATE CONTRACTS_T  SET 
									injured_flag = '||''''||NEW.injured_flag||''''||',' 
									'playing_position = ' ||''''||NEW.playing_position||''''||','|| 
									'player_id = ' ||NEW.player_id||','|| 
									'team_id = ' ||NEW.team_id||','|| 
									'season_id = ' ||NEW.season_id||','|| 
									'contract_start_dt = ' ||''''||NEW.contract_start_dt||''''||','|| 
									'annual_contract_value = ' ||NEW.annual_contract_value||','|| 
									'contract_dur_yr = ' ||NEW.contract_dur_yr  ||
									'WHERE contract_id= '||NEW.contract_id
								);										
		ELSE	
			--raise notice 'I am in trigger insert % , %',NEW.contract_start_dt,c;
			
			PERFORM dblink_exec('myconn',' 
						INSERT INTO CONTRACTS_T ( playing_position,  injured_flag,player_id, team_id, season_id, 
												annual_contract_value , contract_start_dt	, contract_dur_yr)  
						VALUES('||''''||NEW.playing_position||''''||  ',' 
								||''''||NEW.injured_flag||''''||  ',' 
								||NEW.player_id||',' 
								||NEW.team_id||',' 
								||NEW.season_id||',' 
								||NEW.annual_contract_value||',' 
								||''''||NEW.contract_start_dt||''''||',' 
								||NEW.contract_dur_yr||	') 
							');								

	END IF;	
END IF;

IF (TG_OP = 'DELETE') THEN
	raise notice 'I am in trigger delete';
	PERFORM dblink_exec('myconn','DELETE FROM CONTRACTS_T WHERE contract_id= '||OLD.contract_id
								);
END IF;	

--        RAISE EXCEPTION 'Debit value must be non-negative';
/*
MERGE INTO CONTRACTS_T@BLMS_REP x
USING (select :new.contract_id,:new.player_id, :new.team_id, :new.season_id, :new.playing_position, :new.injured_flag
        , :new.annual_contract_value   , :new.contract_start_dt, :new.contract_dur_yr FROM DUAL) y
ON (x.contract_id  = :new.contract_id)
WHEN MATCHED THEN
    UPDATE SET 
            x.player_id = :new.player_id 
            , x.team_id = :new.team_id
            , x.season_id = :new.season_id
            , x.injured_flag = :new.injured_flag
            , x.annual_contract_value = :new.annual_contract_value
            , x.contract_start_dt = :new.contract_start_dt
            , x.contract_dur_yr = :new.contract_dur_yr

WHEN NOT MATCHED THEN
    INSERT (x.player_id, x.team_id, x.season_id, x.playing_position,  x.injured_flag, x.annual_contract_value , x.contract_start_dt, x.contract_dur_yr)  
    VALUES(:new.player_id, :new.team_id, :new.season_id , :new.playing_position, :new.injured_flag, :new.annual_contract_value , :new.contract_start_dt, :new.contract_dur_yr);

*/

RETURN NEW;
EXCEPTION        
    WHEN OTHERS THEN
		RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;  
$$

/*
CREATE  TRIGGER TRG_CONRACTS_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON CONTRACTS_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_CONRACTS_T_REP();
  */
  