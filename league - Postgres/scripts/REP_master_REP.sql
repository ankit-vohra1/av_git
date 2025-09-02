

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

GRANT ALL PRIVILEGES ON TABLE contracts_t TO postgres,ankit,hr;
GRANT ALL PRIVILEGES ON TABLE league_season_t TO postgres,ankit,hr;
GRANT ALL PRIVILEGES ON TABLE PLAYERS_T TO postgres,ankit,hr;
GRANT ALL PRIVILEGES ON TABLE TEAMS_T TO postgres,ankit,hr;
GRANT ALL PRIVILEGES ON TABLE trade_hist_t TO postgres,ankit,hr;
GRANT ALL PRIVILEGES ON TABLE POSITIONS_T TO postgres,ankit,hr;
GRANT ALL PRIVILEGES ON TABLE PLAYER_POSITIONS_T TO postgres,ankit,hr;
--prompt Creating functions ................

@@trunc_tbl.sql;
@@fn_generate_data.sql;
@@fn_ret_expensive_lineup.sql;
@@fn_toggle_injured.sql;
@@fn_lux_tax.sql;
@@proc_lux_tax.sql;
@@fn_trade_pl.sql;


