#!/bin/bash
MIZ=ddcs.miz

#extracting MIZ files
if [ -f $MIZ ]; then
  pushd src
  /c/Program\ Files/7-Zip/7z.exe x -y ../$MIZ
  popd
else
  echo "MIZ file not found"
fi
