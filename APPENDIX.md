## Appendix

### Logical design of the SCSI PR run by the defender node (active side)
### 防御ノード (現用系) が実行する SCSI PR の論理デザイン
```
defender {
	register reservation key
	clear key and reservation
	while (1) {
		register reservation key
		reserve
		if (I do not have the reservation) {
			exit	# become attacker
		}
		sleep 3
	}
}
```

### Logical design of the SCSI PR run by the attacker node (standby side)
### 攻撃ノード (待機系) が実行する SCSI PR の論理デザイン
```
attacker {
	register reservation key
	while (1) {
		clear key and reservation
		register reservation key
		sleep 7
		reserve
		if (I have the reservation) {
			sleep 10 (wait for stop of defender)
			exit	# become defender
		}
	}
}
```

### SCSI-3 Persistent Reservation Commands on Linux

Note: the Linux `sg3_utils` package is required.

To query all registrant keys for a given device:

	#sg_persist -i -k -d /dev/sdd

To query all reservations for a given device:

	#sg_persist -i -r -d /dev/sdd

To register a new *reservation key* `0x123abc`:

	#sg_persist -o -G -S 123abc -d /dev/sdd

To clear all registrants:

	#sg_persist -o -C -K 123abc -d /dev/sdd

To reserve:

	#sg_persist -o -R -K 123abc -T 5 -d /dev/sdd

To release:

	#sg_persist -o -L -K 123abc -T 5 -d /dev/sdd

Commonly used reservation types:
- `5` — Write Exclusive, Registrants Only
- `6` — Exclusive Access, Registrants Only

The section above is a copy of [this page][1].

> **⚠ This doesn't match the rest of the repo.** The example above uses type `5`, and this section
> lists `5` and `6` as the commonly used types — but the Linux scripts in `Linux Scripts/` (`attacker.sh`,
> `defender.sh`) actually use type `3`, and the Windows scripts (`attacker.ps1`, `defender.ps1`) use
> type `1`. See the callout in [README.md](README.md#avoiding-the-inconvenience-in-ec) for the full
> picture. Don't treat any single file in this repo, including this one, as the final word on which
> type to use — verify against your own testing.

[1]: http://aliuhui.blogspot.jp/2012/04/scsi-3-persist-reservation-command-on.html

In my case, the active node became unable to read/write when the standby node used `3` (exclusive access) as the argument for the *type* of the *PROUT* command.    

PROUT コマンドの type 引数に 3 (exclusive access) を用いると、待機系の reserve 成功が 現用系に read/write 不能をもたらした。

Reference / 参照:
https://support.microsoft.com/ja-jp/help/309186/how-the-cluster-service-reserves-a-disk-and-brings-a-disk-online

### For Windows

To obtain `sg_persist` for Windows, refer to [README.win32](https://github.com/hreinecke/sg3_utils/blob/master/README.win32) in the `sg3_utils` repository. A [precompiled binary of sg3_utils (for MinGW)](http://sg.danny.cz/sg/sg3_utils.html) is available. See also [Windows.md](Windows.md) in this repository for more on `sg_persist` for Windows. Once `sg_persist` is obtained, the same approach used for Linux applies to Windows as well.

### SCSI Persistent Reservation Types Reference

| Type | Name | Primary Benefit | Write Access | Read Access / Sharing | Common Use Cases |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **1** | **Write Exclusive** | Protects data modifications while allowing universal read access. | Reserving host only. | Any host on the fabric can read. | Single-writer setups, legacy node initialization, initial cluster storage discovery. |
| **3** | **Exclusive Access** | Provides total isolation for a single host during critical operations. | Reserving host only. | Reserving host only (all others locked out). | Heavy-duty volume initialization, destructive formatting, raw disk backup procedures. |
| **5** | **Write Exclusive – Registrants Only** | Ideal for standard clustered environments sharing a single filesystem. | Any registered host. | Non-registered hosts can read only. | Windows Server Failover Clustering (WSFC) on bare metal, Linux Pacemaker/Corosync (OCFS2, GFS2). |
| **6** | **Exclusive Access – Registrants Only** | Restricts all disk activity strictly to a trusted group of cluster nodes. | Any registered host. | Registered hosts only (unregistered blocked). | High-security multi-node bare-metal clusters, strict multi-host isolation frameworks. |
| **7** | **Write Exclusive – All Registrants** | Simplifies clustering; stays active even if the original creator disconnects. | Any registered host. | Unregistered hosts can read only. | Clustered VMDKs on Broadcom VMware ESXi, virtualized WSFC nodes, multi-pathing environments. |
| **8** | **Exclusive Access – All Registrants** | Provides group-wide total isolation for cooperative cluster workloads. | Any registered host. | Registered hosts only (unregistered blocked). | Multi-node virtualized workloads requiring strict multi-tenant or multi-host read/write isolation. |
