#this script copy vendor drivers into the aosp src tree, and also copy the vendor binaries that are required for a functioning device but not included in the released vendor drivers. The required binaries can be grabbed from the vendor factory images.
#the assumption is that you have all vendor drivers within vendor_files_src, and you mount the factory system image at factory_sysimg_mnt

aosp_top=../
vendor_files_src=~/sde/proprietary/drivers/aosp_master-preview/vendor.bak
rm -rf $aosp_top/vendor
cp -a $vendor_files_src $aosp_top/vendor

#get the required file list for each vendor
for vendor in lge qcom google broadcom; do

grep $vendor $aosp_top/device/lge/hammerhead/vendor_owner_info.txt >tmpfile
vendor_files=`cat ./tmpfile`
rm -f flist_required_$vendor

for file in $vendor_files; do
    echo $(basename $file :$vendor) >> raw_flist_$vendor
done

sort raw_flist_$vendor -o flist_required_$vendor
rm raw_flist_$vendor 

done

#get the current available file list for each vendor
#required flist minus available flist is the missing flist. 
for vendor in lge qcom broadcom; do
rm -f raw_flist_avail_$vendor flist_avail_$vendor flist_missing_$vendor
ls $aosp_top/vendor/$vendor/hammerhead/proprietary/ >> raw_flist_avail_$vendor
sort raw_flist_avail_$vendor -o flist_avail_$vendor
comm -23 flist_required_$vendor flist_avail_$vendor >>flist_missing_$vendor
echo "===============missing $vendor files:"
cat flist_missing_$vendor|wc -l
done

echo
#grab the missing files
for vendor in lge qcom broadcom; do 

missing_files=`cat flist_missing_$vendor`
echo
echo "===============copying $vendor files" 
factory_sysimg_mnt=/home/nexus/sde/proprietary/factory_img/hammerhead-ktu84p

device_partial=device-partial.mk.$vendor
rm -f $device_partial

for file in $missing_files; do
    echo "searching $file in sysimg"

    find $factory_sysimg_mnt -name $file|egrep '.*'
    if [ $? -ne 0 ]
    then 
      echo "*****$file not found"
      continue
    fi

    filesrc=$(find $factory_sysimg_mnt -name $file)
    echo "cp $filesrc $aosp_top/vendor/$vendor/hammerhead/proprietary/"
    echo "    vendor/$vendor/hammerhead/proprietary/:$filesrc:$vendor \\" >> $device_partial
    cp $filesrc $aosp_top/vendor/$vendor/hammerhead/proprietary
done

done

#generate the device-partial.mk files, and append it to the vendor/xxx/hammerhead/device-partial.mk so that the missing files can be included in the build.  
for vendor in lge qcom broadcom; do
    echo
    echo "include the $vendor missing files in build"
    #remove the trailing blank lines of the device-partial.mk
    cp $aosp_top/vendor/$vendor/hammerhead/device-partial.mk ./
    sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' device-partial.mk > $aosp_top/vendor/$vendor/hammerhead/device-partial.mk
    #print the thins to be appended at first for error checking
    sed 's/\/home\/nexus\/sde\/proprietary\/factory_img\/hammerhead-ktu84p\/mnt/system/g' device-partial.mk.$vendor
    #append the missing files 
    sed 's/\/home\/nexus\/sde\/proprietary\/factory_img\/hammerhead-ktu84p\/mnt/system/g' device-partial.mk.$vendor >> $aosp_top/vendor/$vendor/hammerhead/device-partial.mk
done
