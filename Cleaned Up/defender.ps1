#PowerShell
#******************************************
#*		defender.ps1 	       	  *
#* monitor script for SCSI-PR shared disk *
#*		version: 1.0		  *
#******************************************

# Parameter
#-----------
$dev = "E:"
#-----------

# finding current node index then making key for Persistent Reserve
$linenum = clpstat --local | Select-String "\*"
$key = "abc00" + $linenum.LineNumber
$downkey = "def00" + $linenum.LineNumber
$interval = 3	#sec

function clear-res {
	sg_persist -o -C -K $key -d $dev
}

function register-key {
	sg_persist -o -G -S $key -d $dev
}

function reserve-disk {
	sg_persist -o -R -K $key -T 1 -d $dev
}

sg_persist -i -k -d $dev | findstr $downkey
if ($lastExitCode -eq 0) {
    #Failed as defender, lost shared disk reservation
    exit 1
}

# Count is used to count how many times the defender failed to reserve the shared disk.
# If the defender fails to reserve twice in a row, this server will SUICIDE.
# Once the defender succeeds to reserve, Count will be reset to 0.
$count = 0
while (1) {
    register-key
    reserve-disk
    sg_persist -r $dev | findstr $key
    if ($lastExitCode -ne 0) {
        $count = $count + 1
        if ($count -eq 2) {
            #Will SUICIDE as failed defender
            break
        }
    } else {
        $count = 0
    }
    sleep $interval
}

# Downkey is set only when reserve is failed.
# Even if a defender script is restarted before OS reboot,
# it will exit before entering the above loop.
# Downkey will be cleared when an attacker script on this server starts
sg_persist -i -k -d $dev | findstr $key
if ($lastExitCode -ne 0) {
    sg_persist -o -G -S $downkey -d $dev
} else {
    sg_persist -o -G -K $key -S $downkey -d $dev
}

exit 1