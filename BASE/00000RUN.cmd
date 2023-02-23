@Echo Off

FOR /f %%i IN ('DIR *.Sql /B') do call :RunScript %%i

pause
GOTO :END

  

:RunScript

set "STRTDT=$(ESCAPE_SQUOTE(STRTDT))"
set "STRTTM=$(ESCAPE_SQUOTE(STRTTM))"
set "SRVR=$(ESCAPE_SQUOTE(SRVR))"
set "INST=$(ESCAPE_SQUOTE(INST))"
Echo Executing %1

SQLCMD -S localhost -d XXXXX-m 1 -i %1

Echo Completed %1

 

:END