rem ***************************************
rem *              genw.bat               *
rem *     for SCSI-PR shared disk         *
rem *            version : 1.0            *
rem ***************************************

pushd "C:\Program Files\EXPRESSCLUSTER\scripts\monitor.s\genw-scsipr-defender"
Powershell -File .\defender.ps1
set ret=%ERRORLEVEL%
popd
exit %ret%
