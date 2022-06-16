# Exclusive control of shared-disk for HA cluster using SCSI-3 Persistent Reservation

ECX does not use SCSI-PR (SCSI-3 Persistent Reservation) for exclusive control of shared-disk.
Therefore, it can lose consistency and can occur data loss in a specific configuration and situation.
This document describes how ECX breaks consistency, and how a general failover clustering solutions maintains consistency in such a situation, and 
how to introduce SCSI-PR into ECX so that it guarantees No Data Loss as same as general failover clustering solutions.

----

## An Ideal Case

Explain NP resolution by ECX in a 2-node shared disk type cluster with a typical and ideal configuration.

Premise:
- `PM-A, B` are *physical machines*.
- `SD` is a *shared disk*.
- `SW` is a *network switch*. it has an IP address which ECX (Ping NP resource) uses as a Tie Breaker.
- `G` is a *failover group* (a set of cluster resources).

1. Each node periodically sends an HB (heartbeat) to all nodes (via ethernet).

   `G` is running on `PM-A`.


   ```
	     G
	PM-A[o]-----[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

2. The network between `PM-A` and `SW` is disconnected.
  Become NP state (both nodes cannot communicate with each other).

   ```
	     G
	PM-A[o]--x--[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

3. `PM-A` becomes not receiving HB from `PM-B` and detects HBTO (heartbeat timeout) after the configured time has elapsed, and vice versa.

4. As an NP resolution process, `PM-A` and `PM-B` send ping to `SW`, then "survive if there is a reply" or "suicide if there is no reply".  
`PM-A` suicides and `PM-B` survives as the result.

   ```
	
	PM-A[x]--x--[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

5. `PM-B` performs a failover (starts `G` on `PM-B`).

   ```
	                      G
	PM-A[x]--x--[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

The failover group does not get active at both node in the same time, there is no situation where I/O is issued simultaneously and parallelly from the both nodes to the shared disk, thus the consistency is maintained as long as a failure occurs at a single point, the business operation continues by failover.


## An Inconvenient Case

The difference from "An Ideal Case" is the use of virtual machines `VM-A` and `VM-B` and the type of failure that occurs. Again, the configuration itself is typical.

1. Each node periodically sends an HB (heartbeat) to all nodes (via ethernet).

   `G` is running on `VM-A`.

   ```
	     G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```


2. `VM-A` operation is **delayed** (HB transmission, I/O to shared disk is temporarily stopped).

3. `VM-B` becomes not receiving HB from `VM-A` and detects HBTO (heartbeat timeout) after the configured time has elapsed.

4. As an NP resolution process, `VM-B` sends ping to `SW`, has the reply from `SW`, decides surviving, executes failover (`VM-B` start the failover group `G`).

   ```
	     G                G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

5. The delay of `VM-A` has subsided, HB transmission and I/O to the `SD` are resumed, `VM-B` receives HB from `VM-A` again.

6. Both nodes noticed that "the FOG running on the own node is also running on the other node", according to the common sense of prioritizing data protection over business continuity, commit suicide, and the business continuity is lost.

   ```
	
	VM-A[x]-----[SW]-----[x]VM-B
	     |                |
	     +------[SD]------+
   ```

The failover group `G` become running on both nodes at No. 4, from that time until the both nodes commit suicide at No. 6, the both nodes issue I/Os to the shared disk `SD` simultaneously and in parallel.
This makes the data on the shared disk inconsistent and unreliable.
Inspecting the area on the shared disk with `fsck` command etc. should find files that need to be repaired.
Even if the data can be read without error, the possibility of reading dirty data cannot be ruled out.

In reality, it is almost impossible to know whether the data is reliable after the dual active situation, and even if the file is recovered by `fsck` command etc., there is no guarantee of the consistency.
In almost all cases, a restore from a backup brings the data back to a safe state, and the restore results in the loss of the data updated since the last backup was taken.

The reason for using VM is that a delayed physical machine can be stopped by the watchdog timer, and the problem is more likely not to occur. In VM, the watchdog timer itself is also delayed, the VM continues running, and the problem is more likely to occur.


## How general failover cluster software avoid the inconvenience

Use the same configuration as "An Inconvenient Case".

1. Each node periodically sends an HB (heartbeat) to all nodes (via ethernet).
 
   `G` is running on `VM-A`.

   ```
	     G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

2. `VM-A` operation is **delayed** (HB transmission, I/O to shared disk is temporarily stopped).

3. `VM-B` becomes not receiving HB from `VM-A` and detects HBTO (heartbeat timeout) after the configured time has elapsed.

4. As an NP resolution process, `VM-B` obtains the exclusive access to `SD` by using SCSI-PR (SCSI-3 Persistent Reservation). `VM-A' loses the access to `SD` as the result.

5. `VM-B` which obtained exclusive access to `SD` performs a failover (starts failover group `G` on `VM-B`).

   ```
	     G                G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

6. The VM-A has subsided the delay and resumes HB transmission and I/O to SD, but the I/O does not reach to SD due to the lost of access.
Thus the behavior that breaks the data consistency is eliminated, and business continuity is maintained.

   ```
	                      G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

ECX gained compatibility with a variety of storages at the expense of consistency by not using SCSI-PR. This made ECX unique.
Although ECX aims to enhance consistency, such as Fencing feature, it still makes sense to use SCSI-PR to achieve both consistency and availability as well as other HA clustering software.
Therefore, the following describes how to utilize SCSI-PR in ECX.


## Avoiding the Inconvenience in EC

Use the sg_persist command from the sg3_utils package and do the following to get the same functionality as a typical failover cluster.

- Add a custom monitor resource, set it's monitoring timing to `active`, and run SCSI-PR as a defender node where FOG (failover group) is running on  
  `defender.sh` is a sample script for genw.sh in the custom monitor resource.

- Add an exec resource to the FOG and run SCSI-PR as an attacker node where the FOG is just starting.  
  `attacker.sh` is a sample script for start.sh in the exec resource.

- Set the SD (shared disk) resource to depend on the above exec resource.

By the above, the structure of "reservation retention (defender) by node1 which is the active node" and "reservation acquisition (attacker) by node2 which is the standby node" is enabled for NP situation.


### Setup steps for Linux

- On Cluster WebUI, go to [Config mode]

- Create a cluster
	- Add Group and name it [failover1]

- [ADD resource] at the right side of [failover1]
	- select [EXEC resource] as [Type] > input [exec-scsipr-attacker] as [Name] > [Next]
	- uncheck [Follow the default dependency] > [Next]
	- input [0] times as [Failover Threshold] > select [Stop group] as [Final Action] of [Recovery Operation at Activation Failure Detection] > [Next] 
	- select [Start Script] > [Replace] > select [[attacker.sh](Linux%20Scripts/attacker.sh)] > [Open] > [Edit] > edit the parameter in the script
	- set the `dev` parameter to specify where the SD resource is located. For example, if the data partition is `/dev/sdc1`, specify it's whole device `/dev/sdc/`.

				dev=/dev/sdc

	- [Tuning] > [Maintenance] > input [/opt/nec/clusterpro/log/exec-scsipr-attacker.log] as [Log Output Path] > check [Rotate Log] > [OK] > [Finish]

- [ADD resource] at the right side of [failover1]
	- select [Disk resource] as [Type] > input [disk1] as [Name] > [Next]
	- uncheck [Follow the default dependency] > select [exec-scsipr-attacker] > [Add] > [Next]
	- [Next]
	- (This is just a sample) )select [disk] as [Disk Type] > select [ext3] as [File System] > select [/dev/sdc2] as [Device Name] > input [/mnt] as [Mount Point] > [Finish]

- [Add monitor resource] at the right side of [Monitors]
	- select [Custom monitor] as [Type] > input [genw-scsipr-defender] as [Name] > [Next]

	- select [Active] as [Monitor Timing] > [Browse] > select [disk1] > [OK] > [Next]

	- [Replace] > select [[defender.sh](Linux%20Scripts/defender.sh)] > [Open] > [Edit] > edit the parameter in the script
	- set the `dev` parameter to specify where the SD resource is located. For example, if the data partition is `/dev/sdc1`, specify it's whole device `/dev/sdc/`.

				dev=/dev/sdc

	- select [Asynchronous] as [Monitor Type] > input [/opt/nec/clusterpro/log/genw-scsipr-defender.log] as [Log Output Path] > check [Rotate Log] > [Next]
	- select [Execute only the final action] > [Browse] > select [failover1] > [OK] > select [Stop group] as [Final Action] > [Finish]

- [Apply the Configuration File]

### Setup steps for Windows [link](Windows%20Setup.md)
----
2022.06.16 [Miyamoto Kazuyuki](mailto:kazuyuki@nec.com) 2nd issue  
2020.03.03 [Miyamoto Kazuyuki](mailto:kazuyuki@nec.com) 1st issue
