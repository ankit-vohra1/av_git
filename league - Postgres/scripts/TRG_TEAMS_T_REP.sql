create or replace FUNCTION   FN_TRG_TEAMS_T_REP()   
RETURNS TRIGGER  LANGUAGE PLPGSQL AS
$$
DECLARE
	v_cnt	INTEGER := 0;
BEGIN  

--SELECT dblink_connect('myconn', 'db2remote') into v_flag;

IF (TG_OP = 'INSERT')  OR (TG_OP = 'UPDATE')  THEN

	select * from dblink('myconn','select COUNT(1) from TEAMS_T WHERE team_id ='|| NEW.team_id)  AS t(a integer) INTO v_cnt ;
	
	IF v_cnt > 0 THEN					
			PERFORM dblink_exec('myconn','
									UPDATE TEAMS_T  SET 
									team_name = '||''''||NEW.team_name||''''||
									'WHERE team_id= '||NEW.team_id
								);										
		ELSE	
			PERFORM dblink_exec('myconn',' 
								INSERT INTO TEAMS_T (team_name,team_id)  
								VALUES('||''''||NEW.team_name||''''||  ',' 
										||NEW.team_id||') 
								');																			
	END IF;	
END IF;

IF (TG_OP = 'DELETE') THEN
	raise notice 'I am in trigger delete';
	PERFORM dblink_exec('myconn','DELETE FROM TEAMS_T WHERE team_id= '||OLD.team_id
								);
END IF;	

/*
MERGE INTO TEAMS_T@BLMS_REP x
USING (select :new.team_id, :new.team_name  FROM DUAL) y
ON (x.team_id  = :new.team_id)
WHEN MATCHED THEN
    UPDATE SET 
           x.team_name          =   :new.team_name

WHEN NOT MATCHED THEN
    INSERT (x.team_id, x.team_name )  
    VALUES(:new.team_id, :new.team_name );*/

RETURN NEW;
EXCEPTION        
    WHEN OTHERS THEN
		RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;  
$$

  
  
/*
CREATE  TRIGGER TRG_TEAMS_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON TEAMS_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_TEAMS_T_REP();
  */
  