
this script copy vendor drivers into the aosp src tree, and also copy the vendor binaries that are required for a functioning device but not included in the released vendor drivers. The required binaries can be grabbed from the vendor factory images.

the assumption is that you have all vendor drivers within vendor_files_src, and you mount the factory system image at factory_sysimg_mnt
