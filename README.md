# Exclusive control of shared-disk for HA cluster using SCSI-3 Persistent Reservation

ECX does not use SCSI-PR (SCSI-3 Persistent Reservation) for exclusive control of shared-disk.
Therefore, it can lose consistency and can occur data loss in a specific configuration and situation.
This document describes how ECX breaks consistency, and how a general failover clustering solutions maintains consistency in such a situation, and 
how to introduce SCSI-PR into ECX so that it guarantees No Data Loss as same as general failover clustering solutions.

EC は共有ディスクの排他制御に SCSI PR (SCSI-3 Persistent Reservation) を使用しない。
このため、特定の構成・状況で一貫性を失い、データ損失を起こしうる。
この文書は「EC が如何に一貫性を失うか」「同じ状況に一般的なフェイルオーバークラスタが如何に対処するか」そして「EC に SCSI PR を導入し (一般的なフェイルオーバークラスタ同様に)  一貫性とデータ損失が無いことを保証する方法」を述べる。

----

## An Ideal Case

Explain NP resolution by ECX in a 2-node shared disk type cluster with a typical and ideal configuration.

典型的・理想的な構成の 2ノード共有ディスク型クラスタ を用いて EC における NP解決 を説明する。

Premise:
- `PM-A, B` are *physical machines*.

   物理マシンとして PM-A, B を用いる

- `SD` is a *shared disk*.

  共有ディスクとして "SD" を用いる

- `SW` is a *network switch*. it has an IP address which ECX (Ping NP resource) uses as a Tie Breaker.

  Tie Breaker として Ping NP リソース にネットワークスイッチ "SW" のIPアドレスを用いる

- `G` is a *failover group* (a set of cluster resources).

  フェイルオーバーグループ (クラスタリソースの集合) として "G" を用いる


