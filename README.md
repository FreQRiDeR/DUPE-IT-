<div align="center">
             <img src="/DUPE-IT!/DUPE-IT.png" width="400" />
             <h1>DUPE-IT!</h1>
</div>

Clone Disks, Partitions with ASR and Create Restorable DMG backups!

* 100% Written is Swift
* Uses built in macOS CLI tools! ASR (Apple Software Restore) and HDIUTIL
* Clone Disks, Partitions, Containers
* Select Source, DMG from dropdown menu and then target disk.
  (target disk will be completely erased!)
* Create a DMG for later restoration, backup!
  (Use default UDZO FOR COMPRESSED DMG, untick for read/writable DMG.
* DON'T BE STUPIT! DUPE-IT!

* By FreQRiDeR, Augment and GitHub CoPilot.


<div align="center">
             <img src="/DUPE-IT!/images/window1.png" width="700" />
             
</div>

Usage

Select Source disk, partition to clone in ’SOURCES’ drop down menu. This is the disk you wish to clone.DISK MUST BE UNMOUNTED!
Now select the target disk in ‘TARGET’ Dropdown menu. This is the disk you wish to clone to. 
Hit ’Start Cloning’ button. That’s it!

To create a DMG backup of a disk, partition that is restorable, select DMG source disk from the dropdown menu in the DMG Creation section. By default, DUPE-IT! Will create a COMPRESSED DMG. (UDZO format) If you wish to create a read,writable DMG to save space, untick the UDZO option. DMG images must be imagescanned before restoring! Select DMG as source and click 'ImageScan DMG' button to perform imagescan. Once completed, restore as usual. (Be patient! Imagescan takes a long time!)

A few tips! If you want to make a bootable clone of a working macOS system, select the APFS container that houses the system you wish to clone. DMG backup creation was designed to make backups of working, system disks, containers as it writes pertinent backup data needed for a bootable restoration.

THANKS FOR USING DUPE-IT!

FreQRiDeR
