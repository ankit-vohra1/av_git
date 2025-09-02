create or replace FUNCTION   FN_TRG_PLAYERS_T_REP()   
RETURNS TRIGGER  LANGUAGE PLPGSQL AS
$$
DECLARE
	v_cnt	INTEGER := 0;
BEGIN  

--SELECT dblink_connect('myconn', 'db2remote') into v_flag;

IF (TG_OP = 'INSERT')  OR (TG_OP = 'UPDATE')  THEN

	select * from dblink('myconn','select COUNT(1) from PLAYERS_T WHERE player_id ='|| NEW.player_id)  AS t(a integer) INTO v_cnt ;
	
	IF v_cnt > 0 THEN					
			PERFORM dblink_exec('myconn','
									UPDATE PLAYERS_T  SET 
									name = '||''''||NEW.name||''''||
									'WHERE player_id= '||NEW.player_id
								);										
		ELSE	
			PERFORM dblink_exec('myconn',' 
								INSERT INTO PLAYERS_T (name,player_id)  
								VALUES('||''''||NEW.name||''''||  ',' 
										||NEW.player_id||') 
								');																			
	END IF;	
END IF;

IF (TG_OP = 'DELETE') THEN
	raise notice 'I am in trigger delete';
	PERFORM dblink_exec('myconn','DELETE FROM PLAYERS_T WHERE player_id= '||OLD.player_id
								);
END IF;	

/*
MERGE INTO PLAYERS_T@BLMS_REP x
USING (select :new.player_id, :new.name  FROM DUAL) y
ON (x.player_id  = :new.player_id)
WHEN MATCHED THEN
    UPDATE SET 
           x.name          =   :new.name

WHEN NOT MATCHED THEN
    INSERT (x.player_id, x.name )  
    VALUES(:new.player_id, :new.name );
*/

RETURN NEW;
EXCEPTION        
    WHEN OTHERS THEN
		RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;  
$$
/*
CREATE  TRIGGER TRG_PLAYERS_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON PLAYERS_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_PLAYERS_T_REP();
  */
  