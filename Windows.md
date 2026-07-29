# sg3_utils for Windows

Microsoft provides the structures needed to write your own utility using `IOCTL_STORAGE_PERSISTENT_RESERVE_IN` and `IOCTL_STORAGE_PERSISTENT_RESERVE_OUT`. See the [PERSISTENT_RESERVE_COMMAND structure](https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddstor/ns-ntddstor-_persistent_reserve_command) documentation for what you need to provide for these IOCTLs.

An easier route is to use the precompiled binaries of `sg3_utils` (for MinGW), which are available for both Linux and Windows. This package includes various SCSI utilities, but the one used for SCSI-PR is `sg_persist.exe`. [README.win32](https://github.com/hreinecke/sg3_utils/blob/master/README.win32) in the `sg3_utils` repository has details on the Windows binary, and [precompiled binaries of sg3_utils (for MinGW)](http://sg.danny.cz/sg/sg3_utils.html) are available for download from the same site, which also documents each utility that sends SCSI commands to devices.

`sg_persist.exe` is the primary utility used here. `sg_scan.exe` is helpful for listing storage devices along with the key identifier needed as a `sg_persist` parameter — though a drive letter works too. Place both utilities in the Windows `PATH`. Examples for each follow.

## sg_scan

The syntax for `sg_scan` is:

```
sg_scan.exe -s
```

The output might look something like this:

```
PD0     [CD]    Virtual HD  1.1.0
PD1             Virtual HD  1.1.0
PD2     [WX]    Msft      Virtual Disk      1.0   C2BA37F099A88B43B3CA0FEE726A71BF

SCSI0:0,0,0    claimed=1 pdt=0h          Virtual   HD  1.1.
SCSI0:0,1,0    claimed=1 pdt=0h          Virtual   HD  1.1.
SCSI3:0,0,0    claimed=1 pdt=0h          Msft      Virtual Disk      1.0
```

In this example, `PD2` is the device identifier for the shared disk. `W` and `X` are partitions on the drive — they can also be used as identifiers by adding a colon afterward, e.g. `X:`. A device identifier is required as a parameter for the `sg_persist` command.

## sg_persist

This utility queries and changes persistent reservations and registrations. There are two steps to the persistent reservation process: first, a reservation key must be registered by the application; once accepted, the application can use that key to reserve the device.

### Disk reservation

1. Create a key on the device (e.g. `123abc` for device `PD2`):

   ```
   sg_persist -o -G -S 123abc -d PD2
   ```

   If successful, move to step 2.

2. Use the key to reserve the device:

   ```
   sg_persist -o -R -K 123abc -T 3 -d PD2
   ```

   > Note: the `-T` (type) value of `3` gives the owner exclusive access. See the reservation-type
   > callout in [README.md](README.md#avoiding-the-inconvenience-in-ec) — the scripts shipped
   > with this repo don't all use the same type value, so don't assume `3` is what you should use
   > without checking there first.

   The exit status of `sg_persist` is `0` when successful.

### Query keys

To see if any keys have been created on a given device (`PD2`):

```
sg_persist -i -k -d PD2
```

### Query reservations

To see if any reservations have been made on a given device (`PD2`):

```
sg_persist -i -r -d PD2
```

### Release the reservation

To release the reservation on a given device (`PD2`):

```
sg_persist -o -L -K 123abc -T 3 -d PD2
```

### Release the reservation and clear all reservation keys

To clear all reservation keys on a given device (`PD2`), which both releases the reservation and clears the keys in one step:

```
sg_persist -o -C -K 123abc -d PD2
```

---

Information on using `sg_persist` with EXPRESSCLUSTER can be found in the ["Avoiding the Inconvenience in EC"](README.md#avoiding-the-inconvenience-in-ec) section of this repository's `README.md`.
