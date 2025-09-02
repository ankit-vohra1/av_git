create or replace FUNCTION   FN_TRG_POSITIONS_T_REP()   
RETURNS TRIGGER  LANGUAGE PLPGSQL AS
$$
DECLARE
	v_cnt	INTEGER := 0;
BEGIN  

--SELECT dblink_connect('myconn', 'db2remote') into v_flag;

IF (TG_OP = 'INSERT')  OR (TG_OP = 'UPDATE')  THEN

	select * from dblink('myconn','select COUNT(1) from POSITIONS_T WHERE position_id ='|| ''''||NEW.position_id||'''')  AS t(a integer) INTO v_cnt ;

	IF v_cnt > 0 THEN					
			PERFORM dblink_exec('myconn','
									UPDATE POSITIONS_T  SET 
									description = '||''''||NEW.description||''''
									||'WHERE position_id ='|| ''''||NEW.position_id||''''
								);										
		ELSE	
			PERFORM dblink_exec('myconn',' 
								INSERT INTO POSITIONS_T (description,position_id)  
								VALUES('||''''||NEW.description||''''||  ',' 
										||''''||NEW.position_id||''''||') 
								');																			
	END IF;	
END IF;

IF (TG_OP = 'DELETE') THEN
	raise notice 'I am in trigger delete';
	PERFORM dblink_exec('myconn','DELETE FROM POSITIONS_T WHERE position_id= '||''''||OLD.position_id||''''
								);
END IF;	

RETURN NEW;
EXCEPTION        
    WHEN OTHERS THEN
		RAISE NOTICE 'ERROR WHILE EXECUTING THE QUERY: % %', SQLSTATE, SQLERRM;
END;  
$$

/*
CREATE  TRIGGER TRG_POSITIONS_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON POSITIONS_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_POSITIONS_T_REP();
*/
  