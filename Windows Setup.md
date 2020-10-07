# Configure EXPRESSCLUSTER X with SCSI-PR on Windows
## Preparation
- Prepare two Windows servers, both connected to a shared disk. Install EXPRESSCLUSTER X 4.2 with instructions for using a shared disk.    
\*A disk heartbeat partition is not needed on the shared disk for this configuration.

- We don't use any NP resources because SCSI-PR function works like NP resources.

- Download the scripts for EXPRESSCLUSTER shared disk with SCSI persistent reservation.
