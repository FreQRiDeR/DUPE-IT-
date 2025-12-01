<div align="center">
             <img src="/DUPE-IT/DUPE-IT.png" width="500" />
             <h1>DUPE-IT!</h1>
</div>

Clone Disks, Partitions with ASR and Create Restorable DMG backups!

* 100% Written is Swift
* Uses built in macOS CLI tools! ASR (Apple Software Restore) and HDIUTIL
* Clone Disks, Partitions, Containers
* Select Source, DMG from dropdown menu and then target disk.
  (target disk will be completely erased!)
* Create a DMG for later restoration, backup!
  (Use default RWZO for read/writable DMG. UDZO option for compressed DMG)

* DON'T BE STUPIT! DUPE-IT!

* By FreQRiDeR, Augment and GitHub CoPilot.


<div align="center">
             <img src="/DUPE-IT!/images/window1.png" width="700" />
             
</div>

Usage

Select Source disk, partition to clone in ’SOURCES’ drop down menu. This is the disk you wish to clone.
Now select the target disk in ‘TARGET’ Dropdown menu. This is the disk you wish to clone to. 
Hit ’Start Cloning’ button. That’s it!

To create a DMG backup of a disk, partition that is restorable, select DMG source disk from the dropdown menu in the DMG Creation section. By default, DUPE-IT! Will create a read/writable DMG. (RWZO format) If you wish to create a compressed DMG to save space, select the UDZO option. (Note, the UDZO DMG is not writable!)

A few tips! If you want to clone a working macOS system and you have multiple systems on the same disk, select the container that houses the system you wish to clone. If the system is in the same container with other systems, (NOT RECCOMENDED!) Both systems will be cloned. DMG backup creation was designed to make backups of working, system disks, containers as it writes pertinent backup data needed for a bootable restoration. If you wish to make a backup of a data only disk I suggest you use Disk Utility to image the disk and use copy, paste for restoration. 

Thanks for using DUPE-IT!

FreQRiDeR
