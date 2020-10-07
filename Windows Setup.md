# Configure EXPRESSCLUSTER X with SCSI-PR on Windows
## Preparation
- Prepare two Windows servers, both connected to a shared disk. Install EXPRESSCLUSTER X 4.2 with instructions for using a shared disk.    
- Download the scripts for EXPRESSCLUSTER shared disk with SCSI persistent reservation.    
Notes:    
\*A disk heartbeat partition is not needed on the shared disk for this configuration.    
\*\*Also note that we don't use any NP resources because the SCSI-PR function works like NP resources.


