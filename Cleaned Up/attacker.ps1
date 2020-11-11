#PowerShell
#****************************************
#*		attacker.ps1		*
#*    script for SCSI-PR shared disk 	*
#*		version: 1.0		*
#****************************************

# Parameter
#-----------
$dev = "E:"
#-----------

# finding current node index then make key for Persistent Reservation
$linenum = clpstat --local | Select-String "\*"
$key = "abc00" + $linenum.LineNumber
$downkey = "def00" + $linenum.LineNumber
$interval = 10	#sec

function clear-res {
	sg_persist -o -C -K $key -d $dev
}

function register-key  {
    sg_persist -i -k -d $dev | findstr $downkey
    if ($lastExitCode -eq 0) {
        sg_persist -o -G -K $downkey -S $key -d $dev
    } else {
        sg_persist -o -G -S $key -d $dev
    }
}

function reserve-disk {
	sg_persist -o -R -K $key -T 1 -d $dev
}

#Try to reserve shared disk
register-key
for ($i=0; $i -lt 3; $i++) {
    clear-res
    register-key
    sleep $interval
    reserve-disk
    sg_persist -r $dev | findstr $key
    if ($lastExitCode -eq 0) {
       #Attack succeeded, shared disk reserved
	exit 0
    }
}

# Attack failed
exit 1
