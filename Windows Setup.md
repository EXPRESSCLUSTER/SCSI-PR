# Configure EXPRESSCLUSTER X with SCSI-PR on Windows
## Prerequisites
- Prepare two Windows servers, both connected to a shared disk. Install EXPRESSCLUSTER X 4.2 with instructions for using a shared disk.    
- Download the scripts for EXPRESSCLUSTER shared disk with SCSI persistent reservation.    
    
Notes:    
    - *A disk heartbeat partition is not needed on the shared disk for this configuration.*    
    - *NP resources are not needed because the SCSI-PR function works like NP resources.*
    - *Testing was done on Windows Server 2019 Datacenter*

## Create a Cluster

1.	Launch the **Cluster WebUI** dashboard.
2.	After the **Cluster WebUI** window opens, select [**Config mode**] from the dropdown menu of the tool bar. Click [**Cluster generation wizard**] to start the wizard.
3.	In the new window, type a **Cluster Name** (Example: [**sd_cluster**]), select your [**Language**], and click [**Next**].
4.	In the next window, to add another server to the cluster, click [**Add**].
5.	Type the [**Server Name**] or the [**IP Address**] of [**Secondary Server**], and then click [**OK**].
6.	Both servers are now on the list. If the [**Primary Server**] is not in the top (Master Server) position, then move it up. Click [**Next**].

### Set up the network configuration
1.	EXPRESSCLUSTER X automatically detects the IP addresses of the servers. If using one network card, the [**Interconnect List**] is automatically set up. Leave the [**Type**] as [**Kernel Mode**] and leave [**MDC**] as [**Do Not Use**]. Verify that the correct IP addresses for each server are displayed. Click [**Next**].
2.	In the [**NP Resolution**] window, click [**Next**].

### Create a Failover Group
1.	To add a group, in the **Cluster Generation Wizard**, in the [**Group**] section, click [**Add**].
2.	In the next window, select [**failover**] for group [**Type**]. Name the group [***failover1***], click [**Next**], click [**Next**], and then click [**Next**]. (Three times total).

### Add Group Resources
#### Script Resource
1.	Click [**Add**] to add a **Script Resource**.
2.	Select [**Script resource**] as [**Type**]. For [**Name**] enter [***exec-scsipr-attacker***]. Click [**Next**].
3.	Uncheck [**Follow the default dependency**]. Click [**Next**].
4.	Under the [**Recovery Operation at Activity Failure Detection**] section, change the [**Failover Threshold**] to [***0***] times.
5.	Select [**Stop the cluster service and reboot OS**] as [**Final Action**]. Click [**Next**].
6.	Select [**Start Script**] and click [**Replace**]. Navigate to the downloaded scripts folder and select [***start.bat***]. Click [**Open**] and then [**Yes**] to replace the file.
7.	Click [**Add**] and then [**Browse**]. Navigate to the downloaded scripts folder. Choose [***All Files (*.*)***] as type and select [***attacker.ps1***]. Click [**Open**] and then [**Save**].
8.	Select [***attacker.ps1***] and click [**Edit**]. Change the **$dev** parameter to the drive letter of the data partition of the shared disk (e.g. ***$dev="X:"***). Click [**OK**].
9.	Click [**Tuning**].
10.	Set the [**Normal Return Value**] under [**Start**] and [**Stop**] to [***0***]. Click [**OK**]. Click [**Finish**].

#### Disk Resource
1.	Click [**Add**] to add a **Disk Resource**.
2.	Select [**Disk resource**] as [**Type**] and enter [***disk1***] as [**Name**]. Click [**Next**].
3.	Uncheck [**Follow the default dependency**]. Select [***exec-scsipr-attacker***] and click [**Add**]. Click [**Next**].
4.	Click [**Next**] in the [**Recovery Operation**] window.
5.	Enter the [**Drive Letter**] of the data partition of the shared disk e.g. ***X:*** 
6.	Select [***\<Primary Server>***] under [**Name**] and click [**Add**].
7.	Click [**Connect**] and select the drive letter of the data partition of the shared disk e.g. [***X:\\***]. Click [**OK**].
8.	Select [***\<Secondary Server***>] under [**Name**] and click [**Add**].
9.	Click [**Connect**] and select the drive letter of the data partition of the shared disk e.g. [***X:\\***]. Click [**OK**]. Click [**Finish**].
10.	Click [**Finish**].
11.	Click [**Next**].

### Add Monitor Resource
1.	Click [**Add**] to add a **Monitor Resource**.
2.	Select [**Custom monitor**] as [**Type**]. Enter [***genw-scsipr-defender***] as [**Name**]. Click [**Next**].
3.	Set [**Interval**] to [***1***].
4.	Set [**Retry Count**] to [***0***].
3.	Under [**Monitor Timing**] select [**Active**].
4.	Click [**Browse**] and select [***disk1***]. Click [**OK**]. Click [**Next**].
5.	Under [**Script created with this product**] (genw.bat) click [**Replace**]. Navigate to the downloaded scripts folder and select [**genw.bat**]. Click [**Open**]. Click [**Yes**] to replace.
6.	Select [**Asynchronous**] as [**Monitor Type**]. Click [**Next**].
7.	Under [**Recovery Action**] select [**Execute only the final action**].
8.	Click [**Browse**], select [***failover1***] (group name), and click [**OK**].
9.	At the bottom of the dialog, select [**Stop the cluster service and reboot OS**] as [**Final Action**]. Click [**Finish**].
10.	Click [**Finish**].
11.	Click [**Yes**] for the prompt to enable the operations listed.

### Disable Server Auto-Return To Cluster
1.	Click on the cluster properties icon (the gear with pencil icon to the right of the cluster name).
2.	Click the [**Extension**] tabl in the **Cluster Properties** window.
3.	Set [**Auto Return**] to [**Off**].
4.	Click [**OK**].

### Apply the Configuration File
1.	Click [**Apply the Configuration File**].
2.	For this configuration, a DISK network partition resolution resource is not needed. Click [**No**] to continue uploading the configuration file.
3.	If there is a prompt to set up HBA information, click [**Yes**].
4.	Click [**OK**] to suspend the cluster and apply the changes.
5.	Click [**OK**] to resume the cluster.

### Final Steps
1. Click on [**Operation mode**] and click on the [**Status**] tab to view the status.
2. Stop the group [***failover1***] if it is running.
3. Navigate to the downloaded scripts folder in File Explorer and edit [***defender.ps1***]. Change the **$dev** parameter to the drive letter of the data partition of the shared disk (e.g. ***$dev="X:"***). Save the file and copy it to the directory [**"C:\Program Files\EXPRESSCLUSTER\scripts\monitor.s\genw-scsipr-defender"**].
4. Open a command prompt and run the following command to copy the script to the other server:
[***clpcfctrl --push***]
5. Copy **sg_persist.exe** to a folder in Windows' path (e.g. **C:\Program Files\EXPRESSCLUSTER\bin**)
6. Start group [***failover1***] from the **Cluster WebUI**.
