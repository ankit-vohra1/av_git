create or replace FUNCTION   FN_TRG_TRADE_HIST_T_REP()   
RETURNS TRIGGER  LANGUAGE PLPGSQL AS
$$
DECLARE
	v_cnt	INTEGER := 0;
BEGIN  

--SELECT dblink_connect('myconn', 'db2remote') into v_flag;

IF (TG_OP = 'INSERT')  OR (TG_OP = 'UPDATE')  THEN

	select * from dblink('myconn','select COUNT(1) from TRADE_HIST_T WHERE txn_id ='|| NEW.txn_id)  AS t(a integer) INTO v_cnt ;
	
	IF v_cnt > 0 THEN
						
			PERFORM dblink_exec('myconn','
									UPDATE TRADE_HIST_T  SET 
									trade_id = ' ||NEW.trade_id||','
									'player_id = ' ||NEW.player_id||','|| 
									'current_team = ' ||NEW.current_team||','|| 
									'previous_team = ' ||NEW.previous_team||','|| 
									'txn_dt = ' ||''''||NEW.txn_dt||''''||','|| 
									'traded_value = ' ||NEW.traded_value  ||
									' WHERE txn_id= '||NEW.txn_id
								);										
		ELSE	
			--raise notice 'I am in trigger insert % , %',NEW.contract_start_dt,c;
			
			PERFORM dblink_exec('myconn',' 
						INSERT INTO TRADE_HIST_T ( trade_id, player_id, current_team , previous_team, txn_dt , traded_value)  
						VALUES('||NEW.trade_id||',' 
								||NEW.player_id||',' 
								||NEW.current_team||',' 
								||NEW.previous_team||',' 
								||''''||NEW.txn_dt||''''||',' 
								||NEW.traded_value||	') 
							');								

	END IF;	
END IF;

IF (TG_OP = 'DELETE') THEN
	raise notice 'I am in trigger delete';
	PERFORM dblink_exec('myconn','DELETE FROM TRADE_HIST_T WHERE txn_id= '||OLD.txn_id
								);
END IF;	

--        RAISE EXCEPTION 'Debit value must be non-negative';
/*
 MERGE INTO TRADE_HIST_T@BLMS_REP x
    USING (select :new.trade_id, :new.player_id, :new.current_team , :new.previous_team,:new.traded_value, :new.txn_dt FROM DUAL) y
    ON (x.txn_id  = :new.txn_id)
    WHEN MATCHED THEN
        UPDATE SET 
               x.trade_id           =   :new.trade_id
               , x.player_id        =   :new.player_id
               , x.current_team     =   :new.current_team
               , x.previous_team    =   :new.previous_team
               , x.txn_dt           =   :new.txn_dt
           , x.traded_value	=   :new.traded_value	
    
    WHEN NOT MATCHED THEN
        INSERT (x.trade_id, x.player_id, x.current_team , x.previous_team, x.txn_dt , x.traded_value)  
        VALUES(:new.trade_id, :new.player_id, :new.current_team , :new.previous_team, :new.txn_dt , :new.traded_value );

*/

RETURN NEW;
EXCEPTION        
    WHEN OTHERS THEN
		RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;  
$$


/*
CREATE  TRIGGER TRG_TRADE_HIST_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON TRADE_HIST_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_TRADE_HIST_T_REP();
  */
 