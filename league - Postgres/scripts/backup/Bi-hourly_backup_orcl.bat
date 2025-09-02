SET ORACLE_HOME=F:\imp_sw\Sw_bkp\Oracle_18c
SET ORACLE_SID=orcl18c
echo %date:~7,2%
call :MonthName %date:~7,2% MONTH
echo %MONTH%

::del C:\BLMS\league\scripts\backup\BLMS_*_%MONTH%*.log
::del C:\BLMS\league\scripts\backup\BLMS_*_%MONTH%*.DMP

F:\imp_sw\Sw_bkp\Oracle_18c\bin\expdp \"sys/ankit@orcl18c as sysdba\"   schemas=BLMS directory=TEST_DIR dumpfile=DB_BKP_%date:~4,2%_%MONTH%_%date:~10,4%_%time:~0,2%_%time:~3,2%.dmp logfile=DB_BKP_%date:~4,2%_%MONTH%_%date:~10,4%_%time:~0,2%_%time:~3,2%.log

::del C:\Users\IBM_ADMIN\Documents\temp\daily_rman_backup_orcl_log.txt

::11g
::C:\oracle\product\11.2.0\dbhome_1\bin\Rman target sys/ankit@orcl cmdfile=C:\Users\IBM_ADMIN\Documents\temp\daily_backup_orcl.txt log=C:\Users\IBM_ADMIN\Documents\temp\daily_rman_backup_orcl_log.txt USING '%date:~4,2%_%date:~7,2%_%date:~10,4%'


::del C:\BLMS\league\scripts\backup\bihourly_rman_backup_orcl18c_log.txt
::F:\imp_sw\Sw_bkp\Oracle_18c\bin\Rman target sys/ankit@orcl18c cmdfile=C:\BLMS\league\scripts\backup\bihourly_backup_orcl18c.txt log=C:\BLMS\league\scripts\backup\bihourly_rman_backup_orcl18c_log.txt USING '%date:~4,2%_%date:~7,2%_%date:~10,4%'


:MonthName %mm% month

:: Func: Returns the name of month from the number of the month.
::
:: Args: %1 month number convert to name of month, 1 or 01 to 12 (by val)
::       %2 var to receive name of month (by ref)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal ENABLEEXTENSIONS&set /a m=100%1%%100
for /f "tokens=%m%" %%a in ('echo/January February March April May June^
  July August September October November December'
) do endlocal&set %2=%%a&goto :EOF