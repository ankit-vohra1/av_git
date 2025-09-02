
--raise notice 'Dropping Objects ................'

drop table contracts_t;
drop table trade_hist_t;
drop table LEAGUE_SEASON_T;
drop table teams_t;
drop table players_t;

drop table POSITIONS_T;
drop table PLAYER_POSITIONS_T;

drop sequence player_id_gen;
drop sequence trade_id_gen;

drop procedure trunc_tbl;
drop function fn_generate_data;
drop function fn_lux_tax;
drop function fn_ret_expensive_lineup;
drop function fn_toggle_injured;
drop function fn_trade_pl;
drop procedure proc_lux_tax;