1. Each node periodically sends an HB (heartbeat) to all nodes (via ethernet).

   各ノードは 定期的に HB (heartbeat) を (ethernet 経由で) 全ノードに送信する。

   `G` is running on `PM-A`.

   FOG (failover group) "G" は PM-A で稼動している。


   ```
	     G
	PM-A[o]-----[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

2. The network between `PM-A` and `SW` is disconnected.
  Become NP state (both nodes cannot communicate with each other).

   PM-A と スイッチ "SW" との間のネットワークが切断状態になる。
   つまり NP 状態 (両ノードがお互いに通信不能な状態) になる。

   ```
	     G
	PM-A[o]--x--[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

3. `PM-A` becomes not receiving HB from `PM-B` and detects HBTO (heartbeat timeout) after the configured time has elapsed, and vice versa.

   PM-A (B) は PM-B (A) からの HB を受信しなくなり、設定時間経過後 HBTO (heartbeat timeout) を検知する。


4. As an NP resolution process, `PM-A` and `PM-B` send ping to `SW`, then "survive if there is a reply" or "suicide if there is no reply".  
`PM-A` suicides and `PM-B` survives as the result.

   NP解決処理として、PM-A, PM-B は Tie Breaker となる スイッチ SW (の IP address) に ping を投げ、「反応が有れば生残」し、「反応が無ければ自殺」する。この結果 PM-A は自殺し、PM-B は生残する。

   ```
	
	PM-A[x]--x--[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

5. `PM-B` performs a failover (starts `G` on `PM-B`).

   PM-B はフェイルオーバを実行する (PM-B で FOG を起動させる)。

   ```
	                      G
	PM-A[x]--x--[SW]-----[o]PM-B
	     |                |
	     +------[SD]------+
   ```

The failover group does not get active at both node in the same time, there is no situation where I/O is issued simultaneously and parallelly from the both nodes to the shared disk, thus the consistency is maintained as long as a failure occurs at a single point, the business operation continues by failover.

障害の発生が 一箇所 である限り、両ノードで FOG が起動状態となり、共有ディスクへ 同時/平行 に I/O を行うような「システム・データ が一貫性を失う状況」は発生せず、また、FO により 業務も継続される。


## An Inconvenient Case

The difference from "An Ideal Case" is the use of virtual machines `VM-A` and `VM-B` and the type of failure that occurs. Again, the configuration itself is typical.

「An Ideal Case」との違いは、サーバとして仮想マシン VM-A, B を用いることと 発生する障害の種類である。これもまた構成そのものは典型的と言える。

1. Each node periodically sends an HB (heartbeat) to all nodes (via ethernet).

   各ノードは 定期的に HB (heartbeat) を (ethernet 経由で) 全ノードに送信する。

   `G` is running on `VM-A`.

   ```
	     G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```


2. `VM-A` operation is **delayed** (HB transmission, I/O to shared disk is temporarily stopped).

   VM-A の動作が **遅延** する (HB送信、共有ディスクへの I/O が一時的に停止する)。

3. `VM-B` becomes not receiving HB from `VM-A` and detects HBTO (heartbeat timeout) after the configured time has elapsed.

   VM-B は VM-A の HB を受信しなくなり、設定時間経過後 HBTO (heartbeat timeout) を検知する。

4. As an NP resolution process, `VM-B` sends ping to `SW`, has the reply from `SW`, decides surviving, executes failover (`VM-B` start the failover group `G`).

   **NP解決処理として** VM-B は tie-breaker となる IP address (上図の [SW]) に ping を投げ、反応が有り 生残 を決断、フェイルオーバを実行する (VM-B で FOG を起動させる)。

   ```
	     G                G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

5. The delay of `VM-A` has subsided, HB transmission and I/O to the `SD` are resumed, `VM-B` receives HB from `VM-A` again.

   VM-A の遅延が治まる (HB送信、共有ディスクへの I/O が再開する)。VM-B は再び VM-A の HB を受信するようになる。

6. Both nodes noticed that "the FOG running on the own node is also running on the other node", according to the common sense of prioritizing data protection over business continuity, commit suicide, and the business continuity is lost.

   両ノードとも「自ノードで稼働中の FOG が 相手ノードでも稼動している」ことに気付き (業務継続よりデータ保護を優先するというお題目に従い) 自殺し、業務停止となる。

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


4番で、両ノード共 FOG が起動状態となり、6番で自殺するまで、両ノードから共有ディスクへ I/O が 同時/並行 に行われる状況が発生する。
これによって 共有ディスクの領域 (ドライブ・パーティション等) 上のデータ (ファイル・ディレクトリ等) は一貫性を失い、そこに保存されていたデータは「信頼できない状態」となる (fsck 等で共有ディスク上の領域を検査すれば 要修正なファイルの発生 が判明するであろう)。
たとえ ファイルがエラー無く読み込めたとしても、読み込んだデータが「化けている」可能性は排除できない。

<!--
上記は 「EC を理想的な構成で使用し、障害の発生が 一箇所 であるにも関わらず『業務継続』も『データ保護』も得られないケースの存在」、言い換えれば「EC が業務継続・データ保護 を確率的に行うこと」を示している。
-->

現実には、更新されてしまったのか否かを後から調査・検証することは困難で、たとえ fsck でファイルが復旧されたとしても そのファイルを用いて業務を再開できる保障は無い。
殆どの場合は テープバックアップ等からのリストアによって 安全な状態に戻すことになり、また、このリストアによって「バックアップが取得された以降に更新されたデータ」を失うことになる (クライアントのログを使用した手動ロールフォワードによってデータを回復するケースの存在も否定はできないが)。

尚、仮想マシンを使用したのは「物理マシンの場合、遅延が生じた PM-A は watchdog timer によって停止されるケースが殆どで、問題が顕在化しにくいから」である。仮想マシンでは watchdog timer 諸共に遅延し、停止に至らない状況が起こりやすい。

## How general failover cluster software avoid the inconvenience

Use the same configuration as "An Inconvenient Case".

「An Inconvenient Case」と同じ構成を用いる。

1. Each node periodically sends an HB (heartbeat) to all nodes (via ethernet).

   各ノードは 定期的に HB (heartbeat) を (ethernet 経由で) 全ノードに送信する。
 
   `G` is running on `VM-A`.

   FOG "G" は VM-A で稼動している。

   ```
	     G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

2. `VM-A` operation is **delayed** (HB transmission, I/O to shared disk is temporarily stopped).

   VM-A の動作が **遅延** する (HB送信、共有ディスクへの I/O が一時的停止する)。

3. `VM-B` becomes not receiving HB from `VM-A` and detects HBTO (heartbeat timeout) after the configured time has elapsed.

   VM-B は VM-A の HB を受信しなくなり、設定時間経過後 HBTO (heartbeat timeout) を検知する。

4. As an NP resolution process, `VM-B` obtains the exclusive access to `SD` by using SCSI-PR (SCSI-3 Persistent Reservation). `VM-A' loses the access to `SD` as the result.

   **NP解決処理として** VM-B は SCSI PR (SCSI-3 Persistent Reservation) を用いて、共有ディスクの排他的アクセスを獲得する。その結果 VM-A は共有ディスクへのアクセスを失う。

5. `VM-B` which obtained exclusive access to `SD` performs a failover (starts failover group `G` on `VM-B`).

   共有ディスクへの排他的アクセスを獲得した VM-B はフェイルオーバを実行する (VM-B で FOG を起動させる)。

   ```
	     G                G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

6. The VM-A has subsided the delay and resumes HB transmission and I/O to SD, but the I/O does not reach to SD due to the lost of access.
Thus the behavior that breaks the data consistency is eliminated, and business continuity is maintained.

   VM-A は遅延が治まり、HB送信、共有ディスクへの I/O を再開するも、共有ディスクへのアクセスを失っているため I/O は失敗し、一貫性を崩す挙動は排除され、業務継続が達成される。

   ```
	                      G
	VM-A[o]-----[SW]-----[o]VM-B
	     |                |
	     +------[SD]------+
   ```

ECX gained compatibility with a variety of storages at the expense of consistency by not using SCSI-PR. This made ECX unique.
Although ECX aims to enhance consistency, such as Fencing feature, it still makes sense to use SCSI-PR to achieve both consistency and availability as well as other HA clustering software.
Therefore, the following describes how to utilize SCSI-PR in ECX.

ECX は SCSI-PR を使わないことで 一貫性を犠牲にして多様なストレージへの適合性を獲得した。この点が ECX をユニークな存在にしている。

ECX は Fencing 機能など逐次機能強化を行い、一貫性を強化しているが、それでも、一貫性と可用性を両立させるため、他のHAクラスタソフトと同様に SCSI-PR を使うことは理に適っている。
そこで、以下では ECX で SCSI-PR を活用する方法を述べる。


## Avoiding the Inconvenience in EC

Use the sg_persist command from the sg3_utils package and do the following to get the same functionality as a typical failover cluster.

sg3_utils パッケージの sg_persist コマンドを使用し、以下を行うことで、一般的なフェイルオーバー型クラスタと同じ状況が得られる。

- Add a custom monitor resource, set it's monitoring timing to `active`, and run SCSI-PR as a defender node where FOG (failover group) is running on  
  `defender.sh` is a sample script for genw.sh in the custom monitor resource.

  カスタムモニタリソース を追加、活性時監視に設定し、自ノードで FOG が稼動したら SCSI PR を防御ノードとして実行する。(同梱の defender.sh はカスタムモニタリソースに登録するスクリプト genw.sh のサンプル)

- Add an exec resource to the FOG and run SCSI-PR as an attacker node where the FOG is just starting.  
  `attacker.sh` is a sample script for start.sh in the exec resource.

   FOG に exec リソース を追加し、FOG 起動時に SCSI PR を攻撃ノードとして実行する。(同梱の attacker.sh は execリソースに登録するスクリプト start.sh のサンプル)

- Set the SD (shared disk) resource to depend on the above exec resource.

  FOG の SDリソース (共有ディスク) を上記 exec リソース に依存するよう設定する。

By the above, the structure of "reservation retention (defender) by node1 which is the active node" and "reservation acquisition (attacker) by node2 which is the standby node" is enabled for NP situation.

これにより、NP状態において「現用系であった node1 による Reservation 保持 (防御)」と「待機系であった node2 による Reservation 獲得(攻撃)」という構造が得られる。

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
