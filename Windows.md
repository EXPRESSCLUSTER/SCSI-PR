# SG_UTILS for Windows
Microsoft provides the structure to write your own utility that uses IOCTL_STORAGE_PERSISTENT_RESERVE_IN and IOCTL_STORAGE_PERSISTENT_RESERVE_OUT. See [PERSISTENT_RESERVE_COMMAND structure](https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddstor/ns-ntddstor-_persistent_reserve_command) for the structure you need to provide for the above IOCTLs. An easier way though is to use the precompiled binaries of sg3_utils (for MinGW) which are available for Linux and Windows. Various SCSI utilities are available in this package, but the tool for SCSI PR is called **sg_persist**. [README.win32](https://github.com/hreinecke/sg3_utils/blob/master/README.win32) provides information on the Windows binary. [A precompiled binary of sg3_utils (for MinGW)](http://sg.danny.cz/sg/sg3_utils.html) is available for download. This site also provides an overview of each utility that sends SCSI commands to devices. Although **sg_persist** is the primary utility to use, **sg_scan** is helpful in showing the storage devices with the key identifier name for the device to be used with the sg_persist utility. Place these utilities in the Windows path. Examples for each of these two utilities follow.    

## Sg_scan
The syntax for sg_scan is:    

      sg_scan.exe -s    
      
The output might be something like the following:    
    
PD0     [CD]    Virtual HD  1.1.0    
PD1             Virtual HD  1.1.0    
PD2     [WX]    Msft      Virtual Disk      1.0   C2BA37F099A88B43B3CA0FEE726A71BF    
    
SCSI0:0,0,0    claimed=1 pdt=0h          Virtual   HD  1.1.    
SCSI0:0,1,0    claimed=1 pdt=0h          Virtual   HD  1.1.    
SCSI3:0,0,0    claimed=1 pdt=0h          Msft      Virtual Disk      1.0    

In the above example, ‘PD2’ is the device identifier for the shared disk. ‘W’ and ‘X’ are partitions on the drive but they also may be used as identifiers by adding a colon afterwards e.g. ‘X:’. A device identifier is needed as a parameter for the sg_persist command. 

## Sg_persist
This utility allows persistent reservations and registrations to be queried and changed. There are two steps to the persistent reservation process. First a reservation key must be registered by the application.  If the key is accepted, the application can then use that key to try and reserve the device.
### Disk reservation
1. Create a key on the device (e.g. 123abc for device PD2)    

       sg_persist -o -G -S 123abc -d PD2    
       
    If successful, move to step 2.
2. Use the key to reserve the device    

       sg_persist -o -R -K 123abc -T 3 -d PD2    
   \*Note that the -T (type) value of ‘3’ gives the owner exclusive access    
    The exit status of sg_persist is 0 when it is successful.
### Query keys
Use the following command to see if any keys have been created on the given device (PD2):    

       sg_persist -i -k -d PD2
### Query reservations
Use the following command to see if any reservations have been made on the given device (PD2):    

       sg_persist -i -r -d PD2    
       
### Release the reservation
Use the following command to release the reservation on the given device (PD2):    

       sg_persist -o -L -K 123abc -T 3 -d PD2    
       
### Release the reservation and clear all reservation keys
Use the following command to clear all reservation keys on the given device (PD2):    

       sg_persist -o -C -K 123abc -d PD2

\*This command can both release the reservation and clear all reservation keys in one step

Information on using the sg_persist tool with EXPRESSCLUSTER can be found in the [Readme](README.md#Setup-steps) file.
