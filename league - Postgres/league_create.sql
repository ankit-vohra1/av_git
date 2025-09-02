
/*
select team_id,count(1) from contracts_t group by team_id ; 
select team_id,sum(annual_contract_value) from contracts_t group by team_id ; 
select * from dba_objects where object_name in ('TEAMS_T','PLAYERS_T' ,'MATCHES_T','PLAYER_ID_GEN');
create  sequence player_id_gen INCREMENT BY 1    START WITH 101    MINVALUE 100    MAXVALUE 10000000     NOCYCLE    CACHE 10;

*/

drop table contracts_t;
drop table LEAGUE_SEASON_T;
drop table teams_t;
drop table players_t;
drop table trade_hist_t;
drop sequence player_id_gen;

create  sequence player_id_gen INCREMENT BY 1    START WITH 101    MINVALUE 100    MAXVALUE 10000000     NOCYCLE    CACHE 10;

CREATE TABLE contracts_t (
    contract_id            INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 2001 INCREMENT BY 1 NOCYCLE CACHE 10),
    player_id               INTEGER NOT NULL,
    team_id                 INTEGER NOT NULL,
    season_id               INTEGER NOT NULL,
    playing_position        VARCHAR2(30) NOT NULL CHECK(playing_position IN ('Point Guard','Shooting Guard','Small Forward','Power Forward','Center')),
    injured_flag            CHAR(1) NOT NULL,
    annual_contract_value   NUMBER(14, 2) NOT NULL,
    contract_start_dt       DATE NOT NULL,
    contract_dur_yr         INTEGER NOT NULL,
    rec_insert_tmst         DATE DEFAULT SYSDATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE contracts_t ADD CONSTRAINT contracts_t_pk PRIMARY KEY ( contract_id );

