
--prompt Dropping Objects ................

drop table contracts_t;
drop table trade_hist_t;
drop table LEAGUE_SEASON_T;
drop table teams_t;
drop table players_t;

drop table POSITIONS_T;
drop table PLAYER_POSITIONS_T;

drop sequence player_id_gen;
drop sequence trade_id_gen;

drop function fn_trg_league_season_t_rep;
drop function fn_trg_positions_t_rep;
drop function fn_trg_players_t_rep;
drop function fn_trg_teams_t_rep;
drop function fn_trg_trade_hist_t_rep;
drop function fn_trg_conracts_t_rep;

drop function fn_generate_data;
drop function fn_lux_tax;
drop function fn_ret_expensive_lineup;
drop function fn_toggle_injured;
drop function fn_trade_pl;
drop procedure proc_lux_tax;
drop procedure trunc_tbl;

/*
drop type table_expensive_lineup2;
drop type table_stat_log;
drop type table_expensive_lineup;
drop type table_lux_tax;

drop type stat_log_obj;
drop type expensive_lineup_obj;
drop type lux_tax_obj;
drop type expensive_lineup2_obj;
BEGIN DBMS_SCHEDULER.drop_job(job_name            =>'GENERATE_LUXURY_TAX_RECS'); end;*/

select (select count(1) from pg_tables where tableowner='ankit') as tables,
(select count(1) from pg_proc where proname like '%fn_trg_%') as trig_proc,
(select count(1) from pg_trigger where tgfoid in (select oid from pg_proc where proname like '%fn_trg_%')) as triggers,
(select count(1) from pg_sequences where sequenceowner='ankit') as seq ,
(select count(1) from information_schema.routines where routine_name like 'fn_%') as func;

select * from information_schema.routines where routine_name like 'fn_%' and routine_name not like '%_rep';

select * from pg_tables where tablename like '%tr%';

select * from pg_proc where proname like '%proc_lux%' or  proname like '%trunc_tbl%';
drop procedure proc_lux_tax;
drop procedure trunc_tbl;
select * from pg_tables where tableowner='ankit';
select * from pg_proc where proname like '%fn_trg_%';
select * from pg_trigger where tgfoid in (select oid from pg_proc where proname like '%fn_trg_%');
select * from pg_sequences where sequenceowner='ankit';

select * from pg_constraint;
select * from pg_class where relname='contracts_t_league_t_fk';

