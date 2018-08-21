#!/bin/bash
ZIP=temp.zip
MIZ=ddcs.miz
BACKUP=temp.zip

# backup dir ?
if [ ! -d backup ]; then
  mkdir backup
fi

echo $MIZ

 #backup previous mission...
if [ -f $MIZ ]; then
 BACKUP_FILE=backup/`date +%y%m%d%H%M%s`.miz
 echo backup previous mission to $BACKUP_FILE
 mv $MIZ $BACKUP_FILE
fi

# build new MIZ
pushd src
/c/Program\ Files/7-Zip/7z.exe a -r ../$ZIP -mem=AES256 *
popd
mv $ZIP $MIZ