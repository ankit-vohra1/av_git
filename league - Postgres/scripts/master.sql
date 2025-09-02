/*
Author  : Ankit Vohra
Date    : Sep-2020
Version : 1.0
Purpose : This master script creates required objects for BLMS DB  
Usage 	: @master.sql
*/

--prompt Creating DB Objects ................

create  sequence player_id_gen INCREMENT BY 1    START WITH 101    MINVALUE 100    MAXVALUE 10000000     NO CYCLE    CACHE 10;
create  sequence trade_id_gen INCREMENT BY 1    START WITH 1    MINVALUE 1    MAXVALUE 10000000     NO CYCLE    CACHE 10;

CREATE TABLE contracts_t (
    contract_id            INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 2001 INCREMENT BY 1 NO CYCLE CACHE 10),
    player_id               INTEGER NOT NULL,
    team_id                 INTEGER NOT NULL,
    season_id               INTEGER NOT NULL,
    playing_position        VARCHAR(30) NOT NULL ,
    injured_flag            CHAR(1) NOT NULL,
    annual_contract_value   NUMERIC(14, 2) NOT NULL,
    contract_start_dt       DATE NOT NULL,
    contract_dur_yr         INTEGER NOT NULL,
    rec_insert_tmst         DATE DEFAULT CURRENT_DATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE contracts_t ADD CONSTRAINT contracts_t_pk PRIMARY KEY ( contract_id );