CREATE TABLE league_season_t (
    season_id        INTEGER  GENERATED ALWAYS AS IDENTITY (START WITH 1001 INCREMENT BY 1 NOCYCLE CACHE 10),
    season_name       VARCHAR2(20) NOT NULL,
    active_season     CHAR(1) NOT NULL CHECK(active_season IN ('Y','N') ),
    max_players_num   INTEGER ,
    max_season_budget   NUMBER(14, 2)  ,
    rec_insert_tmst         DATE DEFAULT SYSDATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE league_season_t ADD CONSTRAINT league_t_pk PRIMARY KEY ( season_id );

CREATE TABLE players_t (
    player_id          INTEGER ,
    name              VARCHAR2(50) NOT NULL,
    rec_insert_tmst         DATE DEFAULT SYSDATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE players_t ADD CONSTRAINT players_pk PRIMARY KEY ( player_id );

CREATE TABLE teams_t (
    team_id           INTEGER   ,
    team_name         VARCHAR2(30) NOT NULL,
    rec_insert_tmst         DATE DEFAULT SYSDATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE teams_t ADD CONSTRAINT teams_pk PRIMARY KEY ( team_id );

CREATE TABLE trade_hist_t (
    trade_id          INTEGER  GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 10) ,
    player_id         INTEGER NOT NULL,
    current_team      INTEGER NOT NULL,
    previous_team     INTEGER NOT NULL,
    txn_dt            DATE NOT NULL,
    rec_insert_tmst         DATE DEFAULT SYSDATE,
    rec_upd_tmst            DATE DEFAULT NULL
);

ALTER TABLE trade_hist_t ADD CONSTRAINT contracts_tv1_pk PRIMARY KEY ( trade_id );

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




/*
truncate table LEAGUE_SEASON_T;
*/

insert into LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2016-2017' ,  'N' , 15, 50000000 ); 
insert into LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2017-2018' ,  'N' , 12, 50000000 ) ;
insert into LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2018-2019' ,  'N' , 18, 50000000 ) ;
insert into LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2019-2020' ,  'N' , 10, 50000000 ) ;
insert into LEAGUE_SEASON_T (season_name,active_season,max_players_num,max_season_budget) values ( '2020-2021' ,  'Y' , NULL, 50000000) ;

commit;

/*
truncate table teams_t;
*/

insert into teams_t (team_name) values ( 'Chennai SK') ;
insert into teams_t (team_name) values ( 'Punjab WR') ;
insert into teams_t (team_name) values ( 'Rajasthan RY') ;
insert into teams_t (team_name) values ( 'Mumbai CH') ;
insert into teams_t (team_name) values ( 'Pune PR') ;
--insert into teams_t values (, 'Delhi DD', SYSDATE, NULL) ;

commit;

/*
truncate table players_t;
*/

insert into players_t (name) values ( 'Dave') ;
insert into players_t (name) values ( 'Arun') ;
insert into players_t (name) values ( 'Mahesh') ;
insert into players_t (name) values ( 'Guru') ;
insert into players_t (name) values ( 'Raj') ;
insert into players_t (name) values ( 'Mike') ;
insert into players_t (name) values ( 'Suru') ;
insert into players_t (name) values ( 'Pavi') ;
insert into players_t (name) values ( 'Kalu') ;
insert into players_t (name) values ( 'Mesi') ;
insert into players_t (name) values ( 'Rupa') ;
insert into players_t (name) values ( 'Gana') ;
insert into players_t (name) values ( 'Titu') ;
insert into players_t (name) values ( 'Kaha') ;
insert into players_t (name) values ( 'Rana') ;
insert into players_t (name) values ( 'Jahan') ;
insert into players_t (name) values ( 'Aurangzeb') ;
insert into players_t (name) values ( 'Akash') ;
insert into players_t (name) values ( 'Mamtani') ;
insert into players_t (name) values ( 'Amit') ;
insert into players_t (name) values ( 'Abhishek') ;
insert into players_t (name) values ( 'Parbhakar') ;
insert into players_t (name) values ( 'Prabhdeep') ;
insert into players_t (name) values ( 'Rahul') ;
insert into players_t (name) values ( 'Padosi') ;
insert into players_t (name) values ( 'Kajart') ;
insert into players_t (name) values ( 'Malik') ;
insert into players_t (name) values ( 'Rahi') ;
insert into players_t (name) values ( 'Parkash') ;
insert into players_t (name) values ( 'Raghuveer') ;
insert into players_t (name) values ( 'Adarsh') ;
insert into players_t (name) values ( 'AB') ;
insert into players_t (name) values ( 'Ankit') ;
insert into players_t (name) values ( 'Sagar') ;
insert into players_t (name) values ( 'Raju C') ;
insert into players_t (name) values ( 'Malay') ;
insert into players_t (name) values ( 'Sourabh') ;
insert into players_t (name) values ( 'Vikas') ;
insert into players_t (name) values ( 'Kajala') ;
insert into players_t (name) values ( 'Vimal') ;
insert into players_t (name) values ( 'Harman') ;
insert into players_t (name) values ( 'Hart1') ;
insert into players_t (name) values ( 'Wahet') ;
insert into players_t (name) values ( 'Junagad') ;
insert into players_t (name) values ( 'Ralao') ;
insert into players_t (name) values ( 'Charles') ;
insert into players_t (name) values ( 'Chuck') ;
insert into players_t (name) values ( 'Mahesh N') ;
insert into players_t (name) values ( 'Guru Raj ') ;
insert into players_t (name) values ( 'RajBabbar') ;
insert into players_t (name) values ( 'Mike T') ;
insert into players_t (name) values ( 'Surulaya') ;
insert into players_t (name) values ( 'Pavina') ;
insert into players_t (name) values ( 'Kalupar') ;
insert into players_t (name) values ( 'Mesi D') ;
insert into players_t (name) values ( 'Rupankar ') ;
insert into players_t (name) values ( 'Ganater') ;
insert into players_t (name) values ( 'Titutim') ;
insert into players_t (name) values ( 'Kahapat ') ;
insert into players_t (name) values ( 'Ranaji') ;
insert into players_t (name) values ( 'Mike T') ;
insert into players_t (name) values ( 'Surulaya') ;
insert into players_t (name) values ( 'Pavina') ;
insert into players_t (name) values ( 'Kalupar') ;
insert into players_t (name) values ( 'Jatin') ;
insert into players_t (name) values ( 'Bhavan') ;
insert into players_t (name) values ( 'Rulan') ;
insert into players_t (name) values ( 'Grat') ;
insert into players_t (name) values ( 'Pushkar') ;
insert into players_t (name) values ( 'janam') ;
insert into players_t (name) values ( 'Rochak') ;
insert into players_t (name) values ( 'Balu') ;
insert into players_t (name) values ( 'Machin') ;
insert into players_t (name) values ( 'Keshav') ;
insert into players_t (name) values ( 'Mahesh') ;
insert into players_t (name) values ( 'Suresh') ;
insert into players_t (name) values ( 'Aamesh') ;
insert into players_t (name) values ( 'Mahinder') ;
insert into players_t (name) values ( 'Amarnath') ;
insert into players_t (name) values ( 'Sam') ;

commit;

select * from LEAGUE_SEASON_T;
select * from teams_t;
select * from players_t;

commit;

/*
truncate table contract_t
*/

insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (501,1,1,1005,'Point Guard','N',2000000,to_date('01-01-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (502,1,2,1005,'Shooting Guard','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (503,1,3,1005,'Small Forward','N',4000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (504,1,4,1005,'Center','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (505,1,5,1005,'Point Guard','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (506,1,6,1005,'Shooting Guard','N',7000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (507,1,7,1005,'Small Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (508,1,8,1005,'Power Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (509,1,9,1005,'Center','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (510,1,10,1005,'Point Guard','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (511,1,11,1005,'Shooting Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (512,1,12,1005,'Small Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (513,1,13,1005,'Power Forward','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (514,1,14,1005,'Center','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (515,1,15,1005,'Power Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (516,2,1,1005,'Point Guard','N',4000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (517,2,2,1005,'Shooting Guard','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (518,2,3,1005,'Small Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (519,2,4,1005,'Center','N',6000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (520,2,5,1005,'Power Forward','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (521,2,6,1005,'Point Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (522,2,7,1005,'Shooting Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (523,2,8,1005,'Small Forward','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (524,2,9,1005,'Center','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (525,2,10,1005,'Power Forward','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (526,2,11,1005,'Power Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (527,2,12,1005,'Point Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (528,3,1,1005,'Power Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (529,3,2,1005,'Shooting Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (530,3,3,1005,'Small Forward','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (531,3,4,1005,'Center','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (532,3,5,1005,'Power Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (533,3,6,1005,'Point Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (534,3,7,1005,'Shooting Guard','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (535,3,8,1005,'Small Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (536,3,9,1005,'Center','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (537,3,10,1005,'Point Guard','N',4000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (538,3,11,1005,'Power Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (539,3,12,1005,'Shooting Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (540,3,13,1005,'Small Forward','N',9000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (541,3,14,1005,'Center','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (542,3,15,1005,'Point Guard','N',4000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (543,4,1,1005,'Point Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (544,4,2,1005,'Shooting Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (545,4,3,1005,'Small Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (546,4,4,1005,'Center','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (547,4,5,1005,'Power Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (548,4,6,1005,'Point Guard','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (549,4,7,1005,'Shooting Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (550,4,8,1005,'Small Forward','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (551,4,9,1005,'Center','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (552,4,10,1005,'Power Forward','N',4000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (553,4,11,1005,'Shooting Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (554,4,12,1005,'Small Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (555,5,1,1005,'Point Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (556,5,2,1005,'Shooting Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (557,5,3,1005,'Small Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (558,5,4,1005,'Center','N',8000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (559,5,5,1005,'Power Forward','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (560,5,6,1005,'Point Guard','N',4000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (561,5,7,1005,'Shooting Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (562,5,8,1005,'Small Forward','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (563,5,9,1005,'Center','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (564,5,10,1005,'Power Forward','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (565,5,11,1005,'Point Guard','N',5000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (566,5,12,1005,'Shooting Guard','N',2000000,to_date('01-02-2020','DD-MM-YYYY'),3);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (567,5,13,1005,'Small Forward','N',3000000,to_date('01-02-2020','DD-MM-YYYY'),1);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (568,5,14,1005,'Center','N',7000000,to_date('01-02-2020','DD-MM-YYYY'),2);
insert into contracts_t (player_id,team_id,player_seq,season_id,playing_position,injured_flag,annual_contract_value,contract_start_dt,contract_dur_yr) values (569,5,15,1005,'Point Guard','N',1000000,to_date('01-02-2020','DD-MM-YYYY'),3);

COMMIT;

/*
Create a function which places a player on an injury list. Also, create a function or the same one to remove a player from an injury list.  
*/

SELECT COUNT(1) cnt FROM CONTRACTS_T WHERE injured_flag='Y';
               
               select fn_toggle_injured(5181) from dual;

			create or replace FUNCTION fn_toggle_injured (id NUMBER DEFAULT 0) RETURN VARCHAR2 AS

v_errm          VARCHAR2(200);
v_continue      PLS_INTEGER     := 0 ;
PRAGMA          AUTONOMOUS_TRANSACTION;

BEGIN
       
        /* Check if player parameter is a valid */
        SELECT CASE WHEN  c.cnt = 1 THEN 1 ELSE 0 END 
        INTO v_continue
        FROM (SELECT COUNT(1) cnt FROM CONTRACTS_T WHERE player_id=id) c ; 

        IF v_continue = 0 THEN
            DBMS_OUTPUT.PUT_LINE ('Failed : Invalid Player id');
            RETURN 'Failed : Invalid Player id' ;
        END IF;
                        
        UPDATE  CONTRACTS_T 
        SET     injured_flag=  'Y' 
        WHERE   player_id = id
        AND     injured_flag='N';
        
        IF SQL%ROWCOUNT =1 THEN
            COMMIT; 
            RETURN 'Success: Marked Injured' ;
        ELSE
            ROLLBACK;
        END IF;
        
        UPDATE  CONTRACTS_T 
        SET     injured_flag=  'N' 
        WHERE   player_id = id
        AND     injured_flag='Y';
        
        IF SQL%ROWCOUNT =1 THEN
            COMMIT; 
            RETURN 'Success: Marked NOT Injured' ;
        ELSE
            ROLLBACK;
        END IF;

EXCEPTION

WHEN OTHERS THEN
        ROLLBACK;
        v_errm := SUBSTR(SQLERRM, 1 , 200);
        RETURN ('Error errmsg=>'||v_errm||' :: '||DBMS_UTILITY.format_error_backtrace);
END;



/*
Create a function or a procedure to create trade between two teams. Allow trading multiple players from each side. 
*/

--Create a function or a procedure to create trade between two teams. Allow trading multiple players from each side. 
--Teams can trade players. It is important to know when teams are doing trades, a sum of player’s contracts on each side must be similar. 
--There can be a difference of 20% of overall traded value. 
--E.g. Player A and B have an annual contract value of $10.000.000 and a team wants to trade them in order to get a player C. 
--Their annual contract value is $12.000.000. This is allowed, however, teams must be sure they have enough empty spots on a roster. 
--Players can get injured during a season. In that case, their contract is not calculated in a budget. Also, in that case, an empty spot is available on a team roster. 
select regexp_substr ('507,508,509,10002', '[^,]+',1, rownum) str
                from dual
                connect by level <= regexp_count ('507,508,509,10002', '[^,]+');
select * from contracts_t;
		drop type table_stat_log;
		create or replace type stat_log_obj as object (msg VARCHAR2(200) );
		/
		--Create a nested table for holding luxury tax records to be returned
		create or replace type table_stat_log as table of stat_log_obj;
		/

		--Create the function to trade players



/*
Create a function which will provide information about the most expensive starting lineup for a specific team. A starting lineup has one player on each position and it has to return five players, one for each position. 
Players can get injured during a season. In that case, their contract is not calculated in a budget. Also, in that case, an empty spot is available on a team roster. 
*/

		--Create an object type for data
		drop type table_expensive_lineup;
		create or replace type expensive_lineup_obj as object (player_id INTEGER, name VARCHAR2(30),playing_position VARCHAR2(30)  );
		/
		--Create a nested table for holding records to be returned
		create or replace type table_expensive_lineup as table of expensive_lineup_obj;
		/

		--Create the function 
		create or replace function fn_ret_expensive_lineup(t_id INTEGER) return table_expensive_lineup is 
		 rec1 table_expensive_lineup := table_expensive_lineup(); 
		begin
		    for r in (SELECT p.player_id,p.name,e.playing_position FROM (
			    select player_id,playing_position ,annual_contract_value , row_number() OVER(partition by playing_position ORDER BY annual_contract_value desc, player_id) r
			    from contracts_t
			    where team_id=t_id
			    AND injured_flag='N') e
                ,players_t p
			    WHERE r = 1
                AND p.player_id=e.player_id
			    ORDER BY playing_position) 
		    loop
		    
		    rec1.extend;
		    rec1(rec1.count) := expensive_lineup_obj(r.player_id,r.name,r.playing_position);
		 
		    end loop;
		    
		    return rec1;
		end;
		/
		select * from table (fn_ret_expensive_lineup(5));



/*
Create a function which provides monthly validation if some of the teams breached a contract limit. This function should generate luxury tax record.
Players can get injured during a season. In that case, their contract is not calculated in a budget. Also, in that case, an empty spot is available on a team roster. 
*/

		--Create an object type for luxury tax data
		drop type table_lux_tax;
		create or replace type lux_tax_obj as object (team_id number, name varchar2(30),tax NUMBER(14,3)   );
		/
		--Create a nested table for holding luxury tax records to be returned
		create or replace type table_lux_tax as table of lux_tax_obj;
		/

		--Create the function to generate and return tax data
		create or replace function fn_lux_tax return table_lux_tax is 
		 rec1 table_lux_tax := table_lux_tax(); 
		begin
		    for r in (select t.team_id,t.team_name,(e.s-50000000) TAX
			    FROM teams_t t
			    ,(SELECT team_id,sum(annual_contract_value) s FROM contracts_t WHERE INJURED_FLAG='N' group by team_id ) e
			    WHERE t.team_id = e.team_id
			    AND e.s>50000000 
			    ORDER BY t.team_id) 
		    loop
		    
		    rec1.extend;
		    rec1(rec1.count) := lux_tax_obj(r.team_id,r.team_name,r.tax);
		 
		    end loop;
		    
		    return rec1;
		end;
		/
		select * from table (fn_lux_tax);
		
		
/*
Create a query which provides information which teams went over the budget limit for during the season. 
Players can get injured during a season. In that case, their contract is not calculated in a budget. Also, in that case, an empty spot is available on a team roster. 
*/

		select t.team_name ||' : '|| to_char(e.s) || ' M' over_budget_teams
		FROM teams_t t
		,(SELECT team_id,sum(annual_contract_value) s FROM contracts_t WHERE INJURED_FLAG='N' group by team_id ) e
		WHERE t.team_id = e.team_id
		AND e.s> (SELECT max_season_budget FROM LEAGUE_SEASON_T WHERE active_season = 'Y') 
		ORDER BY t.team_id;

/*
Create a list of most expensive teams and most expensive player. 
Players can get injured during a season. In that case, their contract is not calculated in a budget. Also, in that case, an empty spot is available on a team roster. 
*/
		SELECT '===== Most Expensive Players and Teams =====' FROM DUAL
		UNION ALL
		select team_name ||' : '|| to_char(e.s) || ' M' from teams_t t
		,(SELECT team_id,sum(annual_contract_value) s,row_number() OVER(ORDER BY sum(annual_contract_value) desc ) r
		FROM contracts_t WHERE INJURED_FLAG='N' group by team_id ) e
		WHERE t.team_id = e.team_id
		AND e.r=1
		UNION ALL
		SELECT p.name ||' : '|| to_char(annual_contract_value) || ' M' FROM contracts_t c
		, players_t p
		WHERE annual_contract_value in (SELECT MAX(annual_contract_value) FROM contracts_t WHERE INJURED_FLAG='N')
		AND INJURED_FLAG='N' 
		AND p.player_id=c.player_id
		ORDER BY 1;

