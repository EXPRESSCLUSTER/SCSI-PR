# Configure EXPRESSCLUSTER X with SCSI-PR on Windows

![Configuration](SG%20Configuration.png)

## Prerequisites

- Prepare two Windows servers, both connected to a shared disk. Install EXPRESSCLUSTER X 4.2 with instructions for using a shared disk. (Testing was done on Windows Server 2019 Datacenter — if you're on a newer EXPRESSCLUSTER or Windows Server release, confirm this procedure still applies before following it.)
- [Download the scripts](Windows%20Scripts) needed for an EXPRESSCLUSTER shared disk with SCSI persistent reservation: `start.bat`, `attacker.ps1`, `genw.bat`, and `defender.ps1`.
- Download `sg_persist.exe`, the SCSI-PR utility described in [Windows.md](Windows.md).

Notes:
- A disk heartbeat partition is not needed on the shared disk for this configuration.
- NP resources are not needed because the SCSI-PR function works like NP resources.
- By default, both servers will shut down when EXPRESSCLUSTER detects a dual activation of the group. This solution disables that emergency shutdown and allows the server holding the shared disk reservation to survive. See [Disable Emergency Shutdown](#disable-emergency-shutdown) below.      
- ⚠ The reservation type (`-T`) used in the scripts below doesn't match the type used in the Linux setup in this repo's `README.md`. See the callout there before relying on either as authoritative.

## Create a Cluster

1.	Launch the **Cluster WebUI** dashboard on the Primary server.
2.	After the **Cluster WebUI** window opens, select [**Config mode**] from the dropdown menu of the tool bar. Click [**Cluster generation wizard**] to start the wizard.
3.	In the new window, type a **Cluster Name** (Example: [**sd_cluster**]), select your [**Language**], and click [**Next**].
4.	In the next window, to add another server to the cluster, click [**Add**].
5.	Type the [**Server Name**] or the [**IP Address**] of the [**Secondary Server**], and then click [**OK**].
6.	Both servers are now on the list. If the [**Primary Server**] is not in the top (Master Server) position, move it up. Click [**Next**].

### Set up the network configuration
1.	EXPRESSCLUSTER X automatically detects the IP addresses of the servers. If using one network card, the [**Interconnect List**] is automatically set up. Leave the [**Type**] as [**Kernel Mode**] and leave [**MDC**] as [**Do Not Use**]. Verify that the correct IP addresses for each server are displayed. Click [**Next**].
2.	In the [**NP Resolution**] window, click [**Next**].

### Create a Failover Group
1.	To add a group, in the **Cluster Generation Wizard**, in the [**Group**] section, click [**Add**].
2.	In the next window, select [**failover**] for group [**Type**]. Name the group [***failover1***], click [**Next**], click [**Next**], and then click [**Next**] (three times total).

### Add Group Resources
#### Script Resource
1.	Click [**Add**] to add a **Script Resource**.
2.	Select [**Script resource**] as [**Type**]. For [**Name**] enter [***exec-scsipr-attacker***]. Click [**Next**].
3.	Uncheck [**Follow the default dependency**]. Click [**Next**].
4.	Under [**Recovery Operation at Activity Failure Detection**], change the [**Failover Threshold**] to [***0***] times.
5.	Select [**Stop the cluster service and reboot OS**] as [**Final Action**]. Click [**Next**].
6.	Select [**Start Script**] and click [**Replace**]. Navigate to the downloaded scripts folder and select [[***start.bat***](Windows%20Scripts/start.bat)]. Click [**Open**] and then [**Yes**] to replace the file.
7.	Click [**Add**] and then [**Browse**]. Navigate to the downloaded scripts folder. Choose [***All Files (*.*)***] as type and select [[***attacker.ps1***](Windows%20Scripts/attacker.ps1)]. Click [**Open**] and then [**Save**].
8.	Select [***attacker.ps1***] and click [**Edit**]. Change the `$dev` parameter to the drive letter of the shared disk's data partition (e.g. `$dev="E:"`). Click [**OK**].
9.	Click [**Tuning**].
10.	Set the [**Normal Return Value**] under [**Start**] and [**Stop**] to [***0***]. Click [**OK**]. Click [**Finish**].

#### Disk Resource
1.	Click [**Add**] to add a **Disk Resource**.
2.	Select [**Disk resource**] as [**Type**] and enter [***disk1***] as [**Name**]. Click [**Next**].
3.	Uncheck [**Follow the default dependency**]. Select [***exec-scsipr-attacker***] and click [**Add**]. Click [**Next**].
4.	Click [**Next**] in the [**Recovery Operation**] window.
5.	Enter the [**Drive Letter**] of the shared disk's data partition, e.g. `E:`.
6.	Select [***\<Primary Server>***] under [**Name**] and click [**Add**].
7.	Click [**Connect**] and select the drive letter of the shared disk's data partition, e.g. [***E:\\***]. Click [**OK**].
8.	Select [***\<Secondary Server>***] under [**Name**] and click [**Add**].
9.	Click [**Connect**] and select the drive letter of the shared disk's data partition, e.g. [***E:\\***]. Click [**OK**]. Click [**Finish**].
10.	Click [**Finish**].
11.	Click [**Next**].

### Add Monitor Resource
1.	Click [**Add**] to add a **Monitor Resource**.
2.	Select [**Custom monitor**] as [**Type**]. Enter [***genw-scsipr-defender***] as [**Name**]. Click [**Next**].
3.	Set [**Interval**] to [***1***].
4.	Set [**Retry Count**] to [***0***].
5.	Under [**Monitor Timing**] select [**Active**].
6.	Click [**Browse**] and select [***disk1***] as the **Target Resource**. Click [**OK**]. Click [**Next**].
7.	Under [**Script created with this product**] (genw.bat), click [**Replace**]. Navigate to the downloaded scripts folder and select [[***genw.bat***](Windows%20Scripts/genw.bat)]. Click [**Open**]. Click [**Yes**] to replace.
8.	Select [**Asynchronous**] as [**Monitor Type**]. Click [**Next**].
9.	Under [**Recovery Action**] select [**Execute only the final action**].
10.	Click [**Browse**], select [***failover1***] (group name) as the **Recovery Target**, and click [**OK**].
11.	At the bottom of the dialog, select [**Stop the cluster service and reboot OS**] as [**Final Action**]. Click [**Finish**].
12.	Click [**Finish**].
13.	Click [**Yes**] for the prompt to enable the operations listed.

### Disable Server Auto-Return To Cluster
1.	Click the cluster properties icon (the gear with pencil icon to the right of the cluster name).
2.	Click the [**Extension**] tab in the **Cluster Properties** window.
3.	Set [**Auto Return**] to [**Off**].
4.	Click [**OK**].

### Apply the Configuration File
1.	Click [**Apply the Configuration File**].
2.	For this configuration, a DISK network partition resolution resource is not needed. Click [**No**] to continue uploading the configuration file.
3.	If prompted to set up HBA information, click [**Yes**].
4.	Click [**OK**] to suspend the cluster and apply the changes.
5.	Click [**OK**] to resume the cluster.

### Stop the Cluster
Before continuing, stop the cluster so the remaining setup steps can be applied:

1.	Click [**Operation mode**] and click the [**Status**] tab to view the cluster's status.
2.	In EXPRESSCLUSTER X v4.2, click the triangle to the left of the cluster name to display the operations available for the cluster. Click the icon with the solid black square to stop the cluster.

### Add Defender Script
1.	Navigate to the downloaded scripts folder in File Explorer and edit [[***defender.ps1***](Windows%20Scripts/defender.ps1)].
2.	Change the `$dev` parameter to the drive letter of the shared disk's data partition (e.g. `$dev="E:"`).
3.	Save the file and copy it to `C:\Program Files\EXPRESSCLUSTER\scripts\monitor.s\genw-scsipr-defender`.

### Disable Emergency Shutdown
1.	Navigate to the configuration file folder in File Explorer: `C:\Program Files\EXPRESSCLUSTER\etc\`.
2.	Open `clp.conf` in a text editor.
3.	Add the following under `<root>`:
    ```xml
    <rc>
      <checkgroup>
        <downopt>0</downopt>
      </checkgroup>
    </rc>
    ```
4.	Save and close the file.

### Synchronize Changes
1.	Open a command prompt and run the following command to synchronize changes to the other server:
    ```
    clpcfctrl --push
    ```

### Copy SCSI-PR Utility to Windows Path
1.	Copy `sg_persist.exe` to a folder in Windows' `PATH` (e.g. `C:\Program Files\EXPRESSCLUSTER\bin`).

    **This step must be performed on BOTH servers.**

### Start the Cluster
1.	Start the cluster from the **Cluster WebUI**. In EXPRESSCLUSTER X v4.2, click the icon with the solid black triangle under the cluster name.

-----

# Common Tasks

## Return a server to the cluster in the WebUI

Whenever a server in the cluster is rebooted, it returns in a suspended or isolated state and needs to be manually returned to the cluster.

1.	First, resolve any known problems that may lead to cluster errors, such as network connection issues or disk connection/corruption issues.
2.	From the **Status** tab in **Operation mode**, expand the **Server** label to show the available server operations.
3.	The suspended server will be shown in red. Click the icon of the arrow that curves upward to **Recover server**.