CREATE TABLE league_season_t (
    season_id        INTEGER  GENERATED ALWAYS AS IDENTITY (START WITH 1001 INCREMENT BY 1 NO CYCLE CACHE 10),
    season_name       VARCHAR(20) NOT NULL,
    active_season     CHAR(1) NOT NULL CHECK(active_season IN ('Y','N') ),
    max_players_num   INTEGER ,
    max_season_budget   NUMERIC(14, 2) ,
    rec_insert_tmst         DATE DEFAULT CURRENT_DATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE league_season_t ADD CONSTRAINT league_t_pk PRIMARY KEY ( season_id );

CREATE TABLE players_t (
    player_id          INTEGER ,
    name              VARCHAR(50) NOT NULL,
    rec_insert_tmst         DATE DEFAULT CURRENT_DATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE players_t ADD CONSTRAINT players_pk PRIMARY KEY ( player_id );

CREATE TABLE teams_t (
    team_id           INTEGER   ,
    team_name         VARCHAR(30) NOT NULL,
    rec_insert_tmst         DATE DEFAULT CURRENT_DATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE teams_t ADD CONSTRAINT teams_pk PRIMARY KEY ( team_id );

CREATE TABLE trade_hist_t (
    txn_id          	INTEGER  GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1 NO CYCLE CACHE 10) ,
    trade_id	      INTEGER NOT NULL,	
    player_id         INTEGER NOT NULL,
    current_team      INTEGER NOT NULL,
    previous_team     INTEGER NOT NULL,
    txn_dt            DATE DEFAULT CURRENT_DATE,
    traded_value   	NUMERIC(14, 2) NOT NULL,
    rec_insert_tmst         DATE DEFAULT CURRENT_DATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE trade_hist_t ADD CONSTRAINT contracts_tv1_pk PRIMARY KEY ( txn_id );

ALTER TABLE contracts_t
    ADD CONSTRAINT contracts_t_league_t_fk FOREIGN KEY ( season_id )
        REFERENCES league_season_t ( season_id );

ALTER TABLE contracts_t
    ADD CONSTRAINT contracts_t_players_t_fk FOREIGN KEY ( player_id )
        REFERENCES players_t ( player_id );

ALTER TABLE contracts_t
    ADD CONSTRAINT contracts_t_teams_t_fk FOREIGN KEY ( team_id )
        REFERENCES teams_t ( team_id );

ALTER TABLE trade_hist_t
    ADD CONSTRAINT trade_hist_t_players_t_fk FOREIGN KEY ( player_id )
        REFERENCES players_t ( player_id );


CREATE TABLE POSITIONS_T (
    position_id        VARCHAR(20) NOT NULL,
    description       VARCHAR(20) NOT NULL,
    rec_insert_tmst         DATE DEFAULT CURRENT_DATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

--ALTER TABLE POSITIONS_T ADD CONSTRAINT POSITIONS_T_pk PRIMARY KEY ( season_id );

CREATE TABLE PLAYER_POSITIONS_T (
	player_id	INTEGER NOT NULL,
    position_id        VARCHAR(20) NOT NULL ,
    rec_insert_tmst         DATE DEFAULT CURRENT_DATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE PLAYER_POSITIONS_T ADD CONSTRAINT PLAYER_POSITIONS_T_pk PRIMARY KEY ( player_id,position_id );

--trigger functions
@@TRG_CONRACTS_T_REP.sql;
@@TRG_LEAGUE_SEASON_T_REP.sql;
@@TRG_PLAYERS_T_REP.sql;
@@TRG_TEAMS_T_REP.sql;
@@TRG_TRADE_HIST_T_REP.sql;
@@TRG_POSITIONS_T_REP.sql

--business functions & procs
@@trunc_tbl.sql;
@@fn_generate_data.sql;
@@fn_ret_expensive_lineup.sql;
@@fn_toggle_injured.sql;
@@fn_lux_tax.sql;
@@proc_lux_tax.sql;
@@fn_trade_pl.sql;


CREATE  TRIGGER TRG_CONRACTS_T_REP   AFTER  INSERT OR UPDATE OR DELETE   ON CONTRACTS_T  FOR EACH ROW  EXECUTE PROCEDURE FN_TRG_CONRACTS_T_REP();
    

CREATE  TRIGGER TRG_LEAGUE_SEASON_T_REP  AFTER  INSERT OR UPDATE OR DELETE   ON LEAGUE_SEASON_T  FOR EACH ROW  EXECUTE PROCEDURE FN_TRG_LEAGUE_SEASON_T_REP();
  
  
CREATE  TRIGGER TRG_PLAYERS_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON PLAYERS_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_PLAYERS_T_REP();
  
  
CREATE  TRIGGER TRG_TEAMS_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON TEAMS_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_TEAMS_T_REP();
  
  
  CREATE  TRIGGER TRG_TRADE_HIST_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON TRADE_HIST_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_TRADE_HIST_T_REP();
  
  CREATE  TRIGGER TRG_POSITIONS_T_REP
  AFTER  INSERT OR UPDATE OR DELETE 
  ON POSITIONS_T
  FOR EACH ROW
  EXECUTE PROCEDURE FN_TRG_POSITIONS_T_REP();





--select fn_generate_data (10 , 15 ,70000000) ;

/*
#prompt Creating object types and object tables ................


create or replace type stat_log_obj as object (msg VARCHAR(200) );
/
create or replace type table_stat_log as table of stat_log_obj;
/


create or replace type expensive_lineup2_obj as object (player_id INTEGER, position VARCHAR(300),contract_value NUMERIC(14,2)  );
/
create or replace type table_expensive_lineup2 as table of expensive_lineup2_obj;
/


create or replace type expensive_lineup_obj as object (player_id INTEGER, name VARCHAR(30),playing_position VARCHAR(30)  );
/
create or replace type table_expensive_lineup as table of expensive_lineup_obj;
/

create or replace type lux_tax_obj as object (team_id INTEGER, name varchar2(30),tax NUMERIC(14,3)   );
/
create or replace type table_lux_tax as table of lux_tax_obj;
/
*/

--prompt Creating functions ................



/*
BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'GENERATE_LUXURY_TAX_RECS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN blms.proc_lux_tax; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'freq=monthly; bymonthday=1; byhour=1; byminute=0; bysecond=0;',
    enabled         => TRUE);
END;
/
*/



