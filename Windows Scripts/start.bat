rem ***************************************
rem *              start.bat              *
rem *     for SCSI-PR shared disk         *
rem *            version : 1.0            *
rem ***************************************





rem ***************************************
rem Check startup attributes
rem ***************************************
IF "%CLP_EVENT%" == "START" GOTO NORMAL
IF "%CLP_EVENT%" == "FAILOVER" GOTO FAILOVER
IF "%CLP_EVENT%" == "RECOVER" GOTO RECOVER

rem Cluster Server is not started
GOTO no_arm





rem ***************************************
rem Normal Startup process
rem ***************************************
:NORMAL


rem Check Disk
IF "%CLP_DISK%" == "FAILURE" GOTO ERROR_DISK


rem *************
rem Routine procedure
rem *************

cd "%CLP_SCRIPT_PATH%"
Powershell -File .\attacker.ps1
set ret=%ERRORLEVEL%
exit %ret%

rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER1

rem *************
rem Highest Priority Process
rem (Example) ARMBCAST /MSG "Running on the highest priority server" /A
rem *************
GOTO EXIT

:ON_OTHER1
rem *************
rem Other Process
rem (Example) ARMBCAST /MSG "Running on the other server(s) except the highest priority server" /A
rem *************
GOTO EXIT





rem ***************************************
rem Recovery process
rem ***************************************
:RECOVER

rem *************
rem Recovery process after return to the cluster
rem *************

GOTO EXIT





rem ***************************************
rem Process for failover
rem ***************************************
:FAILOVER


rem Check Disk
IF "%CLP_DISK%" == "FAILURE" GOTO ERROR_DISK


rem *************
rem Starting applications/services and recovering process after failover
rem *************

cd "%CLP_SCRIPT_PATH%"
Powershell -File .\attacker.ps1
set ret=%ERRORLEVEL%
exit %ret%

rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER2

rem *************
rem Highest Priority Process
rem (Example) ARMBCAST /MSG "Running on the highest priority server(after failover)" /A
rem *************
GOTO EXIT

:ON_OTHER2
rem *************
rem Other Process
rem (Example) ARMBCAST /MSG "Running on the other server(s) except the highest priority server(after failover)" /A
rem *************
GOTO EXIT



rem ***************************************
rem Irregular process
rem ***************************************

rem Process for disk errors
:ERROR_DISK
ARMBCAST /MSG "Failed to connect the switched disk partition" /A
GOTO EXIT


rem Cluster Server is not started
:no_arm
ARMBCAST /MSG "Cluster Server is offline" /A



:EXIT
